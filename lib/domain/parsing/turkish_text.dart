/// Turkish-safe casing and folding.
///
/// Dart's `toLowerCase`/`toUpperCase` are locale-independent: `'I'` becomes
/// `'i'` (Turkish: `'ı'`), `'i'` becomes `'I'` (Turkish: `'İ'`) and `'İ'`
/// lowers to two code units (`'i̇'`), which shifts every index after it.
/// Everything here maps **one UTF-16 code unit to one code unit** (except
/// [toUpper] for non-Turkish specials), so offsets into the original string
/// stay valid.
abstract final class TurkishText {
  /// Turkish lower case: `İ→i`, `I→ı`, other letters as usual.
  static String toLower(String input) {
    final units = input.codeUnits;
    final out = List<int>.filled(units.length, 0);
    for (var i = 0; i < units.length; i++) {
      out[i] = _lowerUnit(units[i]);
    }
    return String.fromCharCodes(out);
  }

  /// Turkish upper case: `i→İ`, `ı→I`, other letters as usual.
  static String toUpper(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune == 0x69) {
        buffer.writeCharCode(0x130); // i → İ
      } else if (rune == 0x131) {
        buffer.writeCharCode(0x49); // ı → I
      } else {
        buffer.write(String.fromCharCode(rune).toUpperCase());
      }
    }
    return buffer.toString();
  }

  /// Lower case plus Turkish diacritics removed (`ç→c ğ→g ı→i ö→o ş→s ü→u`,
  /// circumflex `â î û` too) and typographic apostrophes as `'`. Same length
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
  /// emoji, punctuation) precede it: `istanbul` → `İstanbul`,
  /// `🛒 ekmek` → `🛒 Ekmek`; `2 ekmek` and `#iş` stay.
  static String capitalizeFirst(String input) {
    final runes = input.runes.toList();
    for (var i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      // Digits and tag markers (`#iş`, `@ev`) keep the text as typed.
      if (_digit.hasMatch(ch) || ch == '#' || ch == '@') return input;
      if (_letter.hasMatch(ch)) {
        final upper = toUpper(ch);
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
      if (c == 0x49) return 0x131; // I → ı
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
        return 0x69;
      case 0xF6: // ö
        return 0x6F;
      case 0x15F: // ş
        return 0x73;
      case 0xFC: // ü
      case 0xFB: // û
        return 0x75;
      case 0xE2: // â
        return 0x61;
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
