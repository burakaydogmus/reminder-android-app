import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show
        GlassAdaptiveScope,
        GlassContainer,
        GlassQuality,
        LiquidGlassSettings,
        LiquidOval,
        LiquidRoundedSuperellipse,
        LiquidShape;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';

enum KorGlassShape { capsule, circle }

/// Glass for iOS floating chrome only (`kor-design-proposal.md` §1 B4/B5,
/// §3.1 "Cam"): `liquid_glass_widgets` shader glass tinted with
/// `KorColors.glassTint` and a 1px `glassStroke`.
///
/// Renders solid `surfaceContainerHigh` with a 1px `outline` (2px with
/// `MediaQuery.highContrastOf`) instead when [prefersSolid]: iOS Reduce
/// Transparency, Increase Contrast or Low Power Mode ([A11yPrefs]), high
/// contrast, or a [GlassAdaptiveScope] that dropped to
/// [GlassQuality.minimal] (no shader support / slow frames).
class KorGlassSurface extends StatelessWidget {
  const KorGlassSurface({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.shape = KorGlassShape.capsule,
  });

  final double width;
  final double height;
  final KorGlassShape shape;
  final Widget child;

  static const glassKey = ValueKey('KorGlassSurface.glass');
  static const solidKey = ValueKey('KorGlassSurface.solid');

  /// Whether glass chrome under [context] should use the solid fallback.
  static bool prefersSolid(BuildContext context) {
    if (A11yPrefs.of(context).prefersSolid) return true;
    if (MediaQuery.highContrastOf(context)) return true;
    final adaptive = GlassAdaptiveScope.maybeOf(context);
    return adaptive?.effectiveQuality == GlassQuality.minimal;
  }

  OutlinedBorder _border(BorderSide side) => switch (shape) {
        KorGlassShape.capsule => StadiumBorder(side: side),
        KorGlassShape.circle => CircleBorder(side: side),
      };

  LiquidShape get _liquidShape => switch (shape) {
        KorGlassShape.capsule =>
          LiquidRoundedSuperellipse(borderRadius: height / 2),
        KorGlassShape.circle => const LiquidOval(),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (prefersSolid(context)) {
      final elevation = theme.brightness == Brightness.dark
          ? KorElevation.dark
          : KorElevation.light;
      return Container(
        key: solidKey,
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerHigh,
          shadows: elevation.level2,
          shape: _border(
            BorderSide(
              color: scheme.outline,
              width: MediaQuery.highContrastOf(context)
                  ? KorGlass.highContrastStrokeWidth
                  : KorGlass.strokeWidth,
            ),
          ),
        ),
        child: child,
      );
    }

    final colors = context.korColors;
    return GlassContainer(
      key: glassKey,
      width: width,
      height: height,
      shape: _liquidShape,
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        glassColor: colors.glassTint,
        blur: KorGlass.blurSigma,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: _border(
            BorderSide(color: colors.glassStroke, width: KorGlass.strokeWidth),
          ),
        ),
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
