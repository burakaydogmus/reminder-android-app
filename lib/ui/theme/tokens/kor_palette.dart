import 'dart:ui' show Color;

/// Raw colour tokens of the "Kor" design direction.
///
/// Source of truth: `docs/design/kor-design-proposal.md` §3.1 and the `tokens`
/// block of `docs/design/kor-screens.json`. These are plain data; widgets must
/// not read them directly. Use `Theme.of(context).colorScheme` or the
/// `KorColors` theme extension instead.
///
/// Not wired into the running app yet (F4.1 switches the app to `KorTheme`).
abstract final class KorPaletteLight {
  static const background = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6F2EC);
  static const surfaceContainer = Color(0xFFF1ECE3);
  static const surfaceContainerHigh = Color(0xFFEAE4D9);
  static const onSurface = Color(0xFF1F1B16);
  static const onSurfaceVariant = Color(0xFF5C554C);
  static const outline = Color(0xFF8C8479);
  static const outlineVariant = Color(0xFFDDD5CA);

  static const primary = Color(0xFFB8430F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFFDCC8);
  static const onPrimaryContainer = Color(0xFF4A1A00);

  static const tertiary = Color(0xFF2F5A8A);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFD6E4F7);
  static const onTertiaryContainer = Color(0xFF0F2A47);

  static const success = Color(0xFF2F6B34);
  static const onSuccess = Color(0xFFFFFFFF);
  static const successContainer = Color(0xFFD5ECD3);

  static const error = Color(0xFFB3261E);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFF9DEDC);
  static const onErrorContainer = Color(0xFF410E0B);

  static const inverseSurface = Color(0xFF33302B);
  static const onInverseSurface = Color(0xFFEDE6DC);
  static const inversePrimary = Color(0xFFFF9B63);
  static const scrim = Color(0xFF000000);
  static const shadow = Color(0xFF1F1B16);

  /// rgba(255,255,255,.72)
  static const glassTint = Color(0xB8FFFFFF);

  /// rgba(31,27,22,.08)
  static const glassStroke = Color(0x141F1B16);
  static const nowLine = Color(0xFFB8430F);

  /// Text/icons drawn on top of a filled category `fg` colour.
  static const onCategory = Color(0xFFFFFFFF);
}

abstract final class KorPaletteDark {
  static const background = Color(0xFF14120F);
  static const surface = Color(0xFF1D1B17);
  static const surfaceContainerLowest = Color(0xFF14120F);
  static const surfaceContainerLow = Color(0xFF221F1B);
  static const surfaceContainer = Color(0xFF2A2621);
  static const surfaceContainerHigh = Color(0xFF35302A);
  static const onSurface = Color(0xFFEDE6DC);
  static const onSurfaceVariant = Color(0xFFB9B0A4);
  static const outline = Color(0xFF857D72);
  static const outlineVariant = Color(0xFF4A443C);

  static const primary = Color(0xFFFF9B63);
  static const onPrimary = Color(0xFF3B1500);
  static const primaryContainer = Color(0xFF6A2A08);
  static const onPrimaryContainer = Color(0xFFFFDCC8);

  static const tertiary = Color(0xFF9CC3F0);
  static const onTertiary = Color(0xFF0F2A47);
  static const tertiaryContainer = Color(0xFF23446B);
  static const onTertiaryContainer = Color(0xFFD6E4F7);

  static const success = Color(0xFF8FD08F);
  static const onSuccess = Color(0xFF0B3310);
  static const successContainer = Color(0xFF1F4A23);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const inverseSurface = Color(0xFFEDE6DC);
  static const onInverseSurface = Color(0xFF1F1B16);
  static const inversePrimary = Color(0xFF9A380B);
  static const scrim = Color(0xFF000000);
  static const shadow = Color(0xFF000000);

  /// rgba(29,27,23,.64)
  static const glassTint = Color(0xA31D1B17);

  /// rgba(237,230,220,.10)
  static const glassStroke = Color(0x1AEDE6DC);
  static const nowLine = Color(0xFFFF9B63);

  /// Text/icons drawn on top of a filled category `fg` colour.
  static const onCategory = Color(0xFF14120F);
}

/// Stable colour keys for categories. Persist [KorColorKey.name]
/// (e.g. `"lacivert"`), never a hex value, so light/dark can be resolved.
///
/// The first seven are the built-in categories; all twelve form the user
/// category palette (F4.3).
enum KorColorKey {
  market,
  ev,
  is_,
  saglik,
  gunluk,
  diger,
  dogumGunu,
  kor,
  lacivert,
  zeytin,
  kiremit,
  arduvaz;

  /// Key as written in `kor-screens.json` (`is`, `dogumgunu`).
  String get storageKey => switch (this) {
        KorColorKey.is_ => 'is',
        KorColorKey.dogumGunu => 'dogumgunu',
        _ => name,
      };

