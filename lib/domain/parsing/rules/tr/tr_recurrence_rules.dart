part of '../../capture_parser.dart';

/// Repeats.
///
/// - `her gün`/`hergün` (daily), `her sabah/öğlen/akşam/gece` (daily at the
///   day part; `her akşam 9'da` = 21:00), plural `sabahları`, `akşamları`.
/// - `her hafta` (weekly on the first occurrence's weekday), `her pazartesi`,
///   `her pazartesi, çarşamba ve cuma`, `her salı ile perşembe`, plural
///   `cumaları`, `pazartesileri ve perşembeleri` (`pazarları` is left alone:
///   also "the markets").
/// - `hafta içi`/`haftaiçi`/`hafta içleri`/`her hafta içi` (Mon–Fri),
///   `hafta sonları`/`her hafta sonu` (Sat–Sun). Bare `hafta sonu` is a
///   one-off date (this weekend), see `_DateRules`.
/// - `her ay` (monthly on the first occurrence's day), `her ayın 17'si`,
///   `her ay 15'inde`.
/// - `her yıl`/`her sene`, `yıllık`/`senelik` (yearly on the first
///   occurrence's month and day), `2 yılda bir`/`iki senede bir`.
/// - `3 günde bir`/`üç günde bir` (every N days), `gün aşırı`/`günaşırı`
///   (every 2 days), `2 haftada bir`, `3 ayda bir`, `2 yılda bir`
///   (`1 günde bir` = daily, `1 yılda bir` = yearly).
/// - Not supported (left as text): `her şey`.
extension _TrRecurrenceRules on _TrScanner {
  static final RegExp _pluralWeekday = RegExp(
    r'^(pazartesi|sali|carsamba|persembe|cumartesi|cuma)(leri|lari)$',
  );
  static final RegExp _pluralDaypart =
      RegExp(r'^(sabah|aksam|gece|oglen|ogle)(lari|leri)$');
  static final RegExp _digits = RegExp(r'^\d+$');

  static const RecurrenceSpec _daily = RecurrenceSpec(
    kind: RecurrenceKind.daily,
  );
  static const RecurrenceSpec _weekdays = RecurrenceSpec(
    kind: RecurrenceKind.weekly,
    weekdays: [1, 2, 3, 4, 5],
  );
  static const RecurrenceSpec _weekends = RecurrenceSpec(
    kind: RecurrenceKind.weekly,
    weekdays: [6, 7],
  );
  static const RecurrenceSpec _yearly = RecurrenceSpec(
    kind: RecurrenceKind.yearly,
  );

  /// Nouns that make `yıllık` / `senelik` an adjective ("yıllık rapor"),
  /// not a repeat — the Turkish twin of the English `_repeatNouns` guard.
  static const Set<String> _yearlyNouns = {
    'izin',
    'izni',
    'izinler',
    'rapor',
    'raporu',
    'bilanco',
    'faiz',
    'gelir',
    'gider',
    'ortalama',
    'toplam',
    'butce',
    'plan',
    'abonelik',
    'uyelik',
    'sozlesme',
    'ucret',
    'kira',
  };

  _Unit? recurrenceRule(int i) {
    final w = words[i].fold;
    switch (w) {
      case 'her':
        return _every(i);
      case 'hergun':
        return _rec(i, i + 1, _daily, 1);
      case 'haftaici':
      case 'haftaicleri':
        return _rec(i, i + 1, _weekdays, 0.9);
      case 'haftasonlari':
        return _rec(i, i + 1, _weekends, 0.9);
      case 'hafta':
        final n = next(i + 1);
        if (n == 'ici' || n == 'icleri') return _rec(i, i + 2, _weekdays, 0.9);
        if (n == 'sonlari') return _rec(i, i + 2, _weekends, 0.9);
        return null;
      case 'yillik':
      case 'senelik':
        return _yearlyAdjective(i) ? null : _rec(i, i + 1, _yearly, 0.9);
      case 'gunasiri':
        return _rec(i, i + 1, _everyDays(2), 0.95);
      case 'gun':
        return next(i + 1) == 'asiri'
            ? _rec(i, i + 2, _everyDays(2), 0.95)
            : null;
    }

    final n = _TrDateRules.numberValue(w);
    if (n != null) {
      final unit = next(i + 1);
      if (n == 0 || next(i + 2) != 'bir') return null;
      final spec = switch (unit) {
        'gunde' => n == 1 ? _daily : _everyDays(n),
        'haftada' => RecurrenceSpec(kind: RecurrenceKind.weekly, interval: n),
        'ayda' => RecurrenceSpec(kind: RecurrenceKind.monthly, interval: n),
        'yilda' ||
        'senede' =>
          RecurrenceSpec(kind: RecurrenceKind.yearly, interval: n),
        _ => null,
      };
      return spec == null ? null : _rec(i, i + 3, spec, 0.95);
    }

    final list = _weekdayList(i, w, plural: true);
    if (list != null) {
      return _rec(
        i,
        list.end,
        RecurrenceSpec(kind: RecurrenceKind.weekly, weekdays: list.days),
        0.9,
      );
    }
    final pd = _pluralDaypart.firstMatch(w);
    if (pd != null) {
      final base = pd.group(1)!;
      return _daypartRepeat(i, i + 1, base == 'oglen' ? 'ogle' : base, 0.9);
    }
    return null;
  }

