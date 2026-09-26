import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/calendar_settings_store.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/calendar/device_calendar_scope.dart';

import '../../helpers/fake_permission_service.dart';
import '../../services/fake_device_calendar_platform.dart';

/// Sunday 13 September 2026, 14:32 — the clock of the other UI tests.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _day(int day) => DateTime(2026, 9, day);

void main() {
  late FakePermissionService permissions;
  late FakeDeviceCalendarPlatform platform;
  late CalendarSettingsStore store;
  late DeviceCalendarController controller;

  DeviceCalendarController build({bool enabled = false}) {
    store = CalendarSettingsStore.memory(enabled: enabled);
    return controller = DeviceCalendarController(
      permissions: permissions,
      platform: platform,
      store: store,
    );
  }

  setUp(() {
    permissions = FakePermissionService();
    platform = FakeDeviceCalendarPlatform(
      calendarList: [
        buildDeviceCalendar(id: 'cal-personal', name: 'Kişisel'),
        buildDeviceCalendar(id: 'cal-work', name: 'İş'),
      ],
      eventList: [
        buildCalendarEvent(
          id: 'standup',
          calendarId: 'cal-work',
          title: 'Günlük toplantı',
          start: DateTime(2026, 9, 13, 10),
        ),
        buildCalendarEvent(
          id: 'holiday',
          calendarId: 'cal-personal',
          title: 'Tatil',
          start: _day(13),
          isAllDay: true,
        ),
      ],
    );
  });

  tearDown(() => controller.dispose());

  group('opt-in', () {
    test('off by default: nothing is read and no event is returned', () async {
      await build().load();

      expect(controller.ready, isTrue);
      expect(controller.enabled, isFalse);
      expect(controller.calendars, isEmpty);
      expect(controller.eventsOnDay(_now), isEmpty);
      expect(platform.calls, isEmpty);
    });

    test('enabling reads the calendars and persists the opt-in', () async {
      await build().load();

      expect(await controller.setEnabled(true), isTrue);

      expect(controller.enabled, isTrue);
      expect(controller.calendars.map((c) => c.name), ['Kişisel', 'İş']);
      expect(await store.isEnabled(), isTrue);
    });

    test('a denied permission leaves the toggle off and stores nothing',
        () async {
      permissions.snapshot = permissions.snapshot.copyWith(
        calendar: CalendarPermissionState.denied,
      );
      await build().load();

      expect(await controller.setEnabled(true), isFalse);

      expect(controller.enabled, isFalse);
      expect(await store.isEnabled(), isFalse);
      expect(platform.calls, isEmpty);
    });

    test('disabling forgets the cache at once', () async {
      await build(enabled: true).load();
      controller.eventsOnDay(_now);
      await pumpEventQueue();
      expect(controller.eventsOnDay(_now), isNotEmpty);

      await controller.setEnabled(false);

      expect(controller.enabled, isFalse);
      expect(controller.calendars, isEmpty);
      expect(controller.eventsOnDay(_now), isEmpty);
      expect(await store.isEnabled(), isFalse);
    });
  });

  group('lazy loading and caching', () {
    test('events are read once and served from the cache afterwards', () async {
      await build(enabled: true).load();

      // First ask: nothing cached yet, a read is scheduled (not synchronous).
      expect(controller.eventsOnDay(_now), isEmpty);
      expect(platform.eventQueries, isEmpty);
      await pumpEventQueue();

      expect(platform.eventQueries, hasLength(1));
      expect(
        controller.eventsOnDay(_now).map((e) => e.id),
        ['holiday', 'standup'],
        reason: 'all-day rows come first',
      );

      // Every later ask inside the padded window is answered from the cache.
      for (var i = 0; i < 5; i++) {
        controller.eventsOnDay(_now);
        controller.eventsInRange(_day(13), _day(20));
      }
      await pumpEventQueue();
      expect(platform.eventQueries, hasLength(1));
    });

    test('the window is padded, so paging back a week stays cached', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      final (from, to, _) = platform.eventQueries.single;
      expect(from, _day(13 - DeviceCalendarController.padBeforeDays));
      expect(to, _day(14 + DeviceCalendarController.padAfterDays));

      controller.eventsInRange(_day(7), _day(8));
      await pumpEventQueue();
      expect(platform.eventQueries, hasLength(1));
    });

    test('a range outside the window triggers exactly one more read', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      controller.eventsInRange(DateTime(2027), DateTime(2027, 1, 2));
      controller.eventsInRange(DateTime(2027), DateTime(2027, 1, 2));
      await pumpEventQueue();

      expect(platform.eventQueries, hasLength(2));
    });

    test('recurring occurrences are kept apart per day', () async {
      platform.eventList = [
        for (var day = 13; day <= 15; day++)
          buildCalendarEvent(
            id: 'weekly@$day',
            eventId: 'weekly',
            title: 'Haftalık toplantı',
            start: DateTime(2026, 9, day, 9),
          ),
      ];
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(16));
      await pumpEventQueue();

      for (var day = 13; day <= 15; day++) {
        final onDay = controller.eventsOnDay(_day(day));
        expect(onDay, hasLength(1), reason: 'day $day');
        expect(onDay.single.id, 'weekly@$day');
        expect(onDay.single.eventId, 'weekly');
      }
    });

    test('an all-day event is reported as all-day (no 00:00 time)', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      final allDay = controller.eventsOnDay(_day(13)).first;
      expect(allDay.id, 'holiday');
      expect(allDay.isAllDay, isTrue);
    });
  });

  group('calendar selection', () {
    test('all calendars are shown until the user chooses', () async {
      await build(enabled: true).load();

      expect(controller.visibleCalendarIds, isNull);
      expect(controller.isCalendarVisible('cal-work'), isTrue);
      expect(controller.isCalendarVisible('cal-personal'), isTrue);
      expect(controller.allCalendarsHidden, isFalse);
    });

    test('hiding one calendar persists and re-reads without it', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      await controller.setCalendarVisible('cal-work', false);
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      expect(await store.visibleCalendarIds(), ['cal-personal']);
      expect(platform.eventQueries.last.$3, ['cal-personal']);
      expect(controller.eventsOnDay(_day(13)).map((e) => e.id), ['holiday']);
    });

    test('the selection survives a reload of the controller', () async {
      await build(enabled: true).load();
      await controller.setCalendarVisible('cal-work', false);
      final saved = store;
      controller.dispose();

      controller = DeviceCalendarController(
        permissions: permissions,
        platform: platform,
        store: saved,
      );
      await controller.load();

      expect(controller.visibleCalendarIds, {'cal-personal'});
      expect(controller.isCalendarVisible('cal-work'), isFalse);
    });

    test('every calendar hidden: no read at all and nothing to show', () async {
      await build(enabled: true).load();
      await controller.setCalendarVisible('cal-work', false);
      await controller.setCalendarVisible('cal-personal', false);

      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      expect(controller.allCalendarsHidden, isTrue);
      expect(platform.eventQueries, isEmpty);
      expect(controller.eventsOnDay(_day(13)), isEmpty);
    });
  });

  group('graceful degradation', () {
    test('a revoked permission turns the toggle back off', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();
      expect(controller.eventsOnDay(_day(13)), isNotEmpty);

      platform.failure = const DeviceCalendarReadException(
        DeviceCalendarFailure.permissionDenied,
      );
      permissions.snapshot = permissions.snapshot.copyWith(
        calendar: CalendarPermissionState.denied,
      );
      await controller.refresh();

      expect(controller.enabled, isFalse);
      expect(await store.isEnabled(), isFalse);
      expect(controller.eventsOnDay(_day(13)), isEmpty);
      expect(controller.calendars, isEmpty);
      expect(controller.unavailable, isFalse);
    });

    test('a denial found mid-read degrades without throwing', () async {
      await build(enabled: true).load();
      platform.failure = const DeviceCalendarReadException(
        DeviceCalendarFailure.permissionDenied,
      );

      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      expect(controller.enabled, isFalse);
      expect(await store.isEnabled(), isFalse);
    });

    test('a non-permission failure keeps the feature on', () async {
      await build(enabled: true).load();
      platform.failure = const DeviceCalendarReadException(
        DeviceCalendarFailure.unavailable,
      );

      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();

      expect(controller.enabled, isTrue);
      expect(controller.unavailable, isTrue);
      expect(controller.eventsOnDay(_day(13)), isEmpty);
    });

    test('a stored opt-in without permission is dropped on refresh', () async {
      permissions.snapshot = permissions.snapshot.copyWith(
        calendar: CalendarPermissionState.denied,
      );
      await build(enabled: true).load();

      await controller.refresh();

      expect(controller.enabled, isFalse);
      expect(await store.isEnabled(), isFalse);
    });

    test('openEvent reports failure so the caller can show the sheet',
        () async {
      await build(enabled: true).load();
      platform.openSucceeds = false;

      expect(await controller.openEvent('standup'), isFalse);
      expect(platform.openedEventIds, ['standup']);

      platform.openSucceeds = true;
      expect(await controller.openEvent('standup'), isTrue);
    });

    test('openEvent degrades on a revoked permission', () async {
      await build(enabled: true).load();
      platform.openFailure = const DeviceCalendarReadException(
        DeviceCalendarFailure.permissionDenied,
      );

      expect(await controller.openEvent('standup'), isFalse);
      expect(controller.enabled, isFalse);
    });
  });

  group('refresh', () {
    test('re-reads the current window with fresh data', () async {
      await build(enabled: true).load();
      controller.eventsInRange(_day(13), _day(14));
      await pumpEventQueue();
      expect(controller.eventsOnDay(_day(13)), hasLength(2));

      platform.eventList = [
        buildCalendarEvent(
          id: 'new',
          title: 'Yeni etkinlik',
          start: DateTime(2026, 9, 13, 18),
        ),
      ];
      await controller.refresh();

      expect(controller.eventsOnDay(_day(13)).map((e) => e.id), ['new']);
    });

    test('is a no-op while the feature is off', () async {
      await build().load();
      await controller.refresh();
      expect(platform.calls, isEmpty);
    });
  });

  test('compareCalendarEvents: all-day first, then start, then title', () {
    final events = [
      buildCalendarEvent(id: 'b', title: 'B', start: DateTime(2026, 9, 13, 9)),
      buildCalendarEvent(id: 'a', title: 'A', start: DateTime(2026, 9, 13, 9)),
      buildCalendarEvent(
        id: 'early',
        title: 'Erken',
        start: DateTime(2026, 9, 13, 8),
      ),
      buildCalendarEvent(
        id: 'allday',
        title: 'Tüm gün',
        start: _day(13),
        isAllDay: true,
      ),
    ]..sort(compareCalendarEvents);

    expect(events.map((e) => e.id), ['allday', 'early', 'a', 'b']);
  });
}
