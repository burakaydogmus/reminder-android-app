import 'package:material_ui/material_ui.dart';

/// Kor type scale on the bundled variable font Google Sans Flex
/// (`fonts/GoogleSansFlex/GoogleSansFlex-Latin.ttf`: latin + latin-ext, axes wght 300–800,
/// opsz 8–48, ROND 0–100).
///
/// Values: `docs/design/kor-design-proposal.md` §3.1 "Tipografi" and
/// `kor-screens.json` `tokens.type` (tracking, opsz). Rule: headings are
/// rounded (friendly), body text is flat (legible).
///
/// Styles carry no colour; `KorTheme` applies `onSurface`.
abstract final class KorTypography {
  /// Family name registered in `pubspec.yaml`.
  static const fontFamily = 'GoogleSansFlex';

  /// Builds a style with explicit `wght`, `opsz` and `ROND` variations.
  ///
  /// [fontWeight] is set to the nearest [FontWeight] so platform fallback fonts
  /// still render with a matching weight; the explicit `wght` variation wins
  /// for the variable font.
  static TextStyle style({
    required double size,
    required double lineHeight,
    required double weight,
    required double rond,
    double? opsz,
    double tracking = 0,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: lineHeight / size,
      letterSpacing: tracking,
      fontWeight: _nearestWeight(weight),
      fontVariations: [
        FontVariation.weight(weight),
        FontVariation.opticalSize(opsz ?? size),
        FontVariation('ROND', rond),
      ],
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static FontWeight _nearestWeight(double weight) {
    final index = ((weight / 100).round() - 1).clamp(0, 8);
    return FontWeight.values[index];
  }

  // ---- Styles from the design table -------------------------------------

  /// 44/48 · 620 · ROND 100 · tabular — countdown, widget clock.
  static final displayTime = style(
    size: 44,
    lineHeight: 48,
    weight: 620,
    rond: 100,
    opsz: 48,
    tracking: -0.5,
    tabular: true,
  );

  /// 32/40 · 650 · ROND 70 — screen title "Bugün".
  static final headlineLarge = style(
    size: 32,
    lineHeight: 40,
    weight: 650,
    rond: 70,
    tracking: -0.25,
  );

  /// 24/32 · 600 · ROND 50 — editor title, empty-state title.
  static final headlineSmall =
      style(size: 24, lineHeight: 32, weight: 600, rond: 50);

  /// 20/28 · 600 · ROND 30 — sheet title.
  static final titleLarge =
      style(size: 20, lineHeight: 28, weight: 600, rond: 30);

  /// 16/22 · 560 · ROND 20 — card title.
  static final titleMedium =
      style(size: 16, lineHeight: 22, weight: 560, rond: 20, tracking: 0.1);

  /// 16/24 · 400 · ROND 0 — input, description.
  static final bodyLarge =
      style(size: 16, lineHeight: 24, weight: 400, rond: 0, tracking: 0.1);

  /// 14/20 · 400 · ROND 0 — secondary text.
  static final bodyMedium =
      style(size: 14, lineHeight: 20, weight: 400, rond: 0, tracking: 0.15);

  /// 14/20 · 600 · ROND 30 — button, section header.
  static final labelLarge =
      style(size: 14, lineHeight: 20, weight: 600, rond: 30, tracking: 0.1);

  /// 12/16 · 600 · ROND 30 — card meta.
  static final labelMedium =
      style(size: 12, lineHeight: 16, weight: 600, rond: 30, tracking: 0.3);

  /// 11/16 · 650 · ROND 30 — pill, "SIRADAKİ" (minimum size).
  static final labelSmall =
      style(size: 11, lineHeight: 16, weight: 650, rond: 30, tracking: 0.5);

  /// 13/16 · 600 · ROND 60 · tabular — time ribbon hours.
  static final timeLabel = style(
    size: 13,
    lineHeight: 16,
    weight: 600,
    rond: 60,
    tabular: true,
  );

  // ---- Derived roles (not in the design table) ---------------------------
  // Material roles the design does not use; derived so every TextTheme slot is
  // on the Kor font instead of falling back to the platform default.

  static final displayLarge =
      style(size: 57, lineHeight: 64, weight: 600, rond: 100, opsz: 48);
  static final displayMedium =
      style(size: 45, lineHeight: 52, weight: 600, rond: 100, opsz: 48);
  static final displaySmall =
      style(size: 36, lineHeight: 44, weight: 620, rond: 80);
  static final headlineMedium =
      style(size: 28, lineHeight: 36, weight: 620, rond: 60);
  static final titleSmall =
      style(size: 14, lineHeight: 20, weight: 560, rond: 20, tracking: 0.1);
  static final bodySmall =
      style(size: 12, lineHeight: 16, weight: 400, rond: 0, tracking: 0.3);

  /// Full Material [TextTheme] (colourless).
  static final TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
