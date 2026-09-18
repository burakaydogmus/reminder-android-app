import 'package:intl/intl.dart';

import 'package:reminder/domain/model/birthday.dart';
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
  static const _locale = 'tr_TR';

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
  static String monthHeader(DateTime month, DateTime now) =>
      DateFormat(month.year == now.year ? 'MMMM' : 'MMMM y', _locale)
          .format(month);

  /// Birth day and month: `14 Eylül` (29 Şubat stays 29 Şubat).
  static String birthDay(Birthday b) => DateFormat('d MMMM', _locale)
      .format(DateTime(2000, b.date.month, b.date.day));

  /// Row subtitle: `14 Eylül · 30 yaşına` / `3 Ekim · yaş bilinmiyor`.
  static String rowSubtitle(BirthdayOccurrence o) {
    final age = o.age;
    return '${birthDay(o.birthday)} · '
        '${age != null ? '$age yaşına' : 'yaş bilinmiyor'}';
  }

  /// 29 Şubat note when this occurrence falls in a non-leap year.
  static String? leapDayNote(BirthdayOccurrence o) =>
      o.movedFromLeapDay ? "Artık yıl değil: 28 Şubat'ta hatırlatılır" : null;

  /// Hero line: `Yarın · 30 yaşına giriyor`, `21 Eylül · yaşı bilinmiyor`.
  static String heroLine(BirthdayOccurrence o, DateTime now) {
    final when = switch (o.daysUntil) {
      0 => 'Bugün',
      1 => 'Yarın',
      _ => KorFormat.dayMonth(o.date, now),
    };
    final age = o.age;
    return age != null ? '$when · $age yaşına giriyor' : when;
  }
}
