import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// One month section on the Doğum günleri page.
class BirthdayMonthGroup {
  const BirthdayMonthGroup({required this.month, required this.items});

  /// First day of the month (of the occurrence year).
  final DateTime month;
  final List<BirthdayOccurrence> items;
}

/// Pure groupings for the Doğum günleri page (§3.3.7).
abstract final class BirthdayGroups {
  /// Next occurrence of every birthday, soonest first (ties by name).
  static List<BirthdayOccurrence> upcoming(
    List<Birthday> birthdays,
    DateTime now,
  ) {
    return [for (final b in birthdays) BirthdayOccurrence.next(b, now)]
      ..sort((a, b) {
        final byDays = a.daysUntil.compareTo(b.daysUntil);
        return byDays != 0
            ? byDays
            : a.birthday.name.compareTo(b.birthday.name);
      });
  }

  /// The "SIRADAKİ" hero: the soonest birthday (today counts), or `null`.
  static BirthdayOccurrence? hero(List<Birthday> birthdays, DateTime now) {
    final list = upcoming(birthdays, now);
    return list.isEmpty ? null : list.first;
  }

  /// [upcoming] split into consecutive months, starting with this month
  /// (a birthday already passed this year is in next year's month, so the
  /// current month can appear again at the end).
  static List<BirthdayMonthGroup> byMonth(
    List<Birthday> birthdays,
    DateTime now,
  ) {
    final groups = <BirthdayMonthGroup>[];
    for (final o in upcoming(birthdays, now)) {
      final month = DateTime(o.date.year, o.date.month);
      if (groups.isEmpty || groups.last.month != month) {
        groups.add(BirthdayMonthGroup(month: month, items: []));
      }
      groups.last.items.add(o);
    }
    return groups;
  }

  /// `Eylül`, or `Ocak 2027` in another year than [now].
  static String monthHeader(
    DateTime month,
    DateTime now,
    AppLocalizations l10n,
  ) =>
      KorFormat.pattern(
        month.year == now.year
            ? l10n.dateFormatMonth
            : l10n.dateFormatMonthYear,
        month,
        l10n,
      );

  /// Birth day and month: `14 Eylül` (29 Şubat stays 29 Şubat).
  static String birthDay(Birthday b, AppLocalizations l10n) =>
      KorFormat.pattern(
        l10n.dateFormatDayMonth,
        DateTime(2000, b.month, b.day),
        l10n,
      );

  /// Row subtitle: `14 Eylül · 30 yaşına` / `3 Ekim · yaş bilinmiyor`.
  static String rowSubtitle(BirthdayOccurrence o, AppLocalizations l10n) {
    final age = o.age;
    final day = birthDay(o.birthday, l10n);
    return age != null
        ? l10n.birthdayRowAge(day, '$age')
        : l10n.birthdayRowNoAge(day);
  }

  /// 29 Şubat note when this occurrence falls in a non-leap year.
  static String? leapDayNote(BirthdayOccurrence o, AppLocalizations l10n) =>
      o.movedFromLeapDay ? l10n.birthdayLeapNote : null;

  /// Hero line: `Yarın · 30 yaşına giriyor`, `21 Eylül · yaşı bilinmiyor`.
  static String heroLine(
    BirthdayOccurrence o,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final when = switch (o.daysUntil) {
      0 => l10n.dayToday,
      1 => l10n.dayTomorrow,
      _ => KorFormat.dayMonth(o.date, now, l10n),
    };
    final age = o.age;
    return age != null ? l10n.birthdayHeroAge(when, '$age') : when;
  }

  /// Advance offset chip: "Doğum gününde", "1 saat önce", "3 gün önce",
  /// "1 hafta önce".
  static String offsetLabel(int minutes, AppLocalizations l10n) {
    if (minutes <= 0) return l10n.birthdayOffsetOnDay;
    if (minutes % 10080 == 0) return l10n.birthdayOffsetWeeks(minutes ~/ 10080);
    if (minutes % 1440 == 0) return l10n.birthdayOffsetDays(minutes ~/ 1440);
    if (minutes % 60 == 0) return l10n.birthdayOffsetHours(minutes ~/ 60);
    return l10n.birthdayOffsetMinutes(minutes);
  }
}
