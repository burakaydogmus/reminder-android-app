part of '../turkish_capture_parser.dart';

/// "Maddelere böl?" (design §3.3.3 › Liste algılama).
///
/// Suggested only when the input carries a `#tag` of a list-like category
/// (`CaptureParserConfig.listCategoryIds`, default: market) and the title
/// splits into at least two items at `,`, `;`, new lines or the word `ve`
/// (`#market ekmek, süt ve yumurta` → `ekmek`, `süt`, `yumurta`).
///
/// - A comma between digits is a decimal comma, not a separator
///   (`1,5 litre süt`).
/// - A closing shopping verb is dropped from the last item
///   (`ekmek ve süt al` → `ekmek`, `süt`).
/// - Items keep their text as typed; empty items are skipped.
extension _ListRules on _Scanner {
  static final RegExp _separators = RegExp(
    r'\s*(?:(?<!\d),|,(?!\d)|;|\n)\s*|\s+[vV][eE]\s+',
  );
  static final RegExp _lastWord = RegExp(r'\s+(\S+)$');

  /// Folded verbs that close a shopping list (`… al`, `… alınacak`).
  static const Set<String> _listVerbs = {
    'al',
    'alin',
    'alinacak',
    'alinacaklar',
    'alinsin',
    'alalim',
    'getir',
  };

  List<String> splitSuggestion(String title) {
    final id = _categoryId;
    if (id == null || !config.listCategoryIds.contains(id)) return const [];
    final items = [
      for (final part in title.split(_separators))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    if (items.length < 2) return const [];
    final last = items.last;
    final verb = _lastWord.firstMatch(last);
    if (verb != null && _listVerbs.contains(TurkishText.fold(verb.group(1)!))) {
      items[items.length - 1] = last.substring(0, verb.start).trim();
    }
    return List.unmodifiable(items);
  }
}
