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
  });
}
