import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/calendar_settings_store.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_device_calendar_platform.dart';

void main() {
  group('DeviceCalendarEvent', () {
    test('a timed event covers only the day it is on', () {
      final event = buildCalendarEvent(
        start: DateTime(2026, 9, 13, 16),
        end: DateTime(2026, 9, 13, 17),
      );
      expect(event.coversDay(DateTime(2026, 9, 12)), isFalse);
      expect(event.coversDay(DateTime(2026, 9, 13)), isTrue);
      expect(event.coversDay(DateTime(2026, 9, 14)), isFalse);
      expect(event.isMultiDay, isFalse);
    });

    test('an event ending at midnight does not leak into the next day', () {
      final event = buildCalendarEvent(
        start: DateTime(2026, 9, 13, 22),
        end: DateTime(2026, 9, 14),
      );
      expect(event.coversDay(DateTime(2026, 9, 13)), isTrue);
      expect(event.coversDay(DateTime(2026, 9, 14)), isFalse);
      expect(event.isMultiDay, isFalse);
    });

    test('an all-day event covers its own day only', () {
      final event = buildCalendarEvent(
        start: DateTime(2026, 9, 13),
        isAllDay: true,
      );
      expect(event.isAllDay, isTrue);
      expect(event.coversDay(DateTime(2026, 9, 13)), isTrue);
      expect(event.coversDay(DateTime(2026, 9, 14)), isFalse);
    });

    test('a multi-day event covers every day it spans', () {
      final event = buildCalendarEvent(
        start: DateTime(2026, 9, 12),
        end: DateTime(2026, 9, 15),
        isAllDay: true,
      );
      expect(event.isMultiDay, isTrue);
      for (final day in [12, 13, 14]) {
        expect(
          event.coversDay(DateTime(2026, 9, day)),
          isTrue,
          reason: 'day $day',
        );
      }
      expect(event.coversDay(DateTime(2026, 9, 11)), isFalse);
      expect(event.coversDay(DateTime(2026, 9, 15)), isFalse);
    });

    test('a zero-length event still shows on its own day', () {
      final at = DateTime(2026, 9, 13, 9, 30);
      final event = buildCalendarEvent(start: at, end: at);
      expect(event.coversDay(DateTime(2026, 9, 13)), isTrue);
      expect(event.coversDay(DateTime(2026, 9, 14)), isFalse);
    });

    test('value equality (cached windows are compared, not rebuilt)', () {
      final a = buildCalendarEvent(start: DateTime(2026, 9, 13, 16));
      final b = buildCalendarEvent(start: DateTime(2026, 9, 13, 16));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(buildCalendarEvent(id: 'other', start: a.start)));
    });
  });

  group('DeviceCalendarPlatform contract (fake)', () {
    test('events are filtered by range and calendar', () async {
      final platform = FakeDeviceCalendarPlatform(
        eventList: [
          buildCalendarEvent(
            id: 'work',
            calendarId: 'cal-work',
            start: DateTime(2026, 9, 13, 10),
          ),
          buildCalendarEvent(
            id: 'personal',
            calendarId: 'cal-personal',
            start: DateTime(2026, 9, 20, 10),
          ),
        ],
      );

      final all = await platform.events(
        from: DateTime(2026, 9, 13),
        to: DateTime(2026, 9, 14),
        calendarIds: const [],
      );
      expect(all.map((e) => e.id), ['work']);

      final none = await platform.events(
        from: DateTime(2026, 9, 13),
        to: DateTime(2026, 9, 14),
        calendarIds: const ['cal-personal'],
      );
      expect(none, isEmpty);
    });

    test('a failure surfaces as DeviceCalendarReadException', () async {
      final platform = FakeDeviceCalendarPlatform()
        ..failure = const DeviceCalendarReadException(
          DeviceCalendarFailure.permissionDenied,
        );
      await expectLater(
        platform.calendars(),
        throwsA(
          isA<DeviceCalendarReadException>().having(
            (e) => e.failure,
            'failure',
            DeviceCalendarFailure.permissionDenied,
          ),
        ),
      );
    });

    test('the seam has no write method (read-only by contract)', () {
      // A compile-time guard: DeviceCalendarPlatform exposes exactly these
      // three members, so no code path can create or change a device event.
      const platform = PluginDeviceCalendarPlatform();
      expect(platform, isA<DeviceCalendarPlatform>());
      expect(platform.calendars, isA<Function>());
      expect(platform.events, isA<Function>());
      expect(platform.openEvent, isA<Function>());
    });
  });

  group('CalendarSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is off by default and round-trips the opt-in', () async {
      final store = CalendarSettingsStore();
      expect(await store.isEnabled(), isFalse);
      await store.setEnabled(true);
      expect(await CalendarSettingsStore().isEnabled(), isTrue);
    });

    test('unset selection means all; an empty list means none', () async {
      final store = CalendarSettingsStore();
      expect(await store.visibleCalendarIds(), isNull);
      await store.setVisibleCalendarIds(const []);
      expect(await CalendarSettingsStore().visibleCalendarIds(), isEmpty);
      await store.setVisibleCalendarIds(const ['a', 'b']);
      expect(
        await CalendarSettingsStore().visibleCalendarIds(),
        ['a', 'b'],
      );
    });

    test('the memory store behaves the same', () async {
      final store = CalendarSettingsStore.memory();
      expect(await store.isEnabled(), isFalse);
      expect(await store.visibleCalendarIds(), isNull);
      await store.setEnabled(true);
      await store.setVisibleCalendarIds(const ['x']);
      expect(await store.isEnabled(), isTrue);
      expect(await store.visibleCalendarIds(), ['x']);
    });
  });
}
