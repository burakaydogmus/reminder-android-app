part of '../capture_parser.dart';

/// "Maddelere böl?" (design §3.3.3 › Liste algılama).
///
/// Suggested only when the input carries a `#tag` of a list-like category
/// (`CaptureParserConfig.listCategoryIds`, default: market) and the title
/// splits into at least two items at the grammar's separators
/// ([_Scanner.listSeparators]): `,`, `;`, new lines and the conjunction —
/// `ve` in Turkish, `and`/`&` in English.
///
/// - `#market ekmek, süt ve yumurta` → `ekmek`, `süt`, `yumurta`
/// - `#market buy bread, milk and eggs` → `bread`, `milk`, `eggs`
///
/// A comma between digits is a decimal comma, not a separator (`1,5 litre
/// süt`). A shopping verb is dropped by the grammar
/// ([_Scanner.tidyListItems]): Turkish closes the list with it
/// (`ekmek ve süt al`), English opens it (`buy bread and milk`). Items keep
/// their text as typed; empty items are skipped.
extension _ListRules on _Scanner {
  List<String> splitSuggestion(String title) {
    final id = _categoryId;
    if (id == null || !config.listCategoryIds.contains(id)) return const [];
    final items = [
      for (final part in title.split(listSeparators))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    if (items.length < 2) return const [];
    return List.unmodifiable(tidyListItems(items));
  }
}