  /// Parses a stored key; returns `null` for unknown values.
  static KorColorKey? tryParse(String? key) {
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }

  /// Built-in category colours (first seven keys).
  static const builtIn = [market, ev, is_, saglik, gunluk, diger, dogumGunu];
}

/// A category colour pair for one brightness.
class KorCategoryTone {
  const KorCategoryTone({
    required this.fg,
    required this.container,
    Color? onContainer,
  }) : onContainer = onContainer ?? fg;

  /// Icon, text and filled backgrounds.
  final Color fg;

  /// Light tonal background.
  final Color container;

  /// Text drawn on [container]. Defaults to [fg]; set only where [fg] on
  /// [container] is below 4.5:1 (then [fg] stays icon-only on that
  /// background).
  final Color onContainer;
}

/// Category colour tokens per brightness.
abstract final class KorCategoryPalette {
  static const Map<KorColorKey, KorCategoryTone> light = {
    KorColorKey.market:
        KorCategoryTone(fg: Color(0xFF2E7031), container: Color(0xFFDDEFD9)),
    KorColorKey.ev:
        KorCategoryTone(fg: Color(0xFF00696B), container: Color(0xFFD2EEEC)),
    KorColorKey.is_:
        KorCategoryTone(fg: Color(0xFF2D5EA8), container: Color(0xFFDDE7F7)),
    KorColorKey.saglik:
        KorCategoryTone(fg: Color(0xFFB0265E), container: Color(0xFFFADCE7)),
    KorColorKey.gunluk:
        KorCategoryTone(fg: Color(0xFF8A5300), container: Color(0xFFF8E6C8)),
    KorColorKey.diger:
        KorCategoryTone(fg: Color(0xFF6546C8), container: Color(0xFFE7E0FA)),
    KorColorKey.dogumGunu:
        KorCategoryTone(fg: Color(0xFF9A2A8A), container: Color(0xFFF6DDF1)),
    // #B8430F on #FFDCC8 is 4.24:1, so Kor stays icon-only on its container
    // and text there uses dark brown (owner decision, 2026-09-13).
    KorColorKey.kor: KorCategoryTone(
      fg: Color(0xFFB8430F),
      container: Color(0xFFFFDCC8),
      onContainer: Color(0xFF4A1A00),
    ),
    KorColorKey.lacivert:
        KorCategoryTone(fg: Color(0xFF3A4A9C), container: Color(0xFFDFE2F7)),
    KorColorKey.zeytin:
        KorCategoryTone(fg: Color(0xFF5B6300), container: Color(0xFFE7EBC4)),
    KorColorKey.kiremit:
        KorCategoryTone(fg: Color(0xFF9C3B2E), container: Color(0xFFF7DDD8)),
    KorColorKey.arduvaz:
        KorCategoryTone(fg: Color(0xFF4F5B66), container: Color(0xFFE1E6EB)),
  };

  static const Map<KorColorKey, KorCategoryTone> dark = {
    KorColorKey.market:
        KorCategoryTone(fg: Color(0xFF8ED68A), container: Color(0xFF1E3B1E)),
    KorColorKey.ev:
        KorCategoryTone(fg: Color(0xFF6FD6D2), container: Color(0xFF0F3534)),
    KorColorKey.is_:
        KorCategoryTone(fg: Color(0xFF9EC2F7), container: Color(0xFF1A2C47)),
    KorColorKey.saglik:
        KorCategoryTone(fg: Color(0xFFFF9EC2), container: Color(0xFF48182C)),
    KorColorKey.gunluk:
        KorCategoryTone(fg: Color(0xFFF2BE6B), container: Color(0xFF3F2C0E)),
    KorColorKey.diger:
        KorCategoryTone(fg: Color(0xFFC2B1FF), container: Color(0xFF2D2450)),
    KorColorKey.dogumGunu:
        KorCategoryTone(fg: Color(0xFFF2A3E4), container: Color(0xFF44193D)),
    KorColorKey.kor:
        KorCategoryTone(fg: Color(0xFFFF9B63), container: Color(0xFF4A2410)),
    KorColorKey.lacivert:
        KorCategoryTone(fg: Color(0xFFB6C0FF), container: Color(0xFF232B55)),
    KorColorKey.zeytin:
        KorCategoryTone(fg: Color(0xFFC9D36A), container: Color(0xFF2E3208)),
    KorColorKey.kiremit:
        KorCategoryTone(fg: Color(0xFFFFB0A3), container: Color(0xFF4A1D16)),
    KorColorKey.arduvaz:
        KorCategoryTone(fg: Color(0xFFBAC7D3), container: Color(0xFF29313A)),
  };
}
