import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';

/// F6.2c: inexact fallback when exact alarms are not permitted.
void main() {
  late FakeNotificationsPlugin plugin;
  late NotificationService service;
  late bool canScheduleExact;
  late int capabilityChecks;

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final first = buildReminder(id: 'first', remindAt: tomorrow);
  final second = buildReminder(
    id: 'second',
    remindAt: tomorrow.add(const Duration(hours: 1)),
  );
  final birthday = buildBirthday(id: 'b1');

  Set<int> birthdayIds(Birthday b) =>
      {for (final o in b.advanceOffsetsMinutes) b.notificationIdFor(o)};

  Set<int> allIds() => {
        first.notificationId,
        second.notificationId,
        ...birthdayIds(birthday),
      };

  Set<AndroidScheduleMode?> pendingModes() =>
      {for (final n in plugin.pending.values) n.scheduleMode};

  Future<void> sync() => service.syncSchedules(
        reminders: [first, second],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plugin = FakeNotificationsPlugin();
    canScheduleExact = true;
    capabilityChecks = 0;
    service = NotificationService.forTesting(
      plugin,
      canScheduleExact: () async {
        capabilityChecks++;
        return canScheduleExact;
      },
    );
  });

  group('mode selection', () {
    test('fingerprint version is 6 (mode per sync, F6.1 language)', () {
      expect(NotificationService.scheduleFingerprintVersion, 6);
    });

    test('scheduleModeFor maps the capability to exact / inexact', () {
      expect(
        NotificationService.scheduleModeFor(canScheduleExact: true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      expect(
        NotificationService.scheduleModeFor(canScheduleExact: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('permitted: everything is scheduled exact', () async {
      await sync();

      expect(plugin.pending.keys.toSet(), allIds());
      expect(pendingModes(), {AndroidScheduleMode.exactAllowWhileIdle});
    });

    test('not permitted: everything is scheduled inexact, nothing fails',
        () async {
      canScheduleExact = false;
      plugin.exactAlarmsPermitted = false;

      await sync();

      expect(plugin.pending.keys.toSet(), allIds());
      expect(pendingModes(), {AndroidScheduleMode.inexactAllowWhileIdle});
      expect(plugin.rejectedExactIds, isEmpty, reason: 'no exact attempt');
    });

    test('the capability is checked once per sync', () async {
      await sync();
      expect(capabilityChecks, 1);

      await sync();
      expect(capabilityChecks, 2);
    });

    test('nothing to schedule: no capability check', () async {
      await service.syncSchedules(
        reminders: const [],
        birthdays: const [],
        notificationsEnabled: true,
      );
      await service.syncSchedules(
        reminders: [first],
        birthdays: [birthday],
        notificationsEnabled: false,
      );

      expect(capabilityChecks, 0);
    });
  });

  group('per-notification fallback', () {
    test('an exact PlatformException falls back to inexact and continues',
        () async {
      // The check says yes, but the OS rejects exact alarms (permission
      // revoked between the check and scheduling).
      plugin.exactAlarmsPermitted = false;

      await sync();

      expect(plugin.rejectedExactIds, hasLength(1),
          reason: 'after the first rejection the sync stays inexact');
      expect(plugin.pending.keys.toSet(), allIds());
      expect(pendingModes(), {AndroidScheduleMode.inexactAllowWhileIdle});
    });

    test('fallback fingerprints are inexact: an exact sync upgrades them',
        () async {
      plugin.exactAlarmsPermitted = false;
      await sync();

      // Permission works again: the next sync reschedules them exact.
      plugin.exactAlarmsPermitted = true;
      plugin.resetCounters();
      await sync();

      expect(plugin.scheduledIds.toSet(), allIds());
      expect(pendingModes(), {AndroidScheduleMode.exactAllowWhileIdle});
    });
  });

  group('capability flip (resync on permission change)', () {
    test('granting the permission reschedules every notification exact',
        () async {
      canScheduleExact = false;
      await sync();
      expect(pendingModes(), {AndroidScheduleMode.inexactAllowWhileIdle});

      canScheduleExact = true;
      plugin.resetCounters();
      await sync();

      expect(plugin.scheduledIds.toSet(), allIds());
      expect(plugin.cancelledIds, isEmpty);
      expect(pendingModes(), {AndroidScheduleMode.exactAllowWhileIdle});

      plugin.resetCounters();
      await sync();
      expect(plugin.writeCalls, 0, reason: 'rescheduled only once');
    });

    test('revoking the permission reschedules every notification inexact',
        () async {
      await sync();
      expect(pendingModes(), {AndroidScheduleMode.exactAllowWhileIdle});

      canScheduleExact = false;
      plugin.exactAlarmsPermitted = false;
      plugin.resetCounters();
      await sync();

      expect(plugin.scheduledIds.toSet(), allIds());
      expect(plugin.rejectedExactIds, isEmpty);
      expect(pendingModes(), {AndroidScheduleMode.inexactAllowWhileIdle});
    });

    test('an unchanged capability writes nothing', () async {
      canScheduleExact = false;
      await sync();

      plugin.resetCounters();
      await sync();

      expect(plugin.writeCalls, 0);
    });
  });
}
