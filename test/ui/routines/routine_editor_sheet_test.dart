import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/ui/routines/routine_editor_sheet.dart';
import 'package:reminder/ui/routines/routine_step_sheet.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// The routine editor and its step sheet (F3.7).
void main() {
  final morning = buildRoutine(
    items: [
      buildRoutineStep(id: 'sport', title: 'Spor', time: '07:00'),
      buildRoutineStep(id: 'water', title: 'Su iç'),
    ],
  );

  Future<UiHarness> pumpEditor(
    WidgetTester tester, {
    Routine? existing,
    List<Routine> routines = const [],
    String Function()? newId,
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create(
      routines: routines,
      now: () => DateTime(2026, 9, 26, 6, 30),
    );
    await tester.pumpWidget(h.app(
      home: Scaffold(
        body: RoutineEditorSheet(existing: existing, newId: newId),
      ),
    ));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('creates a routine with a name, colour, icon and a step',
      (tester) async {
    var ids = 0;
    final h = await pumpEditor(tester, newId: () => 'id${++ids}');

    await tester.enterText(
      find.byKey(RoutineEditorKeys.name),
      '  Sabah   rutini ',
    );
    await tester.tap(find.byKey(RoutineEditorKeys.swatch(KorColorKey.kor)));
    await tester
        .tap(find.byKey(RoutineEditorKeys.icon(CategoryIconKeys.heart)));
    await tester.pumpAndSettle();

    // Add a step through the step sheet.
    await tester.tap(find.byKey(RoutineEditorKeys.addStep));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineStepSheet), findsOneWidget);
    await tester.enterText(find.byKey(RoutineStepKeys.title), 'Spor');
    await tester.tap(find.byKey(RoutineStepKeys.timeSwitch));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(RoutineStepKeys.category(ReminderCategoryIds.health)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineStepKeys.save));
    await tester.pumpAndSettle();

    expect(find.text('Spor'), findsWidgets);
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    final saved = h.cubit.state.routines.single;
    expect(saved.name, 'Sabah rutini');
    expect(saved.colorKey, KorColorKey.kor.storageKey);
    expect(saved.iconKey, CategoryIconKeys.heart);
    expect(saved.repeat, RecurrenceRule.none);
    expect(saved.items.single.title, 'Spor');
    expect(saved.items.single.categoryId, ReminderCategoryIds.health);
    // "Saat ver" without picking one uses the sheet's default hour.
    expect(saved.items.single.time, RoutineStepSheet.defaultTime);
    verify(() => h.repository.saveRoutines(any())).called(1);
  });

  testWidgets('a step keeps its priority and subtasks', (tester) async {
    var ids = 0;
    final h = await pumpEditor(tester, newId: () => 'id${++ids}');

    await tester.enterText(find.byKey(RoutineEditorKeys.name), 'Sabah');
    await tester.tap(find.byKey(RoutineEditorKeys.addStep));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RoutineStepKeys.title), 'Vitamin');
    await tester.tap(find.text('Yüksek'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('subtasks.add')), 'D vitamini');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineStepKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    final step = h.cubit.state.routines.single.items.single;
    expect(step.priority, ReminderPriority.high);
    expect(step.subtasks.map((s) => s.title), ['D vitamini']);
    expect(step.subtasks.single.isDone, isFalse);
  });

  testWidgets('a name is required and must be unique', (tester) async {
    final h = await pumpEditor(tester, routines: [morning]);

    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();
    expect(find.text('Bir ad yaz'), findsOneWidget);
    expect(h.cubit.state.routines, hasLength(1));

    // Case and Turkish diacritics are ignored.
    await tester.enterText(find.byKey(RoutineEditorKeys.name), 'SABAH RUTINI');
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();
    expect(find.text('Bu adda bir rutin var'), findsOneWidget);
    expect(h.cubit.state.routines, hasLength(1));
  });

  testWidgets('the repeat row offers off / daily / chosen days',
      (tester) async {
    final h = await pumpEditor(tester, existing: morning, routines: [morning]);

    expect(find.text('Otomatik uygula'), findsOneWidget);
    expect(find.text('Günler'), findsNothing);

    await tester.tap(find.text('Her gün'));
    await tester.pumpAndSettle();
    expect(find.text('Günler'), findsNothing);
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();
    expect(h.cubit.state.routines.single.repeat, RecurrenceRule.daily());
  });

  testWidgets('chosen days writes a weekly rule', (tester) async {
    final h = await pumpEditor(tester, existing: morning, routines: [morning]);

    await tester.tap(find.text('Seçili günler'));
    await tester.pumpAndSettle();
    expect(find.text('Günler'), findsOneWidget);

    await tester.tap(find.byKey(RoutineEditorKeys.weekday(DateTime.monday)));
    await tester.tap(find.byKey(RoutineEditorKeys.weekday(DateTime.wednesday)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    expect(
      h.cubit.state.routines.single.repeat,
      RecurrenceRule.weekly(const [DateTime.monday, DateTime.wednesday]),
    );
  });

  testWidgets('an existing repeat is shown and can be turned off',
      (tester) async {
    final daily = buildRoutine(
      repeat: RecurrenceRule.daily(),
      items: [buildRoutineStep(id: 'sport', title: 'Spor', time: '07:00')],
    );
    final h = await pumpEditor(tester, existing: daily, routines: [daily]);

    expect(find.text('Her gün'), findsWidgets);
    await tester.tap(find.text('Yok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    expect(h.cubit.state.routines.single.repeat, RecurrenceRule.none);
  });

  testWidgets('steps can be reordered and deleted from the row menu',
      (tester) async {
    final h = await pumpEditor(tester, existing: morning, routines: [morning]);

    await tester.tap(find.byKey(RoutineEditorKeys.stepMenu('water')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yukarı taşı').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RoutineEditorKeys.stepMenu('sport')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil').last);
    await tester.pumpAndSettle();
    expect(find.byKey(RoutineEditorKeys.step('sport')), findsNothing);

    // Nothing is stored before "Kaydet".
    expect(h.cubit.state.routines.single.items, hasLength(2));
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();
    expect(h.cubit.state.routines.single.items.map((i) => i.id), ['water']);
    expect(h.cubit.state.routines.single.items.single.position, 0);
  });

  testWidgets('tapping a step edits it in place', (tester) async {
    final h = await pumpEditor(tester, existing: morning, routines: [morning]);

    await tester.tap(find.byKey(RoutineEditorKeys.step('sport')));
    await tester.pumpAndSettle();
    expect(find.text('Adımı düzenle'), findsOneWidget);
    await tester.enterText(find.byKey(RoutineStepKeys.title), 'Yüzme');
    await tester.tap(find.byKey(RoutineStepKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    final items = h.cubit.state.routines.single.items;
    expect(items.map((i) => i.title), ['Yüzme', 'Su iç']);
    // The id and position survive an edit, so the routine link stays valid.
    expect(items.first.id, 'sport');
    expect(items.first.position, 0);
  });

  testWidgets('a step without a time is kept timeless', (tester) async {
    final h = await pumpEditor(tester, existing: morning, routines: [morning]);

    await tester.tap(find.byKey(RoutineEditorKeys.step('sport')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineStepKeys.timeSwitch));
    await tester.pumpAndSettle();
    expect(find.byKey(RoutineStepKeys.timeChip), findsNothing);
    await tester.tap(find.byKey(RoutineStepKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RoutineEditorKeys.save));
    await tester.pumpAndSettle();

    expect(h.cubit.state.routines.single.items.first.time, isNull);
  });

  testWidgets('the empty routine shows the step hint and no Sil',
      (tester) async {
    await pumpEditor(tester);

    expect(find.text('Henüz adım yok. Rutin neyi oluştursun?'), findsOneWidget);
    expect(find.byKey(RoutineEditorKeys.delete), findsNothing);
  });

  testWidgets('Sil confirms and keeps the reminders the routine created',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create(
      routines: [morning],
      reminders: [
        buildReminder(
          id: 'r1',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7),
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ],
      now: () => DateTime(2026, 9, 26, 6, 30),
    );
    await tester.pumpWidget(h.app(
      home: Scaffold(body: RoutineEditorSheet(existing: morning)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RoutineEditorKeys.delete));
    await tester.pumpAndSettle();
    expect(find.text('“Sabah rutini” silinsin mi?'), findsOneWidget);
    expect(
      find.text(
          'Rutin silinir; bu rutinden oluşturduğun hatırlatıcılar kalır.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(h.cubit.state.routines, isEmpty);
    expect(h.cubit.state.reminders.single.id, 'r1');
  });

  group('Hatırlatıcılara uygula (F3.7 follow-up)', () {
    Future<UiHarness> pumpWithReminder(
      WidgetTester tester, {
      List<Reminder>? reminders,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await UiHarness.create(
        routines: [morning],
        reminders: reminders ??
            [
              buildReminder(
                id: 'r1',
                title: 'Spor',
                note: 'kendi notum',
                pinned: true,
                isDone: true,
                remindAt: DateTime(2026, 9, 19, 7),
                subtasks: buildSubtasks(['Isınma', 'Koşu'], done: {0}),
                routineId: 'morning',
                routineItemId: 'sport',
              ),
            ],
        now: () => DateTime(2026, 9, 26, 6, 30),
      );
      // Opened as a real modal sheet over a host page, so the pop after the
      // action returns to a page whose ScaffoldMessenger shows the snackbar.
      await tester.pumpWidget(h.app(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showRoutineEditorSheet(context, existing: morning),
              child: const Text('Aç'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets(
        'the action is hidden for a new routine and for one with no '
        'reminders', (tester) async {
      await pumpEditor(tester);
      expect(find.byKey(RoutineEditorKeys.refreshReminders), findsNothing);

      await pumpEditor(tester, existing: morning, routines: [morning]);
      expect(find.byKey(RoutineEditorKeys.refreshReminders), findsNothing);
    });

    testWidgets('it says how many reminders exist and asks for confirmation',
        (tester) async {
      final h = await pumpWithReminder(tester);
      expect(find.byKey(RoutineEditorKeys.refreshReminders), findsOneWidget);
      expect(
        find.textContaining('Bu rutinden oluşturulmuş 1 hatırlatıcı var'),
        findsOneWidget,
      );

      // Rename the step through the step sheet, then push it.
      await tester.tap(find.byKey(RoutineEditorKeys.step('sport')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(RoutineStepKeys.title), 'Sabah sporu');
      await tester.tap(find.byKey(RoutineStepKeys.save));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RoutineEditorKeys.refreshReminders));
      await tester.pumpAndSettle();
      expect(find.text('Hatırlatıcılar güncellensin mi?'), findsOneWidget);
      expect(find.textContaining('1 hatırlatıcının başlığı'), findsOneWidget);

      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      final updated = h.cubit.state.reminders.single;
      expect(updated.id, 'r1', reason: 'the same reminder, not a new one');
      expect(updated.title, 'Sabah sporu');
      // The edit itself is saved too.
      expect(
        h.cubit.state.routines.single.items.first.title,
        'Sabah sporu',
      );
      // Nothing of the user's own is touched.
      expect(updated.isDone, isTrue);
      expect(updated.note, 'kendi notum');
      expect(updated.pinned, isTrue);
      expect(updated.subtasks.map((t) => t.isDone), [true, false]);
      expect(updated.remindAt, DateTime(2026, 9, 19, 7),
          reason: 'the day and the unchanged time stay');
      expect(find.textContaining('1 hatırlatıcı güncellendi'), findsOneWidget);
    });

    testWidgets('cancelling changes neither the routine nor the reminders',
        (tester) async {
      final h = await pumpWithReminder(tester);
      await tester.tap(find.byKey(RoutineEditorKeys.step('sport')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(RoutineStepKeys.title), 'Sabah sporu');
      await tester.tap(find.byKey(RoutineStepKeys.save));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RoutineEditorKeys.refreshReminders));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(h.cubit.state.reminders.single.title, 'Spor');
      expect(h.cubit.state.routines.single.items.first.title, 'Spor');
    });

    testWidgets('nothing to change says so instead of asking', (tester) async {
      final h = await pumpWithReminder(tester);
      await tester.tap(find.byKey(RoutineEditorKeys.refreshReminders));
      await tester.pumpAndSettle();

      expect(find.text('Hatırlatıcılar güncellensin mi?'), findsNothing);
      expect(
        find.text('Hatırlatıcılar zaten rutinle aynı'),
        findsOneWidget,
      );
      expect(h.cubit.state.reminders.single.title, 'Spor');
    });
  });
}
