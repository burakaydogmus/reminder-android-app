import 'package:intl/intl.dart';

/// Date/time helpers for the Turkish UI. Pure functions of their inputs so
/// screens can pass an injected clock.
abstract final class KorFormat {
  static const _locale = 'tr_TR';

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

  /// `18:30` (24 h).
  static String time(DateTime t) => DateFormat('HH:mm', _locale).format(t);

  /// Spoken form for screen readers: `saat 18:30`.
  static String spokenTime(DateTime t) => 'saat ${time(t)}';

  /// `Cumartesi, 13 Eylül`.
  static String headerDate(DateTime d) =>
      DateFormat('EEEE, d MMMM', _locale).format(d);

  /// `13 Eylül` (with year when it differs from [now]).
  static String dayMonth(DateTime d, DateTime now) => d.year == now.year
      ? DateFormat('d MMMM', _locale).format(d)
      : DateFormat('d MMMM y', _locale).format(d);

  /// `Bugün`, `Yarın`, `Dün` or `14 Eyl` / `14 Eyl 2027`.
  static String relativeDay(DateTime d, DateTime now) {
    switch (dayDiff(now, d)) {
      case 0:
        return 'Bugün';
      case 1:
        return 'Yarın';
      case -1:
        return 'Dün';
    }
    return d.year == now.year
        ? DateFormat('d MMM', _locale).format(d)
        : DateFormat('d MMM y', _locale).format(d);
  }

  /// Card trailing label: `18:30` today, otherwise `Yarın 09:00`,
  /// `Dün 18:00`, `14 Eyl 09:00`.
  static String when(DateTime at, DateTime now) {
    if (isSameDay(at, now)) return time(at);
    return '${relativeDay(at, now)} ${time(at)}';
  }

  /// Agenda day header: `BUGÜN · CUMARTESİ 13 EYLÜL`,
  /// `YARIN · PAZAR 14 EYLÜL`, `PAZARTESİ 15 EYLÜL`.
  static String agendaDayHeader(DateTime day, DateTime now) {
    final pattern = day.year == now.year ? 'EEEE d MMMM' : 'EEEE d MMMM y';
    final date = DateFormat(pattern, _locale).format(day);
    final diff = dayDiff(now, day);
    final prefix = switch (diff) {
      0 => 'Bugün · ',
      1 => 'Yarın · ',
      _ => '',
    };
    return upperTr('$prefix$date');
  }

  /// Birthday countdown: `Bugün`, `Yarın`, `8 gün`.
  static String countdown(int daysUntil) => switch (daysUntil) {
        0 => 'Bugün',
        1 => 'Yarın',
        _ => '$daysUntil gün',
      };
}
