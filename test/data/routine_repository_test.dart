import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import '../helpers/factories.dart';
import '../helpers/test_database.dart';

/// Routines (F3.7) in the repository: the same diff + soft delete rule as the
/// other lists, steps written in the same transaction.
void main() {
  late AppDatabase db;
  late ReminderRepository repository;
  var clock = DateTime(2026, 9, 26, 8);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 9, 26, 8);
    db = openTestDatabase();
    repository = ReminderRepository(database: db, clock: () => clock);
  });

  tearDown(() => db.close());

  Routine morning({
    String name = 'Sabah rutini',
    RecurrenceRule repeat = RecurrenceRule.none,
    List<RoutineItem>? items,
  }) =>
      buildRoutine(
        name: name,
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
              buildRoutineStep(
                id: 'water',
                title: 'Su iç',
                subtasks: buildSubtasks(['Bir bardak']),
              ),
            ],
      );

  test('round-trips a routine with its steps', () async {
    final routine = morning(repeat: RecurrenceRule.daily());
    await repository.saveRoutines([routine]);

    final loaded = await repository.loadRoutines();
    expect(loaded, [routine]);
    final first = loaded.single;
    expect(first.repeat, RecurrenceRule.daily());
    expect(first.items.map((i) => i.id), ['sport', 'water']);
    expect(first.items.first.time, const RoutineTime(7, 0));
    expect(first.items.first.priority, ReminderPriority.medium);
    expect(first.items.last.time, isNull);
    expect(first.items.last.subtasks.map((s) => s.title), ['Bir bardak']);
    expect(first.createdAt, routine.createdAt);
  });

  test('keeps the list order in position and loads it back', () async {
    await repository.saveRoutines([
      buildRoutine(id: 'a', name: 'Sabah'),
      buildRoutine(id: 'b', name: 'Akşam'),
    ]);
    final rows = await (db.select(db.routines)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(rows.map((r) => (r.id, r.position)), [('a', 0), ('b', 1)]);

    await repository.saveRoutines([
      buildRoutine(id: 'b', name: 'Akşam'),
      buildRoutine(id: 'a', name: 'Sabah'),
    ]);
    expect(
      (await repository.loadRoutines()).map((r) => r.id),
      ['b', 'a'],
    );
  });

  test('only touches changed rows (updated_at)', () async {
    await repository.saveRoutines([
      buildRoutine(id: 'a', name: 'Sabah'),
      buildRoutine(id: 'b', name: 'Akşam'),
    ]);
    final before = {
      for (final row in await db.select(db.routines).get())
        row.id: row.updatedAt
    };

    clock = DateTime(2026, 9, 26, 9);
    await repository.saveRoutines([
      buildRoutine(id: 'a', name: 'Sabah sporu'),
      buildRoutine(id: 'b', name: 'Akşam'),
    ]);
    final after = {
      for (final row in await db.select(db.routines).get())
        row.id: row.updatedAt
    };
    expect(after['a'], greaterThan(before['a']!));
    expect(after['b'], before['b']);
  });

  test('a step change touches the step row, not the routine row', () async {
    await repository.saveRoutines([morning()]);
    final routineBefore = (await db.select(db.routines).getSingle()).updatedAt;

    clock = DateTime(2026, 9, 26, 10);
    await repository.saveRoutines([
      morning(items: [
        buildRoutineStep(id: 'sport', title: 'Spor', time: '08:00'),
        buildRoutineStep(
          id: 'water',
          title: 'Su iç',
          subtasks: buildSubtasks(['Bir bardak']),
        ),
      ]),
    ]);
    expect((await db.select(db.routines).getSingle()).updatedAt, routineBefore);
    final steps = await (db.select(db.routineItems)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(steps.first.timeOfDay, '08:00');
    expect(steps.first.updatedAt, greaterThan(routineBefore));
    expect(steps.last.updatedAt, routineBefore);
  });

  test('soft-deletes a removed routine and its steps', () async {
    await repository.saveRoutines([
      morning(),
      buildRoutine(id: 'evening', name: 'Akşam'),
    ]);

    clock = DateTime(2026, 9, 26, 11);
    await repository.saveRoutines([buildRoutine(id: 'evening', name: 'Akşam')]);

    expect((await repository.loadRoutines()).map((r) => r.id), ['evening']);
    final rows = await db.select(db.routines).get();
    expect(rows.map((r) => r.id).toSet(), {'morning', 'evening'});
    expect(rows.firstWhere((r) => r.id == 'morning').deletedAt, isA<int>());
    final steps = await db.select(db.routineItems).get();
    expect(steps.length, 2);
    expect(steps.every((s) => s.deletedAt != null), isTrue);
  });

  test('re-saving a soft-deleted routine restores it with its steps', () async {
    await repository.saveRoutines([morning()]);
    await repository.saveRoutines([]);
    expect(await repository.loadRoutines(), isEmpty);

    await repository.saveRoutines([morning()]);
    final restored = (await repository.loadRoutines()).single;
    expect(restored.items.map((i) => i.id), ['sport', 'water']);
    expect(restored.items.last.subtasks.map((s) => s.title), ['Bir bardak']);
  });

  test('a removed step is soft-deleted and stops loading', () async {
    await repository.saveRoutines([morning()]);
    await repository.saveRoutines([
      morning(items: [buildRoutineStep(id: 'sport', title: 'Spor')]),
    ]);

    final loaded = (await repository.loadRoutines()).single;
    expect(loaded.items.map((i) => i.id), ['sport']);
    final steps = await db.select(db.routineItems).get();
    expect(steps.firstWhere((s) => s.id == 'water').deletedAt, isA<int>());
  });

  test('a step cannot reference a missing routine (foreign key)', () async {
    await expectLater(
      db.into(db.routineItems).insert(RoutineItemsCompanion.insert(
            routineId: 'ghost',
            id: 'i1',
            title: 'Spor',
            categoryId: ReminderCategoryIds.other,
            position: 0,
            updatedAt: 1000,
          )),
      throwsA(
        isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        ),
      ),
    );
    expect(await db.select(db.routineItems).get(), isEmpty);
  });

  test('hard-deleting a routine with steps is refused (restrict)', () async {
    await repository.saveRoutines([morning()]);
    await expectLater(
      (db.delete(db.routines)..where((t) => t.id.equals('morning'))).go(),
      throwsA(isA<SqliteException>()),
    );
    expect(await db.select(db.routines).get(), hasLength(1));
    expect(await db.select(db.routineItems).get(), hasLength(2));
  });

  test('clearAll removes routines and steps', () async {
    await repository.saveRoutines([morning()]);
    await repository.clearAll();
    expect(await db.select(db.routines).get(), isEmpty);
    expect(await db.select(db.routineItems).get(), isEmpty);
    expect(await repository.loadRoutines(), isEmpty);
  });

  test('duplicate step ids in one routine keep the first', () async {
    await repository.saveRoutines([
      buildRoutine(items: [
        buildRoutineStep(id: 'same', title: 'İlk'),
        buildRoutineStep(id: 'same', title: 'İkinci'),
      ]),
    ]);
    final loaded = (await repository.loadRoutines()).single;
    expect(loaded.items.map((i) => i.title), ['İlk']);
  });

  test('reminders created by a routine keep their loose link', () async {
    await repository.saveRoutines([morning()]);
    await repository.saveReminders([
      buildReminder(
        id: 'r1',
        title: 'Spor',
        remindAt: DateTime(2026, 9, 26, 7),
        routineId: 'morning',
        routineItemId: 'sport',
      ),
    ]);
    final loaded = (await repository.loadReminders()).single;
    expect(loaded.routineId, 'morning');
    expect(loaded.routineItemId, 'sport');

    // Deleting the routine leaves the reminder — and its link — untouched.
    await repository.saveRoutines([]);
    final after = (await repository.loadReminders()).single;
    expect(after.routineId, 'morning');
    expect(after.title, 'Spor');
  });

  test('a reminder may link to a routine that does not exist', () async {
    await repository.saveReminders([
      buildReminder(id: 'r1', routineId: 'ghost', routineItemId: 'i1'),
    ]);
    expect((await repository.loadReminders()).single.routineId, 'ghost');
  });
}
