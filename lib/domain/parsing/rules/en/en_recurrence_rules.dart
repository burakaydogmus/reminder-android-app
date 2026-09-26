part of '../../capture_parser.dart';

/// English repeats — the mirror of `_TrRecurrenceRules` (F4.6c).
///
/// - `every day`, `everyday`, `daily`; `every morning/afternoon/evening/
///   night`, `nightly`, plural `mornings`, `evenings` (daily at the day
///   part; `every evening at 9` = 21:00).
/// - `every week`, `weekly` (weekly on the first occurrence's weekday),
///   `every week on friday`, `weekly on friday`; `every monday`,
///   `every monday, wednesday and friday`, `every mon & wed`, plural
///   `mondays`, `on fridays`.
/// - `every weekday`, `weekdays`, `on weekdays` (Mon–Fri); `every weekend`,
///   `weekends`, `on weekends` (Sat–Sun). Bare `weekend` is a one-off date
///   (this weekend), see `_EnDateRules`.
/// - `every month`, `monthly` (monthly on the first occurrence's day),
///   `every month on the 17th`, `monthly on the 17th`, `every 17th of the
///   month`.
/// - `every year`, `yearly`, `annually` (yearly on the first occurrence's
///   month and day), `every 2 years`, `every other year`.
/// - `every 3 days`, `every other day` (every 2 days), `every 2 weeks`,
///   `every other week`, `every 3 months`, `every other monday`
///   (`every 1 day` = daily).
/// - The adjective forms `daily` / `weekly` / `monthly` / `yearly` /
///   `nightly` are **not** repeats in front of a noun (`weekly report`,
///   `daily standup`, `yearly budget`), the same guard the Turkish `yıllık`
///   uses. `annually` is only ever an adverb, so it always repeats.
extension _EnRecurrenceRules on _EnScanner {
  static const RecurrenceSpec _daily = RecurrenceSpec(
    kind: RecurrenceKind.daily,
  );
  static const RecurrenceSpec _weeklyAny = RecurrenceSpec(
    kind: RecurrenceKind.weekly,
  );
  static const RecurrenceSpec _monthlyAny = RecurrenceSpec(
    kind: RecurrenceKind.monthly,
  );
  static const RecurrenceSpec _yearlyAny = RecurrenceSpec(
    kind: RecurrenceKind.yearly,
  );
  static const RecurrenceSpec _weekdaysSpec = RecurrenceSpec(
    kind: RecurrenceKind.weekly,
    weekdays: [1, 2, 3, 4, 5],
  );
  static const RecurrenceSpec _weekendsSpec = RecurrenceSpec(
    kind: RecurrenceKind.weekly,
    weekdays: [6, 7],
  );

  /// Nouns that turn `daily` / `weekly` / `monthly` / `yearly` into an
  /// adjective.
  static const Set<String> _repeatNouns = {
    'report',
    'reports',
    'meeting',
    'meetings',
    'standup',
    'summary',
    'review',
    'reviews',
    'digest',
    'newsletter',
    'update',
    'updates',
    'plan',
    'planner',
    'routine',
    'budget',
    'invoice',
    'rent',
    'sync',
    'goal',
    'goals',
    'basis',
    'total',
    'totals',
    'check',
    'checkin',
    'quota',
    'special',
    'deal',
    'deals',
    'driver',
    'carry',
  };

  _Unit? recurrenceRule(int i) {
    final w = words[i].fold;
    switch (w) {
      case 'every':
        return _every(i);
      case 'everyday':
      case 'daily':
        return _adjective(i) ? null : _rec(i, i + 1, _daily, 1);
      case 'nightly':
        return _adjective(i) ? null : _daypartRepeat(i, i + 1, 'night', 1);
      case 'weekly':
        if (_adjective(i)) return null;
        final list = _weekdaysAfter(i + 1);
        if (list != null) {
          return _rec(i, list.end, _weeklyOn(list.days), 1);
        }
        return _rec(i, i + 1, _weeklyAny, 1);
      case 'monthly':
        if (_adjective(i)) return null;
        final day = _dayOfMonthTail(i + 1);
        if (day != null) return _rec(i, day.end, _monthly(day.day), 1);
        return _rec(i, i + 1, _monthlyAny, 1);
      case 'yearly':
        return _adjective(i) ? null : _rec(i, i + 1, _yearlyAny, 1);
      // `annually` is only ever an adverb, so no noun guard.
      case 'annually':
        return _rec(i, i + 1, _yearlyAny, 1);
      case 'weekdays':
        return _rec(i, i + 1, _weekdaysSpec, 0.9);
      case 'weekends':
        return _rec(i, i + 1, _weekendsSpec, 0.9);
      case 'on':
        final n = next(i + 1);
        if (n == 'weekdays') return _rec(i, i + 2, _weekdaysSpec, 0.95);
        if (n == 'weekends') return _rec(i, i + 2, _weekendsSpec, 0.95);
        final list = _weekdayList(i + 1, n, plural: true);
        return list == null
            ? null
            : _rec(i, list.end, _weeklyOn(list.days), 0.95);
    }

    final list = _weekdayList(i, w, plural: true);
    if (list != null) return _rec(i, list.end, _weeklyOn(list.days), 0.9);
    final part = _EnTimeRules.daypartPlurals[w];
    if (part != null) return _daypartRepeat(i, i + 1, part, 0.9);
    return null;
  }

