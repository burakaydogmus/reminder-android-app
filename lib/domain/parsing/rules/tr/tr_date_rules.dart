part of '../../capture_parser.dart';

/// Day phrases and relative offsets.
///
/// - `bugün`, `yarın`/`yarına (kadar)`, `öbür gün`/`öbürgün`.
/// - `haftaya` (+7 days), `haftaya bugün`, `haftaya cuma` (next Friday + 7),
///   `gelecek/önümüzdeki hafta (cuma)`, `gelecek cuma`, `bu cuma`.
/// - Weekdays `pazartesi…pazar` with case suffixes (`cumaya (kadar)`,
///   `pazartesiye`, `Cuma'ya`, `cuma günü`): the next occurrence; today only
///   when a time is given and still ahead (resolved later).
///   **`pazar` with a suffix is not a date** (`pazara git` = the market) and
///   `geçen cuma` / `dün` phrases are left alone (past). `salı` is not
///   matched from `şalı`.
/// - `hafta sonu`, `bu hafta sonu`: next Saturday (the plural
///   `hafta sonları` and `her hafta sonu` are repeats).
/// - `ayın 17'si` / `17sinde` / `1'inde`: this month if not before today,
///   otherwise the next month that has that day (`ayın 31'i` in September →
///   31 October).
/// - `17 eylül`, `17 Eylül'de`, `1 ocak 2027`: without a year the next
///   occurrence (today included; `29 şubat` → next leap year); with a year as
///   given, even in the past (`isPast`). Invalid days (`31 nisan`) are text.
/// - `17.09`, `17/09`, `17.09.2027`, `01/10/26`: the second part needs two
///   digits unless a year follows (`1.5 kilo` is text). A dot form without a
///   year is a **time** when its second part is not a month (`18.30`) or a
///   locative suffix follows (`17.09'da` = 17:09).
/// - `3 gün sonra`, `iki hafta sonra`, `1 ay sonra` (dates);
///   `2 saat sonra`, `yarım saat sonra`, `10 dk sonra` (instants, time tokens).
extension _TrDateRules on _TrScanner {
  static final RegExp _weekday = RegExp(
    r"^(pazartesi|sali|carsamba|persembe|cumartesi|cuma|pazar)"
    r"(?:'?(ya|ye|a|e|da|de|dan|den))?$",
  );
  static final RegExp _gunu = RegExp(r'^gunu(ne|nde|nden)?$');
  static final RegExp _dayOfMonth =
      RegExp(r"^(\d{1,2})(?:'?s?[iu](?:n(?:de|da|e|a|den|dan))?)?$");
  static final RegExp _plainDay = RegExp(r'^(\d{1,2})$');
  static final RegExp _month = RegExp(
    r'^(ocak|subat|mart|nisan|mayis|haziran|temmuz|agustos|eylul|ekim|kasim|'
    r"aralik)(?:'?(da|de|ta|te|a|e|ya|ye|in|un|nin|nun|dan|den|tan|ten))?$",
  );
  static final RegExp _year =
      RegExp(r"^(20\d\d)(?:'?(da|de|ta|te|a|e|ya|ye))?$");
  static final RegExp _numericDate = RegExp(
    r'^(\d{1,2})([./])(\d{1,2})(?:([./])(\d{4}|\d{2}))?'
    r"(?:'?(da|de|ta|te|a|e|ya|ye))?$",
  );
  static final RegExp _number = RegExp(r'^\d{1,3}$');
  static final RegExp _relativeUnit =
      RegExp(r'^(gun|hafta|ay|saat|sa|dakika|dk|dak)$');

  static const Map<String, int> weekdayNumbers = {
    'pazartesi': DateTime.monday,
    'sali': DateTime.tuesday,
    'carsamba': DateTime.wednesday,
    'persembe': DateTime.thursday,
    'cuma': DateTime.friday,
    'cumartesi': DateTime.saturday,
    'pazar': DateTime.sunday,
  };
  static const List<String> _months = [
    'ocak',
    'subat',
    'mart',
    'nisan',
    'mayis',
    'haziran',
    'temmuz',
    'agustos',
    'eylul',
    'ekim',
    'kasim',
    'aralik',
  ];
  static const Map<String, int> numberWords = {
    'bir': 1,
    'iki': 2,
    'uc': 3,
    'dort': 4,
    'bes': 5,
    'alti': 6,
    'yedi': 7,
    'sekiz': 8,
    'dokuz': 9,
    'on': 10,
  };
  static const Set<String> _dative = {'ya', 'ye', 'a', 'e'};

