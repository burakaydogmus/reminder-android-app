// E2E 7b/7 — applying a routine (F3.7) end to end on the device.
//
// The routine itself is saved through the cubit (its editor is a multi-sheet
// flow; driving it adds flake without adding platform coverage), but the
// **apply** is done the way a user does it: Listeler › Rutinlerim → the
// routine's row → "Uygula". What that produces is then checked against the
// real database and the real OS alarm list, which is the part no widget test
// can reach.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/ui/routines/routine_apply_sheet.dart';
import 'package:reminder/ui/routines/routine_list_section.dart';

import 'helpers/e2e.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('applying a routine creates real reminders and real alarms',
      (tester) async {
    await launchApp(tester);
    await reachToday(tester);
    final cubit = cubitOf(tester);

    const routineId = 'e2e-routine';
    final now = DateTime.now();
    final routine = Routine(
      id: routineId,
      name: 'Sabah rutini',
      createdAt: now,
      repeat: RecurrenceRule.daily(),
      items: [
        RoutineItem(
          id: 'step-timed',
          title: 'Vitamin al',
          // The routine repeats, so even when 07:30 is already past today the
          // notification is scheduled for the next occurrence (F3.1) — the
          // assertion below does not depend on the wall-clock time of the run.
          time: const RoutineTime(7, 30),
          categoryId: ReminderCategoryIds.health,
          position: 0,
        ),
        RoutineItem(
          id: 'step-untimed',
          title: 'Yatağı topla',
          categoryId: ReminderCategoryIds.home,
          position: 1,
        ),
      ],
    );
    await cubit.saveRoutine(routine);
    await pumpUntilTrue(
      tester,
      () => cubit.state.routines.any((r) => r.id == routineId),
      reason: 'for the routine to be stored',
    );

    // Listeler › Rutinlerim → the routine's row opens the apply sheet.
    await openLists(tester);
    final row = find.byKey(RoutineListKeys.row(routineId));
    await pumpUntil(tester, find.byType(RoutineListSection),
        reason: 'for the Rutinlerim section on Listeler');
    await tester.scrollUntilVisible(row, 200, maxScrolls: 30);
    await settle(tester);
    await tester.tap(row);
    await settle(tester);

    await pumpUntil(tester, find.byKey(RoutineApplyKeys.apply),
        reason: 'for the "Rutini uygula" sheet');
    await tester.tap(find.byKey(RoutineApplyKeys.apply));
    await settle(tester);

    // Two real reminders, both linked to the routine.
    await pumpUntilTrue(
      tester,
      () =>
          cubit.state.reminders.where((r) => r.routineId == routineId).length ==
          2,
      reason: 'for the routine to create two reminders, got '
          '${cubit.state.reminders.length}',
    );
    final created =
        cubit.state.reminders.where((r) => r.routineId == routineId).toList();
    expect(created.map((r) => r.title).toSet(),
        <String>{'Vitamin al', 'Yatağı topla'});
    final timed = created.singleWhere((r) => r.remindAt != null);
    expect(timed.title, 'Vitamin al');
    expect(timed.categoryId, ReminderCategoryIds.health);
    // A repeating routine hands its rule to the timed reminders it creates.
    expect(timed.recurrence.isNone, isFalse);
    expect(
        created.singleWhere((r) => r.remindAt == null).title, 'Yatağı topla');

    // They are in the real database…
    final repository = ReminderRepository();
    addTearDown(repository.close);
    final stored = await repository.loadReminders();
    expect(stored.where((r) => r.routineId == routineId), hasLength(2));
    expect(
      stored.singleWhere((r) => r.routineItemId == 'step-timed').remindAt,
      isNotNull,
    );
    expect(await reminderTitlesOnDisk(),
        containsAll(<String>['Vitamin al', 'Yatağı topla']));

    // …and the timed one is scheduled with the OS.
    await pumpUntilTrue(
      tester,
      () async =>
          (await pendingNotificationIds()).contains(timed.notificationId),
      reason: 'for the routine reminder ${timed.notificationId} to be '
          'scheduled with the OS',
    );
    expect(await pendingNotificationIds(), {timed.notificationId},
        reason: 'the untimed step must not schedule anything');

    expect(tester.takeException(), isNull);
  });
}
