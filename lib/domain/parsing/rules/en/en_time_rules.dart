part of '../../capture_parser.dart';

/// English clock times and day parts — the mirror of `_TrTimeRules`
/// (F4.6c).
///
/// - `18:00`, `8:15`, `21:45`: always a time. `9.30`, `18.30`: a time when
///   the date rule did not take it (English numeric dates use `/`, so a dot
///   form is always a time) — but not before a unit (`1.50 usd`, `2.30 kg`).
/// - `9am`, `9 am`, `9 a.m.`, `9pm`, `9:30pm`, `9.30 p.m.`: 12-hour clock;
///   `12am` is 00:00, `12pm` is 12:00.
/// - `at 9`, `by 9`, `at 9:30`, `9 o'clock`: a **bare** hour is a time only
///   in that context (never guessed as pm: `at 9` is 09:00; with no date it
///   is today when still ahead, else tomorrow). Confidence 0.8, exactly
///   like the Turkish `9'da`.
/// - `at noon` / `noon` / `midday` (12:00), `at midnight` / `midnight`
///   (00:00), `half past 8` (08:30), `quarter past 8` (08:15),
///   `quarter to 9` (08:45).
/// - Day parts `morning` (config, 09:00), `afternoon` (15:00), `evening`
///   (20:00), `night` (22:00), also `this morning`, `in the evening`,
///   `at night`, and `tonight` (= today at the evening hour). With an hour
///   they shift it: `evening at 8` = 20:00, `at night 11` = 23:00,
///   `afternoon 3` = 15:00. `this …` and `tonight` also fix the date to
///   today.
/// - A bare day part is **not** a time when it is part of a noun phrase:
///   after `a`/`an`/`the`/`one`/`last`/`yesterday`/`each`/`some`
///   (`a morning`, `the morning meeting`), or before a compound noun
///   (`morning run`, `evening class`, `night cream`, `afternoon tea`, …).
///   The compound-noun guard only applies to a **bare** day part — after
///   `this`/`in the`/`at` or a date the phrase is unambiguous, so
///   `this morning stretch` is 09:00 + "Stretch".
extension _EnTimeRules on _EnScanner {
  static final RegExp _time = RegExp(
    r'^(\d{1,2})(?:[:.](\d{2}))?(a\.?m\.?|p\.?m\.?)?$',
  );

  /// Day part word → normalized part.
  static const Map<String, String> dayparts = {
    'morning': 'morning',
    'afternoon': 'afternoon',
    'evening': 'evening',
    'night': 'night',
  };

  /// Plural day parts are repeats (`every morning` ≙ `mornings`).
  static const Map<String, String> daypartPlurals = {
    'mornings': 'morning',
    'afternoons': 'afternoon',
    'evenings': 'evening',
    'nights': 'night',
  };

  /// Words before a bare day part that make it a noun (`a morning`,
  /// `the morning meeting`, `last night`).
  static const Set<String> _blockers = {
    'a',
    'an',
    'the',
    'one',
    'that',
    'some',
    'any',
    'each',
    'all',
    'last',
    'yesterday',
    'good',
    'whole',
    'entire',
    'which',
  };

  /// Words that turn a bare day part into a compound noun.
  static const Set<String> _compoundNouns = {
    'run',
    'runs',
    'walk',
    'walks',
    'jog',
    'workout',
    'workouts',
    'routine',
    'routines',
    'shift',
    'shifts',
    'class',
    'classes',
    'lesson',
    'lessons',
    'news',
    'meeting',
    'meetings',
    'standup',
    'cream',
    'mask',
    'sickness',
    'person',
    'star',
    'owl',
    'show',
    'shows',
    'coffee',
    'tea',
    'meal',
    'meals',
    'snack',
    'prayer',
    'yoga',
    'session',
    'sessions',
    'commute',
    'traffic',
    'sky',
    'market',
    'flight',
    'train',
    'pill',
    'pills',
    'dose',
    'edition',
    'paper',
    'playlist',
    'skincare',
    'stretch',
    'swim',
    'ride',
    'break',
    'call',
    'calls',
    'email',
    'emails',
    'report',
    'reports',
    'school',
    'club',
    'sun',
    'light',
  };