  /// `her …` at [i].
  _Unit? _every(int i) {
    final n1 = next(i + 1);
    if (n1 == null) return null;
    switch (n1) {
      case 'gun':
        return _rec(i, i + 2, _daily, 1);
      case 'hafta':
        final n2 = next(i + 2);
        if (n2 == 'ici' || n2 == 'icleri') return _rec(i, i + 3, _weekdays, 1);
        if (n2 == 'sonu' || n2 == 'sonlari') {
          return _rec(i, i + 3, _weekends, 1);
        }
        return _rec(
          i,
          i + 2,
          const RecurrenceSpec(kind: RecurrenceKind.weekly),
          1,
        );
      case 'haftaici':
        return _rec(i, i + 2, _weekdays, 1);
      case 'haftasonu':
        return _rec(i, i + 2, _weekends, 1);
      case 'ay':
        final w = next(i + 2);
        final day = w == null || _digits.hasMatch(w) ? null : _dayOfMonth(w);
        if (day != null) return _rec(i, i + 3, _monthly(day), 1);
        return _rec(
          i,
          i + 2,
          const RecurrenceSpec(kind: RecurrenceKind.monthly),
          1,
        );
      case 'ayin':
        final day = _dayOfMonth(next(i + 2));
        return day == null ? null : _rec(i, i + 3, _monthly(day), 1);
      case 'yil':
      case 'sene':
        return _rec(i, i + 2, _yearly, 1);
    }
    if (_TrTimeRules.daypartNames.contains(n1)) {
      return _daypartRepeat(i, i + 2, n1 == 'oglen' ? 'ogle' : n1, 1);
    }
    final list = _weekdayList(i + 1, n1, plural: false);
    if (list == null) return null;
    return _rec(
      i,
      list.end,
      RecurrenceSpec(kind: RecurrenceKind.weekly, weekdays: list.days),
      1,
    );
  }

  /// `yıllık rapor`, `senelik izin`: an adjective, not a repeat.
  bool _yearlyAdjective(int i) {
    final following = next(i + 1);
    return following != null && _yearlyNouns.contains(following);
  }

  static RecurrenceSpec _everyDays(int n) =>
      RecurrenceSpec(kind: RecurrenceKind.everyNDays, interval: n);

  static RecurrenceSpec _monthly(int day) =>
      RecurrenceSpec(kind: RecurrenceKind.monthly, dayOfMonth: day);

  static int? _dayOfMonth(String? w) {
    final m = _TrDateRules._dayOfMonth.firstMatch(w ?? '');
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    return day >= 1 && day <= 31 ? day : null;
  }

  _Unit _rec(int from, int to, RecurrenceSpec spec, double confidence) =>
      _Unit(to)
        ..recurrence = spec
        ..tokens.add(token(CaptureTokenKind.recurrence, from, to, confidence));

  /// Daily at a day part; an hour right after becomes its own time token.
  _Unit _daypartRepeat(int from, int to, String part, double confidence) {
    final clock = daypartClock(to, part);
    if (clock == null) {
      return _rec(from, to, _daily, confidence)
        ..time = _Clock(defaultHour(part), 0);
    }
    return _Unit(clock.end)
      ..recurrence = _daily
      ..time = clock.clock
      ..tokens.add(token(CaptureTokenKind.recurrence, from, to, confidence))
      ..tokens.add(token(CaptureTokenKind.time, to, clock.end, 1));
  }

  /// One or more weekdays from [j] joined by `,`, `ve` or `ile`.
  ({List<int> days, int end})? _weekdayList(
    int j,
    String? w, {
    required bool plural,
  }) {
    final first = _listDay(j, w, plural: plural);
    if (first == null) return null;
    final days = <int>{first.day};
    var end = first.end;
    while (end < words.length) {
      var k = end;
      final sep = nextInList(k);
      if (sep == null) break;
      String? candidate;
      if (sep == 've' || sep == 'ile') {
        k++;
        candidate = next(k);
      } else if (words[k - 1].trailing == ',') {
        candidate = sep;
      } else {
        break;
      }
      final day = _listDay(k, candidate, plural: plural);
      if (day == null) break;
      days.add(day.day);
      end = day.end;
    }
    return (days: days.toList()..sort(), end: end);
  }

  ({int day, int end})? _listDay(int j, String? w, {required bool plural}) {
    if (w == null) return null;
    final int? day;
    if (plural) {
      final m = _pluralWeekday.firstMatch(w);
      day = m == null ? null : _TrDateRules.weekdayNumbers[m.group(1)!];
    } else {
      day = _TrDateRules.weekdayNumbers[w];
    }
    if (day == null) return null;
    if (day == DateTime.tuesday && words[j].lower.startsWith('ş')) return null;
    var end = j + 1;
    if (!plural) {
      final g = next(end);
      if (g == 'gunu' || g == 'gunleri') end++;
    }
    return (day: day, end: end);
  }
}
