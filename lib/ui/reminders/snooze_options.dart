import 'package:intl/intl.dart';

import 'package:reminder/ui/common/kor_format.dart';

/// Which quick snooze an option is (the sheet maps it to an icon).
enum SnoozeKind { tenMinutes, oneHour, evening, tomorrowMorning }

/// One quick snooze choice: [label] ("10 dakika") and the resulting time.
class SnoozeOption {
  const SnoozeOption({
    required this.kind,
    required this.label,
    required this.at,
  });

  final SnoozeKind kind;
  final String label;
  final DateTime at;

  @override
  String toString() => 'SnoozeOption($label, $at)';
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
        label: '10 dakika',
        at: minute.add(const Duration(minutes: 10)),
      ),
      SnoozeOption(
        kind: SnoozeKind.oneHour,
        label: '1 saat',
        at: minute.add(const Duration(hours: 1)),
      ),
      SnoozeOption(
        kind: SnoozeKind.evening,
        label: eveningToday ? 'Bu akşam' : 'Yarın akşam',
        at: eveningToday
            ? evening
            : DateTime(now.year, now.month, now.day + 1, eveningHour),
      ),
      SnoozeOption(
        kind: SnoozeKind.tomorrowMorning,
        label: 'Yarın sabah',
        at: DateTime(now.year, now.month, now.day + 1, morningHour),
      ),
    ];
  }

  /// Option subtitle: `14:42` today, otherwise `Pzt 09:00`.
  static String timeLabel(DateTime at, DateTime now) {
    if (KorFormat.isSameDay(at, now)) return KorFormat.time(at);
    return '${DateFormat('EEE', 'tr_TR').format(at)} ${KorFormat.time(at)}';
  }

  /// Snackbar text: `Yarın 09:00'a ertelendi`, `14:42'ye ertelendi`.
  static String snoozedMessage(DateTime at, DateTime now) =>
      "${KorFormat.when(at, now)}'${dativeSuffix(at)} ertelendi";

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
