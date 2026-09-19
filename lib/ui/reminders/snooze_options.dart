import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Which quick snooze an option is (the sheet maps it to an icon).
enum SnoozeKind { tenMinutes, oneHour, evening, tomorrowMorning }

/// One quick snooze choice: its [kind] and the resulting time; [labelIn]
/// is its name ("10 dakika").
class SnoozeOption {
  const SnoozeOption({
    required this.kind,
    required this.at,
    this.today = true,
  });

  final SnoozeKind kind;
  final DateTime at;

  /// Whether the evening option is still today ("Bu akşam" vs "Yarın
  /// akşam").
  final bool today;

  /// "10 dakika", "1 saat", "Bu akşam" / "Yarın akşam", "Yarın sabah".
  String labelIn(AppLocalizations l10n) => switch (kind) {
        SnoozeKind.tenMinutes => l10n.snoozeTenMinutes,
        SnoozeKind.oneHour => l10n.snoozeOneHour,
        SnoozeKind.evening =>
          today ? l10n.snoozeThisEvening : l10n.snoozeTomorrowEvening,
        SnoozeKind.tomorrowMorning => l10n.snoozeTomorrowMorning,
      };

  @override
  String toString() => 'SnoozeOption($kind, $at)';
}

/// Pure snooze time rules (Ertele sheet, §3.3.4). Everything is a function of
/// the given `now`, so callers pass their injected clock.
abstract final class SnoozeOptions {
  static const int eveningHour = 20;
  static const int morningHour = 9;

  /// `10 dakika`, `1 saat`, `Bu akşam 20:00` (or `Yarın akşam 20:00` once
  /// 20:00 has passed) and `Yarın sabah 09:00`. Relative options drop the
  /// seconds of [now].
  static List<SnoozeOption> from(DateTime now) {
    final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final evening = DateTime(now.year, now.month, now.day, eveningHour);
    final eveningToday = now.isBefore(evening);
    return [
      SnoozeOption(
        kind: SnoozeKind.tenMinutes,
        at: minute.add(const Duration(minutes: 10)),
      ),
      SnoozeOption(
        kind: SnoozeKind.oneHour,
        at: minute.add(const Duration(hours: 1)),
      ),
      SnoozeOption(
        kind: SnoozeKind.evening,
        today: eveningToday,
        at: eveningToday
            ? evening
            : DateTime(now.year, now.month, now.day + 1, eveningHour),
      ),
      SnoozeOption(
        kind: SnoozeKind.tomorrowMorning,
        at: DateTime(now.year, now.month, now.day + 1, morningHour),
      ),
    ];
  }

  /// Option subtitle: `14:42` today, otherwise `Pzt 09:00`.
  static String timeLabel(DateTime at, DateTime now, AppLocalizations l10n) {
    if (KorFormat.isSameDay(at, now)) return KorFormat.time(at);
    return l10n.snoozeWeekdayTime(
      KorFormat.pattern(l10n.dateFormatWeekdayShort, at, l10n),
      KorFormat.time(at),
    );
  }

  /// Snackbar text: `Yarın 09:00'a ertelendi`, `14:42'ye ertelendi`;
  /// English `Snoozed until Tomorrow 09:00`.
  static String snoozedMessage(
    DateTime at,
    DateTime now,
    AppLocalizations l10n,
  ) =>
      l10n.snoozedTo(KorFormat.when(at, now, l10n), dativeSuffix(at));

  static const _units = [
    '',
    'bir',
    'iki',
    'üç',
    'dört',
    'beş',
    'altı',
    'yedi',
    'sekiz',
    'dokuz',
  ];
  static const _tens = ['', 'on', 'yirmi', 'otuz', 'kırk', 'elli'];

  /// Turkish dative suffix for a `HH:mm` time, following the last spoken
  /// number word: `09:00` → "dokuz" → `a`, `14:42` → "iki" → `ye`,
  /// `20:00` → "yirmi" → `ye`, `10:30` → "otuz" → `a`.
  static String dativeSuffix(DateTime t) {
    final n = t.minute != 0 ? t.minute : t.hour;
    final word =
        n == 0 ? 'sıfır' : (n % 10 != 0 ? _units[n % 10] : _tens[n ~/ 10]);
    const vowels = 'aeıioöuü';
    const back = 'aıou';
    var last = '';
    for (final ch in word.split('')) {
      if (vowels.contains(ch)) last = ch;
    }
    final vowel = back.contains(last) ? 'a' : 'e';
    final endsWithVowel = vowels.contains(word[word.length - 1]);
    return endsWithVowel ? 'y$vowel' : vowel;
  }
}
