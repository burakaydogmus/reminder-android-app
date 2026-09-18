import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/components/fade_through_indexed_stack.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

void main() {
  const motion = KorMotion.standard;

  group('KorSpring as duration + curve', () {
    test('settle times follow stiffness', () {
      final fast = motion.spatialFast.settleDuration;
      final slow = motion.spatialSlow.settleDuration;
      expect(fast.inMilliseconds, inInclusiveRange(200, 400));
      expect(slow.inMilliseconds, inInclusiveRange(350, 700));
      expect(slow, greaterThan(fast));
    });

    test('curve runs 0 → 1; spatial springs overshoot unless clamped', () {
      final curve = motion.spatialFast.curve();
      expect(curve.transform(0), 0);
      expect(curve.transform(1), 1);
      final samples = [for (var i = 1; i < 100; i++) curve.transform(i / 100)];
      expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(1));

      final clamped = motion.spatialFast.curve(clampOvershoot: true);
      for (var i = 1; i < 100; i++) {
        expect(clamped.transform(i / 100), lessThanOrEqualTo(1));
      }
    });

    test('effects springs never overshoot', () {
      final curve = motion.effectsSlow.curve();
      for (var i = 1; i < 100; i++) {
        expect(curve.transform(i / 100), lessThanOrEqualTo(1 + 1e-9));
      }
    });
  });

  group('sheetStyleOf', () {
    Future<AnimationStyle> styleIn(
      WidgetTester tester, {
      required bool reduceMotion,
    }) async {
      late AnimationStyle style;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Builder(
            builder: (context) {
              style = motion.sheetStyleOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return style;
    }

    testWidgets('spatialSlow spring on entrance', (tester) async {
      final style = await styleIn(tester, reduceMotion: false);
      expect(style.duration, motion.spatialSlow.settleDuration);
      expect(style.curve!.transform(0.5), inExclusiveRange(0.5, 1.0001));
    });

    testWidgets('Reduce Motion: 150 ms ease', (tester) async {
      final style = await styleIn(tester, reduceMotion: true);
      expect(style.duration, const Duration(milliseconds: 150));
      expect(style.reverseDuration, const Duration(milliseconds: 150));
      expect(style.curve, motion.fallbackCurve);
    });
  });

  group('FadeThroughIndexedStack', () {
    Widget host(int index, {bool reduceMotion = false}) => MaterialApp(
          theme: KorTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: FadeThroughIndexedStack(
              index: index,
              children: const [
                _Counter(key: ValueKey('a')),
                _Counter(key: ValueKey('b')),
              ],
            ),
          ),
        );

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(FadeThroughIndexedStack),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    double scale(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(FadeThroughIndexedStack),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .entry(0, 0);

    testWidgets('fades the new page in and keeps page state', (tester) async {
      await tester.pumpWidget(host(0));
      await tester.tap(find.text('0'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(host(1));
      expect(opacity(tester), 0);
      expect(scale(tester), FadeThroughIndexedStack.enterScale);
      await tester.pump(const Duration(milliseconds: 60));
      expect(opacity(tester), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
      expect(scale(tester), 1);

      await tester.pumpWidget(host(0));
      await tester.pumpAndSettle();
      // Page "a" kept its counter.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Reduce Motion: fade only, no scale', (tester) async {
      await tester.pumpWidget(host(0, reduceMotion: true));
      await tester.pumpWidget(host(1, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 30));
      expect(scale(tester), 1);
      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => _count++),
        child: Text('$_count'),
      );
}
