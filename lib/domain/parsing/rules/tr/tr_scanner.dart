part of '../../capture_parser.dart';

/// The Turkish grammar (F4.6a): the rule order of the scan and the few
/// language tables the shared scanner needs. The rules themselves are the
/// `_Tr…Rules` extensions in this folder.
class _TrScanner extends _Scanner {
  _TrScanner(String input, DateTime now, CaptureParserConfig config)
      : super(input, now, config, CaptureLocale.turkish);

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

  /// A closing shopping verb is dropped from the last item
  /// (`ekmek ve süt al` → `ekmek`, `süt`).
  @override
  List<String> tidyListItems(List<String> items) {
    final last = items.last;
    final verb = _lastWord.firstMatch(last);
    if (verb != null && _listVerbs.contains(locale.fold(verb.group(1)!))) {
      items[items.length - 1] = last.substring(0, verb.start).trim();
    }
    return items;
  }

  static final RegExp _leadingConnector =
      RegExp(r'^(?:ve|ile)\s+', caseSensitive: false);
  static final RegExp _trailingConnector =
      RegExp(r'\s+(?:ve|ile)$', caseSensitive: false);

  /// `,`, `;`, new lines and the word `ve`. A comma between digits is a
  /// decimal comma, not a separator (`1,5 litre süt`).
  static final RegExp _listSeparators = RegExp(
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
}
