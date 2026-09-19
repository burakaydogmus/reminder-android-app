part of '../capture_parser.dart';

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime? validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) return null;
  if (day > daysInMonth(year, month)) return null;
  return DateTime(year, month, day);
}

/// [day] plus [months], clamped to the target month (31 Jan + 1 → 28/29 Feb).
DateTime addMonthsClamped(DateTime day, int months) {
  final first = DateTime(day.year, day.month + months, 1);
  final d = day.day.clamp(1, daysInMonth(first.year, first.month));
  return DateTime(first.year, first.month, d);
}

DateTime _at(DateTime day, _Clock time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);

/// Turns the collected slots into `dateTime`, `hasExplicitTime`, `isPast`
/// and the first occurrence of a repeat.
extension _Resolution on _Scanner {
  /// Next `day.month` (this year when not before today; Feb 29 → next leap
  /// year); `null` for a day that never exists.
  DateTime? nextDayMonth(int day, int month) {
    for (var y = today.year; y <= today.year + 8; y++) {
      final d = validDate(y, month, day);
      if (d != null && !d.isBefore(today)) return d;
    }
    return null;
  }

  /// `ayın N'i`: this month when not before today, else the next month that
  /// has day [day].
  DateTime? nextDayOfMonth(int day) {
    if (day < 1 || day > 31) return null;
    for (var k = 0; k <= 12; k++) {
      final first = DateTime(today.year, today.month + k, 1);
      final d = validDate(first.year, first.month, day);
      if (d != null && !d.isBefore(today)) return d;
    }
    return null;
  }

  DateTime resolveDate(_DateSpec spec, _Clock? time) {
    switch (spec) {
      case _FixedDate(:final day):
        return day;
      case _WeekdayDate(:final weekday, :final extraWeeks):
        var d = addDays(today, (weekday - today.weekday + 7) % 7);
        final todayCounts = time != null && _at(d, time).isAfter(now);
        if (d == today && !todayCounts) d = addDays(d, 7);
        return addDays(d, 7 * extraWeeks);
    }
  }

  ({DateTime? dateTime, bool timed, bool past, RecurrenceSpec? recurrence})
      resolve() {
    final instant = _instant;
    if (instant != null) {
      return (dateTime: instant, timed: true, past: false, recurrence: null);
    }
    final time = _time;
    final recurrence = _recurrence;
    if (recurrence != null) {
      final first = _firstOccurrence(recurrence, time);
      return (
        dateTime: first.at,
        timed: time != null,
        past: false,
        recurrence: first.spec,
      );
    }
    final date = _date;
    if (date != null) {
      final day = resolveDate(date, time);
      if (time == null) {
        return (
          dateTime: day,
          timed: false,
          past: day.isBefore(today),
          recurrence: null,
        );
      }
      final at = _at(day, time);
      return (
        dateTime: at,
        timed: true,
        past: at.isBefore(now),
        recurrence: null,
      );
    }
    if (time != null) {
      var at = _at(today, time);
      if (!at.isAfter(now)) at = _at(addDays(today, 1), time);
      return (dateTime: at, timed: true, past: false, recurrence: null);
    }
    return (dateTime: null, timed: false, past: false, recurrence: null);
  }

  /// First occurrence at or after now (or after an explicit start date).
  /// A day counts when no time is given or the time is still ahead.
  ({RecurrenceSpec spec, DateTime at}) _firstOccurrence(
    RecurrenceSpec rec,
    _Clock? time,
  ) {
    final anchor = _date == null ? null : resolveDate(_date!, time);
    final start = anchor == null || anchor.isBefore(today) ? today : anchor;
    bool fits(DateTime day) =>
        time == null || day.isAfter(today) || _at(day, time).isAfter(now);
    DateTime at(DateTime day) => time == null ? day : _at(day, time);

    switch (rec.kind) {
      case RecurrenceKind.daily:
      case RecurrenceKind.everyNDays:
        final d = fits(start) ? start : addDays(start, 1);
        return (spec: rec, at: at(d));
      case RecurrenceKind.weekly:
        if (rec.weekdays.isEmpty) {
          final d = fits(start) ? start : addDays(start, 7);
          return (spec: rec.copyWith(weekdays: [d.weekday]), at: at(d));
        }
        for (var k = 0; k < 14; k++) {
          final d = addDays(start, k);
          if (rec.weekdays.contains(d.weekday) && fits(d)) {
            return (spec: rec, at: at(d));
          }
        }
        return (spec: rec, at: at(start));
      case RecurrenceKind.monthly:
        final dom = rec.dayOfMonth ?? start.day;
        for (var k = 0; k <= 48; k++) {
          final first = DateTime(start.year, start.month + k, 1);
          final d = validDate(first.year, first.month, dom);
          if (d != null && !d.isBefore(start) && fits(d)) {
            return (spec: rec.copyWith(dayOfMonth: dom), at: at(d));
          }
        }
        return (spec: rec.copyWith(dayOfMonth: dom), at: at(start));
    }
  }
}
