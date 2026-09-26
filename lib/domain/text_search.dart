/// Turkish-insensitive text matching for search (§3.3.8).
///
/// [fold] maps every UTF-16 code unit to exactly one code unit, so an index
/// in the folded string is the same index in the original string and match
/// ranges can be used to highlight the original text.
///
/// Folding: case (locale-safe, without `toLowerCase` on `İ`, which would
/// produce two code units), `İ I ı → i`, `ş → s`, `ğ → g`, `ç → c`,
/// `ö → o`, `ü → u` and the circumflex vowels `â î û → a i u`.
abstract final class TextSearch {
  static const Map<String, String> _map = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ç': 'c',
    'ç': 'c',
    'Ö': 'o',
    'ö': 'o',
    'Ü': 'u',
    'ü': 'u',
    'Â': 'a',
    'â': 'a',
    'Î': 'i',
    'î': 'i',
    'Û': 'u',
    'û': 'u',
  };

  /// Folds a single code unit (as a one-unit string).
  static String _foldUnit(String unit) {
    final mapped = _map[unit];
    if (mapped != null) return mapped;
    final lower = unit.toLowerCase();
    // Keep the 1:1 index mapping; the few characters whose lower case is
    // longer stay as they are.
    return lower.length == 1 ? lower : unit;
  }

  /// Folded form of [text] with the same length as [text].
  static String fold(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      buffer.write(_foldUnit(text[i]));
    }
    return buffer.toString();
  }

  /// Folded comparison key for a **name**: [fold] plus trimming and collapsing
  /// runs of whitespace, so `Ayşe  Yılmaz`, `ayse yilmaz` and ` AYŞE YILMAZ `
  /// give the same key. Used wherever two user-typed names must count as the
  /// same one (category names, the F7.3 contact birthday dedupe).
  ///
  /// Unlike [fold] this does **not** keep the 1:1 index mapping, so never use
  /// it to highlight ranges in the original text.
  static String foldName(String name) =>
      fold(name.trim()).replaceAll(RegExp(r'\s+'), ' ');

  /// Query split into folded, non-empty tokens (whitespace separated).
  static List<String> tokens(String query) => [
        for (final t in fold(query).split(RegExp(r'\s+')))
          if (t.isNotEmpty) t,
      ];

  /// Whether folded [text] contains folded [query].
  static bool contains(String text, String query) {
    final q = fold(query.trim());
    if (q.isEmpty) return false;
    return fold(text).contains(q);
  }

  /// Non-overlapping ranges of every [tokens] occurrence in [text], sorted
  /// and merged. [tokens] must already be folded (see [tokens]).
  static List<MatchRange> ranges(String text, List<String> tokens) {
    if (tokens.isEmpty || text.isEmpty) return const [];
    final folded = fold(text);
    final found = <MatchRange>[];
    for (final token in tokens) {
      var from = 0;
      while (true) {
        final i = folded.indexOf(token, from);
        if (i < 0) break;
        found.add(MatchRange(i, i + token.length));
        from = i + token.length;
      }
    }
    if (found.isEmpty) return const [];
    found.sort((a, b) => a.start.compareTo(b.start));
    final merged = <MatchRange>[found.first];
    for (final r in found.skip(1)) {
      final last = merged.last;
      if (r.start <= last.end) {
        if (r.end > last.end) {
          merged[merged.length - 1] = MatchRange(last.start, r.end);
        }
      } else {
        merged.add(r);
      }
    }
    return List.unmodifiable(merged);
  }

  /// Whether folded [token] starts a word in [text] (start of text or after a
  /// non letter/digit character).
  static bool startsWord(String text, String token) {
    final folded = fold(text);
    var from = 0;
    while (true) {
      final i = folded.indexOf(token, from);
      if (i < 0) return false;
      if (i == 0 || !_isWordUnit(folded.codeUnitAt(i - 1))) return true;
      from = i + 1;
    }
  }

  static final RegExp _wordUnit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static bool _isWordUnit(int unit) =>
      _wordUnit.hasMatch(String.fromCharCode(unit));
}

/// A half-open `[start, end)` range in the original (unfolded) text.
class MatchRange {
  const MatchRange(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is MatchRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'MatchRange($start, $end)';
}
