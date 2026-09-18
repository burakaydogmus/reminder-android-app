part of '../turkish_capture_parser.dart';

/// Clock times and day parts.
///
/// - `18:00`, `18:00'de`, `8:15`: always a time. `18.30`, `18.30'da`,
///   `17.09'da`: a time when the date rule did not take it (see
///   `_DateRules`); not before a unit (`1.50 TL`, `2.30 kg`).
/// - `saat 9`, `saat 9'da`, `saat 18:30`, `saat 3 buçuk`: literal hour.
/// - `9'da`/`9da`/`15'te`: literal hour 0–23 (no am/pm guess: `9'da` is
///   09:00; with no date it is today when still ahead, else tomorrow). Not in
///   fractions (`3'te bir`). Confidence 0.8.
/// - `9 buçukta` = 09:30 (standalone needs the suffix: `1 buçuk kilo` is text).
/// - Day parts `sabah` (config, 09:00), `öğlen`/`öğle`/`öğleyin` (12:00),
///   `öğleden sonra` (15:00), `akşam` (20:00), `gece` (22:00), also
///   `sabahleyin`, `akşama (kadar)`, and possessive `akşamı`/`gecesi` right
///   after a date (`cuma akşamı`). With an hour they shift it: `akşam 8'de` =
///   20:00, `gece 11'de` = 23:00, `gece 2'de` = 02:00, `öğlen 1'de` = 13:00
///   (1–6 after `öğlen`/`öğle` and 1–11 after `öğleden sonra` are PM).
///   `bu akşam` also fixes the date to today.
/// - A bare day part is **not** a time when it is part of a noun phrase:
///   suffixed forms (`akşamki`, `akşamın`), after `bir/o/şu/dün/geçen/bütün/
///   tüm/aynı/hangi/bazı` (`bir akşam`), or before a compound noun
///   (`akşam yemeği`, `öğle arası`, `gece kremi`, `sabah sporu`, …).
extension _TimeRules on _Scanner {
  static final RegExp _clock =
      RegExp(r"^(\d{1,2})([:.])(\d{2})(?:'?(da|de|ta|te|a|e|ya|ye))?$");
  static final RegExp _hourSuffixed = RegExp(r"^(\d{1,2})'?(da|de|ta|te)$");
  static final RegExp _bareHour = RegExp(r'^(\d{1,2})$');
  static final RegExp _daypart =
      RegExp(r'^(sabah|aksam|gece|oglen|ogle)(leyin|yin|a|e|ye|i|si|ni)?$');

  static const Set<String> daypartNames = {
    'sabah',
    'aksam',
    'gece',
    'oglen',
    'ogle',
  };

  /// Words before a day part that make it a noun (`bir akşam`, `dün akşam`).
  static const Set<String> _blockers = {
    'bir',
    'o',
    'su',
    'dun',
    'gecen',
    'butun',
    'tum',
    'ayni',
    'hangi',
    'bazi',
  };

  /// Prefixes of words that turn a bare day part into a compound noun.
  static const List<String> _compoundNouns = [
    'yemeg',
    'kahvalti',
    'krem',
    'namaz',
    'ezan',
    'spor',
    'yuruyus',
    'kosu',
    'vardiya',
    'mesai',
    'nobet',
    'haber',
    'bulten',
    'ders',
    'rutin',
    'bakim',
    'maske',
    'arasi',
    'ogun',
    'program',
    'egzersiz',
    'yarisi',
    'hayat',
    'kulub',
    'okul',
  ];

  /// Units after a number that make `1.50` a price or amount, not a time.
  static const Set<String> _units = {
    'tl',
    'lira',
    'kurus',
    'kr',
    'kg',
    'kilo',
    'gr',
    'gram',
    'lt',
    'litre',
    'ml',
    'cm',
    'mm',
    'm',
    'km',
    'adet',
    'tane',
    'puan',
    'euro',
    'dolar',
  };

  static const Set<String> _dativeSuffixes = {'a', 'e', 'ya', 'ye'};

  int defaultHour(String part) => switch (part) {
        'sabah' => config.morningHour,
        'aksam' => config.eveningHour,
        'gece' => config.nightHour,
        'ogleden' => config.afternoonHour,
        _ => config.noonHour,
      };

  /// Shifts a 12-hour style hour into the day part.
  static int adjustHour(String part, int hour) {
    switch (part) {
      case 'aksam':
      case 'ogleden':
        return hour >= 1 && hour <= 11 ? hour + 12 : hour;
      case 'gece':
        if (hour >= 6 && hour <= 11) return hour + 12;
        return hour == 12 ? 0 : hour;
      case 'ogle':
        return hour >= 1 && hour <= 6 ? hour + 12 : hour;
      default:
        return hour;
    }
  }