  /// Units after a number that make `1.50` a price or amount, not a time.
  static const Set<String> _units = {
    'usd',
    'eur',
    'gbp',
    'dollar',
    'dollars',
    'euro',
    'euros',
    'pound',
    'pounds',
    'lb',
    'lbs',
    'kg',
    'kgs',
    'kilo',
    'kilos',
    'g',
    'gram',
    'grams',
    'oz',
    'l',
    'liter',
    'liters',
    'litre',
    'litres',
    'ml',
    'cm',
    'mm',
    'm',
    'km',
    'mi',
    'mile',
    'miles',
    'tl',
    'lira',
    'percent',
    'gb',
    'mb',
    'items',
    'pcs',
    'points',
    'stars',
  };

  static const Set<String> _oClock = {"o'clock", 'oclock'};

  int defaultHour(String part) => switch (part) {
        'morning' => config.morningHour,
        'afternoon' => config.afternoonHour,
        'evening' => config.eveningHour,
        'night' => config.nightHour,
        _ => config.noonHour,
      };

  /// Shifts a 12-hour style hour into the day part.
  static int adjustHour(String part, int hour) {
    switch (part) {
      case 'afternoon':
      case 'evening':
        return hour >= 1 && hour <= 11 ? hour + 12 : hour;
      case 'night':
        if (hour >= 6 && hour <= 11) return hour + 12;
        return hour == 12 ? 0 : hour;
      default:
        return hour;
    }
  }

  static String? _meridiem(String? w) {
    if (w == null) return null;
    final s = w.replaceAll('.', '');
    if (s == 'am') return 'am';
    if (s == 'pm') return 'pm';
    return null;
  }

