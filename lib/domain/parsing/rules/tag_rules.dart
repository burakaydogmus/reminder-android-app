part of '../turkish_capture_parser.dart';

/// `#kategori`, `@yer`, `!`/`!!`/`!!!`.
///
/// - A tag is a whole word starting with `#`/`@` followed by letters, digits,
///   `_` or `-` (`e@posta.com` and `C#` are not tags).
/// - `#tag` matches a category when its folded form (case, Turkish
///   diacritics, spaces/`_`/`-` ignored) equals an alias
///   (`#saglik` = `#SAĞLIK` = Sağlık, `#is` = İş, `#ev_isleri` = Ev İşleri),
///   or — for 5+ letters — is one edit away (`#markt`). Otherwise the raw tag
///   is kept with `categoryId == null` ("Yeni kategori oluştur?").
/// - Priority only from a standalone run of 1–3 `!` (`Acil!` and `!!!!` are
///   text).
extension _TagRules on _Scanner {
  static final RegExp _tag =
      RegExp(r'^([#@])([\p{L}\p{N}_\-]+)$', unicode: true);
  static final RegExp _tagSeparators = RegExp(r'[\s_\-]');

  _Unit? tagRule(int i) {
    final word = words[i];
    final text = word.text;
    if (text.startsWith('!')) {
      if (text.length > 3 || text.replaceAll('!', '').isNotEmpty) return null;
      return _Unit(i + 1)
        ..priority = text.length
        ..tokens.add(token(CaptureTokenKind.priority, i, i + 1, 1));
    }
    final m = _tag.firstMatch(text);
    if (m == null) return null;
    final key = m.group(2)!;
    if (m.group(1) == '@') {
      return _Unit(i + 1)
        ..placeKey = key
        ..tokens.add(token(CaptureTokenKind.place, i, i + 1, 1));
    }
    return _Unit(i + 1)
      ..categoryKey = key
      ..categoryId = _matchCategory(key)
      ..tokens.add(token(CaptureTokenKind.category, i, i + 1, 1));
  }

  String? _matchCategory(String key) {
    final folded = TurkishText.fold(key).replaceAll(_tagSeparators, '');
    if (folded.isEmpty) return null;
    String? near;
    for (final entry in config.categoryAliases.entries) {
      for (final alias in entry.value) {
        final a = TurkishText.fold(alias).replaceAll(_tagSeparators, '');
        if (a == folded) return entry.key;
        if (near == null &&
            folded.length >= 5 &&
            a.length >= 5 &&
            _withinOneEdit(a, folded)) {
          near = entry.key;
        }
      }
    }
    return near;
  }

  /// Levenshtein distance ≤ 1 (one insert, delete or substitution).
  static bool _withinOneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a.codeUnitAt(i) == b.codeUnitAt(j)) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}
