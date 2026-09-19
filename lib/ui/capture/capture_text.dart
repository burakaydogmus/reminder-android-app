import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/parsing/turkish_capture_parser.dart';

/// Parses capture input while some recognized phrases were turned back
/// into plain text ("×" on a chip, design §3.3.3 › Token davranışı).
///
/// The parser has no "ignore this range" option, so every whole-word
/// occurrence of a suppressed phrase is replaced by a same-length run of a
/// private-use character before parsing (offsets stay valid, no rule matches
/// it) and the original text is put back into the title and list items.
abstract final class CaptureText {
  static final String _mask = String.fromCharCode(0xE000);
  static final RegExp _maskRuns = RegExp('$_mask+');
  static final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static CaptureParseResult parse(
    String input, {
    required DateTime now,
    Set<String> suppressed = const {},
    CaptureParserConfig config = const CaptureParserConfig(),
  }) {
    final ranges = _suppressedRanges(input, suppressed);
    if (ranges.isEmpty) {
      return CaptureParser.parse(input, now: now, config: config);
    }
    final masked = StringBuffer();
    var at = 0;
    for (final (start, end) in ranges) {
      masked
        ..write(input.substring(at, start))
        ..write(_mask * (end - start));
      at = end;
    }
    masked.write(input.substring(at));
    final result = CaptureParser.parse(
      masked.toString(),
      now: now,
      config: config,
    );
    final originals = [for (final (s, e) in ranges) input.substring(s, e)];
    return CaptureParseResult(
      input: input,
      title: _capitalized(_restore(result.title, originals)),
      tokens: result.tokens,
      dateTime: result.dateTime,
      hasExplicitTime: result.hasExplicitTime,
      isPast: result.isPast,
      recurrence: result.recurrence,
      categoryKey: result.categoryKey,
      categoryId: result.categoryId,
      priority: result.priority,
      placeKey: result.placeKey,
      splitSuggestion: _restoreItems(result.splitSuggestion, originals),
    );
  }

  /// Merged, sorted ranges of whole-word occurrences of [suppressed].
  static List<(int, int)> _suppressedRanges(
    String input,
    Set<String> suppressed,
  ) {
    final found = <(int, int)>[];
    for (final phrase in suppressed) {
      if (phrase.isEmpty) continue;
      var from = 0;
      while (true) {
        final i = input.indexOf(phrase, from);
        if (i < 0) break;
        final end = i + phrase.length;
        final before = i == 0 ? '' : input[i - 1];
        final after = end >= input.length ? '' : input[end];
        final boundaryBefore = before.isEmpty ||
            !_wordChar.hasMatch(before) ||
            !_wordChar.hasMatch(phrase[0]);
        final boundaryAfter = after.isEmpty ||
            !_wordChar.hasMatch(after) ||
            !_wordChar.hasMatch(phrase[phrase.length - 1]);
        if (boundaryBefore && boundaryAfter) found.add((i, end));
        from = i + 1;
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final r in found) {
      if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
        final last = merged.removeLast();
        merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  static String _restore(String text, List<String> originals) {
    var k = 0;
    return text.replaceAllMapped(
      _maskRuns,
      (m) => k < originals.length ? originals[k++] : m[0]!,
    );
  }

  static List<String> _restoreItems(
      List<String> items, List<String> originals) {
    if (items.isEmpty) return items;
    var k = 0;
    return List.unmodifiable([
      for (final item in items)
        item.replaceAllMapped(
          _maskRuns,
          (m) => k < originals.length ? originals[k++] : m[0]!,
        ),
    ]);
  }

  static String _capitalized(String text) {
    if (text.isEmpty) return text;
    final first = text[0];
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${text.substring(1)}';
  }
}

/// Styles one recognized token for inline highlighting.
typedef CaptureTokenStyler = TextStyle Function(CaptureToken token);

/// Text controller of the capture field: paints recognized tokens in place
/// (`TextEditingController.buildTextSpan`, design §3.3.3). Tokens are set
/// together with the text they were parsed from; while the text differs
/// (a keystroke not parsed yet) or an IME composition is active, the text is
/// plain.
class CaptureTextController extends TextEditingController {
  CaptureTextController({super.text});

  List<CaptureToken> _tokens = const [];
  String _tokensText = '';
  CaptureTokenStyler? _styler;

  List<CaptureToken> get tokens => _tokens;

  void setTokens(
      String text, List<CaptureToken> tokens, CaptureTokenStyler styler) {
    _tokens = [...tokens]..sort((a, b) => a.start.compareTo(b.start));
    _tokensText = text;
    _styler = styler;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final styler = _styler;
    final composing = withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed;
    if (styler == null || _tokens.isEmpty || text != _tokensText || composing) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final children = <InlineSpan>[];
    var at = 0;
    for (final token in _tokens) {
      if (token.start < at || token.end > text.length) continue;
      if (token.start > at) {
        children.add(TextSpan(text: text.substring(at, token.start)));
      }
      children.add(
        TextSpan(
          text: text.substring(token.start, token.end),
          style: styler(token),
        ),
      );
      at = token.end;
    }
    if (at < text.length) children.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: children);
  }
}
