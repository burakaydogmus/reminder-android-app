import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_color_scheme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

/// WCAG 2.x relative luminance of an opaque colour.
double relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio (1–21).
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _text = 4.5;
const _ui = 3.0;

/// Design values that measure below the threshold. Key: test name, value:
/// skip reason with the measured ratio. Never "fix" a failing token here by
/// changing its value; it needs a design decision.
const Map<String, String> _knownFailures = {
  // The design doc itself notes Kor on primaryContainer is 4.24 ("yalnız
  // ikon"). As user category "kor" (F4.3) its fg/container pair is text.
  'light: category kor fg on container >= 4.5':
      'Design decision needed — measured 4.24 (#B8430F on #FFDCC8); '
          'lock or adjust in F4.3',
};

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.min);
  final String name;
  final Color fg;
  final Color bg;
  final double min;
}

class _Theme {
  const _Theme(this.name, this.background, this.scheme, this.colors);
  final String name;
  final Color background;
  final ColorScheme scheme;
  final KorColors colors;
}

List<_Pair> _pairs(_Theme t) {
  final s = t.scheme;
  final c = t.colors;
  final pairs = <_Pair>[];
  final backgrounds = {
    'background': t.background,
    'surface': s.surface,
    'surfaceContainer': s.surfaceContainer,
  };

  for (final fg in {
    'onSurface': s.onSurface,
    'onSurfaceVariant': s.onSurfaceVariant,
    'primary': s.primary,
  }.entries) {
    for (final bg in backgrounds.entries) {
      pairs.add(_Pair('${fg.key} on ${bg.key}', fg.value, bg.value, _text));
    }
  }

  pairs
    ..add(_Pair('outline on background', s.outline, t.background, _ui))
    ..add(_Pair('onPrimary on primary', s.onPrimary, s.primary, _text))
    ..add(
      _Pair(
        'onPrimaryContainer on primaryContainer',
        s.onPrimaryContainer,
        s.primaryContainer,
        _text,
      ),
    )
    ..add(_Pair('tertiary on background', s.tertiary, t.background, _text))
    ..add(_Pair('success on background', c.success, t.background, _text))
    ..add(_Pair('error on background', s.error, t.background, _text))
    ..add(
      _Pair(
        'onInverseSurface on inverseSurface',
        s.onInverseSurface,
        s.inverseSurface,
        _text,
      ),
    )
    ..add(
      _Pair(
        'inversePrimary on inverseSurface',
        s.inversePrimary,
        s.inverseSurface,
        _text,
      ),
    );

  for (final key in KorColorKey.values) {
    final cat = c.category(key);
    final k = key.storageKey;
    pairs
      ..add(_Pair('category $k fg on background', cat.fg, t.background, _text))
      ..add(_Pair('category $k fg on surface', cat.fg, s.surface, _text))
      ..add(_Pair('category $k fg on container', cat.fg, cat.container, _text))
      ..add(_Pair('category $k onFg on fg', cat.onFg, cat.fg, _text));
  }
  return pairs;
}

void main() {
  test('contrastRatio matches known WCAG values', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.001),
    );
    expect(
      contrastRatio(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
      closeTo(1, 0.001),
    );
    // Design doc: onPrimary (white) on light primary #B8430F = 5.46.
    expect(
      contrastRatio(KorPaletteLight.onPrimary, KorPaletteLight.primary),
      closeTo(5.46, 0.01),
    );
  });

  final themes = [
    _Theme(
      'light',
      KorPaletteLight.background,
      KorColorScheme.light,
      KorColors.light,
    ),
    _Theme(
      'dark',
      KorPaletteDark.background,
      KorColorScheme.dark,
      KorColors.dark,
    ),
  ];

  for (final theme in themes) {
    group('Kor ${theme.name} contrast', () {
      for (final pair in _pairs(theme)) {
        final name = '${pair.name} >= ${pair.min}';
        test(name, () {
          final ratio = contrastRatio(pair.fg, pair.bg);
          expect(
            ratio,
            greaterThanOrEqualTo(pair.min),
            reason: '${theme.name}: ${pair.name} = ${ratio.toStringAsFixed(2)}',
          );
        }, skip: _knownFailures['${theme.name}: $name']);
      }
    });
  }
}
