/// Rule-based quick-capture parser (F4.6a Turkish, F4.6c English) — pure
/// Dart, no Flutter and no `BuildContext`.
///
/// `CaptureParser.parse("cuma 18:00 ekmek ve süt al #market !!", now: ...)`
/// `CaptureParser.parse("fri 6pm buy bread and milk #market !!", now: ...,
/// locale: CaptureLocale.english)` find dates, times, repeats, `#category`,
/// `!` priority and `@place` tokens, return their exact ranges in the input
/// and the remaining title.
///
/// How it works:
/// - The input is split once into words (whitespace runs, surrounding
///   punctuation trimmed). Each word keeps its range in the original string
///   and a folded form (`CaptureLocale.fold`: lower case, no diacritics), so
///   `YARIN`, `yarin` and `yarın` — or `Tomorrow` and `TOMORROW` — match the
///   same rule.
/// - A single left-to-right scan tries the rule groups at each word in a
///   fixed order — tags, repeats, relative phrases, dates, times — and takes
///   the first that matches. A rule may consume several words (`cuma günü`,
///   `the day after tomorrow`) but never crosses punctuation unless it is a
///   list (`her pazartesi, çarşamba ve cuma`, `every monday, wednesday and
///   friday`). All word patterns are anchored regexes compiled once; every
///   rule looks at a bounded number of words, so parsing is linear in the
///   input length.
/// - **First wins:** a match whose slot (date, time, repeat, category, …) is
///   already filled is not tokenized and stays in the title as typed.
/// - **High confidence only:** words that are also ordinary words are
///   tokenized only in clearly temporal use (see the rule files and
///   CLAUDE.md › Quick-capture parser).
///
/// Everything that differs between languages lives in `rules/tr/` and
/// `rules/en/`; the scan loop, the slot bookkeeping, the title tidying, the
/// `#tag`/`!`/`@place` syntax and the date resolution are shared.
library;

import 'package:reminder/domain/parsing/capture_locale.dart';
import 'package:reminder/domain/parsing/capture_parse_result.dart';

export 'package:reminder/domain/parsing/capture_locale.dart';
export 'package:reminder/domain/parsing/capture_parse_result.dart';

part 'rules/capture_scanner.dart';
part 'rules/en/en_date_rules.dart';
part 'rules/en/en_recurrence_rules.dart';
part 'rules/en/en_scanner.dart';
part 'rules/en/en_time_rules.dart';
part 'rules/list_rules.dart';
part 'rules/resolution.dart';
part 'rules/tag_rules.dart';
part 'rules/tr/tr_date_rules.dart';
part 'rules/tr/tr_recurrence_rules.dart';
part 'rules/tr/tr_scanner.dart';
part 'rules/tr/tr_time_rules.dart';

abstract final class CaptureParser {
  /// Parses [input] relative to [now] (local wall-clock time) with the
  /// grammar of [locale].
  static CaptureParseResult parse(
    String input, {
    required DateTime now,
    CaptureParserConfig config = const CaptureParserConfig(),
    CaptureLocale locale = CaptureLocale.turkish,
  }) {
    final scanner = switch (locale) {
      CaptureLocale.turkish => _TrScanner(input, now, config),
      CaptureLocale.english => _EnScanner(input, now, config),
    };
    scanner.run();
    return scanner.buildResult();
  }
}