  /// `N` as digits (1–999) or a number word (`bir`…`on`).
  static int? numberValue(String? word) {
    if (word == null) return null;
    if (_number.hasMatch(word)) return int.parse(word);
    return numberWords[word];
  }

  /// A weekday word at [j] ([w] is its folded text, or `null` when the
  /// phrase may not continue there), with optional `günü` and `kadar`.
  ({int weekday, int end})? weekdayPhrase(int j, String? w) {
    if (w == null) return null;
    final m = _weekday.firstMatch(w);
    if (m == null) return null;
    final name = m.group(1)!;
    final suffix = m.group(2);
    if (name == 'pazar' && suffix != null) return null;
    if (name == 'sali' && words[j].lower.startsWith('ş')) return null;
    var end = j + 1;
    var dative = suffix != null && _dative.contains(suffix);
    if (suffix == null) {
      final g = next(end);
      final gm = g == null ? null : _gunu.firstMatch(g);
      if (gm != null) {
        end++;
        dative = gm.group(1) == 'ne';
      }
    }
    if (dative && next(end) == 'kadar') end++;
    return (weekday: weekdayNumbers[name]!, end: end);
  }

  _Unit? dateRule(int i) {
    final w = words[i].fold;
    switch (w) {
      case 'bugun':
        return _fixed(i, i + 1, today, 1);
      case 'yarin':
        return _fixed(i, i + 1, addDays(today, 1), 1);
      case 'yarina':
        final end = next(i + 1) == 'kadar' ? i + 2 : i + 1;
        return _fixed(i, end, addDays(today, 1), 1);
      case 'oburgun':
        return _fixed(i, i + 1, addDays(today, 2), 1);
      case 'obur':
        return next(i + 1) == 'gun'
            ? _fixed(i, i + 2, addDays(today, 2), 1)
            : null;
      case 'haftaya':
        return _nextWeek(i, i + 1);
      case 'gelecek':
      case 'onumuzdeki':
        if (next(i + 1) == 'hafta') return _nextWeek(i, i + 2);
        final wd = weekdayPhrase(i + 1, next(i + 1));
        return wd == null ? null : _weekdayUnit(i, wd.end, wd.weekday, 0, 0.9);
      case 'bu':
        final wd = weekdayPhrase(i + 1, next(i + 1));
        if (wd != null) return _weekdayUnit(i, wd.end, wd.weekday, 0, 0.95);
        if (next(i + 1) == 'hafta' && next(i + 2) == 'sonu') {
          return _weekend(i, i + 3, 0.95);
        }
        if (next(i + 1) == 'haftasonu') return _weekend(i, i + 2, 0.95);
        return null;
      case 'hafta':
        final s = next(i + 1);
        if (s == 'sonu') return _weekend(i, i + 2, 0.85);
        if (s == 'sonuna' && next(i + 2) == 'kadar') {
          return _weekend(i, i + 3, 0.85);
        }
        return null;
      case 'haftasonu':
        return _weekend(i, i + 1, 0.85);
      case 'ayin':
        final m = _dayOfMonth.firstMatch(next(i + 1) ?? '');
        if (m == null) return null;
        final date = nextDayOfMonth(int.parse(m.group(1)!));
        return date == null ? null : _fixed(i, i + 2, date, 0.95);
    }

    final wd = weekdayPhrase(i, w);
    if (wd != null) {
      final prev = previous(i);
      if (prev == 'gecen' || prev == 'dun') return null;
      return _weekdayUnit(i, wd.end, wd.weekday, 0, 0.9);
    }
    return _dayMonth(i, w) ?? _numeric(i, w);
  }

