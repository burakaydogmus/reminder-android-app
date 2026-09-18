/// Pure calendar date math for the Takvim screen (F4.4).
///
/// Weeks start on **Monday** (Turkish convention). Days are built from
/// calendar fields (`DateTime(y, m, d + n)`), never `Duration` adds, so
/// midnights survive DST changes. All results are local midnights.
abstract final class CalendarDates {
  /// Midnight of [d].
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// [day] moved by [days] calendar days (midnight).
  static DateTime addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// Whole calendar days from [from] to [to] (DST-safe, ignores times).
  static int dayDiff(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Monday of the week containing [d].
  static DateTime weekStart(DateTime d) =>
      addDays(dateOnly(d), -(d.weekday - DateTime.monday));

  /// The 7 days (Mon–Sun) of the week containing [d].
  static List<DateTime> weekDays(DateTime d) {
    final start = weekStart(d);
    return List.unmodifiable([for (var i = 0; i < 7; i++) addDays(start, i)]);
  }

  /// Whole weeks from the week of [from] to the week of [to].
  static int weekDiff(DateTime from, DateTime to) =>
      dayDiff(weekStart(from), weekStart(to)) ~/ 7;

  /// First day of the month of [d].
  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

  /// First day of the month [months] after the month of [d].
  static DateTime addMonths(DateTime d, int months) =>
      DateTime(d.year, d.month + months);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// The 6×7 month grid of the month of [d]: 42 days from the Monday on or
  /// before the 1st, so every month (also a 31-day month starting on Sunday)
  /// fits and the grid height never jumps.
  static List<DateTime> monthGrid(DateTime d) {
    final start = weekStart(monthStart(d));
    return List.unmodifiable([for (var i = 0; i < 42; i++) addDays(start, i)]);
  }

  /// [day]'s date with the wall-clock time of [time] (reschedule keeping the
  /// time).
  static DateTime onDayKeepingTime(DateTime day, DateTime time) => DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
        time.second,
        time.millisecond,
        time.microsecond,
      );
}
