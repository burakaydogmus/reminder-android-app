import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/capture_locale.dart';
import 'package:reminder/domain/parsing/capture_parse_result.dart';

/// `#tag` aliases for the quick-capture parser from the current categories
/// (F4.3). The parser itself stays model-free; the capture UI builds its
/// config with [CategoryAliases.configFor].
///
/// - Built-in categories keep the default aliases of the grammar
///   ([CaptureParserConfig.builtInAliasesOf]: `#alışveriş` in Turkish,
///   those plus `#groceries` / `#shopping` in English) plus their folded
///   display name.
/// - User categories get their folded name ([CaptureLocale.fold]: case and
///   diacritics ignored); the parser also ignores spaces, `_` and `-`, so
///   "Spor salonu" matches `#sporsalonu`, `#spor_salonu` and
///   `#SPOR-SALONU`.
/// - Aliases are listed in catalog order; an alias whose folded form is
///   already taken by an earlier category is dropped, so the first category
///   wins a clash (the parser returns the first exact match).
///
/// [locale] must be the one passed to `CaptureParser.parse`: the parser
/// folds the typed tag the same way, and Turkish and English differ on
/// `I`/`İ` (F4.6c).
abstract final class CategoryAliases {
  static final RegExp _separators = RegExp(r'[\s_\-]');

  static String _key(CaptureLocale locale, String alias) =>
      locale.fold(alias).replaceAll(_separators, '');

  /// Category id → aliases, in [catalog] order.
  static Map<String, List<String>> of(
    CategoryCatalog catalog, {
    CaptureLocale locale = CaptureLocale.turkish,
  }) {
    final builtIns = CaptureParserConfig.builtInAliasesOf(locale);
    final taken = <String>{};
    final result = <String, List<String>>{};
    for (final c in catalog.ordered) {
      final candidates = [
        if (c.isBuiltIn) ...?builtIns[c.id],
        locale.fold(c.name.trim()),
      ];
      final aliases = [
        for (final alias in candidates)
          if (_key(locale, alias).isNotEmpty && taken.add(_key(locale, alias)))
            alias,
      ];
      if (aliases.isNotEmpty) result[c.id] = List.unmodifiable(aliases);
    }
    return Map.unmodifiable(result);
  }

  /// [base] with category aliases from [catalog]; list categories keep the
  /// base set (market).
  static CaptureParserConfig configFor(
    CategoryCatalog catalog, {
    CaptureParserConfig base = const CaptureParserConfig(),
    CaptureLocale locale = CaptureLocale.turkish,
  }) {
    return CaptureParserConfig(
      morningHour: base.morningHour,
      noonHour: base.noonHour,
      afternoonHour: base.afternoonHour,
      eveningHour: base.eveningHour,
      nightHour: base.nightHour,
      categoryAliases: of(catalog, locale: locale),
      listCategoryIds: base.listCategoryIds,
    );
  }
}