  /// A clock at [j] ([w] its folded text): `18:00`, `18.30`, `9'da`,
  /// `9 buçukta`. With [inContext] (after `saat` or a day part) a bare `9`
  /// and `9 buçuk` count too.
  ({int hour, int minute, int end, double confidence})? clockAt(
    int j,
    String? w, {
    required bool inContext,
  }) {
    if (w == null) return null;
    final c = _clock.firstMatch(w);
    if (c != null) {
      final hour = int.parse(c.group(1)!);
      final minute = int.parse(c.group(3)!);
      if (hour > 23 || minute > 59) return null;
      final dot = c.group(2) == '.';
      if (dot && !inContext && _units.contains(next(j + 1))) return null;
      var end = j + 1;
      if (_dativeSuffixes.contains(c.group(4)) && next(end) == 'kadar') end++;
      return (
        hour: hour,
        minute: minute,
        end: end,
        confidence: dot && !inContext ? 0.9 : 1.0,
      );
    }
    final s = _hourSuffixed.firstMatch(w);
    if (s != null) {
      final hour = int.parse(s.group(1)!);
      if (hour > 23 || next(j + 1) == 'bir') return null;
      return (
        hour: hour,
        minute: 0,
        end: j + 1,
        confidence: inContext ? 1.0 : 0.8,
      );
    }
    final b = _bareHour.firstMatch(w);
    if (b != null) {
      final hour = int.parse(b.group(1)!);
      if (hour > 23) return null;
      final half = next(j + 1);
      if (half == 'bucukta' || (inContext && half == 'bucuk')) {
        return (
          hour: hour,
          minute: 30,
          end: j + 2,
          confidence: inContext ? 1.0 : 0.9,
        );
      }
      if (inContext) {
        return (hour: hour, minute: 0, end: j + 1, confidence: 1.0);
      }
    }
    return null;
  }

  /// Optional `saat` plus a clock starting at [k], shifted into [part].
  ({_Clock clock, int end})? daypartClock(int k, String part) {
    var j = k;
    if (next(j) == 'saat') j++;
    final c = clockAt(j, next(j), inContext: true);
    if (c == null) return null;
    return (clock: _Clock(adjustHour(part, c.hour), c.minute), end: c.end);
  }

  /// A day part word at [j]: normalized part (`sabah`, `ogle`, `aksam`,
  /// `gece`, `ogleden`), end, and whether it is possessive (`akşamı`).
  ({String part, int end, bool possessive})? daypartAt(int j, String? w) {
    if (w == null) return null;
    if (w == 'ogleden') {
      return next(j + 1) == 'sonra'
          ? (part: 'ogleden', end: j + 2, possessive: false)
          : null;
    }
    final m = _daypart.firstMatch(w);
    if (m == null) return null;
    final base = m.group(1)!;
    final suffix = m.group(2);
    var end = j + 1;
    if (_dativeSuffixes.contains(suffix) && next(end) == 'kadar') end++;
    return (
      part: base == 'oglen' ? 'ogle' : base,
      end: end,
      possessive: suffix == 'i' || suffix == 'si' || suffix == 'ni',
    );
  }

  _Unit? timeRule(int i) {
    final w = words[i].fold;
    final bu = w == 'bu';
    final dp = bu ? daypartAt(i + 1, next(i + 1)) : daypartAt(i, w);
    if (dp != null) {
      if (dp.possessive && (bu || !afterDateLike(i))) return null;
      if (!bu && _blockers.contains(previous(i))) return null;
      _Unit build(int end, _Clock clock, double confidence) {
        final unit = _Unit(end)
          ..time = clock
          ..tokens.add(token(CaptureTokenKind.time, i, end, confidence));
        if (bu) unit.date = _FixedDate(today);
        return unit;
      }

      final withClock = daypartClock(dp.end, dp.part);
      if (withClock != null) return build(withClock.end, withClock.clock, 1);
      final following = next(dp.end);
      if (following != null && _compoundNouns.any(following.startsWith)) {
        return null;
      }
      final contextual = bu || afterDateLike(i);
      return build(
        dp.end,
        _Clock(defaultHour(dp.part), 0),
        contextual ? 0.95 : 0.8,
      );
    }
    if (bu) return null;
    final inContext = w == 'saat';
    final start = inContext ? i + 1 : i;
    final c = clockAt(start, inContext ? next(start) : w, inContext: inContext);
    if (c == null) return null;
    return _Unit(c.end)
      ..time = _Clock(c.hour, c.minute)
      ..tokens.add(token(CaptureTokenKind.time, i, c.end, c.confidence));
  }
}
