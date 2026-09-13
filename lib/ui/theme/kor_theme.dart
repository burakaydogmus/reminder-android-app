import 'package:flutter/material.dart';

import 'extensions/kor_colors_ext.dart';
import 'extensions/kor_motion_ext.dart';
import 'tokens/kor_color_scheme.dart';
import 'tokens/kor_palette.dart';
import 'tokens/kor_shapes.dart';
import 'tokens/kor_typography.dart';

/// Kor [ThemeData] builders.
///
/// Not used by the app yet: `AppTheme.light/dark` remain active until F4.1
/// wires `theme: KorTheme.light(), darkTheme: KorTheme.dark()` in `app.dart`.
/// Only component themes that are safe to define without the new widgets are
/// set here; F4.1 extends this as screens move over.
abstract final class KorTheme {
  static ThemeData light() => _build(
        scheme: KorColorScheme.light,
        background: KorPaletteLight.background,
        colors: KorColors.light,
      );

  static ThemeData dark() => _build(
        scheme: KorColorScheme.dark,
        background: KorPaletteDark.background,
        colors: KorColors.dark,
      );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required KorColors colors,
  }) {
    final textTheme = KorTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: KorTypography.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      extensions: <ThemeExtension<dynamic>>[colors, KorMotion.standard],
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.mdAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.smAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surfaceContainer,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: const Color(0x00000000),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.sheet),
      ),
    );
  }
}
