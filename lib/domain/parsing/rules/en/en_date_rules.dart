part of '../../capture_parser.dart';

/// English day phrases and relative offsets — the mirror of
/// `_TrDateRules` (F4.6c).
///
/// - `today`, `tomorrow`, `(the) day after tomorrow`.
/// - `next week` (+7 days), `next month` (+1 month, clamped to the month
///   end), `next monday`, `this friday`: like the Turkish `haftaya` /
///   `gelecek cuma`, `next <weekday>` is the **next occurrence** of that
///   weekday, not "the one in the following week".
/// - Weekdays `monday…sunday`: the next occurrence; today only when a time
///   is given and still ahead (resolved later). `last friday` and
///   `yesterday …` are left alone (past). Three/four-letter abbreviations
///   (`mon`, `tue`, `tues`, `wed`, `weds`, `thu`, `thur`, `thurs`, `fri`,
///   `sat`, `sun`) are only read as weekdays **after `on`, `by`, `next`,
///   `this` or `every`**, because `sat`, `sun`, `wed` and `mar` are ordinary
///   words too.
/// - `weekend`, `this weekend`, `on the weekend`: next Saturday (the plural
///   `weekends` and `every weekend` are repeats).
/// - `the 17th`, `on the 17th`: this month if not before today, otherwise
///   the next month that has that day (`the 31st` in September → 31
///   October) — the mirror of `ayın 17'si`.
/// - `May 3`, `May 3rd`, `on May 3`, `3 May`, `3rd of May`, `May 3, 2027`:
///   without a year the next occurrence (today included; `29 February` →
///   next leap year); with a year as given, even in the past (`isPast`).
///   Invalid days (`April 31`) are text. A month name alone is never a date,
///   so `may`, `march` and `august` keep their everyday meaning.
/// - **Numeric dates are month/day (`en_US`):** `5/3` is 3 May, `3/5` is
///   5 March, `5/3/2027` and `5/3/27` likewise. When the first number cannot
///   be a month but the second can, the pair is read as day/month instead
///   (`25/12` → 25 December), so European input is not silently dropped.
///   ISO `2027-05-03` is always year-month-day. Dot forms (`5.3`) are
///   **not** dates in English — they are times (`9.30`) or decimals.
/// - `in 3 days`, `in two weeks`, `in a month` (dates); `in 2 hours`,
///   `in half an hour`, `in 45 minutes`, `in 10 mins` (instants, time
///   tokens).
extension _EnDateRules on _EnScanner {
  static const Map<String, int> weekdayNumbers = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  /// Only recognized in context (see the class doc).
  static const Map<String, int> weekdayAbbreviations = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'weds': DateTime.wednesday,
    'thu': DateTime.thursday,
    'thur': DateTime.thursday,
    'thurs': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  /// Plural weekdays are repeats (`mondays`, `on fridays`).
  static const Map<String, int> weekdayPlurals = {
    'mondays': DateTime.monday,
    'tuesdays': DateTime.tuesday,
    'wednesdays': DateTime.wednesday,
    'thursdays': DateTime.thursday,
    'fridays': DateTime.friday,
    'saturdays': DateTime.saturday,
    'sundays': DateTime.sunday,
  };

