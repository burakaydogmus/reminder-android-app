import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../tokens/kor_palette.dart';

/// Resolved colours for one category key in the current brightness.
@immutable
class CategoryColors {
  const CategoryColors({
    required this.fg,
    required this.container,
    required this.onFg,
  });

  /// Icon, text and filled background.
  final Color fg;

  /// Tonal background.
  final Color container;

  /// Text/icon drawn on a filled [fg] background.
  final Color onFg;

  static CategoryColors lerp(CategoryColors a, CategoryColors b, double t) {
    return CategoryColors(
      fg: Color.lerp(a.fg, b.fg, t)!,
      container: Color.lerp(a.container, b.container, t)!,
      onFg: Color.lerp(a.onFg, b.onFg, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryColors &&
      other.fg == fg &&
      other.container == container &&
      other.onFg == onFg;

  @override
  int get hashCode => Object.hash(fg, container, onFg);
}

/// Kor colours that have no [ColorScheme] role: success, glass, the "now"
/// line and the category palette.
///
/// Read with `Theme.of(context).extension<KorColors>()!` or `context.korColors`.
@immutable
class KorColors extends ThemeExtension<KorColors> {
  const KorColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.glassTint,
    required this.glassStroke,
    required this.nowLine,
    required this.categories,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;

  /// iOS floating chrome tint (translucent).
  final Color glassTint;

  /// iOS floating chrome 1px stroke (translucent).
  final Color glassStroke;

  /// Time ribbon "now" line.
  final Color nowLine;

  /// Colours for every [KorColorKey].
  final Map<KorColorKey, CategoryColors> categories;

  /// Colours for a category [key].
  CategoryColors category(KorColorKey key) => categories[key]!;

  static final KorColors light = KorColors(
    success: KorPaletteLight.success,
    onSuccess: KorPaletteLight.onSuccess,
    successContainer: KorPaletteLight.successContainer,
    glassTint: KorPaletteLight.glassTint,
    glassStroke: KorPaletteLight.glassStroke,
    nowLine: KorPaletteLight.nowLine,
    categories: _resolve(
      KorCategoryPalette.light,
      KorPaletteLight.onCategory,
    ),
  );

  static final KorColors dark = KorColors(
    success: KorPaletteDark.success,
    onSuccess: KorPaletteDark.onSuccess,
    successContainer: KorPaletteDark.successContainer,
    glassTint: KorPaletteDark.glassTint,
    glassStroke: KorPaletteDark.glassStroke,
    nowLine: KorPaletteDark.nowLine,
    categories: _resolve(KorCategoryPalette.dark, KorPaletteDark.onCategory),
  );

  static Map<KorColorKey, CategoryColors> _resolve(
    Map<KorColorKey, KorCategoryTone> tones,
    Color onFg,
  ) {
    return Map.unmodifiable({
      for (final key in KorColorKey.values)
        key: CategoryColors(
          fg: tones[key]!.fg,
          container: tones[key]!.container,
          onFg: onFg,
        ),
    });
  }

  @override
  bool operator ==(Object other) =>
      other is KorColors &&
      other.success == success &&
      other.onSuccess == onSuccess &&
      other.successContainer == successContainer &&
      other.glassTint == glassTint &&
      other.glassStroke == glassStroke &&
      other.nowLine == nowLine &&
      mapEquals(other.categories, categories);

  @override
  int get hashCode => Object.hash(
        success,
        onSuccess,
        successContainer,
        glassTint,
        glassStroke,
        nowLine,
        Object.hashAll(KorColorKey.values.map((k) => categories[k])),
      );

  @override
  KorColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? glassTint,
    Color? glassStroke,
    Color? nowLine,
    Map<KorColorKey, CategoryColors>? categories,
  }) {
    return KorColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      glassTint: glassTint ?? this.glassTint,
      glassStroke: glassStroke ?? this.glassStroke,
      nowLine: nowLine ?? this.nowLine,
      categories: categories ?? this.categories,
    );
  }

  @override
  KorColors lerp(covariant ThemeExtension<KorColors>? other, double t) {
    if (other is! KorColors) return this;
    return KorColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t)!,
      nowLine: Color.lerp(nowLine, other.nowLine, t)!,
      categories: Map.unmodifiable({
        for (final key in KorColorKey.values)
          key: CategoryColors.lerp(
            category(key),
            other.category(key),
            t,
          ),
      }),
    );
  }
}

extension KorColorsContext on BuildContext {
  /// The [KorColors] of the nearest theme. Requires a theme built by
  /// `KorTheme`.
  KorColors get korColors => Theme.of(this).extension<KorColors>()!;
}
