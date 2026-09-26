/// Which grammar the quick-capture parser uses (F4.6c).
library;

import 'package:reminder/domain/parsing/english_text.dart';
import 'package:reminder/domain/parsing/turkish_text.dart';

/// The language whose rules `CaptureParser.parse` applies.
///
/// It is an **explicit input**, never read from the device: the capture UI
/// passes the resolved *app* language (F6.1 `AppLanguage` → `l10n`), so the
/// parser stays pure Dart without a `BuildContext` and background code can
/// pick the same grammar through `BackgroundLocalizations`.
enum CaptureLocale {
  turkish,
  english;

  /// Grammar for an app locale name (`tr`, `tr_TR` → [turkish], anything
  /// else → [english]). Mirrors `AppLocalizationsRules.isTurkish`.
  static CaptureLocale forLanguageCode(String localeName) =>
      localeName.toLowerCase().startsWith('tr') ? turkish : english;

  /// Locale-safe lower case, one code unit per code unit.
  String toLower(String input) => switch (this) {
        CaptureLocale.turkish => TurkishText.toLower(input),
        CaptureLocale.english => EnglishText.toLower(input),
      };

  /// Lower case with diacritics removed, one code unit per code unit.
  /// Both grammars fold Turkish diacritics, so `#saglik` keeps matching
  /// "Sağlık" in English; they differ only in `I`/`İ`.
  String fold(String input) => switch (this) {
        CaptureLocale.turkish => TurkishText.fold(input),
        CaptureLocale.english => EnglishText.fold(input),
      };

  /// Upper-cases the first letter of a title (`i` → `İ` in Turkish,
  /// `i` → `I` in English).
  String capitalizeFirst(String input) => switch (this) {
        CaptureLocale.turkish => TurkishText.capitalizeFirst(input),
        CaptureLocale.english => EnglishText.capitalizeFirst(input),
      };
}