  /// `weekly report`, `the daily standup`: an adjective, not a repeat.
  bool _adjective(int i) {
    final following = next(i + 1);
    return following != null && _repeatNouns.contains(following);
  }

  /// `every …` at [i].
  _Unit? _every(int i) {
    final n1 = next(i + 1);
    if (n1 == null) return null;
    switch (n1) {
      case 'day':
        return _rec(i, i + 2, _daily, 1);
      case 'week':
        final list = _weekdaysAfter(i + 2);
        if (list != null) return _rec(i, list.end, _weeklyOn(list.days), 1);
        return _rec(i, i + 2, _weeklyAny, 1);
      case 'month':
        final day = _dayOfMonthTail(i + 2);
        if (day != null) return _rec(i, day.end, _monthly(day.day), 1);
        return _rec(i, i + 2, _monthlyAny, 1);
      case 'year':
        return _rec(i, i + 2, _yearlyAny, 1);
      case 'weekday':
      case 'weekdays':
        return _rec(i, i + 2, _weekdaysSpec, 1);
      case 'weekend':
      case 'weekends':
        return _rec(i, i + 2, _weekendsSpec, 1);
      case 'other':
        final n2 = next(i + 2);
        switch (n2) {
          case 'day':
            return _rec(i, i + 3, _everyDays(2), 1);
          case 'week':
            return _rec(
              i,
              i + 3,
              const RecurrenceSpec(kind: RecurrenceKind.weekly, interval: 2),
              1,
            );
          case 'month':
            return _rec(
              i,
              i + 3,
              const RecurrenceSpec(kind: RecurrenceKind.monthly, interval: 2),
              1,
            );
          case 'year':
            return _rec(
              i,
              i + 3,
              const RecurrenceSpec(kind: RecurrenceKind.yearly, interval: 2),
              1,
            );
        }
        final wd = weekdayAt(i + 2, n2, allowAbbreviation: true);
        return wd == null
            ? null
            : _rec(
                i,
                wd.end,
                RecurrenceSpec(
                  kind: RecurrenceKind.weekly,
                  interval: 2,
                  weekdays: [wd.weekday],
                ),
                1,
              );
    }

    final part = _EnTimeRules.dayparts[n1];
    if (part != null) return _daypartRepeat(i, i + 2, part, 1);

    final n = _EnDateRules.numberValue(n1);
    if (n != null && n > 0) {
      final unit = next(i + 2);
      final spec = switch (unit) {
        'day' || 'days' => n == 1 ? _daily : _everyDays(n),
        'week' ||
        'weeks' =>
          RecurrenceSpec(kind: RecurrenceKind.weekly, interval: n),
        'month' ||
        'months' =>
          RecurrenceSpec(kind: RecurrenceKind.monthly, interval: n),
        'year' ||
        'years' =>
          RecurrenceSpec(kind: RecurrenceKind.yearly, interval: n),
        _ => null,
      };
      if (spec != null) return _rec(i, i + 3, spec, 0.95);
    }

    // `every 17th of the month`
    final dom = _EnDateRules.ordinalDay(n1);
    if (dom != null &&
        next(i + 2) == 'of' &&
        next(i + 3) == 'the' &&
        next(i + 4) == 'month') {
      return _rec(i, i + 5, _monthly(dom), 1);
    }

    final list = _weekdayList(i + 1, n1, plural: false);
    return list == null ? null : _rec(i, list.end, _weeklyOn(list.days), 1);
  }

  static RecurrenceSpec _everyDays(int n) =>
      RecurrenceSpec(kind: RecurrenceKind.everyNDays, interval: n);

  static RecurrenceSpec _monthly(int day) =>
      RecurrenceSpec(kind: RecurrenceKind.monthly, dayOfMonth: day);

  static RecurrenceSpec _weeklyOn(List<int> days) =>
      RecurrenceSpec(kind: RecurrenceKind.weekly, weekdays: days);

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

  /// Optional `on` plus one or more weekdays (`every week on friday`,
  /// `weekly on mondays`).
  ({List<int> days, int end})? _weekdaysAfter(int k) {
    var j = k;
    if (next(j) == 'on') j++;
    final w = next(j);
    return _weekdayList(j, w, plural: false) ??
        _weekdayList(j, w, plural: true);
  }

  /// `on the 17th` / `the 17th` after `every month` or `monthly`.
  ({int day, int end})? _dayOfMonthTail(int k) {
    var j = k;
    if (next(j) == 'on') j++;
    if (next(j) != 'the') return null;
    j++;
    final day = _EnDateRules.ordinalDay(next(j));
    return day == null ? null : (day: day, end: j + 1);
  }

  /// One or more weekdays from [j] joined by `,`, `and` or `&`.
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
      final separator = nextInList(k);
      if (separator == null) break;
      String? candidate;
      if (separator == 'and' || separator == '&') {
        k++;
        candidate = next(k);
      } else if (words[k - 1].trailing == ',') {
        candidate = separator;
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
    final day = plural
        ? _EnDateRules.weekdayPlurals[w]
        : _EnDateRules.weekdayNumbers[w] ??
            _EnDateRules.weekdayAbbreviations[w];
    return day == null ? null : (day: day, end: j + 1);
  }
}
