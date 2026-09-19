import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Display texts of a [RecurrenceRule] (F3.1, localized in F6.1): the short
/// summary on cards, in the editor and the capture chips.
abstract final class RecurrenceText {
  /// "Her gün", "3 günde bir", "Her Cumartesi", "2 haftada bir Pzt, Çar",
  /// "Hafta içi her gün", "Her ayın 17'si", "2 ayda bir, ayın 31'i"; an end
  /// date adds " · bitiş 31 Ara 2026". English: "Every day", "Every 3
  /// days", "Every Saturday", "Every 2 weeks on Mon, Wed", "Every weekday",
  /// "Monthly on the 17th", "… · until Dec 31, 2026".
  static String summary(RecurrenceRule rule, AppLocalizations l10n) {
    final interval = rule.interval;
    final base = switch (rule.frequency) {
      RecurrenceFrequency.none => l10n.recurrenceNone,
      RecurrenceFrequency.daily => l10n.recurrenceDaily(interval),
      RecurrenceFrequency.weekly => _weekly(rule, l10n),
      RecurrenceFrequency.monthly => l10n.recurrenceMonthly(
          interval,
          dayOfMonthLabel(rule.dayOfMonth ?? 1, l10n),
        ),
    };
    final end = rule.until;
    if (rule.isNone || end == null) return base;
    return l10n.recurrenceUntil(
      base,
      KorFormat.pattern(l10n.dateFormatShortYear, end, l10n),
    );
  }

  static String _weekly(RecurrenceRule rule, AppLocalizations l10n) {
    final interval = rule.interval;
    final weekdays = rule.weekdays;
    if (weekdays.isEmpty) return l10n.recurrenceWeekly(interval);
    if (interval == 1 &&
        weekdays.length == 5 &&
        [for (var d = 1; d <= 5; d++) d].every(weekdays.contains)) {
      return l10n.recurrenceWeekdays;
    }
    if (interval == 1 && weekdays.length == 7) return l10n.recurrenceDaily(1);
    if (weekdays.length == 1) {
      return l10n.recurrenceWeeklyOn(
        interval,
        KorFormat.weekdayName(weekdays.single, l10n),
      );
    }
    final names = [
      for (final d in weekdays) KorFormat.weekdayShort(d, l10n),
    ].join(', ');
    return l10n.recurrenceWeeklyOnDays(interval, names);
  }

  /// Day of month with the Turkish possessive suffix (`1'i`, `2'si`, `3'ü`,
  /// `6'sı`, `9'u`, `10'u`, `17'si`, `20'si`, `30'u`) or the English ordinal
  /// (`1st`, `2nd`, `3rd`, `11th`, `22nd`).
  static String dayOfMonthLabel(int day, AppLocalizations l10n) {
    if (!l10n.isTurkish) {
      final teen = day % 100 >= 11 && day % 100 <= 13;
      final suffix = teen
          ? 'th'
          : switch (day % 10) {
              1 => 'st',
              2 => 'nd',
              3 => 'rd',
              _ => 'th',
            };
      return '$day$suffix';
    }
    const lastDigit = [
      "",
      "'i",
      "'si",
      "'ü",
      "'ü",
      "'i",
      "'sı",
      "'si",
      "'i",
      "'u"
    ];
    const tens = {10: "'u", 20: "'si", 30: "'u"};
    final suffix = day % 10 == 0 ? tens[day] ?? "'ı" : lastDigit[day % 10];
    return '$day$suffix';
  }
}
