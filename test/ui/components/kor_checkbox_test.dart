import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/components/kor_checkbox.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/haptics_store.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Records `HapticFeedback` calls on the platform channel.
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

/// A bare checkbox; counts taps (prepare) and commits.
class _Probe {
  int prepared = 0;
  int committed = 0;

  VoidCallback prepare() {
    prepared++;
    return () => committed++;
  }
}

Widget _host({
  required bool value,
  required _Probe probe,
  bool reduceMotion = false,
  bool show = true,
  HapticsStore? haptics,
}) {
  return MaterialApp(
    theme: KorTheme.light(),
    home: HapticsScope(
      store: haptics ?? HapticsStore.memory(),
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: show
                ? KorCheckbox(
                    value: value,
                    onToggle: probe.prepare,
                    color: const Color(0xFFB4441F),
                    onColor: const Color(0xFFFFFFFF),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('KorCheckbox sequence', () {
    testWidgets('commits after the 900 ms hold, haptic at 0 ms',
        (tester) async {
      final haptics = _recordHaptics(tester);
      final probe = _Probe();
      await tester.pumpWidget(_host(value: false, probe: probe));

      await tester.tap(find.byType(KorCheckbox));
      await tester.pump();
      expect(probe.prepared, 1);
      expect(probe.committed, 0);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);

      // Morph, fill and check finish by 300 ms; the row still holds.
      await tester.pump(KorCheckbox.sequence);
      expect(probe.committed, 0);
      await tester.pump(
        KorCheckbox.hold -
            KorCheckbox.sequence -
            const Duration(milliseconds: 1),
      );
      expect(probe.committed, 0);

      await tester.pump(const Duration(milliseconds: 1));
      expect(probe.committed, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('announces checked during the hold', (tester) async {
      final semantics = tester.ensureSemantics();
      final probe = _Probe();
      await tester.pumpWidget(_host(value: false, probe: probe));
      expect(
        tester.getSemantics(find.byType(KorCheckbox)),
        matchesSemantics(
          label: 'Tamamla',
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(KorCheckbox));
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(KorCheckbox)),
        matchesSemantics(
          label: 'Tamamla',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.pump(KorCheckbox.hold);
      await tester.pumpAndSettle();
      semantics.dispose();
    });

    testWidgets('a second tap during the hold cancels', (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_host(value: false, probe: probe));

      await tester.tap(find.byType(KorCheckbox));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(KorCheckbox));
      await tester.pump(KorCheckbox.hold);
      await tester.pumpAndSettle();
      expect(probe.prepared, 1);
      expect(probe.committed, 0);
    });

    testWidgets('disposing during the hold still commits', (tester) async {
      final probe = _Probe();
      await tester.pumpWidget(_host(value: false, probe: probe));
      await tester.tap(find.byType(KorCheckbox));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpWidget(_host(value: false, probe: probe, show: false));
      expect(probe.committed, 1);
      await tester.pump(KorCheckbox.hold);
      expect(probe.committed, 1);
    });

    testWidgets('Reduce Motion: commits at once, no press, 150 ms fade',
        (tester) async {
      final haptics = _recordHaptics(tester);
      final probe = _Probe();
      await tester.pumpWidget(
        _host(value: false, probe: probe, reduceMotion: true),
      );

      await tester.tap(find.byType(KorCheckbox));
      expect(probe.committed, 1);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      await tester.pump();
      final scale = tester.widget<Transform>(
        find.descendant(
          of: find.byType(KorCheckbox),
          matching: find.byType(Transform),
        ),
      );
      expect(scale.transform.entry(0, 0), 1);
      KorCheckboxPainter painter() => tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(KorCheckbox),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter! as KorCheckboxPainter;
      expect(painter().fadeOnly, isTrue);
      // The fade is done after reduceMotionFade (150 ms).
      await tester.pump(const Duration(milliseconds: 150));
      expect(painter().progress, 1);
    });

    testWidgets('un-checking commits at once without haptics', (tester) async {
      final haptics = _recordHaptics(tester);
      final probe = _Probe();
      await tester.pumpWidget(_host(value: true, probe: probe));
      await tester.tap(find.byType(KorCheckbox));
      expect(probe.committed, 1);
      expect(haptics, isEmpty);
    });

    testWidgets('haptics off: the sequence plays silently', (tester) async {
      final haptics = _recordHaptics(tester);
      final probe = _Probe();
      await tester.pumpWidget(
        _host(
          value: false,
          probe: probe,
          haptics: HapticsStore.memory(enabled: false),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(KorCheckbox));
      await tester.pump(KorCheckbox.hold);
      expect(probe.committed, 1);
      expect(haptics, isEmpty);
    });

    testWidgets('ring is painted around the shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KorTheme.light(),
          home: const Material(
            child: KorCheckbox(
              value: false,
              onToggle: null,
              color: Color(0xFFB4441F),
              onColor: Color(0xFFFFFFFF),
              ring: BorderSide(color: Color(0xFF0000FF), width: 2),
            ),
          ),
        ),
      );
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(KorCheckbox),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter! as KorCheckboxPainter;
      expect(painter.ring?.color, const Color(0xFF0000FF));
      // Ring + outline strokes.
      expect(
        find.byType(KorCheckbox),
        paints
          ..path(color: const Color(0xFF0000FF))
          ..path(color: const Color(0xFFB4441F)),
      );
    });
  });

  group('KorCheckboxPainter timeline', () {
    final painter = KorCheckboxPainter(
      progress: 0,
      fadeOnly: false,
      color: const Color(0xFF000000),
      onColor: const Color(0xFFFFFFFF),
      morphCurve: Curves.linear,
    );

    test('morph and fill run 0–240 ms, the check 120–300 ms', () {
      double at(int ms) => ms / KorCheckbox.sequence.inMilliseconds;
      expect(painter.morphAt(0), 0);
      expect(painter.morphAt(at(240)), 1);
      expect(painter.fillAt(at(240)), 1);
      expect(painter.checkAt(at(120)), 0);
      expect(painter.checkAt(at(200)), inExclusiveRange(0, 1));
      expect(painter.checkAt(at(300)), 1);
    });
  });

  group('ReminderCard completion', () {
    final now = DateTime(2026, 9, 13, 14, 32);
    DateTime clock() => now;
    List<Reminder> reminders() => [
          buildReminder(id: 'book', title: 'Kitabı iade et'),
          buildReminder(id: 'milk', title: 'Süt al'),
        ];

    Finder checkboxOf(String title) => find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(ReminderCard),
          ),
          matching: find.byType(KorCheckbox),
        );

    Reminder byId(UiHarness h, String id) =>
        h.cubit.state.reminders.firstWhere((r) => r.id == id);

    testWidgets('holds, completes, then Geri al reopens', (tester) async {
      final haptics = _recordHaptics(tester);
      final h = await UiHarness.create(reminders: reminders(), now: clock);
      await tester.pumpWidget(h.app(home: HomeShell(clock: clock)));
      await tester.pumpAndSettle();

      await tester.tap(checkboxOf('Kitabı iade et'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(byId(h, 'book').isDone, isFalse);
      expect(find.text('Geri al'), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(byId(h, 'book').isDone, isTrue);
      expect(find.textContaining('tamamlandı'), findsOneWidget);
      // One completion haptic (from the checkbox, not again from the action).
      expect(
        haptics.where((c) => c == 'HapticFeedbackType.mediumImpact'),
        hasLength(1),
      );

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(byId(h, 'book').isDone, isFalse);
      expect(haptics.last, 'HapticFeedbackType.lightImpact');
    });

    testWidgets('Reduce Motion completes immediately', (tester) async {
      final h = await UiHarness.create(reminders: reminders(), now: clock);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: h.app(home: HomeShell(clock: clock)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(checkboxOf('Süt al'));
      await tester.pump();
      expect(byId(h, 'milk').isDone, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('haptics off: completing and undo stay silent', (tester) async {
      final haptics = _recordHaptics(tester);
      final h = await UiHarness.create(reminders: reminders(), now: clock);
      await h.haptics.setEnabled(false);
      await tester.pumpWidget(h.app(home: HomeShell(clock: clock)));
      await tester.pumpAndSettle();

      await tester.tap(checkboxOf('Kitabı iade et'));
      await tester.pump(KorCheckbox.hold);
      await tester.pumpAndSettle();
      expect(byId(h, 'book').isDone, isTrue);
      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
    });
  });
}
