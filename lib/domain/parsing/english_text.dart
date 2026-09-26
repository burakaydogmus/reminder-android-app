/// English-safe casing and folding (F4.6c), the counterpart of
/// [TurkishText] for the English capture grammar.
///
/// Like `TurkishText` every method maps **one UTF-16 code unit to one code
/// unit**, so offsets into the original string stay valid — the parser
/// reports token ranges in the text the user typed.
///
/// The difference to `TurkishText` is the dotted/dotless `i`: here `I`
/// lowers to `i` (not `ı`) and `i` upper-cases to `I` (not `İ`). Turkish
/// diacritics are still folded away, so a Turkish category name or `#tag`
/// (`#sağlık`, `#saglik`) keeps matching while the app is in English.
library;

abstract final class EnglishText {
  /// ASCII/Unicode lower case; `İ` becomes a single `i`.
  static String toLower(String input) {
    final units = input.codeUnits;
    final out = List<int>.filled(units.length, 0);
    for (var i = 0; i < units.length; i++) {
      out[i] = _lowerUnit(units[i]);
    }
    return String.fromCharCodes(out);
  }

  /// Lower case plus diacritics removed (`ç→c ğ→g ı→i ö→o ş→s ü→u`, the
  /// common Latin accents and typographic apostrophes as `'`). Same length
  /// as [input]; used for case/diacritic-insensitive matching.
  static String fold(String input) {
    final units = input.codeUnits;
    final out = List<int>.filled(units.length, 0);
    for (var i = 0; i < units.length; i++) {
      out[i] = _foldUnit(_lowerUnit(units[i]));
    }
    return String.fromCharCodes(out);
  }

  /// Upper-cases the first letter when only non-alphanumerics (spaces,
  /// emoji, punctuation) precede it: `milk` → `Milk`, `🛒 milk` → `🛒 Milk`;
  /// `2 eggs`, `#work` and `@home` stay as typed.
  static String capitalizeFirst(String input) {
    final runes = input.runes.toList();
    for (var i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      if (_digit.hasMatch(ch) || ch == '#' || ch == '@') return input;
      if (_letter.hasMatch(ch)) {
        final upper = ch.toUpperCase();
        if (upper == ch) return input;
        return String.fromCharCodes(runes.sublist(0, i)) +
            upper +
            String.fromCharCodes(runes.sublist(i + 1));
      }
    }
    return input;
  }

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{N}', unicode: true);

  static int _lowerUnit(int c) {
    if (c < 0x80) {
      if (c >= 0x41 && c <= 0x5A) return c + 0x20;
      return c;
    }
    if (c == 0x130) return 0x69; // İ → i
    // Surrogates (emoji) and other non-BMP halves stay as they are.
    if (c >= 0xD800 && c <= 0xDFFF) return c;
    final lowered = String.fromCharCode(c).toLowerCase();
    return lowered.length == 1 ? lowered.codeUnitAt(0) : c;
  }

  static int _foldUnit(int c) {
    switch (c) {
      case 0xE7: // ç
        return 0x63;
      case 0x11F: // ğ
        return 0x67;
      case 0x131: // ı
      case 0xEE: // î
      case 0xED: // í
      case 0xEF: // ï
        return 0x69;
      case 0xF6: // ö
      case 0xF3: // ó
      case 0xF4: // ô
        return 0x6F;
      case 0x15F: // ş
        return 0x73;
      case 0xFC: // ü
      case 0xFB: // û
      case 0xFA: // ú
        return 0x75;
      case 0xE2: // â
      case 0xE0: // à
      case 0xE1: // á
        return 0x61;
      case 0xE9: // é
      case 0xE8: // è
      case 0xEA: // ê
        return 0x65;
      case 0x2019: // ’
      case 0x2018: // ‘
      case 0x60: // `
      case 0xB4: // ´
      case 0x2BC: // ʼ
        return 0x27;
      default:
        return c;
    }
  }
}
