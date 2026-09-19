import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Reminder editor category chips and search filter with user categories
/// (F4.3).
void main() {
  final now = DateTime(2026, 9, 13, 14, 32);
  DateTime clock() => now;
  final gym = buildCategory(id: 'gym', name: 'Spor', colorKey: 'kor');

  Future<UiHarness> openEditor(
    WidgetTester tester, {
    Reminder? existing,
    List<Reminder> reminders = const [],
  }) async {
    final h = await UiHarness.create(
      categories: [gym],
      reminders: reminders,
      now: clock,
    );
    await tester.pumpWidget(h.app(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showReminderEditorSheet(
                context,
                existing: existing,
                now: clock,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return h;
  }

  Finder chipOf(String id) => find.descendant(
        of: find.byKey(ReminderEditorKeys.category(id)),
        matching: find.byType(FilterChip),
      );

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('chips list every category in order, then "+ Yeni"',
      (tester) async {
    await openEditor(tester);
    final ids = [...ReminderCategoryIds.orderedIds, 'gym'];
    final xs = [
      for (final id in ids)
        tester.getTopLeft(find.byKey(ReminderEditorKeys.category(id))).dx,
    ];
    expect([...xs]..sort(), xs);
    expect(
      tester.getTopLeft(find.byKey(ReminderEditorKeys.newCategory)).dx,
      greaterThan(xs.last),
    );
    // The pre-F4.3 "Özel ad" field is gone, also for Diğer.
    expect(find.text('Özel ad (isteğe bağlı)'), findsNothing);
  });

  testWidgets('a user category is saved as the reminder category',
      (tester) async {
    final h = await openEditor(tester);
    await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Koşu');
    await tapKey(tester, ReminderEditorKeys.category('gym'));
    await tapKey(tester, ReminderEditorKeys.save);
    expect(h.cubit.state.reminders.single.categoryId, 'gym');
    expect(h.cubit.state.reminders.single.customCategoryLabel, isNull);
  });

  testWidgets('selected chip: container fill, onContainer text, fg icon',
      (tester) async {
    await openEditor(tester);
    await tapKey(tester, ReminderEditorKeys.category('gym'));
    final chip = tester.widget<FilterChip>(chipOf('gym'));
    final colors = tester
        .element(find.byKey(ReminderEditorKeys.category('gym')))
        .korColors
        .category(KorColorKey.kor);
    expect(chip.selected, isTrue);
    expect(chip.selectedColor, colors.container);
    expect(chip.labelStyle?.color, colors.onContainer);
    expect((chip.avatar! as Icon).color, colors.fg);
    // Light "kor": fg text would fail on its container.
    expect(colors.onContainer, isNot(colors.fg));
  });

  testWidgets('"+ Yeni" creates a category and selects it', (tester) async {
    final h = await openEditor(tester);
    await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Sula');
    await tapKey(tester, ReminderEditorKeys.newCategory);
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Bahçe');
    await tapKey(tester, CategoryEditorKeys.save);

    final created = h.cubit.state.categories.ordered.last;
    expect(created.name, 'Bahçe');
    expect(
      tester.widget<FilterChip>(chipOf(created.id)).selected,
      isTrue,
    );
    await tapKey(tester, ReminderEditorKeys.save);
    expect(h.cubit.state.reminders.single.categoryId, created.id);
  });

  testWidgets('the legacy label survives only an unchanged category',
      (tester) async {
    final legacy = buildReminder(
      id: 'r1',
      title: 'Eski',
      categoryId: 'gym',
      customCategoryLabel: 'Spor',
    );
    final h = await openEditor(tester, existing: legacy, reminders: [legacy]);
    await tapKey(tester, ReminderEditorKeys.save);
    expect(h.cubit.state.reminders.single.customCategoryLabel, 'Spor');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tapKey(
        tester, ReminderEditorKeys.category(ReminderCategoryIds.other));
    await tapKey(tester, ReminderEditorKeys.save);
    // Opened with the original `existing`, so the label is dropped.
    expect(
        h.cubit.state.reminders.single.categoryId, ReminderCategoryIds.other);
    expect(h.cubit.state.reminders.single.customCategoryLabel, isNull);
  });

  testWidgets('search: user categories in the filter and in matching',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create(
      categories: [gym],
      reminders: [
        buildReminder(id: 'a', title: 'Koşu', categoryId: 'gym'),
        buildReminder(id: 'b', title: 'Koşu ayakkabısı al'),
      ],
      now: clock,
    );
    await tester.pumpWidget(h.app(home: const SearchPage()));
    await tester.pumpAndSettle();

    // The category name is searchable.
    await tester.enterText(find.byKey(SearchPageKeys.field), 'spor');
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 1'), findsOneWidget);

    await tester.enterText(find.byKey(SearchPageKeys.field), 'koşu');
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 2'), findsOneWidget);

    await tester.tap(find.byKey(SearchPageKeys.categoryChip));
    await tester.pumpAndSettle();
    expect(find.text('Spor'), findsWidgets);
    await tester.tap(find.widgetWithText(ListTile, 'Spor'));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SearchPageKeys.categoryChip),
        matching: find.text('Spor'),
      ),
      findsOneWidget,
    );
  });
}
