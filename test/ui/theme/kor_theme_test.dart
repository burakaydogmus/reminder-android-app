import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/theme/app_theme.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/theme/tokens/kor_color_scheme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_typography.dart';

void main() {
  group('KorTheme', () {
    for (final (name, build, scheme, colors) in [
      ('light', KorTheme.light, KorColorScheme.light, KorColors.light),
      ('dark', KorTheme.dark, KorColorScheme.dark, KorColors.dark),
    ]) {
      test('$name builds with M3, scheme and extensions', () {
        final theme = build();
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.brightness, scheme.brightness);
        expect(theme.extension<KorColors>(), colors);
        expect(theme.extension<KorMotion>(), isNotNull);
      });

      test('$name text styles use Google Sans Flex with variations', () {
        final textTheme = build().textTheme;
        final styles = [
          textTheme.displayLarge,
          textTheme.displayMedium,
          textTheme.displaySmall,
          textTheme.headlineLarge,
          textTheme.headlineMedium,
          textTheme.headlineSmall,
          textTheme.titleLarge,
          textTheme.titleMedium,
          textTheme.titleSmall,
          textTheme.bodyLarge,
          textTheme.bodyMedium,
          textTheme.bodySmall,
          textTheme.labelLarge,
          textTheme.labelMedium,
          textTheme.labelSmall,
        ];
        for (final style in styles) {
          expect(style?.fontFamily, KorTypography.fontFamily);
          expect(style?.color, scheme.onSurface);
          final axes = style!.fontVariations!.map((v) => v.axis).toSet();
          expect(axes, {'wght', 'opsz', 'ROND'});
        }
      });
    }

    testWidgets('extensions resolve through Theme.of(context)', (
      tester,
    ) async {
      late KorColors colors;
      late KorMotion motion;
      await tester.pumpWidget(
        MaterialApp(
          theme: KorTheme.light(),
          home: Builder(
            builder: (context) {
              colors = Theme.of(context).extension<KorColors>()!;
              motion = context.korMotion;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(colors, KorColors.light);
      expect(colors.nowLine, KorPaletteLight.nowLine);
      expect(motion.spatialDefault.stiffness, 380);
    });
  });

  test('AppTheme stays on the legacy look (no visual change)', () {
    expect(AppTheme.light.useMaterial3, isFalse);
    expect(AppTheme.dark.useMaterial3, isFalse);
    expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, 'Comfortaa');
    expect(AppTheme.light.extension<KorColors>(), isNull);
  });

  group('KorTypography', () {
    test('design table values', () {
      final title = KorTypography.titleMedium;
      expect(title.fontSize, 16);
      expect(title.height, 22 / 16);
      expect(
        title.fontVariations,
        containsAll(const [
          FontVariation('wght', 560),
          FontVariation('ROND', 20),
          FontVariation('opsz', 16),
        ]),
      );
    });

    test('time styles use tabular figures', () {
      for (final style in [
        KorTypography.displayTime,
        KorTypography.timeLabel,
      ]) {
        expect(
            style.fontFeatures, contains(const FontFeature.tabularFigures()));
        expect(style.fontFamily, KorTypography.fontFamily);
      }
      expect(
        KorTypography.displayTime.fontVariations,
        contains(const FontVariation('ROND', 100)),
      );
    });
  });

  group('KorColors', () {
    test('category resolves fg/container/onFg per brightness', () {
      final light = KorColors.light.category(KorColorKey.market);
      expect(light.fg, const Color(0xFF2E7031));
      expect(light.container, const Color(0xFFDDEFD9));
      expect(light.onFg, const Color(0xFFFFFFFF));

      final dark = KorColors.dark.category(KorColorKey.lacivert);
      expect(dark.fg, const Color(0xFFB6C0FF));
      expect(dark.onFg, const Color(0xFF14120F));

      for (final key in KorColorKey.values) {
        expect(KorColors.light.categories, contains(key));
        expect(KorColors.dark.categories, contains(key));
      }
    });

    test('lerp interpolates between light and dark', () {
      expect(KorColors.light.lerp(KorColors.dark, 0), KorColors.light);
      expect(KorColors.light.lerp(KorColors.dark, 1), KorColors.dark);

      final mid = KorColors.light.lerp(KorColors.dark, 0.5);
      expect(
        mid.nowLine,
        Color.lerp(KorPaletteLight.nowLine, KorPaletteDark.nowLine, 0.5),
      );
      expect(
        mid.category(KorColorKey.ev).fg,
        Color.lerp(
          KorColors.light.category(KorColorKey.ev).fg,
          KorColors.dark.category(KorColorKey.ev).fg,
          0.5,
        ),
      );
      expect(KorColors.light.lerp(null, 0.5), KorColors.light);
    });

    test('copyWith replaces only given fields', () {
      const red = Color(0xFFFF0000);
      final copy = KorColors.light.copyWith(nowLine: red);
      expect(copy.nowLine, red);
      expect(copy.success, KorColors.light.success);
      expect(copy.categories, KorColors.light.categories);
    });
  });

  group('KorColorKey', () {
    test('storage keys match kor-screens.json and round-trip', () {
      expect(KorColorKey.values.map((k) => k.storageKey), [
        'market',
        'ev',
        'is',
        'saglik',
        'gunluk',
        'diger',
        'dogumgunu',
        'kor',
        'lacivert',
        'zeytin',
        'kiremit',
        'arduvaz',
      ]);
      for (final key in KorColorKey.values) {
        expect(KorColorKey.tryParse(key.storageKey), key);
      }
      expect(KorColorKey.tryParse('unknown'), isNull);
      expect(KorColorKey.tryParse(null), isNull);
    });
  });

  group('KorMotion', () {
    const motion = KorMotion.standard;

    test('spring tokens build SpringDescriptions', () {
      final spring = motion.spatialFast.description;
      expect(spring.mass, 1);
      expect(spring.stiffness, 800);
      expect(motion.effectsDefault.dampingRatio, 1);
      expect(
        [motion.short, motion.medium, motion.long],
        const [
          Duration(milliseconds: 120),
          Duration(milliseconds: 240),
          Duration(milliseconds: 400),
        ],
      );
    });

    test('reduce motion turns spatial springs into a 150 ms fade', () {
      final reduced = motion.resolve(motion.spatialSlow, reduceMotion: true);
      expect(reduced.usesSpring, isFalse);
      expect(reduced.duration, const Duration(milliseconds: 150));

      final effects = motion.resolve(motion.effectsFast, reduceMotion: true);
      expect(effects.usesSpring, isTrue);

      final normal = motion.resolve(motion.spatialSlow, reduceMotion: false);
      expect(normal.usesSpring, isTrue);
    });

    testWidgets('resolveOf reads MediaQuery.disableAnimations', (
      tester,
    ) async {
      late KorMotionSpec spec;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              spec = motion.resolveOf(context, motion.spatialDefault);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(spec.usesSpring, isFalse);
    });
  });

  test('CookieShapeBorder morphs from a circle', () {
    const cookie = CookieShapeBorder();
    final start = cookie.lerpFrom(const CircleBorder(), 0) as CookieShapeBorder;
    final end = cookie.lerpFrom(const CircleBorder(), 1) as CookieShapeBorder;
    expect(start.depth, 0);
    expect(end.depth, CookieShapeBorder.defaultDepth);

    final path = cookie.getOuterPath(const Rect.fromLTWH(0, 0, 26, 26));
    final bounds = path.getBounds();
    expect(bounds.width, lessThanOrEqualTo(26.001));
    expect(bounds.height, greaterThan(20));
  });
}
