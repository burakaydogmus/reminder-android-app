import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/ui/calendar/reschedule.dart';

import '../../helpers/factories.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  final now = DateTime(2026, 9, 13, 14, 32);

  test('moves to the day and keeps the wall-clock time', () {
    final r = buildReminder(remindAt: DateTime(2026, 9, 13, 18, 30));
    final moved = rescheduledToDay(r, DateTime(2026, 9, 16))!;
    expect(moved.remindAt, DateTime(2026, 9, 16, 18, 30));
    expect(moved.recurrence, RecurrenceRule.none);
    expect(moved.id, r.id);
  });

  test('untimed reminders cannot be moved', () {
    expect(rescheduledToDay(buildReminder(), DateTime(2026, 9, 16)), isNull);
  });

  test('a recurring series moves as a whole (anchor + aligned rule)', () {
    final weekly = buildReminder(
      remindAt: DateTime(2026, 9, 14, 8, 45), // Monday
      recurrence: RecurrenceRule.weekly([DateTime.monday]),
    );
    final moved = rescheduledToDay(weekly, DateTime(2026, 9, 16))!;
    expect(moved.remindAt, DateTime(2026, 9, 16, 8, 45));
    expect(moved.recurrence, RecurrenceRule.weekly([DateTime.wednesday]));

    final monthly = buildReminder(
      remindAt: DateTime(2026, 9, 17, 9),
      recurrence: RecurrenceRule.monthly(dayOfMonth: 17),
    );
    expect(
      rescheduledToDay(monthly, DateTime(2026, 9, 20))!.recurrence,
      RecurrenceRule.monthly(dayOfMonth: 20),
    );

    final daily = buildReminder(
      remindAt: DateTime(2026, 9, 14, 7),
      recurrence: RecurrenceRule.daily(interval: 2),
    );
    expect(
      rescheduledToDay(daily, DateTime(2026, 9, 15))!.recurrence,
      RecurrenceRule.daily(interval: 2),
    );
  });

  group('canRescheduleToDay', () {
    final r = buildReminder(remindAt: DateTime(2026, 9, 15, 9));

    test('another future day is fine', () {
      expect(canRescheduleToDay(r, DateTime(2026, 9, 16), now), isTrue);
    });

    test('the same day is a no-op', () {
      expect(canRescheduleToDay(r, DateTime(2026, 9, 15), now), isFalse);
    });

    test('never into the past (today 09:00 is already over)', () {
      expect(canRescheduleToDay(r, DateTime(2026, 9, 13), now), isFalse);
      expect(canRescheduleToDay(r, DateTime(2026, 9, 12), now), isFalse);
      final evening = buildReminder(remindAt: DateTime(2026, 9, 15, 20));
      expect(canRescheduleToDay(evening, DateTime(2026, 9, 13), now), isTrue);
    });

    test('done and untimed reminders are not movable', () {
      expect(
        canRescheduleToDay(
          buildReminder(isDone: true, remindAt: DateTime(2026, 9, 15, 9)),
          DateTime(2026, 9, 16),
          now,
        ),
        isFalse,
      );
      expect(
        canRescheduleToDay(buildReminder(), DateTime(2026, 9, 16), now),
        isFalse,
      );
    });
  });

  test('snackbar message names the reminder and the new time', () {
    final moved = buildReminder(
      title: 'Market',
      remindAt: DateTime(2026, 9, 16, 18, 30),
    );
    expect(
        rescheduledMessage(moved, now), '“Market” taşındı · Çar 16 Eyl 18:30');
  });
}