  _Unit? relativeRule(int i) {
    final w = words[i].fold;
    final half = w == 'yarim';
    final n = half ? 0 : numberValue(w);
    if (n == null || (!half && n == 0)) return null;
    final unit = next(i + 1);
    if (unit == null || !_relativeUnit.hasMatch(unit)) return null;
    if (next(i + 2) != 'sonra') return null;
    final end = i + 3;
    switch (unit) {
      case 'gun':
      case 'hafta':
      case 'ay':
        if (half) return null;
        final date = switch (unit) {
          'gun' => addDays(today, n),
          'hafta' => addDays(today, 7 * n),
          _ => addMonthsClamped(today, n),
        };
        return _fixed(i, end, date, 0.95);
      default:
        final minutes = half
            ? 30
            : (unit == 'saat' || unit == 'sa')
                ? n * 60
                : n;
        final base =
            DateTime(now.year, now.month, now.day, now.hour, now.minute);
        return _Unit(end)
          ..instant = base.add(Duration(minutes: minutes))
          ..tokens.add(token(CaptureTokenKind.time, i, end, 0.95));
    }
  }

  _Unit _fixed(int from, int to, DateTime day, double confidence) => _Unit(to)
    ..date = _FixedDate(day)
    ..tokens.add(token(CaptureTokenKind.date, from, to, confidence));

  _Unit _weekdayUnit(
    int from,
    int to,
    int weekday,
    int extraWeeks,
    double confidence,
  ) =>
      _Unit(to)
        ..date = _WeekdayDate(weekday, extraWeeks: extraWeeks)
        ..tokens.add(token(CaptureTokenKind.date, from, to, confidence));

  _Unit _weekend(int from, int to, double confidence) =>
      _weekdayUnit(from, to, DateTime.saturday, 0, confidence);

  /// `haftaya` / `gelecek hafta` ending before [j], with an optional weekday
  /// or `bugün`.
  _Unit _nextWeek(int i, int j) {
    final wd = weekdayPhrase(j, next(j));
    if (wd != null) return _weekdayUnit(i, wd.end, wd.weekday, 1, 0.95);
    if (next(j) == 'bugun') return _fixed(i, j + 1, addDays(today, 7), 0.95);
    return _fixed(i, j, addDays(today, 7), 0.95);
  }

  _Unit? _dayMonth(int i, String w) {
    final dm = _plainDay.firstMatch(w);
    if (dm == null) return null;
    final mw = next(i + 1);
    final mm = mw == null ? null : _month.firstMatch(mw);
    if (mm == null) return null;
    final monthName = mm.group(1)!;
    if (monthName == 'nisan' && words[i + 1].lower.contains('ş')) return null;
    final day = int.parse(dm.group(1)!);
    final month = _months.indexOf(monthName) + 1;
    var end = i + 2;
    int? year;
    final suffix = mm.group(2);
    if (suffix == null) {
      final ym = _year.firstMatch(next(end) ?? '');
      if (ym != null) {
        year = int.parse(ym.group(1)!);
        end++;
        if (_dative.contains(ym.group(2)) && next(end) == 'kadar') end++;
      }
    } else if (_dative.contains(suffix) && next(end) == 'kadar') {
      end++;
    }
    final date =
        year != null ? validDate(year, month, day) : nextDayMonth(day, month);
    if (date == null) return null;
    return _fixed(i, end, date, year != null ? 1 : 0.95);
  }

  _Unit? _numeric(int i, String w) {
    final m = _numericDate.firstMatch(w);
    if (m == null) return null;
    final sep = m.group(2)!;
    final secondRaw = m.group(3)!;
    final yearSep = m.group(4);
    final yearRaw = m.group(5);
    final suffix = m.group(6);
    final day = int.parse(m.group(1)!);
    final month = int.parse(secondRaw);
    if (yearSep != null && yearSep != sep) return null;
    if (yearRaw == null) {
      if (secondRaw.length != 2) return null;
      final locative = suffix != null && !_dative.contains(suffix);
      if (sep == '.' && (locative || month == 0 || month > 12)) return null;
    }
    final date = yearRaw == null
        ? nextDayMonth(day, month)
        : validDate(
            yearRaw.length == 2
                ? 2000 + int.parse(yearRaw)
                : int.parse(yearRaw),
            month,
            day,
          );
    if (date == null) return null;
    var end = i + 1;
    if (_dative.contains(suffix) && next(end) == 'kadar') end++;
    final confidence = yearRaw != null
        ? 1.0
        : sep == '/'
            ? 0.9
            : 0.7;
    return _fixed(i, end, date, confidence);
  }
}
