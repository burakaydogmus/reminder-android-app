import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/components/strike_through_title.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';

/// Animated title strike-through (§3.5): the line is drawn from the start
/// edge when a reminder is completed, and not drawn at all under Reduce
/// Motion.
void main() {
  Widget host({required bool done, bool reduceMotion = false}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StrikeThroughTitle(
            done: done,
            builder: (context, struck) => Text(
              'Ekmek al',
              style: TextStyle(
                decoration: struck ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Decorations of every painted copy of the title, in paint order.
  List<TextDecoration?> decorations(WidgetTester tester) => [
        for (final t in tester.widgetList<Text>(find.text('Ekmek al')))
          t.style?.decoration,
      ];

  /// Revealed fraction of the struck copy, or null while it is not painted.
  double? reveal(WidgetTester tester) {
    final clips = tester.widgetList<ClipRect>(find.byType(ClipRect));
    for (final clip in clips) {
      final clipper = clip.clipper;
      if (clipper == null) continue;
      final rect = clipper.getClip(const Size(100, 20));
      return rect.width / 100;
    }
    return null;
  }

  testWidgets('an open title is painted once, without a line', (tester) async {
    await tester.pumpWidget(host(done: false));
    expect(decorations(tester), [null]);
    expect(find.byType(ClipRect), findsNothing);
  });

  testWidgets('a reminder that is already done starts fully struck',
      (tester) async {
    await tester.pumpWidget(host(done: true));
    expect(decorations(tester), [TextDecoration.lineThrough]);
    expect(find.byType(ClipRect), findsNothing);
  });

  testWidgets('completing draws the line from the start edge', (tester) async {
    await tester.pumpWidget(host(done: false));
    await tester.pumpWidget(host(done: true));
    // The first frame is still at 0; the reveal starts with the next one.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    // Both layers are painted while the reveal runs.
    expect(decorations(tester), [null, TextDecoration.lineThrough]);
    final start = reveal(tester)!;
    expect(start, greaterThanOrEqualTo(0));
    expect(start, lessThan(1));

    await tester.pump(const Duration(milliseconds: 60));
    final middle = reveal(tester)!;
    expect(middle, greaterThan(start));
    expect(middle, lessThan(1));

    // It settles within the §3.5 window (KorMotion.effectsDefault).
    await tester.pumpAndSettle();
    expect(decorations(tester), [TextDecoration.lineThrough]);
    expect(find.byType(ClipRect), findsNothing);
  });

  testWidgets('the reveal is no longer than the effectsDefault settle time',
      (tester) async {
    await tester.pumpWidget(host(done: false));
    await tester.pumpWidget(host(done: true));
    await tester.pump();
    await tester.pump(KorMotion.standard.effectsDefault.settleDuration);
    expect(decorations(tester), [TextDecoration.lineThrough]);
    // The whole animation fits in the spec's 120–300 ms window.
    expect(
      KorMotion.standard.effectsDefault.settleDuration,
      lessThanOrEqualTo(const Duration(milliseconds: 300)),
    );
  });

  testWidgets('re-opening wipes the line back', (tester) async {
    await tester.pumpWidget(host(done: true));
    await tester.pumpWidget(host(done: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(decorations(tester), [null, TextDecoration.lineThrough]);
    final first = reveal(tester)!;
    await tester.pump(const Duration(milliseconds: 60));
    expect(reveal(tester)!, lessThan(first));

    await tester.pumpAndSettle();
    expect(decorations(tester), [null]);
  });

  testWidgets('Reduce Motion: the final state is painted immediately',
      (tester) async {
    await tester.pumpWidget(host(done: false, reduceMotion: true));
    await tester.pumpWidget(host(done: true, reduceMotion: true));
    await tester.pump();

    // No second layer, no clip, no frames to settle.
    expect(decorations(tester), [TextDecoration.lineThrough]);
    expect(find.byType(ClipRect), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(host(done: false, reduceMotion: true));
    await tester.pump();
    expect(decorations(tester), [null]);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
