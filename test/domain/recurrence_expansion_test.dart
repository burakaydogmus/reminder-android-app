import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/recurrence_expansion.dart';

import '../helpers/factories.dart';

void main() {
  final from = DateTime(2026, 9, 13);
  final to = DateTime(2026, 9, 20);

  test('untimed reminders have no occurrences', () {
    expect(reminderOccurrences(buildReminder(), from: from, to: to), isEmpty);
  });

  test('one-off: its time when inside [from, to)', () {
    final at = DateTime(2026, 9, 15, 9);
    expect(
      reminderOccurrences(buildReminder(remindAt: at), from: from, to: to),
      [at],
    );
    expect(
      reminderOccurrences(
        buildReminder(remindAt: DateTime(2026, 9, 20)),
        from: from,
        to: to,
      ),
      isEmpty,
      reason: 'to is exclusive',
    );
  });

  test('daily: stored time first, then every day at the anchor time', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 9, 17, 8, 45),
      recurrence: RecurrenceRule.daily(),
    );
    expect(reminderOccurrences(r, from: from, to: to), [
      DateTime(2026, 9, 17, 8, 45),
      DateTime(2026, 9, 18, 8, 45),
      DateTime(2026, 9, 19, 8, 45),
    ]);
  });

  test('an anchor before the range is picked up inside it', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 9, 1, 8, 45), // Tuesday
      recurrence: RecurrenceRule.weekly([DateTime.monday, DateTime.wednesday]),
    );
    expect(reminderOccurrences(r, from: from, to: to), [
      DateTime(2026, 9, 14, 8, 45),
      DateTime(2026, 9, 16, 8, 45),
    ]);
  });

  test('interval rules keep their grid (every 2 days)', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 9, 12, 7),
      recurrence: RecurrenceRule.daily(interval: 2),
    );
    expect(reminderOccurrences(r, from: from, to: to), [
      DateTime(2026, 9, 14, 7),
      DateTime(2026, 9, 16, 7),
      DateTime(2026, 9, 18, 7),
    ]);
  });

  test('monthly on the 31st clamps to the month end', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 8, 31, 10),
      recurrence: RecurrenceRule.monthly(dayOfMonth: 31),
    );
    expect(
      reminderOccurrences(
        r,
        from: DateTime(2026, 9),
        to: DateTime(2027, 3),
      ),
      [
        DateTime(2026, 9, 30, 10),
        DateTime(2026, 10, 31, 10),
        DateTime(2026, 11, 30, 10),
        DateTime(2026, 12, 31, 10),
        DateTime(2027, 1, 31, 10),
        DateTime(2027, 2, 28, 10),
      ],
    );
  });

  test('yearly expands once per year, 29 Feb → 28 Feb in non-leap years', () {
    final r = buildReminder(
      remindAt: DateTime(2028, 2, 29, 10),
      recurrence: RecurrenceRule.yearly(),
    );
    expect(
      reminderOccurrences(r, from: DateTime(2028), to: DateTime(2033)),
      [
        DateTime(2028, 2, 29, 10),
        DateTime(2029, 2, 28, 10),
        DateTime(2030, 2, 28, 10),
        DateTime(2031, 2, 28, 10),
        DateTime(2032, 2, 29, 10),
      ],
    );
  });

  test('a yearly series is picked up inside a later range', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 6, 1, 8),
      recurrence: RecurrenceRule.yearly(interval: 2),
    );
    expect(
      reminderOccurrences(r, from: DateTime(2029), to: DateTime(2034)),
      [DateTime(2030, 6, 1, 8), DateTime(2032, 6, 1, 8)],
    );
  });

  test('until is inclusive and ends the series', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 9, 13, 9),
      recurrence: RecurrenceRule.daily(until: DateTime(2026, 9, 15)),
    );
    expect(reminderOccurrences(r, from: from, to: to), [
      DateTime(2026, 9, 13, 9),
      DateTime(2026, 9, 14, 9),
      DateTime(2026, 9, 15, 9),
    ]);
  });

  test('limit caps long ranges', () {
    final r = buildReminder(
      remindAt: DateTime(2026, 9, 13, 9),
      recurrence: RecurrenceRule.daily(),
    );
    expect(
      reminderOccurrences(r, from: from, to: DateTime(2030), limit: 5),
      hasLength(5),
    );
  });

  // F3.1c: the decision is to show the one date that is real. A projection
  // would be a guess the calendar then presents as fact, and every date after
  // the first would move the moment the user completes the reminder.
  group('completion-anchored: only the current occurrence', () {
    final rule = RecurrenceRule.afterCompletion(
      RecurrenceFrequency.daily,
      interval: 2,
    );

    test('no projected series, however long the range', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 14, 9),
        recurrence: rule,
      );
      expect(reminderOccurrences(r, from: from, to: to), [
        DateTime(2026, 9, 14, 9),
      ]);
      expect(
        reminderOccurrences(r, from: from, to: DateTime(2030)),
        [DateTime(2026, 9, 14, 9)],
      );
      // A calendar rule with the same interval does project a series.
      expect(
        reminderOccurrences(
          buildReminder(
            remindAt: DateTime(2026, 9, 14, 9),
            recurrence: RecurrenceRule.daily(interval: 2),
          ),
          from: from,
          to: to,
        ),
        hasLength(3),
      );
    });

    test('an overdue one is not picked up in a later range', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 1, 9),
        recurrence: rule,
      );
      expect(reminderOccurrences(r, from: from, to: to), isEmpty);
    });

    test('a monthly one behaves the same way', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 15, 7),
        recurrence: RecurrenceRule.afterCompletion(
          RecurrenceFrequency.monthly,
          interval: 3,
        ),
      );
      expect(
        reminderOccurrences(r, from: from, to: DateTime(2028)),
        [DateTime(2026, 9, 15, 7)],
      );
    });
  });
}