  static const Map<String, int> monthNumbers = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static const Map<String, int> numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
  };

  static final RegExp _number = RegExp(r'^\d{1,3}$');
  static final RegExp _ordinal = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?$');
  static final RegExp _year = RegExp(r'^(20\d\d)$');
  static final RegExp _slashDate =
      RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{4}|\d{2}))?$');
  static final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
  static final RegExp _relativeDayUnit = RegExp(r'^(day|week|month)s?$');
  static final RegExp _relativeTimeUnit =
      RegExp(r'^(hour|hr|hrs|hours|minute|minutes|min|mins)$');

  /// `N` as digits (1–999) or a number word (`one`…`twelve`).
  static int? numberValue(String? word) {
    if (word == null) return null;
    if (_number.hasMatch(word)) return int.parse(word);
    return numberWords[word];
  }

  /// `17`, `17th`, `1st` → 1–31.
  static int? ordinalDay(String? word) {
    if (word == null) return null;
    final m = _ordinal.firstMatch(word);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    return day >= 1 && day <= 31 ? day : null;
  }

  /// A weekday word at [j] ([w] its folded text, or `null` when the phrase
  /// may not continue there). Abbreviations need [allowAbbreviation].
  ({int weekday, int end})? weekdayAt(
    int j,
    String? w, {
    required bool allowAbbreviation,
  }) {
    if (w == null) return null;
    final day = weekdayNumbers[w] ??
        (allowAbbreviation ? weekdayAbbreviations[w] : null);
    return day == null ? null : (weekday: day, end: j + 1);
  }

  // ------------------------------------------------------------ entry

  _Unit? dateRule(int i) {
    final w = words[i].fold;
    if (w == 'on' || w == 'by') {
      final r = datePhrase(i + 1, continuing: true, inContext: true);
      return r == null ? null : _dateUnit(i, r);
    }
    final r = datePhrase(i, continuing: false, inContext: false);
    return r == null ? null : _dateUnit(i, r);
  }

  _Unit _dateUnit(
    int from,
    ({_DateSpec spec, int end, double confidence}) r,
  ) =>
      _Unit(r.end)
        ..date = r.spec
        ..tokens.add(token(CaptureTokenKind.date, from, r.end, r.confidence));

  /// A date phrase starting at word [j]. [continuing] reads the first word
  /// with [next] (the phrase may not cross punctuation), [inContext] allows
  /// weekday abbreviations.
  ({_DateSpec spec, int end, double confidence})? datePhrase(
    int j, {
    required bool continuing,
    required bool inContext,
  }) {
    final w = continuing ? next(j) : fold(j);
    if (w == null) return null;
    switch (w) {
      case 'today':
        return (spec: _FixedDate(today), end: j + 1, confidence: 1);
      case 'tomorrow':
        return (spec: _FixedDate(addDays(today, 1)), end: j + 1, confidence: 1);
      case 'the':
        if (next(j + 1) == 'day' &&
            next(j + 2) == 'after' &&
            next(j + 3) == 'tomorrow') {
          return (
            spec: _FixedDate(addDays(today, 2)),
            end: j + 4,
            confidence: 1,
          );
        }
        if (next(j + 1) == 'weekend') {
          return (
            spec: const _WeekdayDate(DateTime.saturday),
            end: j + 2,
            confidence: 0.9,
          );
        }
        // `the 3rd of May` is a named date, not a day of the month.
        final ordinal = next(j + 1);
        final named = ordinal == null ? null : _dayFirst(j + 1, ordinal);
        if (named != null) return named;
        final dom = ordinalDay(ordinal);
        final at = dom == null ? null : nextDayOfMonth(dom);
        return at == null
            ? null
            : (spec: _FixedDate(at), end: j + 2, confidence: 0.9);
      case 'day':
        if (next(j + 1) == 'after' && next(j + 2) == 'tomorrow') {
          return (
            spec: _FixedDate(addDays(today, 2)),
            end: j + 3,
            confidence: 1,
          );
        }
        return null;
      case 'weekend':
        return (
          spec: const _WeekdayDate(DateTime.saturday),
          end: j + 1,
          confidence: 0.85,
        );
      case 'next':
      case 'this':
        return _determiner(j, w);
    }

    final wd = weekdayAt(j, w, allowAbbreviation: inContext);
    if (wd != null) {
      final prev = previous(j);
      if (prev == 'last' || prev == 'yesterday') return null;
      return (
        spec: _WeekdayDate(wd.weekday),
        end: wd.end,
        confidence: 0.9,
      );
    }
    return _monthFirst(j, w) ?? _dayFirst(j, w) ?? _numericDate(j, w);
  }

  /// `next week`, `next month`, `next friday`, `this weekend`,
  /// `this monday`. `next year` is left as text (no yearly repeat and a
  /// bare year is not a day).
  ({_DateSpec spec, int end, double confidence})? _determiner(
    int j,
    String w,
  ) {
    final n = next(j + 1);
    if (n == null) return null;
    if (w == 'next') {
      switch (n) {
        case 'week':
          return (
            spec: _FixedDate(addDays(today, 7)),
            end: j + 2,
            confidence: 0.95,
          );
        case 'month':
          return (
            spec: _FixedDate(addMonthsClamped(today, 1)),
            end: j + 2,
            confidence: 0.95,
          );
      }
    }
    if (n == 'weekend') {
      return (
        spec: const _WeekdayDate(DateTime.saturday),
        end: j + 2,
        confidence: 0.95,
      );
    }
    final wd = weekdayAt(j + 1, n, allowAbbreviation: true);
    return wd == null
        ? null
        : (spec: _WeekdayDate(wd.weekday), end: wd.end, confidence: 0.95);
  }

  /// `May 3`, `May 3rd`, `May 3 2027`, `May 3, 2027`.
  ({_DateSpec spec, int end, double confidence})? _monthFirst(
    int j,
    String w,
  ) {
    final month = monthNumbers[w];
    if (month == null) return null;
    final day = ordinalDay(next(j + 1));
    if (day == null) return null;
    return _named(j + 2, month, day);
  }

  /// `3 May`, `3rd May`, `3rd of May`, `3 May 2027`.
  ({_DateSpec spec, int end, double confidence})? _dayFirst(int j, String w) {
    final day = ordinalDay(w);
    if (day == null) return null;
    var k = j + 1;
    if (next(k) == 'of') k++;
    final month = monthNumbers[next(k)];
    if (month == null) return null;
    return _named(k + 1, month, day);
  }

  /// Optional year at [k], then the calendar day.
  ({_DateSpec spec, int end, double confidence})? _named(
    int k,
    int month,
    int day,
  ) {
    var end = k;
    int? year;
    final yearWord = nextInList(end);
    final ym = yearWord == null ? null : _year.firstMatch(yearWord);
    if (ym != null) {
      year = int.parse(ym.group(1)!);
      end++;
    }
    final date =
        year != null ? validDate(year, month, day) : nextDayMonth(day, month);
    if (date == null) return null;
    return (
      spec: _FixedDate(date),
      end: end,
      confidence: year != null ? 1.0 : 0.95,
    );
  }

  /// `5/3`, `5/3/27`, `5/3/2027` (month/day, `en_US`) and ISO
  /// `2027-05-03`.
  ({_DateSpec spec, int end, double confidence})? _numericDate(
    int j,
    String w,
  ) {
    final iso = _isoDate.firstMatch(w);
    if (iso != null) {
      final date = validDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
      return date == null
          ? null
          : (spec: _FixedDate(date), end: j + 1, confidence: 1);
    }
    final m = _slashDate.firstMatch(w);
    if (m == null) return null;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final yearRaw = m.group(3);
    final int month;
    final int day;
    if (a >= 1 && a <= 12) {
      month = a;
      day = b;
    } else if (b >= 1 && b <= 12 && a <= 31) {
      // `25/12`: the first number cannot be a month, so read day/month.
      month = b;
      day = a;
    } else {
      return null;
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
    return (
      spec: _FixedDate(date),
      end: j + 1,
      confidence: yearRaw != null ? 1.0 : 0.9,
    );
  }

  // --------------------------------------------------------- relative

  /// `in 3 days`, `in a week`, `in 2 hours`, `in half an hour`,
  /// `in 45 minutes`, `in 10 mins`.
  _Unit? relativeRule(int i) {
    if (words[i].fold != 'in') return null;
    final first = next(i + 1);
    if (first == null) return null;
    var j = i + 1;
    int? value;
    var half = false;
    if (first == 'a' || first == 'an') {
      value = 1;
      j++;
    } else if (first == 'half') {
      final particle = next(j + 1);
      if (particle != 'a' && particle != 'an') return null;
      half = true;
      j += 2;
    } else {
      value = numberValue(first);
      if (value == null || value == 0) return null;
      j++;
    }
    final unit = next(j);
    if (unit == null) return null;
    final end = j + 1;

    final dayUnit = _relativeDayUnit.firstMatch(unit);
    if (dayUnit != null) {
      if (half || value == null) return null;
      final date = switch (dayUnit.group(1)!) {
        'day' => addDays(today, value),
        'week' => addDays(today, 7 * value),
        _ => addMonthsClamped(today, value),
      };
      return _Unit(end)
        ..date = _FixedDate(date)
        ..tokens.add(token(CaptureTokenKind.date, i, end, 0.95));
    }
    if (!_relativeTimeUnit.hasMatch(unit)) return null;
    final hours = unit.startsWith('h');
    final minutes = half ? 30 : (hours ? value! * 60 : value!);
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return _Unit(end)
      ..instant = base.add(Duration(minutes: minutes))
      ..tokens.add(token(CaptureTokenKind.time, i, end, 0.95));
  }
}
