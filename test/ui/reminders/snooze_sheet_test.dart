import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';
import 'package:reminder/ui/reminders/snooze_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

class _Result {
  DateTime? value;
  bool closed = false;
}

Widget _opener(Reminder reminder, DateTime Function() clock, _Result result) =>
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              result
                ..value = null
                ..closed = false;
              result.value = await showSnoozeSheet(
                context,
                reminder: reminder,
                now: clock,
              );
              result.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapOk(WidgetTester tester, Type dialog) async {
  final ok = MaterialLocalizations.of(
    tester.element(find.byType(dialog)),
  ).okButtonLabel;
  await tester.tap(find.text(ok));
  await tester.pumpAndSettle();
}

void main() {
  final reminder = buildReminder(
    title: "Ali'yi kurstan al",
    remindAt: DateTime(2026, 9, 13, 16),
  );

  for (final (themeName, theme) in korThemes) {
    group('Snooze sheet ($themeName)', () {
      testWidgets('each option returns its time', (tester) async {
        final now = DateTime(2026, 9, 13, 14, 32);
        final result = _Result();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: _opener(reminder, () => now, result), theme: theme),
        );

        final expected = {
          SnoozeKind.tenMinutes: DateTime(2026, 9, 13, 14, 42),
          SnoozeKind.oneHour: DateTime(2026, 9, 13, 15, 32),
          SnoozeKind.evening: DateTime(2026, 9, 13, 20),
          SnoozeKind.tomorrowMorning: DateTime(2026, 9, 14, 9),
        };
        for (final MapEntry(key: kind, value: at) in expected.entries) {
          await _open(tester);
          expect(find.text('Ertele'), findsOneWidget);
          expect(find.text("Ali'yi kurstan al"), findsOneWidget);
          await tester.tap(find.byKey(SnoozeSheetKeys.option(kind)));
          await tester.pumpAndSettle();
          expect(result.closed, isTrue, reason: kind.name);
          expect(result.value, at, reason: kind.name);
        }
      });

      testWidgets('after 20:00 offers Yarın akşam', (tester) async {
        final now = DateTime(2026, 9, 13, 21, 15);
        final result = _Result();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: _opener(reminder, () => now, result), theme: theme),
        );
        await _open(tester);

        expect(find.text('Bu akşam'), findsNothing);
        expect(find.text('Yarın akşam'), findsOneWidget);
        expect(find.text('Pzt 20:00'), findsOneWidget);
        await tester
            .tap(find.byKey(SnoozeSheetKeys.option(SnoozeKind.evening)));
        await tester.pumpAndSettle();
        expect(result.value, DateTime(2026, 9, 14, 20));
      });

      testWidgets('options are labelled buttons with 48 dp targets',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final now = DateTime(2026, 9, 13, 14, 32);
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: _opener(reminder, () => now, _Result()), theme: theme),
        );
        await _open(tester);

        expect(
          find.bySemanticsLabel('10 dakika, bugün saat 14:42'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Yarın sabah, yarın saat 09:00'),
          findsOneWidget,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });
    });
  }

  group('Snooze sheet custom date', () {
    testWidgets('a future date and time is returned', (tester) async {
      final now = DateTime(2026, 9, 13, 14, 32);
      final result = _Result();
      final h = await UiHarness.create();
      await tester
          .pumpWidget(h.app(home: _opener(reminder, () => now, result)));
      await _open(tester);

      await tester.tap(find.byKey(SnoozeSheetKeys.custom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await _tapOk(tester, DatePickerDialog);
      // Time picker starts at the reminder's future time (16:00).
      await _tapOk(tester, TimePickerDialog);

      expect(result.value, DateTime(2026, 9, 15, 16));
    });

    testWidgets('a past time keeps the sheet open with an error',
        (tester) async {
      final now = DateTime(2026, 9, 13, 14, 32);
      final result = _Result();
      final h = await UiHarness.create();
      final overdue = buildReminder(remindAt: DateTime(2026, 9, 12, 9));
      await tester.pumpWidget(h.app(home: _opener(overdue, () => now, result)));
      await _open(tester);

      await tester.tap(find.byKey(SnoozeSheetKeys.custom));
      await tester.pumpAndSettle();
      await _tapOk(tester, DatePickerDialog); // today
      await _tapOk(tester, TimePickerDialog); // 14:32 = now → not after now

      expect(result.closed, isFalse);
      expect(find.byKey(SnoozeSheetKeys.pastError), findsOneWidget);
      expect(find.text('Bu saat geçti. Daha ileri bir zaman seç.'),
          findsOneWidget);
    });
  });
}
