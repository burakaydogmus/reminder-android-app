import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../ui_harness.dart';

Widget _opener({Reminder? existing}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showReminderEditorSheet(context, existing: existing),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Reminder editor ($themeName)', () {
      testWidgets('title comes first and is focused', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final title = find.byKey(ReminderEditorKeys.title);
        expect(title, findsOneWidget);
        expect(tester.widget<TextField>(title).autofocus, isTrue);
        final editable = tester.widget<EditableText>(
          find.descendant(of: title, matching: find.byType(EditableText)),
        );
        expect(editable.focusNode.hasFocus, isTrue);

        final marketChip = find.widgetWithText(FilterChip, 'Market');
        expect(
          tester.getTopLeft(title).dy,
          lessThan(tester.getTopLeft(marketChip).dy),
        );
      });

      testWidgets('"Diğer" saves without a custom name', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(ReminderEditorKeys.title),
          'Kitabı iade et',
        );
        await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
        await tester.tap(find.byKey(ReminderEditorKeys.save));
        await tester.pumpAndSettle();

        final saved = h.cubit.state.reminders.single;
        expect(saved.title, 'Kitabı iade et');
        expect(saved.categoryId, ReminderCategoryIds.other);
        expect(saved.customCategoryLabel, isNull);
        expect(saved.categoryDisplayLabel, 'Diğer');
        verify(() => h.repository.saveReminders(any())).called(1);
        expect(find.byKey(ReminderEditorKeys.title), findsNothing);
      });

      testWidgets('empty title shows an inline error', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
        await tester.tap(find.byKey(ReminderEditorKeys.save));
        await tester.pumpAndSettle();

        expect(find.text('Başlık boş olamaz.'), findsOneWidget);
        expect(h.cubit.state.reminders, isEmpty);
      });
    });
  }

  testWidgets('location summary never shows coordinates', (tester) async {
    final h = await UiHarness.create();
    final existing = Reminder(
      id: 'loc',
      title: 'Market',
      isDone: false,
      createdAt: DateTime(2026, 9, 1),
      categoryId: ReminderCategoryIds.market,
      locationTriggerEnabled: true,
      locationLatitude: 41.0082,
      locationLongitude: 28.9784,
    );
    await tester.pumpWidget(h.app(home: _opener(existing: existing)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Seçilen konum · 150 m'), findsOneWidget);
    expect(find.textContaining('41.0'), findsNothing);
  });
}
