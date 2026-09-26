import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/parsing/capture_parser.dart';
import 'package:reminder/l10n/l10n.dart';

/// The capture grammar of an app language (F4.6c): the parser is chosen
/// from the **app** language (F6.1 Ayarlar › Görünüm › Dil), never from the
/// device locale.
extension CaptureLocaleOfL10n on AppLocalizations {
  CaptureLocale get captureLocale =>
      isTurkish ? CaptureLocale.turkish : CaptureLocale.english;
}

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
    CaptureLocale locale = CaptureLocale.turkish,
  }) {
    final ranges = _suppressedRanges(input, suppressed);
    if (ranges.isEmpty) {
      return CaptureParser.parse(
        input,
        now: now,
        config: config,
        locale: locale,
      );
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
      locale: locale,
    );
    final originals = [for (final (s, e) in ranges) input.substring(s, e)];
    final title =
        _uncapitalizeAfterMask(result.title, input, ranges, result, locale);
    return CaptureParseResult(
      input: input,
      title: locale.capitalizeFirst(_restore(title, originals)),
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

  /// When the masked title starts with a mask run, the parser capitalized
  /// the first plain word after it (`▯▯▯▯ ekmek` → `▯▯▯▯ Ekmek`); give that
  /// letter back its typed case. The first plain word is the first input
  /// character outside masked ranges, tokens and whitespace.
  static String _uncapitalizeAfterMask(
    String title,
    String input,
    List<(int, int)> masked,
    CaptureParseResult result,
    CaptureLocale locale,
  ) {
    if (!title.startsWith(_mask)) return title;
    bool covered(int i) =>
        masked.any((r) => i >= r.$1 && i < r.$2) ||
        result.tokens.any((t) => i >= t.start && i < t.end);
    String? typed;
    for (var i = 0; i < input.length; i++) {
      if (covered(i) || input[i].trim().isEmpty) continue;
      typed = input[i];
      break;
    }
    if (typed == null) return title;
    for (var q = 0; q < title.length; q++) {
      final c = title[q];
      if (c == _mask || c.trim().isEmpty) continue;
      if (c != typed && c == locale.capitalizeFirst(typed)) {
        return '${title.substring(0, q)}$typed${title.substring(q + 1)}';
      }
      return title;
    }
    return title;
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
