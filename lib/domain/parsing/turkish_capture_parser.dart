/// Rule-based Turkish quick-capture parser (F4.6a, pure Dart).
///
/// `CaptureParser.parse("cuma 18:00 ekmek ve süt al #market !!", now: ...)`
/// finds dates, times, repeats, `#category`, `!` priority and `@place`
/// tokens, returns their exact ranges in the input and the remaining title.
///
/// How it works:
/// - The input is split once into words (whitespace runs, surrounding
///   punctuation trimmed). Each word keeps its range in the original string
///   and a folded form (`TurkishText.fold`: lower case, no diacritics), so
///   `YARIN`, `yarin` and `yarın` match the same rule.
/// - A single left-to-right scan tries the rule groups at each word in a fixed
///   order — tags, repeats, relative phrases, dates, times — and takes the
///   first that matches. A rule may consume several words (`cuma günü`,
///   `akşam 8'de`) but never crosses punctuation unless it is a list
///   (`her pazartesi, çarşamba ve cuma`). All word patterns are anchored
///   regexes compiled once; every rule looks at a bounded number of words, so
///   parsing is linear in the input length.
/// - **First wins:** a match whose slot (date, time, repeat, category, …) is
///   already filled is not tokenized and stays in the title as typed.
/// - **High confidence only:** words that are also ordinary words are
///   tokenized only in clearly temporal use (see the rule files and
///   CLAUDE.md › Quick-capture parser).
library;

import 'capture_parse_result.dart';
import 'turkish_text.dart';

export 'capture_parse_result.dart';

part 'rules/capture_scanner.dart';
part 'rules/date_rules.dart';
part 'rules/recurrence_rules.dart';
part 'rules/resolution.dart';
part 'rules/tag_rules.dart';
part 'rules/time_rules.dart';

abstract final class CaptureParser {
  /// Parses [input] relative to [now] (local wall-clock time).
  static CaptureParseResult parse(
    String input, {
    required DateTime now,
    CaptureParserConfig config = const CaptureParserConfig(),
  }) {
    final scanner = _Scanner(input, now, config);
    scanner.run();
    return scanner.buildResult();
  }
}
