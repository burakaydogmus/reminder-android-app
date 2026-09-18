part of '../turkish_capture_parser.dart';

/// One whitespace-separated word with surrounding punctuation trimmed.
class _Word {
  _Word({
    required this.start,
    required this.end,
    required this.text,
    required this.fold,
    required this.lower,
  });

  /// Range of the trimmed word in the original input.
  final int start;
  final int end;
  final String text;

  /// `TurkishText.fold` of [text] (case and diacritics removed).
  final String fold;

  /// `TurkishText.toLower` of [text] (diacritics kept; used by guards such
  /// as `şalı` ≠ `salı`).
  final String lower;

  /// Punctuation trimmed after the word (`,`, `.`, …) or a punctuation-only
  /// run that follows it. Rules do not continue across it, except lists that
  /// accept a plain `,`.
  String trailing = '';

  bool get breaksAfter => trailing.isNotEmpty;
}

class _Clock {
  const _Clock(this.hour, this.minute);
  final int hour;
  final int minute;
}

/// A date phrase that still needs the time to become a calendar day.
sealed class _DateSpec {
  const _DateSpec();
}

/// A fixed calendar day (`bugün`, `17 eylül`, `ayın 17'si`, `3 gün sonra`).
class _FixedDate extends _DateSpec {
  const _FixedDate(this.day);
  final DateTime day;
}

/// Next [weekday] (Mon=1…Sun=7): today counts only when a time is given and
/// still ahead; plus [extraWeeks] × 7 days (`haftaya cuma`).
class _WeekdayDate extends _DateSpec {
  const _WeekdayDate(this.weekday, {this.extraWeeks = 0});
  final int weekday;
  final int extraWeeks;
}

/// What one rule match contributes. A unit is accepted as a whole or not at
/// all.
class _Unit {
  _Unit(this.endWord);

  /// Index of the first word after the match.
  final int endWord;
  final List<CaptureToken> tokens = [];

  _DateSpec? date;
  _Clock? time;

  /// `2 saat sonra`: date and time at once.
  DateTime? instant;
  RecurrenceSpec? recurrence;
  String? categoryKey;
  String? categoryId;
  int? priority;
  String? placeKey;
}

class _Scanner {
  _Scanner(this.input, this.now, this.config)
      : today = DateTime(now.year, now.month, now.day),
        words = _splitWords(input);

  final String input;
  final DateTime now;
  final DateTime today;
  final CaptureParserConfig config;
  final List<_Word> words;

  final List<CaptureToken> _tokens = [];
  _DateSpec? _date;
  _Clock? _time;
  DateTime? _instant;
  RecurrenceSpec? _recurrence;
  String? _categoryKey;
  String? _categoryId;
  int _priority = 0;
  bool _hasPriority = false;
  String? _placeKey;

  /// Last accepted unit, for context (`cuma akşamı`: possessive day part only
  /// right after a date).
  _Unit? _lastUnit;
  int _lastUnitEnd = -1;

  static final RegExp _run = RegExp(r'\S+');
  static final RegExp _leadingPunct = RegExp('^[("\'“‘«\\[]+');
  static final RegExp _trailingPunct = RegExp('[,.;:!?)"”’»\\]…]+\$');
  static final RegExp _bangs = RegExp(r'^!+$');

