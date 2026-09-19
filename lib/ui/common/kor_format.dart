import 'package:intl/intl.dart';

import 'package:reminder/l10n/l10n.dart';

/// Date/time helpers for the UI. Pure functions of their inputs so screens
/// can pass an injected clock; words and date patterns come from the ARB
/// files ([AppLocalizations]), so Turkish keeps its day-month order and
/// English gets "Sunday, September 13".
abstract final class KorFormat {
  /// Midnight of [d] (local).
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from [from] to [to] (DST-safe).
  static int dayDiff(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Locale-aware Turkish upper case: `i → İ`, `ı → I`.
  static String upperTr(String s) =>
      s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// `18:30` (24 h in both languages).
  static String time(DateTime t) => DateFormat('HH:mm', 'tr_TR').format(t);

  /// Spoken form for screen readers: `saat 18:30` / `at 18:30`.
  static String spokenTime(DateTime t, AppLocalizations l10n) =>
      l10n.timeSpoken(time(t));

  /// [pattern] in the [l10n] locale.
  static String pattern(String pattern, DateTime d, AppLocalizations l10n) =>
      DateFormat(pattern, l10n.intlLocale).format(d);

  /// `Cumartesi, 13 Eylül` / `Sunday, September 13`.
  static String headerDate(DateTime d, AppLocalizations l10n) =>
      pattern(l10n.dateFormatHeader, d, l10n);

  /// `13 Eylül` / `September 13` (with year when it differs from [now]).
  static String dayMonth(DateTime d, DateTime now, AppLocalizations l10n) =>
      pattern(
        d.year == now.year
            ? l10n.dateFormatDayMonth
            : l10n.dateFormatDayMonthYear,
        d,
        l10n,
      );

  /// `14 Eyl` / `Sep 14` (with year when it differs from [now]).
  static String shortDate(DateTime d, DateTime now, AppLocalizations l10n) =>
      pattern(
        d.year == now.year ? l10n.dateFormatShort : l10n.dateFormatShortYear,
        d,
        l10n,
      );

  /// `Bugün`, `Yarın`, `Dün` or `14 Eyl` / `14 Eyl 2027`.
  static String relativeDay(DateTime d, DateTime now, AppLocalizations l10n) {
    switch (dayDiff(now, d)) {
      case 0:
        return l10n.dayToday;
      case 1:
        return l10n.dayTomorrow;
      case -1:
        return l10n.dayYesterday;
    }
    return shortDate(d, now, l10n);
  }

  /// Card trailing label: `18:30` today, otherwise `Yarın 09:00`,
  /// `Dün 18:00`, `14 Eyl 09:00`.
  static String when(DateTime at, DateTime now, AppLocalizations l10n) {
    if (isSameDay(at, now)) return time(at);
    return l10n.dayAndTime(relativeDay(at, now, l10n), time(at));
  }

  /// Screen-reader form of [when]: `Yarın saat 09:00`.
  static String spokenWhen(DateTime at, DateTime now, AppLocalizations l10n) =>
      l10n.dayAndTime(relativeDay(at, now, l10n), spokenTime(at, l10n));

  /// Agenda day header: `BUGÜN · CUMARTESİ 13 EYLÜL`,
  /// `YARIN · PAZAR 14 EYLÜL`, `PAZARTESİ 15 EYLÜL`.
  static String agendaDayHeader(
    DateTime day,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final date = pattern(
      day.year == now.year ? l10n.dateFormatAgenda : l10n.dateFormatAgendaYear,
      day,
      l10n,
    );
    final text = switch (dayDiff(now, day)) {
      0 => l10n.agendaDayToday(date),
      1 => l10n.agendaDayTomorrow(date),
      _ => date,
    };
    return l10n.upper(text);
  }

  /// Birthday countdown: `Bugün`, `Yarın`, `8 gün`.
  static String countdown(int daysUntil, AppLocalizations l10n) =>
      switch (daysUntil) {
        0 => l10n.dayToday,
        1 => l10n.dayTomorrow,
        _ => l10n.countdownDays(daysUntil),
      };

  /// Weekday name, 1 = Monday … 7 = Sunday: `Pazartesi` / `Monday`.
  static String weekdayName(int weekday, AppLocalizations l10n) =>
      pattern('EEEE', DateTime(2024, 1, weekday), l10n);

  /// Short weekday, 1 = Monday: `Pzt` / `Mon`.
  static String weekdayShort(int weekday, AppLocalizations l10n) =>
      pattern('EEE', DateTime(2024, 1, weekday), l10n);
}
