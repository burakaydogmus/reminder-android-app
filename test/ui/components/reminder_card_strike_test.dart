import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/components/kor_checkbox.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/components/strike_through_title.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// The cards draw the §3.5 strike-through instead of switching styles.
void main() {
  final now = DateTime(2026, 9, 13, 14, 30);
  final reminder = buildReminder(id: 'r1', title: 'Ekmek al');

  /// The card, rebuilt from cubit state so a completion is reflected.
  Widget card({required bool compact}) {
    return Scaffold(
      body: BlocBuilder<ReminderCubit, ReminderState>(
        builder: (context, state) {
          final current = state.reminders.firstWhere((r) => r.id == 'r1');
          return compact
              ? ReminderCompactCard(reminder: current, now: now)
              : ReminderCard(reminder: current, now: now);
        },
      ),
    );
  }

  /// Whether each painted copy of the title carries the line, in paint
  /// order (the theme writes `TextDecoration.none` on the open style).
  List<bool> struckLayers(WidgetTester tester) => [
        for (final t in tester.widgetList<Text>(find.text('Ekmek al')))
          t.style?.decoration == TextDecoration.lineThrough,
      ];

  for (final compact in [false, true]) {
    final name = compact ? 'ReminderCompactCard' : 'ReminderCard';

    testWidgets('$name draws the line when the reminder is completed',
        (tester) async {
      final h = await UiHarness.create(reminders: [reminder]);
      await tester.pumpWidget(h.app(home: card(compact: compact)));
      await tester.pumpAndSettle();

      expect(find.byType(StrikeThroughTitle), findsOneWidget);
      expect(struckLayers(tester), [false]);

      await tester.tap(find.byType(KorCheckbox));
      // The completion commits after the checkbox hold (F4.7).
      await tester.pump(KorCheckbox.hold);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // Mid-reveal: the struck copy is clipped over the open one.
      expect(struckLayers(tester), [false, true]);

      await tester.pumpAndSettle();
      expect(struckLayers(tester), [true]);
    });
  }
}
