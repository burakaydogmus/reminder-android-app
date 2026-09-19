import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/subtasks_card.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Holds the list like the editor does and rebuilds the card on change.
class _Host extends StatefulWidget {
  const _Host({required this.initial, this.onComplete});

  final List<Subtask> initial;
  final VoidCallback? onComplete;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<Subtask> items = widget.initial;
  var _next = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SubtasksCard(
          subtasks: items,
          categoryId: 'market',
          newId: () => 'n${_next++}',
          onChanged: (next) => setState(() => items = next),
          onCompleteReminder: widget.onComplete,
        ),
      ),
    );
  }
}

List<Subtask> _items(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host)).items;

List<String> _titles(WidgetTester tester) =>
    [for (final s in _items(tester)) s.title];

Future<_HostState> _pumpCard(
  WidgetTester tester, {
  List<Subtask> initial = const [],
  VoidCallback? onComplete,
  ThemeData Function() theme = korLight,
}) async {
  final h = await UiHarness.create();
  await tester.pumpWidget(
    h.app(
      home: _Host(initial: initial, onComplete: onComplete),
      theme: theme,
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

ThemeData korLight() => korThemes.first.$2();

Future<void> _submitAdd(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(SubtasksCardKeys.addField));
  await tester.enterText(find.byKey(SubtasksCardKeys.addField), text);
  await tester.testTextInput.receiveAction(TextInputAction.next);
  await tester.pumpAndSettle();
}

Future<void> _rowMenu(WidgetTester tester, String id, String item) async {
  await tester.tap(find.byKey(SubtasksCardKeys.menu(id)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void _performCustomAction(SemanticsNode node, String label) {
  final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
        (id) => CustomSemanticsAction.getAction(id)!.label == label,
      );
  node.owner!.performAction(node.id, SemanticsAction.customAction, id);
}

List<String> _customActionLabels(SemanticsNode node) => [
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ?? const <int>[])
        CustomSemanticsAction.getAction(id)!.label ?? '',
    ];

void main() {
  for (final (themeName, theme) in korThemes) {
    group('SubtasksCard ($themeName)', () {
      testWidgets('Enter adds an item and keeps the add field focused',
          (tester) async {
        await _pumpCard(tester, theme: theme);
        expect(find.byKey(SubtasksCardKeys.progress), findsNothing);

        await _submitAdd(tester, '  Süt ');
        expect(_titles(tester), ['Süt']);
        final field = tester.widget<TextField>(
          find.byKey(SubtasksCardKeys.addField),
        );
        expect(field.controller!.text, isEmpty);
        expect(field.focusNode!.hasFocus, isTrue);

        await tester.enterText(find.byKey(SubtasksCardKeys.addField), 'Ekmek');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(_titles(tester), ['Süt', 'Ekmek']);
        expect(
          [for (final s in _items(tester)) s.position],
          [0, 1],
        );
        expect(find.text('0/2'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Empty input adds nothing.
        await _submitAdd(tester, '   ');
        expect(_items(tester), hasLength(2));
      });

      testWidgets('pasting several lines adds one item per line',
          (tester) async {
        await _pumpCard(tester, theme: theme);
        await tester.enterText(
          find.byKey(SubtasksCardKeys.addField),
          'Süt\n- Ekmek, tam buğday\n\n• Yumurta\n',
        );
        await tester.pumpAndSettle();
        expect(_titles(tester), ['Süt', 'Ekmek, tam buğday', 'Yumurta']);
        expect(
          tester
              .widget<TextField>(find.byKey(SubtasksCardKeys.addField))
              .controller!
              .text,
          isEmpty,
        );
      });

      testWidgets('"Maddelere böl" splits commas and " ve "', (tester) async {
        await _pumpCard(tester, theme: theme);
        await tester.enterText(
          find.byKey(SubtasksCardKeys.addField),
          'Tek madde',
        );
        await tester.pump();
        expect(find.byKey(SubtasksCardKeys.splitSuggestion), findsNothing);

        await tester.enterText(
          find.byKey(SubtasksCardKeys.addField),
          'süt, ekmek ve yumurta',
        );
        await tester.pump();
        expect(find.byTooltip('Maddelere böl'), findsOneWidget);
        await tester.tap(find.byKey(SubtasksCardKeys.splitSuggestion));
        await tester.pumpAndSettle();
        expect(_titles(tester), ['süt', 'ekmek', 'yumurta']);
      });

      testWidgets('toggling moves an item under "Tamamlanan N madde"',
          (tester) async {
        await _pumpCard(
          tester,
          initial: buildSubtasks(['Süt', 'Ekmek']),
          theme: theme,
        );
        expect(find.text('0/2'), findsOneWidget);

        await tester.tap(find.byKey(SubtasksCardKeys.check('s1')));
        await tester.pumpAndSettle();
        expect(_items(tester).first.isDone, isTrue);
        expect(find.text('1/2'), findsOneWidget);
        expect(find.text('Tamamlanan 1 madde'), findsOneWidget);
        // Collapsed by default.
        expect(find.byKey(SubtasksCardKeys.row('s1')), findsNothing);

        await tester.tap(find.byKey(SubtasksCardKeys.doneToggle));
        await tester.pumpAndSettle();
        expect(find.byKey(SubtasksCardKeys.row('s1')), findsOneWidget);

        // Unchecking brings it back to the open list.
        await tester.tap(find.byKey(SubtasksCardKeys.check('s1')));
        await tester.pumpAndSettle();
        expect(_items(tester).first.isDone, isFalse);
        expect(find.text('Tamamlanan 1 madde'), findsNothing);
      });

      testWidgets('titles are edited in place', (tester) async {
        await _pumpCard(
          tester,
          initial: buildSubtasks(['Süt']),
          theme: theme,
        );
        await tester.enterText(
          find.byKey(SubtasksCardKeys.field('s1')),
          'Tam yağlı süt',
        );
        await tester.pump();
        expect(_titles(tester), ['Tam yağlı süt']);

        // Pasting lines into an item inserts the rest after it.
        await tester.enterText(
          find.byKey(SubtasksCardKeys.field('s1')),
          'Süt\nKakao',
        );
        await tester.pumpAndSettle();
        expect(_titles(tester), ['Süt', 'Kakao']);
      });

      testWidgets('row menu moves and deletes (no swipe)', (tester) async {
        await _pumpCard(
          tester,
          initial: buildSubtasks(['A', 'B', 'C']),
          theme: theme,
        );
        await _rowMenu(tester, 's2', 'Yukarı taşı');
        expect(_titles(tester), ['B', 'A', 'C']);
        await _rowMenu(tester, 's2', 'Aşağı taşı');
        expect(_titles(tester), ['A', 'B', 'C']);
        await _rowMenu(tester, 's3', 'Sil');
        expect(_titles(tester), ['A', 'B']);
        expect(find.text('0/2'), findsOneWidget);

        // First item cannot move up.
        await tester.tap(find.byKey(SubtasksCardKeys.menu('s1')));
        await tester.pumpAndSettle();
        final up = tester.widget<PopupMenuItem<Object?>>(
          find.ancestor(
            of: find.text('Yukarı taşı'),
            matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
          ),
        );
        expect(up.enabled, isFalse);
      });

      testWidgets('dragging the handle reorders', (tester) async {
        await _pumpCard(
          tester,
          initial: buildSubtasks(['A', 'B', 'C']),
          theme: theme,
        );
        final handle = find.byKey(SubtasksCardKeys.handle('s1'));
        final rowHeight =
            tester.getSize(find.byKey(SubtasksCardKeys.row('s1'))).height;
        final gesture = await tester.startGesture(tester.getCenter(handle));
        await tester.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(Offset(0, rowHeight * 0.25));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(_titles(tester), ['B', 'C', 'A']);
      });

      testWidgets('all done: suggestion chip, nothing completed by itself',
          (tester) async {
        var completed = 0;
        await _pumpCard(
          tester,
          initial: buildSubtasks(['A', 'B'], done: {0}),
          onComplete: () => completed++,
          theme: theme,
        );
        expect(find.byKey(SubtasksCardKeys.completeSuggestion), findsNothing);

        await tester.tap(find.byKey(SubtasksCardKeys.check('s2')));
        await tester.pumpAndSettle();
        expect(
          find.text('Tümü tamam — hatırlatıcıyı tamamla?'),
          findsOneWidget,
        );
        expect(completed, 0);
        await tester.tap(find.byKey(SubtasksCardKeys.completeSuggestion));
        expect(completed, 1);
      });
    });
  }

  group('SubtasksCard accessibility', () {
    testWidgets('rows offer "Yukarı taşı / Aşağı taşı" semantics actions',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, initial: buildSubtasks(['A', 'B', 'C']));

      final middle =
          tester.getSemantics(find.byKey(SubtasksCardKeys.row('s2')));
      expect(
        _customActionLabels(middle),
        containsAll(['Yukarı taşı', 'Aşağı taşı']),
      );
      _performCustomAction(middle, 'Yukarı taşı');
      await tester.pumpAndSettle();
      expect(_titles(tester), ['B', 'A', 'C']);

      _performCustomAction(
        tester.getSemantics(find.byKey(SubtasksCardKeys.row('s1'))),
        'Aşağı taşı',
      );
      await tester.pumpAndSettle();
      expect(_titles(tester), ['B', 'C', 'A']);
      semantics.dispose();
    });

    testWidgets('toggle is a 48 dp checked node labelled with the title',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCard(tester, initial: buildSubtasks(['Süt'], done: {}));

      final check = find.byKey(SubtasksCardKeys.check('s1'));
      expect(tester.getSize(check), const Size.square(48));
      expect(
        tester.getSemantics(check),
        isSemantics(
          label: 'Süt',
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(SubtasksCardKeys.progress)).label,
        'maddeler: 0/1 tamamlandı',
      );
      expect(
        tester.getSize(find.byKey(SubtasksCardKeys.handle('s1'))),
        const Size.square(48),
      );
      semantics.dispose();
    });

    testWidgets('no overflow at 200 % text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final h = await UiHarness.create();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: h.app(
            home: _Host(
              initial: buildSubtasks(
                ['Uzun bir madde başlığı, iki satıra sarmalı', 'B'],
                done: {1},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SubtasksCardKeys.doneToggle));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Reminder editor with subtasks', () {
    final now = DateTime(2026, 9, 13, 12);

    Future<UiHarness> openEditor(WidgetTester tester, Reminder r) async {
      final h = await UiHarness.create(reminders: [r], now: () => now);
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReminderEditorSheet(
                  context,
                  existing: h.cubit.state.reminders.single,
                  now: () => now,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return h;
    }

    Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('Kaydet saves added, toggled and trimmed subtasks',
        (tester) async {
      final h = await openEditor(
        tester,
        buildReminder(title: 'Market', subtasks: buildSubtasks(['Süt'])),
      );
      await tapInSheet(tester, find.byKey(SubtasksCardKeys.check('s1')));
      await tester.ensureVisible(find.byKey(SubtasksCardKeys.addField));
      await tester.enterText(find.byKey(SubtasksCardKeys.addField), 'Ekmek');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      await tapInSheet(tester, find.byKey(ReminderEditorKeys.save));

      final saved = h.cubit.state.reminders.single;
      expect(saved.isDone, isFalse, reason: 'no auto-complete');
      expect([
        for (final s in saved.subtasks) (s.title, s.isDone)
      ], [
        ('Süt', true),
        ('Ekmek', false),
      ]);
      expect([for (final s in saved.subtasks) s.position], [0, 1]);
    });

    testWidgets('all-done chip completes the reminder with undo',
        (tester) async {
      final h = await openEditor(
        tester,
        buildReminder(
          title: 'Market',
          subtasks: buildSubtasks(['Süt', 'Ekmek'], done: {0}),
        ),
      );
      await tapInSheet(tester, find.byKey(SubtasksCardKeys.check('s2')));
      await tapInSheet(
        tester,
        find.byKey(SubtasksCardKeys.completeSuggestion),
      );

      final saved = h.cubit.state.reminders.single;
      expect(saved.isDone, isTrue);
      expect(saved.subtasks.every((s) => s.isDone), isTrue);
      expect(find.text('“Market” tamamlandı'), findsOneWidget);
      expect(find.byKey(ReminderEditorKeys.save), findsNothing);
    });

    testWidgets('recurring: the chip advances, resets items; undo restores',
        (tester) async {
      final h = await openEditor(
        tester,
        buildReminder(
          title: 'Market',
          remindAt: DateTime(2026, 9, 13, 18),
          recurrence: RecurrenceRule.daily(),
          subtasks: buildSubtasks(['Süt', 'Ekmek'], done: {0}),
        ),
      );
      await tapInSheet(tester, find.byKey(SubtasksCardKeys.check('s2')));
      await tapInSheet(
        tester,
        find.byKey(SubtasksCardKeys.completeSuggestion),
      );

      var saved = h.cubit.state.reminders.single;
      expect(saved.isDone, isFalse);
      expect(saved.remindAt, DateTime(2026, 9, 14, 18));
      expect(saved.subtasks.every((s) => !s.isDone), isTrue);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      saved = h.cubit.state.reminders.single;
      expect(saved.remindAt, DateTime(2026, 9, 13, 18));
      expect(saved.subtasks.every((s) => s.isDone), isTrue);
    });

    testWidgets('a done reminder gets no completion chip', (tester) async {
      await openEditor(
        tester,
        buildReminder(
          isDone: true,
          subtasks: buildSubtasks(['Süt'], done: {0}),
        ),
      );
      expect(find.byKey(SubtasksCardKeys.completeSuggestion), findsNothing);
    });
  });

  group('Cards show subtask progress', () {
    final now = DateTime(2026, 9, 13, 12);
    final market = buildReminder(
      title: 'Market',
      categoryId: 'market',
      subtasks: buildSubtasks(['A', 'B', 'C', 'D', 'E', 'F'], done: {0, 1}),
    );

    testWidgets('ReminderCard: "2/6", thin bar, spoken label', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await UiHarness.create(reminders: [market]);
      await tester.pumpWidget(
        h.app(home: Scaffold(body: ReminderCard(reminder: market, now: now))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2/6'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(2 / 6, 1e-9));
      expect(bar.minHeight, 3);
      expect(
        find.bySemanticsLabel(RegExp('maddeler: 2/6 tamamlandı')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('ReminderCard without subtasks is unchanged', (tester) async {
      final plain = buildReminder(title: 'Ekmek al');
      final h = await UiHarness.create(reminders: [plain]);
      await tester.pumpWidget(
        h.app(home: Scaffold(body: ReminderCard(reminder: plain, now: now))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('ReminderCompactCard default subtitle shows "2/6"',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await UiHarness.create(reminders: [market]);
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: ReminderCompactCard(reminder: market, now: now),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2/6'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('maddeler: 2/6 tamamlandı')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
