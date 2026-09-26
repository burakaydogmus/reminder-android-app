// E2E 4/7 — real notification scheduling through `flutter_local_notifications`.
//
// The host suite schedules against `FakeNotificationsPlugin`; here the OS
// AlarmManager is the recorder. `pendingNotificationRequests()` is read back
// from Android itself, so the diff sync (F1.7), the notification ids (F1.5)
// and the exact-alarm fallback (F6.2c) are verified against the platform.
//
// `--dart-define=E2E_EXACT_ALARMS=deny|allow` says which state the harness put
// the `SCHEDULE_EXACT_ALARM` app op in, so the test can assert that the app
// sees the real permission. The workflow runs this file **twice**: once as
// Android installs it (denied on API 34+, i.e. the inexact fallback path) and
// once with the app op granted.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_service.dart';

import 'helpers/e2e.dart';

/// What the harness set the `SCHEDULE_EXACT_ALARM` app op to: `deny`, `allow`
/// or `unknown` (run without the define, e.g. locally).
const String kExactAlarms =
    String.fromEnvironment('E2E_EXACT_ALARMS', defaultValue: 'unknown');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a timed reminder is scheduled with the OS and cancelled when completed',
    (tester) async {
      await launchApp(tester);
      await reachToday(tester);
      final cubit = cubitOf(tester);

      // F6.2c: the app must see the real app-op state, because the schedule
      // mode is chosen from it once per sync.
      final canScheduleExact = await canScheduleExactAlarms();
      switch (kExactAlarms) {
        case 'deny':
          expect(
            canScheduleExact,
            isFalse,
            reason: 'the harness denied the SCHEDULE_EXACT_ALARM app op, so '
                'canScheduleExactNotifications() must report it — otherwise '
                'the sync picks the exact mode and Android rejects every '
                'zonedSchedule call',
          );
          expect(
            NotificationService.scheduleModeFor(canScheduleExact: false),
            NotificationService.inexactScheduleMode,
          );
        case 'allow':
          expect(
            canScheduleExact,
            isTrue,
            reason: 'the harness granted the SCHEDULE_EXACT_ALARM app op',
          );
          expect(
            NotificationService.scheduleModeFor(canScheduleExact: true),
            NotificationService.exactScheduleMode,
          );
        default:
          // Local run without the define: only assert the call reaches the
          // platform at all.
          expect(canScheduleExact, isA<bool>());
      }

      expect(
        await pendingNotificationIds(),
        isEmpty,
        reason: 'expected no pending notifications on a cleared app',
      );

      final now = DateTime.now();
      final reminder = Reminder(
        id: 'e2e-timed',
        title: 'Faturayı öde',
        isDone: false,
        createdAt: now,
        remindAt: now.add(const Duration(hours: 3)),
      );
      await cubit.addReminder(reminder);

      // Whatever the exact-alarm permission is, the sync must end up with the
      // notification actually scheduled: that is the F6.2c fallback. A
      // hard-coded exact mode throws `exact_alarms_not_permitted` on API 34+
      // and would leave this empty.
      await pumpUntilTrue(
        tester,
        () async =>
            (await pendingNotificationIds()).contains(reminder.notificationId),
        reason: 'for notification ${reminder.notificationId} to be scheduled '
            'with the OS (exact alarms: $kExactAlarms)',
      );
      expect(
        await pendingNotificationIds(),
        {reminder.notificationId},
        reason: 'the sync schedules exactly the desired set (F1.7)',
      );
      expect(
        (await pendingNotificationTitles())[reminder.notificationId],
        reminder.title,
      );

      // The fingerprint store recorded it, and a second sync over unchanged
      // data is a no-op — the diff sync does not churn the OS alarms.
      final firstFingerprints = await storedFingerprints();
      expect(firstFingerprints, isNotNull);
      expect(firstFingerprints, contains(reminder.notificationId));
      await cubit.load();
      await pumpUntilTrue(
        tester,
        () async =>
            (await pendingNotificationIds()).contains(reminder.notificationId),
        reason: 'for the notification to survive a re-sync',
      );
      expect(await storedFingerprints(), firstFingerprints,
          reason: 'an unchanged sync must not rewrite the fingerprints');

      // Completing it removes the alarm.
      await cubit.toggleDone(reminder.id);
      await pumpUntilTrue(
        tester,
        () async => (await pendingNotificationIds()).isEmpty,
        reason: 'for the alarm of the completed reminder to be cancelled',
      );

      // Re-opening it schedules again (the same stable id, F1.5).
      await cubit.toggleDone(reminder.id);
      await pumpUntilTrue(
        tester,
        () async =>
            (await pendingNotificationIds()).contains(reminder.notificationId),
        reason: 'for the re-opened reminder to be scheduled again',
      );

      await cubit.deleteReminder(reminder.id);
      await pumpUntilTrue(
        tester,
        () async => (await pendingNotificationIds()).isEmpty,
        reason: 'for the alarm of the deleted reminder to be cancelled',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a daily recurring reminder is accepted by the OS as a repeating alarm',
    (tester) async {
      await launchApp(tester);
      await reachToday(tester);
      final cubit = cubitOf(tester);

      final now = DateTime.now();
      final rule = RecurrenceRule.daily();
      final reminder = Reminder(
        id: 'e2e-daily',
        title: 'Vitamin al',
        isDone: false,
        createdAt: now,
        remindAt: now.add(const Duration(hours: 2)),
        recurrence: rule,
      );
      // A simple daily rule is one the OS itself can repeat, so the sync must
      // pass `matchDateTimeComponents` — and Android must accept it.
      expect(
        NotificationService.reminderRepeatComponents(rule,
            anchor: reminder.remindAt),
        DateTimeComponents.time,
      );

      await cubit.addReminder(reminder);
      await pumpUntilTrue(
        tester,
        () async =>
            (await pendingNotificationIds()).contains(reminder.notificationId),
        reason: 'for the repeating alarm of the daily reminder',
      );
      expect(await pendingNotificationIds(), {reminder.notificationId});

      // Completing a recurring reminder advances it instead of finishing it
      // (F3.1), so the alarm stays — with the same id, at the next occurrence.
      await cubit.toggleDone(reminder.id);
      await pumpUntilTrue(
        tester,
        () =>
            cubit.state.reminders.any((r) => r.id == reminder.id && !r.isDone),
        reason: 'for the recurring reminder to advance instead of completing',
      );
      expect(
        await pendingNotificationIds(),
        {reminder.notificationId},
        reason: 'a recurring reminder keeps a scheduled next occurrence',
      );

      await cubit.deleteReminder(reminder.id);
      await pumpUntilTrue(
        tester,
        () async => (await pendingNotificationIds()).isEmpty,
        reason: 'for the repeating alarm to be cancelled on delete',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a birthday schedules one yearly alarm per advance offset',
      (tester) async {
    await launchApp(tester);
    await reachToday(tester);
    final cubit = cubitOf(tester);

    final now = DateTime.now();
    final birthday = Birthday(
      id: 'e2e-birthday',
      name: 'Deniz',
      month: now.month,
      day: now.day,
      year: 1990,
      createdAt: now,
    );
    await cubit.addBirthday(birthday);

    final expected = {
      for (final offset in birthday.advanceOffsetsMinutes)
        birthday.notificationIdFor(offset),
    };
    expect(expected, hasLength(2));
    await pumpUntilTrue(
      tester,
      () async => (await pendingNotificationIds()).containsAll(expected),
      reason: 'for the birthday alarms $expected',
    );
    expect(await pendingNotificationIds(), expected);

    await cubit.deleteBirthday(birthday.id);
    await pumpUntilTrue(
      tester,
      () async => (await pendingNotificationIds()).isEmpty,
      reason: 'for the birthday alarms to be cancelled',
    );
    expect(tester.takeException(), isNull);
  });
}
