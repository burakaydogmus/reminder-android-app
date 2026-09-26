import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/routine_apply.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

/// Routines in `ReminderCubit` (F3.7): the list itself and the apply path,
/// which goes through the normal `_persistAndSync` (repository +
/// `ScheduleSync.syncAll`).
void main() {
  late MockReminderRepository repository;
  late MockNotificationService notifications;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;

  final now = DateTime(2026, 9, 26, 6, 30);
  final today = DateTime(2026, 9, 26);

  setUpAll(registerModelFallbackValues);

  Routine morning({
    RecurrenceRule repeat = RecurrenceRule.none,
    List<RoutineItem>? items,
  }) =>
      buildRoutine(
        repeat: repeat,
        items: items ??
            [
              buildRoutineStep(
                id: 'sport',
                title: 'Spor',
                time: '07:00',
                categoryId: ReminderCategoryIds.health,
                priority: ReminderPriority.medium,
              ),
              buildRoutineStep(id: 'water', title: 'Su iç'),
            ],
      );

  ReminderCubit build({
    List<Routine> routines = const [],
    List<Reminder> reminders = const [],
  }) {
    when(() => repository.loadReminders()).thenAnswer((_) async => reminders);
    when(() => repository.loadRoutines()).thenAnswer((_) async => routines);
    var ids = 0;
    return ReminderCubit(
      repository,
      notifications,
      geofence: geofence,
      homeWidget: homeWidget,
      now: () => now,
      newId: () => 'new${++ids}',
    );
  }

  setUp(() {
    repository = MockReminderRepository();
    notifications = MockNotificationService();
    geofence = MockGeofenceSync();
    homeWidget = MockHomeWidgetSync();
    stubRepositoryWrites(repository);
    stubNotificationService(notifications);
    stubGeofenceSync(geofence);
    stubHomeWidgetSync(homeWidget);
    when(() => repository.loadReminders()).thenAnswer((_) async => []);
    when(() => repository.loadBirthdays()).thenAnswer((_) async => []);
    when(() => repository.loadSettings())
        .thenAnswer((_) async => const AppSettings());
  });

  group('loading', () {
    blocTest<ReminderCubit, ReminderState>(
      'load reads routines in position order',
      build: () => build(routines: [
        buildRoutine(id: 'b', name: 'Akşam', position: 5),
        buildRoutine(id: 'a', name: 'Sabah', position: 1),
      ]),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.routines.map((r) => r.id), ['a', 'b']);
        expect(cubit.state.routines.map((r) => r.position), [0, 1]);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'the state starts without routines',
      build: build,
      verify: (cubit) => expect(cubit.state.routines, isEmpty),
    );

    blocTest<ReminderCubit, ReminderState>(
      'load keeps the same list object when nothing changed',
      build: () => build(routines: [buildRoutine()]),
      act: (cubit) async {
        await cubit.load();
        final first = cubit.state.routines;
        await cubit.load();
        expect(cubit.state.routines, same(first));
      },
    );
  });

  group('editing', () {
    blocTest<ReminderCubit, ReminderState>(
      'saveRoutine appends a new routine and saves the list',
      build: build,
      act: (cubit) => cubit.saveRoutine(morning()),
      verify: (cubit) {
        expect(cubit.state.routines.single.name, 'Sabah rutini');
        verify(() => repository.saveRoutines(any(
              that: isA<List<Routine>>().having((l) => l.length, 'length', 1),
            ))).called(1);
        // Routines alone never touch reminders or schedules.
        verifyNever(() => repository.saveReminders(any()));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'saveRoutine updates an existing routine in place',
      build: () => build(routines: [
        buildRoutine(id: 'a', name: 'Sabah'),
        buildRoutine(id: 'b', name: 'Akşam', position: 1),
      ]),
      act: (cubit) async {
        await cubit.load();
        await cubit.saveRoutine(buildRoutine(id: 'a', name: 'Sabah sporu'));
      },
      verify: (cubit) {
        expect(
            cubit.state.routines.map((r) => r.name), ['Sabah sporu', 'Akşam']);
        expect(cubit.state.routines.map((r) => r.position), [0, 1]);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'saveRoutine with no change emits nothing',
      build: () => build(routines: [buildRoutine()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        await cubit.saveRoutine(cubit.state.routines.single);
      },
      verify: (_) => verifyNever(() => repository.saveRoutines(any())),
    );

    blocTest<ReminderCubit, ReminderState>(
      'deleteRoutine removes it and leaves its reminders alone',
      build: () => build(
        routines: [morning()],
        reminders: [
          buildReminder(
            id: 'r1',
            title: 'Spor',
            remindAt: DateTime(2026, 9, 26, 7),
            routineId: 'morning',
            routineItemId: 'sport',
          ),
        ],
      ),
      act: (cubit) async {
        await cubit.load();
        await cubit.deleteRoutine('morning');
      },
      verify: (cubit) {
        expect(cubit.state.routines, isEmpty);
        expect(cubit.state.reminders.single.id, 'r1');
        expect(cubit.state.reminders.single.routineId, 'morning');
        verify(() => repository.saveRoutines(const [])).called(1);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'deleteRoutine with an unknown id does nothing',
      build: () => build(routines: [buildRoutine()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        await cubit.deleteRoutine('yok');
      },
      verify: (cubit) {
        expect(cubit.state.routines, hasLength(1));
        verifyNever(() => repository.saveRoutines(any()));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'moveRoutine and reorderRoutines renumber the list',
      build: () => build(routines: [
        buildRoutine(id: 'a', name: 'Sabah'),
        buildRoutine(id: 'b', name: 'Akşam', position: 1),
        buildRoutine(id: 'c', name: 'Hafta sonu', position: 2),
      ]),
      act: (cubit) async {
        await cubit.load();
        await cubit.moveRoutine(2, 0);
        expect(cubit.state.routines.map((r) => r.id), ['c', 'a', 'b']);
        await cubit.reorderRoutines(['b', 'a']);
      },
      verify: (cubit) {
        // Ids left out keep their order at the end; unknown ids are ignored.
        expect(cubit.state.routines.map((r) => r.id), ['b', 'a', 'c']);
        expect(cubit.state.routines.map((r) => r.position), [0, 1, 2]);
      },
    );
  });

  group('applyRoutine', () {
    blocTest<ReminderCubit, ReminderState>(
      'creates the reminders and syncs through the normal path',
      build: () => build(routines: [morning()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        clearInteractions(notifications);
        clearInteractions(homeWidget);
        final outcome = await cubit.applyRoutine(
          cubit.state.routines.single,
          date: today,
        );
        expect(outcome.created, hasLength(2));
        expect(outcome.updated, isEmpty);
      },
      verify: (cubit) {
        expect(cubit.state.reminders.map((r) => r.title), ['Spor', 'Su iç']);
        final sport = cubit.state.reminders.first;
        expect(sport.remindAt, DateTime(2026, 9, 26, 7));
        expect(sport.routineId, 'morning');
        expect(sport.routineItemId, 'sport');
        expect(sport.id, 'new1');
        expect(cubit.state.reminders.last.remindAt, isNull);
        // The normal save + sync path (notifications, geofences, widget).
        verify(() => repository.saveReminders(any())).called(1);
        verify(() => repository.saveBirthdays(any())).called(1);
        verify(() => notifications.syncSchedules(
              reminders: any(named: 'reminders'),
              birthdays: any(named: 'birthdays'),
              notificationsEnabled: any(named: 'notificationsEnabled'),
            )).called(1);
        verify(() => homeWidget.sync(
              any(),
              birthdays: any(named: 'birthdays'),
              notificationsEnabled: any(named: 'notificationsEnabled'),
              categories: any(named: 'categories'),
            )).called(1);
        // Applying never writes the routines themselves.
        verifyNever(() => repository.saveRoutines(any()));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'a repeating routine creates recurring reminders',
      build: () => build(routines: [morning(repeat: RecurrenceRule.daily())]),
      act: (cubit) async {
        await cubit.load();
        await cubit.applyRoutine(cubit.state.routines.single, date: today);
      },
      verify: (cubit) {
        final sport =
            cubit.state.reminders.firstWhere((r) => r.title == 'Spor');
        expect(sport.recurrence, RecurrenceRule.daily());
        expect(sport.isRecurring, isTrue);
        final water = cubit.state.reminders.firstWhere(
          (r) => r.title == 'Su iç',
        );
        expect(water.recurrence, RecurrenceRule.none);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'applying twice on the same day adds nothing by default',
      build: () => build(routines: [morning()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.applyRoutine(cubit.state.routines.single, date: today);
        final outcome = await cubit.applyRoutine(
          cubit.state.routines.single,
          date: today,
        );
        expect(outcome.isEmpty, isTrue);
        expect(outcome.skipped, 2);
      },
      verify: (cubit) => expect(cubit.state.reminders, hasLength(2)),
    );

    blocTest<ReminderCubit, ReminderState>(
      'addAll applies again on purpose',
      build: () => build(routines: [morning()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.applyRoutine(cubit.state.routines.single, date: today);
        await cubit.applyRoutine(
          cubit.state.routines.single,
          date: today,
          mode: RoutineApplyMode.addAll,
        );
      },
      verify: (cubit) => expect(cubit.state.reminders, hasLength(4)),
    );

    blocTest<ReminderCubit, ReminderState>(
      'replaceExisting moves the existing series instead of adding one',
      build: () => build(routines: [morning(repeat: RecurrenceRule.daily())]),
      act: (cubit) async {
        await cubit.load();
        await cubit.applyRoutine(cubit.state.routines.single, date: today);
        final outcome = await cubit.applyRoutine(
          cubit.state.routines.single,
          date: DateTime(2026, 9, 27),
          mode: RoutineApplyMode.replaceExisting,
        );
        // Both linked reminders (the series and the timeless one) move.
        expect(outcome.updated, hasLength(2));
        expect(outcome.created, isEmpty);
      },
      verify: (cubit) {
        expect(cubit.state.reminders, hasLength(2));
        final sport =
            cubit.state.reminders.firstWhere((r) => r.title == 'Spor');
        expect(sport.remindAt, DateTime(2026, 9, 27, 7));
        expect(sport.id, 'new1');
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'an empty routine changes nothing',
      build: () => build(routines: [buildRoutine()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        final outcome = await cubit.applyRoutine(
          cubit.state.routines.single,
          date: today,
        );
        expect(outcome.isEmpty, isTrue);
      },
      verify: (cubit) {
        expect(cubit.state.reminders, isEmpty);
        verifyNever(() => repository.saveReminders(any()));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'planRoutine reports what an apply would do',
      build: () => build(routines: [morning()]),
      act: (cubit) async {
        await cubit.load();
        final routine = cubit.state.routines.single;
        expect(cubit.planRoutine(routine, date: today).hasDuplicates, isFalse);
        await cubit.applyRoutine(routine, date: today);
        final plan = cubit.planRoutine(routine, date: today);
        expect(plan.hasDuplicates, isTrue);
        expect(plan.hasLinked, isTrue);
        expect(plan.newEntries, isEmpty);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'clearAllData resets the routines too',
      build: () => build(routines: [morning()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.clearAllData();
      },
      verify: (cubit) => expect(cubit.state.routines, isEmpty),
    );
  });

  group('refreshRoutineReminders', () {
    /// A reminder the routine created a week ago, with the user's own fields.
    Reminder sportReminder() => buildReminder(
          id: 'sport-1',
          title: 'Spor',
          note: 'kendi notum',
          pinned: true,
          isDone: true,
          remindAt: DateTime(2026, 9, 19, 7),
          categoryId: ReminderCategoryIds.health,
          priority: ReminderPriority.medium,
          subtasks: buildSubtasks(['Isınma', 'Koşu'], done: {0}),
          routineId: 'morning',
          routineItemId: 'sport',
        );

    Routine edited() => morning(items: [
          buildRoutineStep(
            id: 'sport',
            title: 'Sabah sporu',
            time: '08:15',
            categoryId: ReminderCategoryIds.work,
            priority: ReminderPriority.high,
          ),
          buildRoutineStep(id: 'water', title: 'Su iç'),
        ]);

    blocTest<ReminderCubit, ReminderState>(
      'pushes the routine fields and syncs once through the normal path',
      build: () => build(routines: [edited()], reminders: [sportReminder()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        clearInteractions(notifications);
        clearInteractions(homeWidget);
        clearInteractions(geofence);
        expect(
          await cubit.refreshRoutineReminders(cubit.state.routines.single),
          1,
        );
      },
      verify: (cubit) {
        final sport = cubit.state.reminders.single;
        expect(sport.id, 'sport-1');
        expect(sport.title, 'Sabah sporu');
        expect(sport.categoryId, ReminderCategoryIds.work);
        expect(sport.priority, ReminderPriority.high);
        // The reminder's own day, the routine's time.
        expect(sport.remindAt, DateTime(2026, 9, 19, 8, 15));
        // Nothing of the user's is touched.
        expect(sport.isDone, isTrue);
        expect(sport.note, 'kendi notum');
        expect(sport.pinned, isTrue);
        expect(sport.subtasks.map((t) => t.isDone), [true, false]);

        // One save, and notifications/geofence/widget synced exactly once.
        verify(() => repository.saveReminders(any())).called(1);
        verify(() => notifications.syncSchedules(
              reminders: any(named: 'reminders'),
              birthdays: any(named: 'birthdays'),
              notificationsEnabled: any(named: 'notificationsEnabled'),
            )).called(1);
        verify(() => homeWidget.sync(
              any(),
              birthdays: any(named: 'birthdays'),
              notificationsEnabled: any(named: 'notificationsEnabled'),
              categories: any(named: 'categories'),
            )).called(1);
        verify(() => geofence.syncWithReminders(
              any(),
              notificationsEnabled: any(named: 'notificationsEnabled'),
            )).called(1);
        // It changes reminders, never the routines.
        verifyNever(() => repository.saveRoutines(any()));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'nothing to change: no write and no sync',
      build: () => build(routines: [morning()], reminders: [sportReminder()]),
      act: (cubit) async {
        await cubit.load();
        clearInteractions(repository);
        clearInteractions(notifications);
        expect(
          await cubit.refreshRoutineReminders(cubit.state.routines.single),
          0,
        );
      },
      verify: (_) {
        verifyNever(() => repository.saveReminders(any()));
        verifyNever(() => notifications.syncSchedules(
              reminders: any(named: 'reminders'),
              birthdays: any(named: 'birthdays'),
              notificationsEnabled: any(named: 'notificationsEnabled'),
            ));
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'planRoutineReminderRefresh reports the link and the change count',
      build: () => build(routines: [edited()], reminders: [sportReminder()]),
      act: (cubit) async {
        await cubit.load();
        final plan =
            cubit.planRoutineReminderRefresh(cubit.state.routines.single);
        expect(plan.linked, 1);
        expect(plan.hasLinked, isTrue);
        expect(plan.count, 1);

        await cubit.refreshRoutineReminders(cubit.state.routines.single);
        final after =
            cubit.planRoutineReminderRefresh(cubit.state.routines.single);
        expect(after.linked, 1);
        expect(after.count, 0, reason: 'already applied');
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'saveRoutine still leaves the reminders alone',
      build: () => build(routines: [morning()], reminders: [sportReminder()]),
      act: (cubit) async {
        await cubit.load();
        await cubit.saveRoutine(edited().copyWith(id: 'morning'));
      },
      verify: (cubit) {
        // Editing a routine is still not retroactive; only the explicit bulk
        // action changes what it already created.
        expect(cubit.state.reminders.single.title, 'Spor');
        expect(cubit.state.reminders.single.remindAt, DateTime(2026, 9, 19, 7));
      },
    );
  });
}
