import 'package:flutter/widgets.dart';

import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/app_localizations.dart';

export 'package:reminder/l10n/app_localizations.dart';

/// `context.l10n.someKey` — every user-visible string comes from the ARB
/// files (`lib/l10n/app_tr.arb` is the template, `app_en.arb` the English
/// copy). See CLAUDE.md › Localization.
extension AppLocalizationsContext on BuildContext {
  /// Strings for the active app locale. Without [AppLocalizations] in the
  /// tree (isolated widget tests that build their own `MaterialApp`) the
  /// Turkish strings are used.
  AppLocalizations get l10n => AppLocalizations.of(this) ?? AppL10n.turkish;
}

/// Lookups and locale rules shared by UI and background code.
abstract final class AppL10n {
  static final AppLocalizations turkish =
      lookupAppLocalizations(AppLocales.turkish);
  static final AppLocalizations english =
      lookupAppLocalizations(AppLocales.english);

  /// Strings for [locale] (Turkish for `tr`, English otherwise).
  static AppLocalizations of(Locale locale) =>
      locale.languageCode == AppLocales.turkish.languageCode
          ? turkish
          : english;
}

/// Locale-dependent text rules on top of the generated strings.
extension AppLocalizationsRules on AppLocalizations {
  bool get isTurkish => localeName.startsWith('tr');

  /// `intl` locale for `DateFormat` ("tr_TR", "en_US").
  String get intlLocale => isTurkish ? 'tr_TR' : 'en_US';

  /// Locale-aware upper case: Turkish maps `i → İ`, `ı → I`.
  String upper(String s) => isTurkish
      ? s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase()
      : s.toUpperCase();
}
