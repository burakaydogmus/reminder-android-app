import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';

/// Pazar 13 Eylül 2026, 14:32 — the fixed clock of the example tables.
final DateTime kNow = DateTime(2026, 9, 13, 14, 32);

/// One example sentence and everything the parser should get out of it.
///
/// Every field is checked: `null`/defaults mean "must be absent". [tokens]
/// are `'kind:text'` strings in input order; each token's range is also
/// checked against the input.
class CaptureCase {
  const CaptureCase(
    this.input, {
    required this.title,
    this.at,
    this.timed,
    this.past = false,
    this.rec,
    this.tag,
    this.categoryId,
    this.priority = 0,
    this.place,
    this.tokens = const [],
    this.split = const [],
  });

  final String input;
  final String title;
  final DateTime? at;

  /// Expected `hasExplicitTime`; defaults to "[at] is not midnight".
  final bool? timed;
  final bool past;
  final RecurrenceSpec? rec;
  final String? tag;
  final String? categoryId;
  final int priority;
  final String? place;
  final List<String> tokens;
  final List<String> split;
}

RecurrenceSpec daily() => const RecurrenceSpec(kind: RecurrenceKind.daily);

RecurrenceSpec weekly(List<int> days, {int interval = 1}) => RecurrenceSpec(
      kind: RecurrenceKind.weekly,
      interval: interval,
      weekdays: days,
    );

RecurrenceSpec monthly(int day, {int interval = 1}) => RecurrenceSpec(
      kind: RecurrenceKind.monthly,
      interval: interval,
      dayOfMonth: day,
    );

RecurrenceSpec everyDays(int n) =>
    RecurrenceSpec(kind: RecurrenceKind.everyNDays, interval: n);

/// Registers one test per case under the current group.
void runCases(
  List<CaptureCase> cases, {
  DateTime? now,
  CaptureLocale locale = CaptureLocale.turkish,
}) {
  for (final c in cases) {
    test(c.input.isEmpty ? '(empty)' : c.input, () {
      final r = CaptureParser.parse(c.input, now: now ?? kNow, locale: locale);
      expectCase(r, c);
    });
  }
}

void expectCase(CaptureParseResult r, CaptureCase c) {
  final tokens = [for (final t in r.tokens) '${t.kind.name}:${t.text}'];
  for (final t in r.tokens) {
    expect(c.input.substring(t.start, t.end), t.text, reason: 'token range');
  }
  expect(tokens, c.tokens, reason: 'tokens');
  expect(r.title, c.title, reason: 'title');
  expect(r.dateTime, c.at, reason: 'dateTime');
  final timed =
      c.timed ?? (c.at != null && (c.at!.hour != 0 || c.at!.minute != 0));
  expect(r.hasExplicitTime, timed, reason: 'hasExplicitTime');
  expect(r.isPast, c.past, reason: 'isPast');
  expect(r.recurrence, c.rec, reason: 'recurrence');
  expect(r.categoryKey, c.tag, reason: 'categoryKey');
  expect(r.categoryId, c.categoryId, reason: 'categoryId');
  expect(r.priority, c.priority, reason: 'priority');
  expect(r.placeKey, c.place, reason: 'placeKey');
  expect(r.splitSuggestion, c.split, reason: 'splitSuggestion');
}
