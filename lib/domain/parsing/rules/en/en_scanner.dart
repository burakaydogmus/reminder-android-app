part of '../../capture_parser.dart';

/// The English grammar (F4.6c): the rule order of the scan and the few
/// language tables the shared scanner needs. The rules themselves are the
/// `_En…Rules` extensions in this folder.
class _EnScanner extends _Scanner {
  _EnScanner(String input, DateTime now, CaptureParserConfig config)
      : super(input, now, config, CaptureLocale.english);

  @override
  _Unit? ruleAt(int i) =>
      tagRule(i) ??
      recurrenceRule(i) ??
      relativeRule(i) ??
      dateRule(i) ??
      timeRule(i);

  @override
  RegExp get leadingConnector => _leadingConnector;

  @override
  RegExp get trailingConnector => _trailingConnector;

  @override
  RegExp get listSeparators => _listSeparators;

  /// English opens a shopping list with the verb, so it is dropped from the
  /// **first** item (`buy bread and milk` → `bread`, `milk`; `pick up milk,
  /// eggs` → `milk`, `eggs`).
  @override
  List<String> tidyListItems(List<String> items) {
    final first = items.first;
    final m = _leadingVerb.firstMatch(first);
    if (m == null) return items;
    final rest = first.substring(m.end).trim();
    if (rest.isEmpty) return items;
    items[0] = rest;
    return items;
  }

  static final RegExp _leadingConnector =
      RegExp(r'^(?:and|&)\s+', caseSensitive: false);
  static final RegExp _trailingConnector =
      RegExp(r'\s+(?:and|&)$', caseSensitive: false);

  /// `,`, `;`, new lines and the conjunction `and` / `&`. A comma between
  /// digits is a decimal comma, not a separator (`1,5 litres of milk`).
  static final RegExp _listSeparators = RegExp(
    r'\s*(?:(?<!\d),|,(?!\d)|;|\n)\s*|\s+(?:and|&)\s+',
    caseSensitive: false,
  );

  /// Shopping verbs that open a list, with the particle of `pick up`.
  static final RegExp _leadingVerb = RegExp(
    r'^(?:buy|get|grab|order|purchase|pick\s+up|pick)\s+',
    caseSensitive: false,
  );
}
