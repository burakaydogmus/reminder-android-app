import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';

/// Recurring reminder scheduling (F3.1): only the next occurrence is
/// scheduled; simple rules also repeat through `matchDateTimeComponents`.
void main() {
  late FakeNotificationsPlugin plugin;
  late NotificationService service;

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plugin = FakeNotificationsPlugin();
    service = NotificationService.forTesting(plugin);
  });

  group('reminderRepeatComponents', () {
    final cases = <(RecurrenceRule, DateTimeComponents?)>[
      (RecurrenceRule.none, null),
      (RecurrenceRule.daily(), DateTimeComponents.time),
      (RecurrenceRule.daily(interval: 3), null),
      (
        RecurrenceRule.weekly([DateTime.saturday]),
        DateTimeComponents.dayOfWeekAndTime
      ),
      (RecurrenceRule.weekly([DateTime.monday, DateTime.wednesday]), null),
      (RecurrenceRule.weekly([DateTime.saturday], interval: 2), null),
      (
        RecurrenceRule.monthly(dayOfMonth: 17),
        DateTimeComponents.dayOfMonthAndTime
      ),
      (
        RecurrenceRule.monthly(dayOfMonth: 28),
        DateTimeComponents.dayOfMonthAndTime
      ),
      (RecurrenceRule.monthly(dayOfMonth: 31), null),
      (RecurrenceRule.monthly(dayOfMonth: 17, interval: 2), null),
      (RecurrenceRule.daily(until: DateTime(2030)), null),
      (
        RecurrenceRule.yearly(month: 3, dayOfMonth: 17),
        DateTimeComponents.dateAndTime
      ),
      // 29 February: the native repeat would only fire in leap years.
      (RecurrenceRule.yearly(month: 2, dayOfMonth: 29), null),
      (
        RecurrenceRule.yearly(month: 2, dayOfMonth: 28),
        DateTimeComponents.dateAndTime
      ),
      (RecurrenceRule.yearly(interval: 2, month: 3, dayOfMonth: 17), null),
      (
        RecurrenceRule.yearly(month: 3, dayOfMonth: 17, until: DateTime(2030)),
        null
      ),
      // No anchor and no explicit month/day: the target is unknown, so the
      // safe answer is "next occurrence only".
      (RecurrenceRule.yearly(), null),
      // F3.1c: a completion-anchored rule can never use a native repeat — the
      // next date is unknown until the reminder is completed. Even the shapes
      // that *would* repeat natively on schedule return null here.
      (RecurrenceRule.afterCompletion(RecurrenceFrequency.daily), null),
      (
        RecurrenceRule.afterCompletion(RecurrenceFrequency.daily, interval: 14),
        null
      ),
      (RecurrenceRule.afterCompletion(RecurrenceFrequency.weekly), null),
      (RecurrenceRule.afterCompletion(RecurrenceFrequency.monthly), null),
      (RecurrenceRule.afterCompletion(RecurrenceFrequency.yearly), null),
    ];
    for (final (rule, expected) in cases) {
      test('${rule.toJson()} → ${expected?.name ?? 'next only'}', () {
        expect(NotificationService.reminderRepeatComponents(rule), expected);
      });
    }

    test('a yearly rule takes its month and day from the anchor', () {
      expect(
        NotificationService.reminderRepeatComponents(
          RecurrenceRule.yearly(),
          anchor: DateTime(2026, 3, 17, 9),
        ),
        DateTimeComponents.dateAndTime,
      );
      expect(
        NotificationService.reminderRepeatComponents(
          RecurrenceRule.yearly(),
          anchor: DateTime(2028, 2, 29, 9),
        ),
        isNull,
      );
    });

    test('an anchor cannot rescue a completion-anchored rule either', () {
      expect(
        NotificationService.reminderRepeatComponents(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.daily),
          anchor: DateTime(2026, 9, 13, 9),
        ),
        isNull,
      );
    });
  });

  group('reminderFireTime', () {
    final now = DateTime(2026, 9, 13, 12);

    test('future remindAt is used as is', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.daily(),
      );
      expect(
        NotificationService.reminderFireTime(r, now),
        DateTime(2026, 9, 13, 18),
      );
    });

    test('an overdue recurring reminder fires at its next occurrence', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 10, 9),
        recurrence: RecurrenceRule.weekly([DateTime.thursday]),
      );
      expect(
        NotificationService.reminderFireTime(r, now),
        DateTime(2026, 9, 17, 9),
      );
    });

    test('overdue one-off, done, untimed and ended series are skipped', () {
      for (final r in [
        buildReminder(remindAt: DateTime(2026, 9, 13, 9)),
        buildReminder(
          isDone: true,
          remindAt: DateTime(2026, 9, 14, 9),
          recurrence: RecurrenceRule.daily(),
        ),
        buildReminder(recurrence: RecurrenceRule.daily()),
        buildReminder(
          remindAt: DateTime(2026, 9, 12, 9),
          recurrence: RecurrenceRule.daily(until: DateTime(2026, 9, 13)),
        ),
      ]) {
        expect(NotificationService.reminderFireTime(r, now), isNull);
      }
    });

    // F3.1c: a completion-anchored reminder that went overdue has no next
    // date to schedule — it waits in Kaçanlar until the user completes it.
    test('an overdue completion-anchored reminder is not rescheduled', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 10, 9),
        recurrence: RecurrenceRule.afterCompletion(
          RecurrenceFrequency.daily,
          interval: 14,
        ),
      );
      expect(NotificationService.reminderFireTime(r, now), isNull);
      // Before it is due it is scheduled like any other reminder.
      expect(
        NotificationService.reminderFireTime(
          r.copyWith(remindAt: () => DateTime(2026, 9, 13, 18)),
          now,
        ),
        DateTime(2026, 9, 13, 18),
      );
    });
  });

  group('syncSchedules with recurring reminders', () {
    final base = DateTime.now();

    /// A Saturday one to two weeks from now, 10:00 local.
    final saturday = DateTime(
      base.year,
      base.month,
      base.day + (DateTime.saturday - base.weekday) % 7 + 7,
      10,
    );

    test('schedules the next occurrence with repeat components', () async {
      final daily = buildReminder(
        id: 'daily',
        remindAt: saturday,
        recurrence: RecurrenceRule.daily(),
      );
      final custom = buildReminder(
        id: 'custom',
        remindAt: saturday,
        recurrence: RecurrenceRule.daily(interval: 3),
      );

      await service.syncSchedules(
        reminders: [daily, custom],
        birthdays: const [],
        notificationsEnabled: true,
      );

      final d = plugin.pending[daily.notificationId]!;
      expect(d.matchDateTimeComponents, DateTimeComponents.time);
      expect(d.scheduledDate.isAtSameMomentAs(saturday), isTrue);
      final c = plugin.pending[custom.notificationId]!;
      expect(c.matchDateTimeComponents, isNull);
      expect(c.scheduledDate.isAtSameMomentAs(saturday), isTrue);
    });

    test('a yearly reminder repeats natively unless it is on 29 February',
        () async {
      final yearly = buildReminder(
        id: 'yearly',
        remindAt: saturday,
        recurrence: RecurrenceRule.yearly(),
      );
      // A 29 February anchor in a future leap year.
      final leapYear = base.year + (4 - base.year % 4) % 4 + 4;
      final leapDay = buildReminder(
        id: 'leap',
        remindAt: DateTime(leapYear, 2, 29, 10),
        recurrence: RecurrenceRule.yearly(),
      );

      await service.syncSchedules(
        reminders: [yearly, leapDay],
        birthdays: const [],
        notificationsEnabled: true,
      );

      expect(
        plugin.pending[yearly.notificationId]!.matchDateTimeComponents,
        DateTimeComponents.dateAndTime,
      );
      final leap = plugin.pending[leapDay.notificationId]!;
      expect(leap.matchDateTimeComponents, isNull);
      expect(
        leap.scheduledDate.isAtSameMomentAs(DateTime(leapYear, 2, 29, 10)),
        isTrue,
      );
    });

    // F3.1c: no native repeat, and the next date only appears once the
    // reminder is completed — the normal "reschedule after completion" path.
    test('a completion-anchored reminder is scheduled once, then rescheduled',
        () async {
      final r = buildReminder(
        id: 'sheets',
        remindAt: saturday,
        recurrence: RecurrenceRule.afterCompletion(
          RecurrenceFrequency.daily,
          interval: 14,
        ),
      );

      await service.syncSchedules(
        reminders: [r],
        birthdays: const [],
        notificationsEnabled: true,
      );

      final first = plugin.pending[r.notificationId]!;
      expect(first.matchDateTimeComponents, isNull);
      expect(first.scheduledDate.isAtSameMomentAs(saturday), isTrue);

      // Completed two days late: the next notification is 14 days from then.
      final completedAt = DateTime(
        saturday.year,
        saturday.month,
        saturday.day + 2,
        21,
      );
      final next = completeReminder(r, completedAt);
      expect(next.isDone, isFalse);
      await service.syncSchedules(
        reminders: [next],
        birthdays: const [],
        notificationsEnabled: true,
      );

      final second = plugin.pending[r.notificationId]!;
      expect(second.matchDateTimeComponents, isNull);
      expect(
        second.scheduledDate.isAtSameMomentAs(
          DateTime(saturday.year, saturday.month, saturday.day + 16, 10),
        ),
        isTrue,
      );
    });

    test('an overdue recurring reminder stays scheduled', () async {
      final overdue = DateTime(base.year, base.month, base.day - 3, 0, 0);
      final r = buildReminder(
        id: 'overdue',
        remindAt: overdue,
        recurrence: RecurrenceRule.daily(interval: 2),
      );
      final expected = r.recurrence.nextOccurrence(
        after: tz.TZDateTime.now(tz.local),
        anchor: overdue,
      )!;

      await service.syncSchedules(
        reminders: [r],
        birthdays: const [],
        notificationsEnabled: true,
      );

      final pending = plugin.pending[r.notificationId]!;
      expect(pending.scheduledDate.isAtSameMomentAs(expected), isTrue);
      expect(pending.scheduledDate.isAfter(base), isTrue);
    });

    test('completing (advancing remindAt) reschedules the notification',
        () async {
      final r = buildReminder(
        remindAt: saturday,
        recurrence: RecurrenceRule.weekly([DateTime.saturday]),
      );
      await service.syncSchedules(
        reminders: [r],
        birthdays: const [],
        notificationsEnabled: true,
      );
      plugin.resetCounters();

      final next = r.copyWith(
        remindAt: () =>
            DateTime(saturday.year, saturday.month, saturday.day + 7, 10),
      );
      await service.syncSchedules(
        reminders: [next],
        birthdays: const [],
        notificationsEnabled: true,
      );

      expect(plugin.scheduledIds, [r.notificationId]);
      expect(
        plugin.pending[r.notificationId]!.scheduledDate
            .isAtSameMomentAs(next.remindAt!),
        isTrue,
      );
    });

    test('the fingerprint changes when only the rule changes', () async {
      // Both rules are "next only" and fire on the same Saturday.
      final r = buildReminder(
        remindAt: saturday,
        recurrence: RecurrenceRule.weekly([DateTime.saturday], interval: 2),
      );
      await service.syncSchedules(
        reminders: [r],
        birthdays: const [],
        notificationsEnabled: true,
      );
      plugin.resetCounters();

      await service.syncSchedules(
        reminders: [r],
        birthdays: const [],
        notificationsEnabled: true,
      );
      expect(plugin.scheduleCalls, 0, reason: 'unchanged rule');

      await service.syncSchedules(
        reminders: [
          r.copyWith(
            recurrence: RecurrenceRule.weekly(
              [DateTime.saturday, DateTime.sunday],
            ),
          ),
        ],
        birthdays: const [],
        notificationsEnabled: true,
      );
      expect(plugin.scheduledIds, [r.notificationId]);
      expect(
        plugin.pending[r.notificationId]!.matchDateTimeComponents,
        isNull,
      );
    });
  });
}
