import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/routines/routine_apply_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// "Rutini uygula" (F3.7): the day, the preview and the duplicate choices.
void main() {
  /// 26 September 2026 is a Saturday.
  final now = DateTime(2026, 9, 26, 6, 30);

  Routine morning({RecurrenceRule repeat = RecurrenceRule.none}) =>
      buildRoutine(
        repeat: repeat,
        items: [
          buildRoutineStep(
            id: 'sport',
            title: 'Spor',
            time: '07:00',
            categoryId: ReminderCategoryIds.health,
          ),
          buildRoutineStep(id: 'water', title: 'Su iç'),
        ],
      );

  Future<UiHarness> pumpSheet(
    WidgetTester tester, {
    required Routine routine,
    List<Reminder> reminders = const [],
    AppLanguage language = AppLanguage.turkish,
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var ids = 0;
    final h = await UiHarness.create(
      routines: [routine],
      reminders: reminders,
      now: () => now,
      newId: () => 'new${++ids}',
    );
    await tester.pumpWidget(h.app(
      language: language,
      home: NowScope(
        clock: () => now,
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showRoutineApplySheet(
                  context,
                  routine: routine,
                  now: () => now,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('previews the steps for today and applies them', (tester) async {
    final h = await pumpSheet(tester, routine: morning());

    expect(find.text('Sabah rutini'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.byKey(RoutineApplyKeys.step('sport')), findsOneWidget);
    expect(find.textContaining('07:00'), findsOneWidget);
    expect(find.textContaining('Saat yok'), findsOneWidget);
    expect(find.byKey(RoutineApplyKeys.warning), findsNothing);
    expect(find.byKey(RoutineApplyKeys.anyway), findsNothing);
    expect(find.text('Ekle'), findsOneWidget);

    await tester.tap(find.byKey(RoutineApplyKeys.apply));
    await tester.pumpAndSettle();

    expect(h.cubit.state.reminders.map((r) => r.title), ['Spor', 'Su iç']);
    expect(h.cubit.state.reminders.first.remindAt, DateTime(2026, 9, 26, 7));
    expect(h.cubit.state.reminders.last.remindAt, isNull);
    expect(find.text('2 hatırlatıcı eklendi'), findsOneWidget);
    verify(() => h.repository.saveReminders(any())).called(greaterThan(0));
  });

  testWidgets('another day can be picked with the date picker', (tester) async {
    final h = await pumpSheet(tester, routine: morning());

    await tester.tap(find.byKey(RoutineApplyKeys.day));
    await tester.pumpAndSettle();
    // The picker opens on today; pick the 28th.
    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün'), findsNothing);
    expect(find.text('28 Eylül'), findsOneWidget);

    await tester.tap(find.byKey(RoutineApplyKeys.apply));
    await tester.pumpAndSettle();
    expect(h.cubit.state.reminders.first.remindAt, DateTime(2026, 9, 28, 7));
    // A timeless step has no date at all, whichever day was chosen.
    expect(h.cubit.state.reminders.last.remindAt, isNull);
  });

  testWidgets('applying a one-off routine twice warns and adds only new steps',
      (tester) async {
    final h = await pumpSheet(
      tester,
      routine: morning(),
      reminders: [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7),
          categoryId: ReminderCategoryIds.health,
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ],
    );

    expect(find.byKey(RoutineApplyKeys.warning), findsOneWidget);
    expect(find.text('Bugün bu rutini zaten uyguladın'), findsOneWidget);
    expect(find.textContaining('zaten var'), findsWidgets);
    expect(find.text('Yalnızca yenileri ekle'), findsOneWidget);
    expect(find.byKey(RoutineApplyKeys.anyway), findsOneWidget);

    await tester.tap(find.byKey(RoutineApplyKeys.apply));
    await tester.pumpAndSettle();

    expect(h.cubit.state.reminders.map((r) => r.id), ['old', 'new1']);
    expect(h.cubit.state.reminders.map((r) => r.title), ['Spor', 'Su iç']);
    expect(find.text('1 hatırlatıcı eklendi'), findsOneWidget);
  });

  testWidgets('"Yine de hepsini ekle" duplicates on purpose', (tester) async {
    final h = await pumpSheet(
      tester,
      routine: morning(),
      reminders: [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7),
          categoryId: ReminderCategoryIds.health,
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ],
    );

    await tester.tap(find.byKey(RoutineApplyKeys.anyway));
    await tester.pumpAndSettle();

    expect(h.cubit.state.reminders, hasLength(3));
    expect(
      h.cubit.state.reminders.where((r) => r.title == 'Spor').length,
      2,
    );
  });

  testWidgets('a repeating routine offers to update its existing series',
      (tester) async {
    final routine = morning(repeat: RecurrenceRule.daily());
    final h = await pumpSheet(
      tester,
      routine: routine,
      reminders: [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7),
          categoryId: ReminderCategoryIds.health,
          recurrence: RecurrenceRule.daily(),
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ],
    );

    expect(find.text('Bu rutinin hatırlatıcıları zaten var'), findsOneWidget);
    expect(find.text('Hatırlatıcıları güncelle'), findsOneWidget);

    await tester.tap(find.byKey(RoutineApplyKeys.day));
    await tester.pumpAndSettle();
    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RoutineApplyKeys.apply));
    await tester.pumpAndSettle();

    // The series moved instead of a second one being created.
    final sport = h.cubit.state.reminders.firstWhere((r) => r.title == 'Spor');
    expect(sport.id, 'old');
    expect(sport.remindAt, DateTime(2026, 9, 27, 7));
    expect(sport.recurrence, RecurrenceRule.daily());
    expect(
        h.cubit.state.reminders.where((r) => r.title == 'Spor'), hasLength(1));
  });

  testWidgets('an empty routine cannot be applied', (tester) async {
    await pumpSheet(tester, routine: buildRoutine());

    expect(
        find.text('Bu rutinde adım yok. Önce bir adım ekle.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(RoutineApplyKeys.apply),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('everything already applied disables "Ekle"', (tester) async {
    await pumpSheet(
      tester,
      routine: buildRoutine(
        items: [buildRoutineStep(id: 'water', title: 'Su iç')],
      ),
      reminders: [
        buildReminder(
          id: 'old',
          title: 'Su iç',
          createdAt: now,
          routineId: 'morning',
          routineItemId: 'water',
        ),
      ],
    );

    final button = tester.widget<FilledButton>(
      find.byKey(RoutineApplyKeys.apply),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(RoutineApplyKeys.anyway), findsOneWidget);
  });

  testWidgets('English shows the same flow', (tester) async {
    await pumpSheet(
      tester,
      routine: morning(),
      language: AppLanguage.english,
      reminders: [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7),
          categoryId: ReminderCategoryIds.health,
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ],
    );

    expect(find.text('You already applied this routine today'), findsOneWidget);
    expect(find.text('Add only the new ones'), findsOneWidget);
    expect(find.text('Add them all anyway'), findsOneWidget);
  });
}
