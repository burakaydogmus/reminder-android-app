import 'package:flutter/painting.dart';

import 'kor_palette.dart';

/// Kor elevation levels (`kor-design-proposal.md` §3.1 "Yükselti ve
/// bulanıklık"). In dark theme separation mainly comes from the
/// `surfaceContainer*` steps; shadows are secondary.
class KorElevation {
  const KorElevation({
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level1Border,
  });

  /// Flat: done card, list row.
  static const List<BoxShadow> level0 = [];

  /// Cards: `0 1 2 rgba(31,27,22,.06)`.
  final List<BoxShadow> level1;

  /// Nav, capture bar, FAB: `0 8 24` (.12 light / black .40 dark).
  final List<BoxShadow> level2;

  /// Dragged card, open menu: `0 16 40 rgba(31,27,22,.18)`.
  final List<BoxShadow> level3;

  /// 1px `outlineVariant` border for level-1 cards (light only; `null` in dark).
  final BorderSide? level1Border;

  static const light = KorElevation(
    level1: [
      BoxShadow(color: Color(0x0F1F1B16), offset: Offset(0, 1), blurRadius: 2),
    ],
    level2: [
      BoxShadow(color: Color(0x1F1F1B16), offset: Offset(0, 8), blurRadius: 24),
    ],
    level3: [
      BoxShadow(
        color: Color(0x2E1F1B16),
        offset: Offset(0, 16),
        blurRadius: 40,
      ),
    ],
    level1Border: BorderSide(color: KorPaletteLight.outlineVariant),
  );

  static const dark = KorElevation(
    level1: [
      BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    level2: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24),
    ],
    level3: [
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 16),
        blurRadius: 40,
      ),
    ],
    level1Border: null,
  );
}

/// Glass parameters for iOS floating chrome only (tab bar, search button,
/// capture bar). Tint/stroke colours live in `KorColors`; with Reduce
/// Transparency / Increase Contrast use solid `surfaceContainerHigh` instead.
abstract final class KorGlass {
  static const double blurSigma = 24;
  static const double strokeWidth = 1;
}
