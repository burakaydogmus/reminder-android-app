import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/reminder_completion.dart';

import '../helpers/factories.dart';

void main() {
  /// Sunday 13 September 2026, 12:00.
  final now = DateTime(2026, 9, 13, 12);

  group('completeReminder', () {
    test('a one-off reminder is marked done', () {
      final r = buildReminder(remindAt: DateTime(2026, 9, 13, 18));
      final done = completeReminder(r, now);
      expect(done.isDone, isTrue);
      expect(done.remindAt, r.remindAt);
    });

    test('an already done reminder is returned unchanged', () {
      final r = buildReminder(isDone: true, recurrence: RecurrenceRule.daily());
      expect(identical(completeReminder(r, now), r), isTrue);
    });

    test('early completion skips this occurrence (B7)', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.daily(),
      );
      final next = completeReminder(r, now);
      expect(next.isDone, isFalse);
      expect(next.remindAt, DateTime(2026, 9, 14, 18));
    });

    test('an overdue recurring reminder skips missed occurrences', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 10, 9),
        recurrence: RecurrenceRule.daily(),
      );
      expect(completeReminder(r, now).remindAt, DateTime(2026, 9, 14, 9));

      final evening = buildReminder(
        remindAt: DateTime(2026, 9, 10, 18),
        recurrence: RecurrenceRule.daily(),
      );
      expect(
        completeReminder(evening, now).remindAt,
        DateTime(2026, 9, 13, 18),
      );
    });

    test('a yearly reminder advances to the next year', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.yearly(),
      );
      final next = completeReminder(r, now);
      expect(next.isDone, isFalse);
      expect(next.remindAt, DateTime(2027, 9, 13, 18));
    });

    test('a 29 February yearly reminder advances to 28 February', () {
      final r = buildReminder(
        remindAt: DateTime(2028, 2, 29, 10),
        recurrence: RecurrenceRule.yearly(),
      );
      expect(
        completeReminder(r, DateTime(2028, 2, 29, 11)).remindAt,
        DateTime(2029, 2, 28, 10),
      );
    });

    test('a yearly series past its end date is marked done', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.yearly(until: DateTime(2026, 12, 31)),
      );
      expect(completeReminder(r, now).isDone, isTrue);
    });

    test('weekly overdue by weeks moves to the next future Saturday', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 8, 22, 16),
        recurrence: RecurrenceRule.weekly([DateTime.saturday]),
      );
      expect(completeReminder(r, now).remindAt, DateTime(2026, 9, 19, 16));
    });

    test('keeps every other field', () {
      final r = buildReminder(
        id: 'x',
        title: 'Spor',
        note: 'not',
        remindAt: DateTime(2026, 9, 13, 18),
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
        recurrence: RecurrenceRule.weekly([DateTime.sunday]),
      );
      final next = completeReminder(r, now);
      expect(next.id, 'x');
      expect(next.title, 'Spor');
      expect(next.note, 'not');
      expect(next.locationLatitude, 41);
      expect(next.recurrence, r.recurrence);
      expect(next.createdAt, r.createdAt);
    });

    test('a rule without a time behaves like a one-off reminder', () {
      final r = buildReminder(recurrence: RecurrenceRule.daily());
      expect(r.isRecurring, isFalse);
      expect(completeReminder(r, now).isDone, isTrue);
    });

    test('a finished series is marked done', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.daily(until: DateTime(2026, 9, 13)),
      );
      final done = completeReminder(r, now);
      expect(done.isDone, isTrue);
      expect(done.remindAt, r.remindAt);
    });

    // F3.1c: the next date comes from when the reminder was really completed,
    // not from where the schedule said it should have been.
    group('a completion-anchored rule counts from the completion', () {
      final rule = RecurrenceRule.afterCompletion(
        RecurrenceFrequency.daily,
        interval: 14,
      );

      test('an overdue reminder advances from today, not from the schedule',
          () {
        // Due 1 September, completed today (13 September): the next wash is 14
        // days from today, not 14 days from 1 September (15 September).
        final r = buildReminder(
          remindAt: DateTime(2026, 9, 1, 10),
          recurrence: rule,
        );
        final next = completeReminder(r, now);
        expect(next.isDone, isFalse);
        expect(next.remindAt, DateTime(2026, 9, 27, 10));
      });

      test('the reminder keeps its own time of day, not the completion time',
          () {
        final r = buildReminder(
          remindAt: DateTime(2026, 9, 3, 10),
          recurrence: rule,
        );
        expect(
          completeReminder(r, DateTime(2026, 9, 3, 23, 40)).remindAt,
          DateTime(2026, 9, 17, 10),
        );
      });

      test('early completion pulls the next occurrence in', () {
        final r = buildReminder(
          remindAt: DateTime(2026, 9, 20, 10),
          recurrence: rule,
        );
        expect(completeReminder(r, now).remindAt, DateTime(2026, 9, 27, 10));
      });

      test('month and year intervals clamp to the month end', () {
        final monthly = buildReminder(
          remindAt: DateTime(2026, 9, 13, 8),
          recurrence:
              RecurrenceRule.afterCompletion(RecurrenceFrequency.monthly),
        );
        expect(
          completeReminder(monthly, DateTime(2026, 12, 31, 20)).remindAt,
          DateTime(2027, 1, 31, 8),
        );
        final yearly = buildReminder(
          remindAt: DateTime(2028, 2, 29, 8),
          recurrence:
              RecurrenceRule.afterCompletion(RecurrenceFrequency.yearly),
        );
        expect(
          completeReminder(yearly, DateTime(2028, 2, 29, 20)).remindAt,
          DateTime(2029, 2, 28, 8),
        );
      });

      test('subtasks are reset for the next occurrence', () {
        final r = buildReminder(
          remindAt: DateTime(2026, 9, 13, 10),
          recurrence: rule,
          subtasks: buildSubtasks(['Yıka'], done: {0}),
        );
        final next = completeReminder(r, now);
        expect(next.isDone, isFalse);
        expect(next.subtasks.single.isDone, isFalse);
      });

      test('a series past its end date is marked done', () {
        final r = buildReminder(
          remindAt: DateTime(2026, 9, 13, 10),
          recurrence: RecurrenceRule.afterCompletion(
            RecurrenceFrequency.daily,
            interval: 14,
            until: DateTime(2026, 9, 20),
          ),
        );
        final done = completeReminder(r, now);
        expect(done.isDone, isTrue);
        expect(done.remindAt, r.remindAt);
      });
    });
  });
}
