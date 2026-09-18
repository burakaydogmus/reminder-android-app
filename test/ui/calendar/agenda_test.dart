import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';

void main() {
  // 13 Sep 2026 is a Sunday.
  final now = DateTime(2026, 9, 13, 14, 32);

  final agenda = buildAgenda(
    now: now,
    reminders: [
      buildReminder(id: 'past-today', remindAt: DateTime(2026, 9, 13, 9)),
      buildReminder(id: 'yesterday', remindAt: DateTime(2026, 9, 12, 9)),
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

  List<String> ids(AgendaDay d) => [for (final o in d.reminders) o.reminder.id];

  test('groups not-done timed reminders of the 30 days by day', () {
    expect(
      [for (final d in agenda) d.date],
      [
        DateTime(2026, 9, 13),
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 15),
        DateTime(2026, 10, 12),
      ],
    );
    // Overdue items of the range stay (the card says "Gecikti"); earlier
    // days and done/untimed items are not in the agenda.
    expect(ids(agenda[0]), ['past-today', 'today-16']);
    expect(ids(agenda[1]), ['tomorrow']);
    expect(ids(agenda[2]), ['mon-0845', 'mon-13']);
    expect(ids(agenda[3]), ['day-29']);
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

  test('includeEmptyDays returns every day of the range', () {
    final days = buildAgenda(
      reminders: [buildReminder(remindAt: DateTime(2026, 9, 15, 9))],
      birthdays: const [],
      now: now,
      days: 5,
      includeEmptyDays: true,
    );
    expect([for (final d in days) d.date.day], [13, 14, 15, 16, 17]);
    expect([for (final d in days) d.isEmpty], [true, true, false, true, true]);
  });

  test('from starts the range at another day', () {
    final days = buildAgenda(
      reminders: [
        buildReminder(id: 'a', remindAt: DateTime(2026, 9, 15, 9)),
        buildReminder(id: 'b', remindAt: DateTime(2026, 9, 25, 9)),
      ],
      birthdays: const [],
      now: now,
      from: DateTime(2026, 9, 20),
      days: 7,
    );
    expect([for (final d in days) ...ids(d)], ['b']);
  });

  group('recurring reminders', () {
    final weekly = buildReminder(
      id: 'meeting',
      remindAt: DateTime(2026, 9, 14, 8, 45),
      recurrence: RecurrenceRule.weekly([DateTime.monday]),
    );

    test('expand to every occurrence in the range', () {
      final days = buildAgenda(
        reminders: [weekly],
        birthdays: const [],
        now: now,
        days: 30,
      );
      final all = days.expand((d) => d.reminders).toList();
      expect([
        for (final o in all) o.at
      ], [
        DateTime(2026, 9, 14, 8, 45),
        DateTime(2026, 9, 21, 8, 45),
        DateTime(2026, 9, 28, 8, 45),
        DateTime(2026, 10, 5, 8, 45),
        DateTime(2026, 10, 12, 8, 45),
      ]);
      // Only the stored occurrence is editable in place.
      expect([for (final o in all) o.isStored],
          [true, false, false, false, false]);
    });

    test('an overdue series shows its future occurrences read-only', () {
      final daily = buildReminder(
        id: 'pill',
        remindAt: DateTime(2026, 9, 10, 9),
        recurrence: RecurrenceRule.daily(),
      );
      final days = buildAgenda(
        reminders: [daily],
        birthdays: const [],
        now: now,
        days: 3,
      );
      expect(
        [for (final d in days) ...d.reminders.map((o) => (o.at, o.isStored))],
        [
          (DateTime(2026, 9, 13, 9), false),
          (DateTime(2026, 9, 14, 9), false),
          (DateTime(2026, 9, 15, 9), false),
        ],
      );
    });

    test('a finished (done) series is not shown', () {
      expect(
        buildAgenda(
          reminders: [
            weekly.copyWith(isDone: true),
          ],
          birthdays: const [],
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('filters', () {
    final reminders = [
      buildReminder(id: 'plain', remindAt: DateTime(2026, 9, 14, 9)),
      buildReminder(
        id: 'located',
        remindAt: DateTime(2026, 9, 14, 10),
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
      ),
    ];
    final birthdays = [buildBirthday(date: DateTime(1990, 9, 14))];

    List<String> entries(CalendarFilter f) => [
          for (final d in buildAgenda(
            reminders: reminders,
            birthdays: birthdays,
            now: now,
            filter: f,
          )) ...[
            for (final b in d.birthdays) 'birthday:${b.birthday.id}',
            ...ids(d),
          ],
        ];

    test('Tümü shows everything', () {
      expect(entries(CalendarFilter.all), ['birthday:b1', 'plain', 'located']);
    });

    test('Hatırlatıcılar hides birthdays', () {
      expect(entries(CalendarFilter.reminders), ['plain', 'located']);
    });

    test('Doğum günleri shows only birthdays', () {
      expect(entries(CalendarFilter.birthdays), ['birthday:b1']);
    });

    test('Konumlu shows only location reminders', () {
      expect(entries(CalendarFilter.located), ['located']);
    });
  });

  group('day markers (dots)', () {
    final reminders = [
      buildReminder(
        id: 'a',
        categoryId: ReminderCategoryIds.work,
        remindAt: DateTime(2026, 9, 14, 12),
      ),
      buildReminder(
        id: 'b',
        categoryId: ReminderCategoryIds.market,
        remindAt: DateTime(2026, 9, 14, 9),
      ),
      buildReminder(
        id: 'c',
        categoryId: ReminderCategoryIds.market,
        remindAt: DateTime(2026, 9, 14, 18),
      ),
      buildReminder(
        id: 'd',
        categoryId: ReminderCategoryIds.health,
        remindAt: DateTime(2026, 9, 14, 20),
      ),
      buildReminder(
        id: 'e',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 16, 20),
        recurrence: RecurrenceRule.daily(),
      ),
    ];
    final birthdays = [buildBirthday(date: DateTime(1996, 9, 14))];

    Map<DateTime, List<KorColorKey>> markers(CalendarFilter f) =>
        calendarDayMarkers(
          reminders: reminders,
          birthdays: birthdays,
          now: now,
          from: DateTime(2026, 9, 7),
          to: DateTime(2026, 9, 21),
          filter: f,
        );

    test('at most 3 distinct keys, birthday first, then by time', () {
      final m = markers(CalendarFilter.all);
      expect(m[DateTime(2026, 9, 14)], [
        KorColorKey.dogumGunu,
        KorColorKey.market,
        KorColorKey.is_,
      ]);
      expect(m.containsKey(DateTime(2026, 9, 13)), isFalse);
    });

    test('recurring occurrences get dots on every day', () {
      final m = markers(CalendarFilter.all);
      for (var d = 16; d <= 20; d++) {
        expect(m[DateTime(2026, 9, d)], [KorColorKey.ev], reason: '$d');
      }
    });

    test('filters apply to dots', () {
      expect(markers(CalendarFilter.birthdays)[DateTime(2026, 9, 14)],
          [KorColorKey.dogumGunu]);
      expect(markers(CalendarFilter.reminders)[DateTime(2026, 9, 14)], [
        KorColorKey.market,
        KorColorKey.is_,
        KorColorKey.saglik,
      ]);
      expect(markers(CalendarFilter.located), isEmpty);
    });
  });

  group('BirthdayOccurrence', () {
    test('birthday today stays today after its notification time', () {
      final o = BirthdayOccurrence.next(
        buildBirthday(date: DateTime(2000, 9, 13), notifyHour: 9),
        now,
      );
      expect(o.daysUntil, 0);
      expect(o.date, DateTime(2026, 9, 13));
    });

    test('29 February falls on 28 February in non-leap years', () {
      final b = buildBirthday(date: DateTime(2000, 2, 29));
      final next = BirthdayOccurrence.next(b, now);
      expect(next.date, DateTime(2027, 2, 28));
      expect(next.movedFromLeapDay, isTrue);
      final leap = BirthdayOccurrence.inYear(b, 2028, now);
      expect(leap.date, DateTime(2028, 2, 29));
      expect(leap.movedFromLeapDay, isFalse);
    });

    test('a year-less birthday has no age', () {
      final o = BirthdayOccurrence.next(
        buildBirthday(date: DateTime(Birthday.unknownYear, 10, 3)),
        now,
      );
      expect(o.date, DateTime(2026, 10, 3));
      expect(o.age, isNull);
    });

    test('birthdays in a range crossing the year end', () {
      final days = buildAgenda(
        reminders: const [],
        birthdays: [buildBirthday(date: DateTime(1990, 1, 2))],
        now: now,
        from: DateTime(2026, 12, 20),
        days: 20,
      );
      expect(days.single.date, DateTime(2027, 1, 2));
      expect(days.single.birthdays.single.age, 37);
    });
  });
}
