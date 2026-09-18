/// Neutral result types of the Turkish quick-capture parser (F4.6a).
///
/// They deliberately do not depend on `Reminder` or a recurrence model: the
/// capture UI (F4.6b) maps them to the models of F3.1 (recurrence) and F3.4
/// (priority).
library;

import '../model/reminder_category.dart';

/// What a recognized piece of the input means.
enum CaptureTokenKind { date, time, recurrence, category, priority, place }

/// A recognized phrase with its exact range in the **original** input.
///
/// `start` is inclusive, `end` exclusive, so `input.substring(start, end)`
/// equals [text]. Used for inline highlighting and "turn back into text".
class CaptureToken {
  const CaptureToken({
    required this.kind,
    required this.start,
    required this.end,
    required this.text,
    required this.confidence,
  });

  final CaptureTokenKind kind;
  final int start;
  final int end;
  final String text;

  /// 0–1. Only high-confidence matches become tokens at all; the value lets
  /// the UI treat the weaker ones (bare day parts, bare `9'da`, `17.09`)
  /// differently if it wants to.
  final double confidence;

  @override
  bool operator ==(Object other) =>
      other is CaptureToken &&
      other.kind == kind &&
      other.start == start &&
      other.end == end &&
      other.text == text &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(kind, start, end, text, confidence);

  @override
  String toString() => 'CaptureToken(${kind.name}, $start-$end, "$text", '
      '$confidence)';
}

enum RecurrenceKind { daily, weekly, monthly, everyNDays }

/// A repeat rule in model-neutral form.
///
/// - `daily`: every [interval] days (always 1 from the parser).
/// - `everyNDays`: every [interval] days (`3 günde bir`, `gün aşırı`).
/// - `weekly`: every [interval] weeks on [weekdays] (Mon=1 … Sun=7, sorted,
///   never empty from the parser).
/// - `monthly`: every [interval] months on [dayOfMonth] (1–31; months without
///   that day are skipped when computing the first occurrence).
class RecurrenceSpec {
  const RecurrenceSpec({
    required this.kind,
    this.interval = 1,
    this.weekdays = const [],
    this.dayOfMonth,
  });

  final RecurrenceKind kind;
  final int interval;
  final List<int> weekdays;
  final int? dayOfMonth;

  RecurrenceSpec copyWith({List<int>? weekdays, int? dayOfMonth}) =>
      RecurrenceSpec(
        kind: kind,
        interval: interval,
        weekdays: weekdays ?? this.weekdays,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceSpec &&
      other.kind == kind &&
      other.interval == interval &&
      other.dayOfMonth == dayOfMonth &&
      _listEquals(other.weekdays, weekdays);

  @override
  int get hashCode =>
      Object.hash(kind, interval, dayOfMonth, Object.hashAll(weekdays));

  @override
  String toString() => 'RecurrenceSpec(${kind.name}, interval: $interval, '
      'weekdays: $weekdays, dayOfMonth: $dayOfMonth)';
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Tunable values. Day-part hours follow the design's "Ayarlar › sabah saati".
class CaptureParserConfig {
  const CaptureParserConfig({
    this.morningHour = 9,
    this.noonHour = 12,
    this.afternoonHour = 15,
    this.eveningHour = 20,
    this.nightHour = 22,
    this.categoryAliases = defaultCategoryAliases,
    this.listCategoryIds = const {ReminderCategoryIds.market},
  });

  final int morningHour;
  final int noonHour;
  final int afternoonHour;
  final int eveningHour;
  final int nightHour;

  /// Category id → names a `#tag` may use. Compared folded (case and Turkish
  /// diacritics ignored, spaces removed). F4.3 custom categories can pass
  /// their own map.
  final Map<String, List<String>> categoryAliases;

  /// Category ids whose `#tag` turns a comma/`ve` list into a
  /// "Maddelere böl?" suggestion.
  final Set<String> listCategoryIds;

  /// Turkish labels of `ReminderCategoryIds` (plus the ids themselves).
  static const Map<String, List<String>> defaultCategoryAliases = {
    ReminderCategoryIds.market: ['market', 'alışveriş'],
    ReminderCategoryIds.home: ['ev', 'ev işleri', 'home'],
    ReminderCategoryIds.work: ['iş', 'work'],
    ReminderCategoryIds.health: ['sağlık', 'health'],
    ReminderCategoryIds.errands: ['günlük', 'errands'],
    ReminderCategoryIds.other: ['diğer', 'other'],
  };
}

class CaptureParseResult {
  const CaptureParseResult({
    required this.input,
    required this.title,
    this.tokens = const [],
    this.dateTime,
    this.hasExplicitTime = false,
    this.isPast = false,
    this.recurrence,
    this.categoryKey,
    this.categoryId,
    this.priority = 0,
    this.placeKey,
    this.splitSuggestion = const [],
  });

  final String input;

  /// Input without the recognized tokens, tidied and capitalized. Falls back
  /// to the trimmed input when nothing else is left.
  final String title;

  /// Accepted tokens in input order.
  final List<CaptureToken> tokens;

  /// Local wall-clock time. Date-only phrases give midnight with
  /// [hasExplicitTime] `false`. With a [recurrence] this is the first
  /// occurrence at or after `now`.
  final DateTime? dateTime;
  final bool hasExplicitTime;

  /// A one-off date/time that is already behind `now` (explicit past date
  /// or `bugün 9'da` after 09:00). The UI warns instead of shifting it
  /// (F1.8b). Never set with a recurrence.
  final bool isPast;

  final RecurrenceSpec? recurrence;

  /// Raw `#tag` text without `#`, as typed.
  final String? categoryKey;

  /// Matched category id, or `null` when [categoryKey] is new
  /// ("Yeni kategori oluştur?").
  final String? categoryId;

  /// 0 (none) – 3 from standalone `!`, `!!`, `!!!`.
  final int priority;

  /// Raw `@place` text without `@`, as typed.
  final String? placeKey;

  /// Items for "Maddelere böl?" — empty when no list was detected. Only with
  /// a `#tag` of `CaptureParserConfig.listCategoryIds` and at least two
  /// items; the UI picks the list title (design: "Market alışverişi").
  final List<String> splitSuggestion;

  Iterable<CaptureToken> tokensOf(CaptureTokenKind kind) =>
      tokens.where((t) => t.kind == kind);
}
