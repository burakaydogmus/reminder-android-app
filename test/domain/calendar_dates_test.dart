import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/calendar_dates.dart';

void main() {
  group('CalendarDates week math (Monday first)', () {
    test('weekStart is the Monday on or before the day', () {
      // 13 Sep 2026 is a Sunday → Monday 7 Sep.
      expect(
        CalendarDates.weekStart(DateTime(2026, 9, 13, 23, 59)),
        DateTime(2026, 9, 7),
      );
      expect(
          CalendarDates.weekStart(DateTime(2026, 9, 7)), DateTime(2026, 9, 7));
      expect(
          CalendarDates.weekStart(DateTime(2026, 9, 8)), DateTime(2026, 9, 7));
    });

    test('weekDays run Mon–Sun across a month boundary', () {
      final days = CalendarDates.weekDays(DateTime(2026, 10, 1));
      expect(days.first, DateTime(2026, 9, 28));
      expect(days.last, DateTime(2026, 10, 4));
      expect([for (final d in days) d.weekday], [1, 2, 3, 4, 5, 6, 7]);
    });

    test('weekDays across a year boundary', () {
      final days = CalendarDates.weekDays(DateTime(2027, 1, 1));
      expect(days.first, DateTime(2026, 12, 28));
      expect(days.last, DateTime(2027, 1, 3));
    });

    test('weekDiff counts whole weeks', () {
      final base = DateTime(2026, 9, 7);
      expect(CalendarDates.weekDiff(base, DateTime(2026, 9, 13)), 0);
      expect(CalendarDates.weekDiff(base, DateTime(2026, 9, 14)), 1);
      expect(CalendarDates.weekDiff(base, DateTime(2026, 9, 6)), -1);
      expect(CalendarDates.weekDiff(base, DateTime(2027, 1, 1)), 16);
    });

    test('addDays and dayDiff use calendar days', () {
      expect(
        CalendarDates.addDays(DateTime(2026, 2, 27), 2),
        DateTime(2026, 3, 1),
      );
      expect(
        CalendarDates.dayDiff(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 30)),
        2,
      );
    });
  });

  group('CalendarDates month grid', () {
    test('always 42 days from the Monday on or before the 1st', () {
      final grid = CalendarDates.monthGrid(DateTime(2026, 9, 13));
      expect(grid, hasLength(42));
      expect(grid.first, DateTime(2026, 8, 31));
      expect(grid.last, DateTime(2026, 10, 11));
      expect(grid.first.weekday, DateTime.monday);
    });

    test('a month starting on Monday starts the grid on the 1st', () {
      // 1 June 2026 is a Monday.
      expect(CalendarDates.monthGrid(DateTime(2026, 6)).first,
          DateTime(2026, 6, 1));
    });

    test('a 31-day month starting on Sunday fits in six rows', () {
      // 1 Aug 2027 is a Sunday: 1 + 30 days after the first row.
      final grid = CalendarDates.monthGrid(DateTime(2027, 8));
      expect(grid.first, DateTime(2027, 7, 26));
      expect(grid, contains(DateTime(2027, 8, 31)));
    });

    test('February in leap and non-leap years', () {
      expect(CalendarDates.daysInMonth(2027, 2), 28);
      expect(CalendarDates.daysInMonth(2028, 2), 29);
      expect(CalendarDates.monthGrid(DateTime(2028, 2)),
          contains(DateTime(2028, 2, 29)));
      expect(
        CalendarDates.monthGrid(DateTime(2027, 2)).where((d) => d.month == 2),
        hasLength(28),
      );
    });

    test('addMonths rolls over the year', () {
      expect(CalendarDates.addMonths(DateTime(2026, 12, 15), 1),
          DateTime(2027, 1));
      expect(CalendarDates.addMonths(DateTime(2026, 1, 31), -1),
          DateTime(2025, 12));
    });
  });

  test('isLeapYear follows the Gregorian rules', () {
    expect(CalendarDates.isLeapYear(2024), isTrue);
    expect(CalendarDates.isLeapYear(2026), isFalse);
    expect(CalendarDates.isLeapYear(1900), isFalse);
    expect(CalendarDates.isLeapYear(2000), isTrue);
  });

  test('onDayKeepingTime moves the date and keeps the wall-clock time', () {
    expect(
      CalendarDates.onDayKeepingTime(
        DateTime(2026, 9, 16),
        DateTime(2026, 9, 13, 18, 30),
      ),
      DateTime(2026, 9, 16, 18, 30),
    );
  });
}
