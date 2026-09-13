import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/schedule_sync.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

void main() {
  late MockNotificationSync notifications;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;
  late ScheduleSync schedules;

  final reminders = [buildReminder(id: 'a'), buildReminder(id: 'b')];
  final birthdays = [buildBirthday()];

  setUpAll(registerModelFallbackValues);

  setUp(() {
    notifications = MockNotificationSync();
    geofence = MockGeofenceSync();
    homeWidget = MockHomeWidgetSync();
    when(
      () => notifications.syncSchedules(
        reminders: any(named: 'reminders'),
        birthdays: any(named: 'birthdays'),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    ).thenAnswer((_) async {});
    stubGeofenceSync(geofence);
    stubHomeWidgetSync(homeWidget);
    schedules = ScheduleSync(
      notifications: notifications,
      geofence: geofence,
      homeWidget: homeWidget,
    );
  });

  for (final enabled in [true, false]) {
    test(
        'syncAll syncs notifications (with birthdays), geofences and the '
        'widget in order (notificationsEnabled: $enabled)', () async {
      await schedules.syncAll(
        reminders: reminders,
        birthdays: birthdays,
        settings: AppSettings(notificationsEnabled: enabled),
      );

      verifyInOrder([
        () => notifications.syncSchedules(
              reminders: reminders,
              birthdays: birthdays,
              notificationsEnabled: enabled,
            ),
        () => geofence.syncWithReminders(
              reminders,
              notificationsEnabled: enabled,
            ),
        () => homeWidget.sync(reminders),
      ]);
      verifyNoMoreInteractions(notifications);
      verifyNoMoreInteractions(geofence);
      verifyNoMoreInteractions(homeWidget);
    });
  }

  test('refreshHomeWidget only updates the widget', () async {
    await schedules.refreshHomeWidget(reminders);

    verify(() => homeWidget.sync(reminders)).called(1);
    verifyZeroInteractions(notifications);
    verifyZeroInteractions(geofence);
  });

  group('serialization and coalescing (F1.7)', () {
    late _GatedNotificationSync gated;
    late List<String> log;

    final r1 = [buildReminder(id: 'one')];
    final r2 = [buildReminder(id: 'two')];
    final r3 = [buildReminder(id: 'three')];
    const settings = AppSettings();

    String ids(List<Reminder> list) => list.map((r) => r.id).join(',');

    setUp(() {
      log = [];
      gated = _GatedNotificationSync(log);
      when(
        () => geofence.syncWithReminders(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((inv) async {
        log.add('geofence:${ids(inv.positionalArguments.first)}');
      });
      when(() => homeWidget.sync(any())).thenAnswer((inv) async {
        log.add('widget:${ids(inv.positionalArguments.first)}');
      });
      schedules = ScheduleSync(
        notifications: gated,
        geofence: geofence,
        homeWidget: homeWidget,
      );
    });

    Future<void> syncAll(List<Reminder> list) => schedules.syncAll(
          reminders: list,
          birthdays: birthdays,
          settings: settings,
        );

    test('queued calls wait and only the latest state runs', () async {
      var secondDone = false;
      var thirdDone = false;
      final first = syncAll(r1);
      final second = syncAll(r2)..then((_) => secondDone = true);
      final third = syncAll(r3)..then((_) => thirdDone = true);
      await pumpEventQueue();

      expect(log, ['notifications:one'], reason: 'second waits for first');
      expect(secondDone || thirdDone, isFalse);

      gated.release();
      await first;
      await pumpEventQueue();
      expect(log, [
        'notifications:one',
        'geofence:one',
        'widget:one',
        'notifications:three',
      ]);
      expect(secondDone || thirdDone, isFalse, reason: 'latest still running');

      gated.release();
      await Future.wait([second, third]);
      expect(log, [
        'notifications:one',
        'geofence:one',
        'widget:one',
        'notifications:three',
        'geofence:three',
        'widget:three',
      ]);
      expect(gated.requests, hasLength(2), reason: 'r2 was coalesced away');
    });

    test('a call after the queue drains runs right away', () async {
      final first = syncAll(r1);
      gated.release();
      await first;

      final second = syncAll(r2);
      await pumpEventQueue();
      expect(log.last, 'notifications:two');
      gated.release();
      await second;
      expect(log.last, 'widget:two');
    });

    test('a failing sync reports to its caller and still runs the queue',
        () async {
      final first = syncAll(r1);
      final second = syncAll(r2);
      await pumpEventQueue();

      gated.fail(StateError('boom'));
      await expectLater(first, throwsStateError);
      await pumpEventQueue();
      expect(log.last, 'notifications:two');

      gated.release();
      await second;
      expect(log.last, 'widget:two');
    });
  });
}

/// Her `syncSchedules` çağrısını test [release] veya [fail] edene kadar
/// bekleten sahte; çağrıları [log]'a yazar.
class _GatedNotificationSync implements NotificationSync {
  _GatedNotificationSync(this.log);

  final List<String> log;
  final List<List<Reminder>> requests = [];
  final List<Completer<void>> _gates = [];

  @override
  Future<void> syncSchedules({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  }) {
    requests.add(reminders);
    log.add('notifications:${reminders.map((r) => r.id).join(',')}');
    final gate = Completer<void>();
    _gates.add(gate);
    return gate.future;
  }

  void release() => _gates.removeAt(0).complete();

  void fail(Object error) => _gates.removeAt(0).completeError(error);
}
