import 'package:material_ui/material_ui.dart';

import 'extensions/kor_colors_ext.dart';
import 'extensions/kor_motion_ext.dart';
import 'tokens/kor_color_scheme.dart';
import 'tokens/kor_palette.dart';
import 'tokens/kor_shapes.dart';
import 'tokens/kor_spacing.dart';
import 'tokens/kor_typography.dart';

/// Kor [ThemeData] builders, wired in `app.dart`
/// (`theme: KorTheme.light(), darkTheme: KorTheme.dark()`).
///
/// Component themes live here so widgets only pick roles and text styles;
/// no widget sets raw colours or font sizes.
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

  static const _transparent = Color(0x00000000);

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required KorColors colors,
  }) {
    final textTheme = KorTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    const minTouch = Size(KorSizes.minTouch, KorSizes.minTouch);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: KorTypography.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[colors, KorMotion.standard],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: _transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
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
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.smAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minTouch),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(KorSizes.minTouch, 56),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minTouch,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minTouch,
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minTouch),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.lgAll),
        largeSizeConstraints: const BoxConstraints.tightFor(
          width: KorSizes.fabLarge,
          height: KorSizes.fabLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: const OutlineInputBorder(
          borderRadius: KorRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: KorRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KorRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: KorRadius.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: _transparent,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: _transparent,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.mdAll),
        textStyle: textTheme.bodyLarge,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: 6,
        borderRadius: KorRadius.fullAll,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHigh,
        thumbColor: scheme.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: _transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
        surfaceTintColor: _transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.sheet),
      ),
    );
  }
}
