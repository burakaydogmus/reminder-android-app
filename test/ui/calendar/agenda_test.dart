import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/calendar/agenda.dart';

import '../../helpers/factories.dart';

void main() {
  final now = DateTime(2026, 9, 13, 14, 32);

  final agenda = buildAgenda(
    now: now,
    reminders: [
      buildReminder(id: 'past-today', remindAt: DateTime(2026, 9, 13, 9)),
      buildReminder(id: 'today-16', remindAt: DateTime(2026, 9, 13, 16)),
      buildReminder(id: 'mon-13', remindAt: DateTime(2026, 9, 15, 13)),
      buildReminder(id: 'mon-0845', remindAt: DateTime(2026, 9, 15, 8, 45)),
      buildReminder(id: 'tomorrow', remindAt: DateTime(2026, 9, 14, 9, 30)),
      buildReminder(
        id: 'done-tomorrow',
        isDone: true,
        remindAt: DateTime(2026, 9, 14, 10),
      ),
      buildReminder(id: 'untimed'),
      buildReminder(id: 'day-29', remindAt: DateTime(2026, 10, 12, 23, 59)),
      buildReminder(id: 'day-30', remindAt: DateTime(2026, 10, 13, 0, 1)),
    ],
    birthdays: [
      buildBirthday(
          id: 'b-tomorrow', name: 'Zeynep', date: DateTime(1996, 9, 14)),
      buildBirthday(id: 'b-far', date: DateTime(1990, 12, 1)),
    ],
  );

  test('groups upcoming not-done timed reminders by day', () {
    expect(
      [for (final d in agenda) d.date],
      [
        DateTime(2026, 9, 13),
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 15),
        DateTime(2026, 10, 12),
      ],
    );
    expect([for (final r in agenda[0].reminders) r.id], ['today-16']);
    expect([for (final r in agenda[1].reminders) r.id], ['tomorrow']);
    expect([for (final r in agenda[2].reminders) r.id], ['mon-0845', 'mon-13']);
    expect([for (final r in agenda[3].reminders) r.id], ['day-29']);
  });

  test('birthdays are all-day rows inside the 30-day window', () {
    expect(
        [for (final o in agenda[1].birthdays) o.birthday.id], ['b-tomorrow']);
    expect(agenda[1].birthdays.single.age, 30);
    expect(agenda[1].birthdays.single.daysUntil, 1);
    expect(
      agenda.expand((d) => d.birthdays).map((o) => o.birthday.id),
      isNot(contains('b-far')),
    );
  });

  test('empty input gives an empty agenda', () {
    expect(
      buildAgenda(reminders: const [], birthdays: const [], now: now),
      isEmpty,
    );
  });

  test('birthday today stays today after its notification time', () {
    final o = BirthdayOccurrence.next(
      buildBirthday(date: DateTime(2000, 9, 13), notifyHour: 9),
      now,
    );
    expect(o.daysUntil, 0);
    expect(o.date, DateTime(2026, 9, 13));
  });
}