  static List<_Word> _splitWords(String input) {
    final lower = TurkishText.toLower(input);
    final fold = TurkishText.fold(input);
    final result = <_Word>[];
    for (final m in _run.allMatches(input)) {
      var s = m.start;
      var e = m.end;
      final run = m.group(0)!;
      var trailing = '';
      if (!_bangs.hasMatch(run)) {
        final lead = _leadingPunct.firstMatch(run);
        if (lead != null) {
          s += lead.end;
          if (result.isNotEmpty && result.last.trailing.isEmpty) {
            result.last.trailing = lead.group(0)!;
          }
        }
        final trail = _trailingPunct.firstMatch(input.substring(s, e));
        if (trail != null) {
          trailing = trail.group(0)!;
          e = s + trail.start;
        }
      }
      if (e <= s) {
        // Punctuation-only run (`-`, `—`, `,`): breaks the previous word.
        if (result.isNotEmpty && result.last.trailing.isEmpty) {
          result.last.trailing = run;
        }
        continue;
      }
      result.add(
        _Word(
          start: s,
          end: e,
          text: input.substring(s, e),
          fold: fold.substring(s, e),
          lower: lower.substring(s, e),
        )..trailing = trailing,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------- access

  /// Folded word at [index], or `null` when out of range.
  String? fold(int index) =>
      index >= 0 && index < words.length ? words[index].fold : null;

  /// Folded word at [index] when it directly continues the phrase that ends
  /// at `index - 1` (no punctuation in between).
  String? next(int index) {
    if (index <= 0 || index >= words.length) return null;
    if (words[index - 1].breaksAfter) return null;
    return words[index].fold;
  }

  /// Folded word at [index] when it continues a list after `index - 1`
  /// (nothing or a single comma in between).
  String? nextInList(int index) {
    if (index <= 0 || index >= words.length) return null;
    final trailing = words[index - 1].trailing;
    if (trailing.isNotEmpty && trailing != ',') return null;
    return words[index].fold;
  }

  /// Folded word before [index] when nothing separates them.
  String? previous(int index) {
    if (index <= 0 || index > words.length) return null;
    if (words[index - 1].breaksAfter) return null;
    return words[index - 1].fold;
  }

  CaptureToken token(
    CaptureTokenKind kind,
    int fromWord,
    int toWord,
    double confidence,
  ) {
    final start = words[fromWord].start;
    final end = words[toWord - 1].end;
    return CaptureToken(
      kind: kind,
      start: start,
      end: end,
      text: input.substring(start, end),
      confidence: confidence,
    );
  }

  /// Whether the previously accepted unit ends right before [index] and set
  /// a date or a repeat (context for `cuma akşamı`, `her cuma akşamı`).
  bool afterDateLike(int index) {
    final last = _lastUnit;
    if (last == null || _lastUnitEnd != index || index == 0) return false;
    if (words[index - 1].breaksAfter) return false;
    return last.date != null || last.recurrence != null;
  }

  DateTime addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  // ------------------------------------------------------------------ scan

  void run() {
    var i = 0;
    while (i < words.length) {
      final unit = tagRule(i) ??
          recurrenceRule(i) ??
          relativeRule(i) ??
          dateRule(i) ??
          timeRule(i);
      if (unit == null) {
        i++;
        continue;
      }
      if (_accept(unit)) {
        _lastUnit = unit;
        _lastUnitEnd = unit.endWord;
      }
      i = unit.endWord;
    }
  }

  bool _accept(_Unit unit) {
    final hasDate = _date != null || _instant != null;
    final hasTime = _time != null || _instant != null;
    if (unit.date != null && hasDate) return false;
    if (unit.time != null && hasTime) return false;
    if (unit.instant != null && (hasDate || hasTime || _recurrence != null)) {
      return false;
    }
    if (unit.recurrence != null && (_recurrence != null || _instant != null)) {
      return false;
    }
    if (unit.categoryKey != null && _categoryKey != null) return false;
    if (unit.priority != null && _hasPriority) return false;
    if (unit.placeKey != null && _placeKey != null) return false;

    _date ??= unit.date;
    _time ??= unit.time;
    _instant ??= unit.instant;
    _recurrence ??= unit.recurrence;
    if (unit.categoryKey != null) {
      _categoryKey = unit.categoryKey;
      _categoryId = unit.categoryId;
    }
    if (unit.priority != null) {
      _priority = unit.priority!;
      _hasPriority = true;
    }
    _placeKey ??= unit.placeKey;
    _tokens.addAll(unit.tokens);
    return true;
  }

  // -------------------------------------------------------------- result

  CaptureParseResult buildResult() {
    final title = _buildTitle();
    final when = resolve();
    return CaptureParseResult(
      input: input,
      title: title.isEmpty ? input.trim() : TurkishText.capitalizeFirst(title),
      splitSuggestion: title.isEmpty ? const [] : splitSuggestion(title),
      tokens: List.unmodifiable(_tokens),
      dateTime: when.dateTime,
      hasExplicitTime: when.timed,
      isPast: when.past,
      recurrence: when.recurrence,
      categoryKey: _categoryKey,
      categoryId: _categoryId,
      priority: _priority,
      placeKey: _placeKey,
    );
  }

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _spaceBeforePunct = RegExp(r' ([,;:.?)])');
  static final RegExp _emptyParens = RegExp(r'\(\s*\)');
  static final RegExp _repeatedSeparators = RegExp(r'([,;:])(?:\s*[,;:])+');
  static final RegExp _leadingJunk = RegExp(r'^[\s,;:.\-–—·|/]+');
  static final RegExp _trailingJunk = RegExp(r'[\s,;:\-–—·|/]+$');
  static final RegExp _leadingConnector =
      RegExp(r'^(?:ve|ile)\s+', caseSensitive: false);
  static final RegExp _trailingConnector =
      RegExp(r'\s+(?:ve|ile)$', caseSensitive: false);

  /// Input with token ranges removed, whitespace and punctuation tidied
  /// (not capitalized).
  String _buildTitle() {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final t in _tokens) {
      buffer
        ..write(input.substring(cursor, t.start))
        ..write(' ');
      cursor = t.end;
    }
    buffer.write(input.substring(cursor));
    return tidyTitle(buffer.toString());
  }

  static String tidyTitle(String text) {
    var s = text.replaceAll(_spaces, ' ');
    s = s.replaceAll(_emptyParens, ' ').replaceAll(_spaces, ' ');
    s = s.replaceAllMapped(_spaceBeforePunct, (m) => m.group(1)!);
    s = s.replaceAllMapped(_repeatedSeparators, (m) => m.group(1)!);
    for (var pass = 0; pass < 3; pass++) {
      final before = s;
      s = s
          .replaceFirst(_leadingJunk, '')
          .replaceFirst(_trailingJunk, '')
          .replaceFirst(_leadingConnector, '')
          .replaceFirst(_trailingConnector, '');
      if (s == before) break;
    }
    return s.trim();
  }
}