  /// A clock at [j] ([w] its folded text): `18:00`, `9.30`, `9am`, `9 pm`,
  /// `9 o'clock`. With [inContext] (after `at`, `by` or a day part) a bare
  /// `9` counts too.
  ({int hour, int minute, int end, double confidence})? clockAt(
    int j,
    String? w, {
    required bool inContext,
  }) {
    if (w == null) return null;
    final m = _time.firstMatch(w);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minuteText = m.group(2);
    final minute = minuteText == null ? 0 : int.parse(minuteText);
    if (minute > 59) return null;

    var end = j + 1;
    var meridiem = _meridiem(m.group(3));
    if (meridiem == null) {
      final separate = _meridiem(next(end));
      if (separate != null) {
        meridiem = separate;
        end++;
      }
    }

    var confidence = 1.0;
    if (minuteText == null && meridiem == null) {
      // A bare number: only `9 o'clock`, or an hour in context.
      if (_oClock.contains(next(end))) {
        end++;
      } else if (!inContext) {
        return null;
      } else {
        if (_units.contains(next(end))) return null;
        confidence = 0.8;
      }
    } else if (minuteText != null && meridiem == null && w.contains('.')) {
      // `1.50 usd` is a price, `18.30` is a time.
      if (!inContext && _units.contains(next(end))) return null;
      if (!inContext) confidence = 0.9;
    }

    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      hour = meridiem == 'pm'
          ? (hour == 12 ? 12 : hour + 12)
          : (hour == 12 ? 0 : hour);
    } else if (hour > 23) {
      return null;
    }
    return (hour: hour, minute: minute, end: end, confidence: confidence);
  }

  /// A whole time phrase at [j]: a clock, `noon`/`midnight` or
  /// `half past 8` / `quarter to 9`.
  ({_Clock clock, int end, double confidence})? clockPhrase(
    int j, {
    required bool continuing,
    required bool inContext,
  }) {
    final w = continuing ? next(j) : fold(j);
    if (w == null) return null;
    switch (w) {
      case 'noon':
      case 'midday':
        return (
          clock: _Clock(config.noonHour, 0),
          end: j + 1,
          confidence: 1,
        );
      case 'midnight':
        return (clock: const _Clock(0, 0), end: j + 1, confidence: 1);
      case 'half':
        if (next(j + 1) != 'past') return null;
        final c = clockAt(j + 2, next(j + 2), inContext: true);
        if (c == null || c.minute != 0) return null;
        return (clock: _Clock(c.hour, 30), end: c.end, confidence: 1);
      case 'quarter':
        final relation = next(j + 1);
        if (relation != 'past' && relation != 'to') return null;
        final c = clockAt(j + 2, next(j + 2), inContext: true);
        if (c == null || c.minute != 0) return null;
        return relation == 'past'
            ? (clock: _Clock(c.hour, 15), end: c.end, confidence: 1)
            : (
                clock: _Clock((c.hour + 23) % 24, 45),
                end: c.end,
                confidence: 1
              );
    }
    final c = clockAt(j, w, inContext: inContext);
    return c == null
        ? null
        : (
            clock: _Clock(c.hour, c.minute),
            end: c.end,
            confidence: c.confidence,
          );
  }

  /// Optional `at` plus a clock starting at [k], shifted into [part].
  ({_Clock clock, int end})? daypartClock(int k, String part) {
    var j = k;
    if (next(j) == 'at') j++;
    final c = clockAt(j, next(j), inContext: true);
    if (c == null) return null;
    return (clock: _Clock(adjustHour(part, c.hour), c.minute), end: c.end);
  }

  _Unit? timeRule(int i) {
    final w = words[i].fold;

    // `tonight` = today at the evening hour (like `bu akşam`).
    if (w == 'tonight') {
      final withClock = daypartClock(i + 1, 'evening');
      final end = withClock?.end ?? i + 1;
      final clock = withClock?.clock ?? _Clock(defaultHour('evening'), 0);
      return _Unit(end)
        ..date = _FixedDate(today)
        ..time = clock
        ..tokens.add(token(CaptureTokenKind.time, i, end, 1));
    }

    // `this morning`, `in the evening`, `at night`, bare `morning`.
    var dpIndex = i;
    var prefixed = false;
    var fixesToday = false;
    if (w == 'this') {
      dpIndex = i + 1;
      prefixed = true;
      fixesToday = true;
    } else if ((w == 'in' || w == 'at' || w == 'by' || w == 'during') &&
        next(i + 1) == 'the') {
      dpIndex = i + 2;
      prefixed = true;
    } else if (w == 'at' || w == 'by') {
      dpIndex = i + 1;
      prefixed = true;
    }
    final part = dayparts[prefixed ? next(dpIndex) : w];
    if (part != null) {
      if (!prefixed && _blockers.contains(previous(i))) return null;
      _Unit build(int end, _Clock clock, double confidence) {
        final unit = _Unit(end)
          ..time = clock
          ..tokens.add(token(CaptureTokenKind.time, i, end, confidence));
        if (fixesToday) unit.date = _FixedDate(today);
        return unit;
      }

      final withClock = daypartClock(dpIndex + 1, part);
      if (withClock != null) return build(withClock.end, withClock.clock, 1);
      final contextual = prefixed || afterDateLike(i);
      final following = next(dpIndex + 1);
      // Only a **bare** day part can be a compound noun: `this morning` and
      // `tomorrow morning` are unambiguous, so `this morning stretch` is a
      // time while `morning stretch` on its own is text.
      if (!contextual &&
          following != null &&
          _compoundNouns.contains(following)) {
        return null;
      }
      return build(
        dpIndex + 1,
        _Clock(defaultHour(part), 0),
        contextual ? 0.95 : 0.8,
      );
    }

    if (w == 'this') return null;
    final inContext = w == 'at' || w == 'by';
    final c = clockPhrase(
      inContext ? i + 1 : i,
      continuing: inContext,
      inContext: inContext,
    );
    if (c == null) return null;
    return _Unit(c.end)
      ..time = c.clock
      ..tokens.add(token(CaptureTokenKind.time, i, c.end, c.confidence));
  }
}
