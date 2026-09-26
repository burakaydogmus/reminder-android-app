import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/routines/routine_apply_sheet.dart';
import 'package:reminder/ui/routines/routine_editor_sheet.dart';
import 'package:reminder/ui/routines/routine_list_section.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Listeler › Rutinlerim (F3.7).
void main() {
  final morning = buildRoutine(
    items: [
      buildRoutineStep(id: 'sport', title: 'Spor', time: '07:00'),
      buildRoutineStep(id: 'water', title: 'Su iç'),
    ],
  );
  final evening = buildRoutine(
    id: 'evening',
    name: 'Akşam rutini',
    position: 1,
    repeat: RecurrenceRule.daily(),
    items: [buildRoutineStep(id: 'book', title: 'Kitap oku', time: '22:00')],
  );

  Future<UiHarness> pumpLists(
    WidgetTester tester, {
    List<dynamic> routines = const [],
    AppLanguage language = AppLanguage.turkish,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create(
      routines: [...routines.cast()],
      now: () => DateTime(2026, 9, 26, 6, 30),
    );
    await tester.pumpWidget(h.app(
      home: const Scaffold(body: ListsPage()),
      language: language,
    ));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('shows the empty state and no Düzenle button', (tester) async {
    await pumpLists(tester);

    expect(find.text('Rutinlerim'), findsOneWidget);
    expect(find.byKey(RoutineListKeys.empty), findsOneWidget);
    expect(find.text('Henüz rutin yok'), findsOneWidget);
    expect(find.byKey(RoutineListKeys.editToggle), findsNothing);
    expect(find.byKey(RoutineListKeys.newRoutine), findsOneWidget);
  });

  testWidgets('lists routines with their step count and repeat summary',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLists(tester, routines: [morning, evening]);

    expect(find.byKey(RoutineListKeys.empty), findsNothing);
    expect(find.text('Sabah rutini'), findsOneWidget);
    expect(find.text('2 adım'), findsOneWidget);
    expect(find.text('1 adım · Her gün'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(RoutineListKeys.row('morning'))),
      isSemantics(
        label: 'Sabah rutini, 2 adım',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('English keeps the same row shape', (tester) async {
    await pumpLists(
      tester,
      routines: [morning, evening],
      language: AppLanguage.english,
    );

    expect(find.text('My routines'), findsOneWidget);
    expect(find.text('2 steps'), findsOneWidget);
    expect(find.text('1 step · Every day'), findsOneWidget);
  });

  testWidgets('a row opens the apply sheet', (tester) async {
    await pumpLists(tester, routines: [morning]);

    await tester.tap(find.byKey(RoutineListKeys.row('morning')));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineApplySheet), findsOneWidget);
    expect(find.byKey(RoutineApplyKeys.apply), findsOneWidget);
  });

  testWidgets('"+ Yeni rutin" opens the editor', (tester) async {
    await pumpLists(tester);

    await tester.tap(find.byKey(RoutineListKeys.newRoutine));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineEditorSheet), findsOneWidget);
    expect(find.text('Yeni rutin'), findsWidgets);
  });

  testWidgets('Düzenle shows handles and opens the editor', (tester) async {
    await pumpLists(tester, routines: [morning, evening]);

    await tester.tap(find.byKey(RoutineListKeys.editToggle));
    await tester.pumpAndSettle();
    expect(find.text('Bitti'), findsWidgets);
    for (final id in ['morning', 'evening']) {
      expect(find.byKey(RoutineListKeys.editRow(id)), findsOneWidget);
      expect(
        tester.getSize(find.byKey(RoutineListKeys.handle(id))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(find.byTooltip('Sabah rutini rutinini düzenle'), findsOneWidget);

    await tester.tap(find.byTooltip('Sabah rutini rutinini düzenle'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineEditorSheet), findsOneWidget);
  });

  testWidgets('Düzenle: the "Yukarı taşı" semantics action reorders',
      (tester) async {
    final handle = tester.ensureSemantics();
    final h = await pumpLists(tester, routines: [morning, evening]);
    await tester.tap(find.byKey(RoutineListKeys.editToggle));
    await tester.pumpAndSettle();

    final node =
        tester.getSemantics(find.byKey(RoutineListKeys.editRow('evening')));
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

    expect(h.cubit.state.routines.map((r) => r.id), ['evening', 'morning']);
    expect(h.cubit.state.routines.map((r) => r.position), [0, 1]);
    handle.dispose();
  });
}
