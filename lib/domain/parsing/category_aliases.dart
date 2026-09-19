import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/capture_parse_result.dart';
import 'package:reminder/domain/parsing/turkish_text.dart';

/// `#tag` aliases for the quick-capture parser from the current categories
/// (F4.3). The parser itself stays model-free; the capture UI builds its
/// config with [CategoryAliases.configFor].
///
/// - Built-in categories keep their default aliases
///   ([CaptureParserConfig.defaultCategoryAliases], e.g. `#alışveriş`) plus
///   their folded display name.
/// - User categories get their folded name ([TurkishText.fold]: case and
///   Turkish diacritics ignored); the parser also ignores spaces, `_` and
///   `-`, so "Spor salonu" matches `#sporsalonu`, `#spor_salonu` and
///   `#SPOR-SALONU`.
/// - Aliases are listed in catalog order; an alias whose folded form is
///   already taken by an earlier category is dropped, so the first category
///   wins a clash (the parser returns the first exact match).
abstract final class CategoryAliases {
  static final RegExp _separators = RegExp(r'[\s_\-]');

  static String _key(String alias) =>
      TurkishText.fold(alias).replaceAll(_separators, '');

  /// Category id → aliases, in [catalog] order.
  static Map<String, List<String>> of(CategoryCatalog catalog) {
    final taken = <String>{};
    final result = <String, List<String>>{};
    for (final c in catalog.ordered) {
      final candidates = [
        if (c.isBuiltIn) ...?CaptureParserConfig.defaultCategoryAliases[c.id],
        TurkishText.fold(c.name.trim()),
      ];
      final aliases = [
        for (final alias in candidates)
          if (_key(alias).isNotEmpty && taken.add(_key(alias))) alias,
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
  }) {
    return CaptureParserConfig(
      morningHour: base.morningHour,
      noonHour: base.noonHour,
      afternoonHour: base.afternoonHour,
      eveningHour: base.eveningHour,
      nightHour: base.nightHour,
      categoryAliases: of(catalog),
      listCategoryIds: base.listCategoryIds,
    );
  }
}
