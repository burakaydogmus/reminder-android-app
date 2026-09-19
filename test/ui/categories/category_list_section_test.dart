import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/categories/category_list_section.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/lists/reminder_filter_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Listeler › Kategorilerim management (F4.3).
void main() {
  final gym = buildCategory(id: 'gym', name: 'Spor', position: 6);

  Future<UiHarness> pumpLists(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create(
      categories: [gym],
      reminders: [
        buildReminder(id: 'a', categoryId: 'gym'),
        buildReminder(id: 'b', categoryId: 'gym', isDone: true),
        buildReminder(id: 'c', categoryId: ReminderCategoryIds.market),
      ],
    );
    await tester.pumpWidget(h.app(home: const Scaffold(body: ListsPage())));
    await tester.pumpAndSettle();
    return h;
  }

  List<String> rowOrder(
      WidgetTester tester, Key Function(String) keyOf, UiHarness h) {
    final ids = [for (final c in h.cubit.state.categories.ordered) c.id];
    final positions = {
      for (final id in ids) id: tester.getTopLeft(find.byKey(keyOf(id))).dy,
    };
    return ids..sort((a, b) => positions[a]!.compareTo(positions[b]!));
  }

  testWidgets('lists every category in order with open counts', (tester) async {
    final handle = tester.ensureSemantics();
    final h = await pumpLists(tester);

    expect(rowOrder(tester, CategoryListKeys.row, h),
        [...ReminderCategoryIds.orderedIds, 'gym']);
    expect(
      tester.getSemantics(find.byKey(CategoryListKeys.row('gym'))),
      isSemantics(label: 'Spor, 1 açık', isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(
          find.byKey(CategoryListKeys.row(ReminderCategoryIds.market))),
      isSemantics(label: 'Market, 1 açık'),
    );
    handle.dispose();
  });

  testWidgets('a row opens the category list; user lists can be edited',
      (tester) async {
    final h = await pumpLists(tester);
    await tester.tap(find.byKey(CategoryListKeys.row('gym')));
    await tester.pumpAndSettle();

    expect(find.byType(ReminderFilterPage), findsOneWidget);
    expect(find.text('Spor'), findsOneWidget);
    expect(find.text('1 açık · 1 tamam'), findsOneWidget);

    await tester.tap(find.byTooltip('Kategoriyi düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Yoga');
    await tester.ensureVisible(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();
    expect(find.text('Yoga'), findsOneWidget);
    expect(h.cubit.state.categories.labelOf('gym'), 'Yoga');
  });

  testWidgets('deleting from the list page leaves it', (tester) async {
    final h = await pumpLists(tester);
    await tester.tap(find.byKey(CategoryListKeys.row('gym')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kategoriyi düzenle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CategoryEditorKeys.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CategoryEditorKeys.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(find.byType(ReminderFilterPage), findsNothing);
    expect(find.byKey(CategoryListKeys.row('gym')), findsNothing);
    expect(
        h.cubit.state.reminders.where((r) => r.categoryId == 'gym'), isEmpty);
  });

  testWidgets('built-in lists have no edit action', (tester) async {
    await pumpLists(tester);
    await tester
        .tap(find.byKey(CategoryListKeys.row(ReminderCategoryIds.work)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Kategoriyi düzenle'), findsNothing);
  });

  testWidgets('"Yeni kategori" creates a category at the end', (tester) async {
    final h = await pumpLists(tester);
    await tester.tap(find.byKey(CategoryListKeys.newCategory));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Bahçe');
    await tester.ensureVisible(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();

    final created = h.cubit.state.categories.ordered.last;
    expect(created.name, 'Bahçe');
    expect(find.byKey(CategoryListKeys.row(created.id)), findsOneWidget);
  });

  testWidgets('Düzenle: handles, edit buttons for user categories only',
      (tester) async {
    await pumpLists(tester);
    await tester.tap(find.byKey(CategoryListKeys.editToggle));
    await tester.pumpAndSettle();

    expect(find.text('Bitti'), findsOneWidget);
    for (final id in [...ReminderCategoryIds.orderedIds, 'gym']) {
      expect(find.byKey(CategoryListKeys.handle(id)), findsOneWidget);
      expect(tester.getSize(find.byKey(CategoryListKeys.handle(id))).height,
          greaterThanOrEqualTo(48));
    }
    expect(find.byTooltip('Spor düzenle'), findsOneWidget);
    expect(find.byTooltip('Market düzenle'), findsNothing);

    await tester.tap(find.byTooltip('Spor düzenle'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditorSheet), findsOneWidget);
  });

  testWidgets('Düzenle: "Yukarı taşı" semantics action reorders',
      (tester) async {
    final handle = tester.ensureSemantics();
    final h = await pumpLists(tester);
    await tester.tap(find.byKey(CategoryListKeys.editToggle));
    await tester.pumpAndSettle();

    final node =
        tester.getSemantics(find.byKey(CategoryListKeys.editRow('gym')));
    final actions = {
      for (final id in node.getSemanticsData().customSemanticsActionIds ?? [])
        CustomSemanticsAction.getAction(id)!.label: id,
    };
    expect(actions.keys, contains('Yukarı taşı'));

    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      actions['Yukarı taşı'],
    );
    await tester.pumpAndSettle();

    final ids = [for (final c in h.cubit.state.categories.ordered) c.id];
    expect(ids.indexOf('gym'), 5);
    expect(ids.last, ReminderCategoryIds.other);
    verify(() => h.repository.saveCategories(any())).called(1);
    expect(rowOrder(tester, CategoryListKeys.editRow, h), ids);
    handle.dispose();
  });
}
