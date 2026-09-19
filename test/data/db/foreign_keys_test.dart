import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import '../../helpers/factories.dart';
import '../../helpers/test_database.dart';

/// SQLite foreign keys are enforced from F6.4 (`PRAGMA foreign_keys = ON` in
/// the `beforeOpen` hook): `subtasks.reminder_id` cannot point at a missing
/// reminder, and a reminder row with subtasks cannot be hard-deleted
/// (default `NO ACTION`, i.e. restrict).
void main() {
  late AppDatabase db;
  late ReminderRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    repository = ReminderRepository(database: db);
  });

  tearDown(() => db.close());

  SubtasksCompanion subtaskFor(String reminderId) => SubtasksCompanion.insert(
        reminderId: reminderId,
        id: 's1',
        title: 'Süt',
        isDone: false,
        position: 0,
        updatedAt: 1000,
      );

  test('the pragma is on for every opened connection', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('a subtask cannot reference a missing reminder', () async {
    await expectLater(
      db.into(db.subtasks).insert(subtaskFor('ghost')),
      throwsA(
        isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        ),
      ),
    );
    expect(await db.select(db.subtasks).get(), isEmpty);
  });

  test('hard-deleting a reminder with subtasks is refused (restrict)',
      () async {
    await repository.saveReminders([
      buildReminder(id: 'r1', subtasks: buildSubtasks(['Süt'])),
    ]);
    expect(await db.select(db.subtasks).get(), hasLength(1));

    await expectLater(
      (db.delete(db.reminders)..where((t) => t.id.equals('r1'))).go(),
      throwsA(isA<SqliteException>()),
    );
    // Nothing was removed.
    expect(await db.select(db.reminders).get(), hasLength(1));
    expect(await db.select(db.subtasks).get(), hasLength(1));
  });

  test('the repository flows still work with the constraint on', () async {
    // Saving a reminder with subtasks writes both tables in one transaction.
    await repository.saveReminders([
      buildReminder(id: 'r1', subtasks: buildSubtasks(['Süt', 'Ekmek'])),
      buildReminder(id: 'r2'),
    ]);
    expect((await repository.loadReminders()).map((r) => r.id), ['r1', 'r2']);

    // Deleting is soft, so the referenced row stays.
    await repository.saveReminders([buildReminder(id: 'r2')]);
    expect((await repository.loadReminders()).map((r) => r.id), ['r2']);
    final rows = await db.select(db.reminders).get();
    expect(rows.map((r) => r.id), containsAll(['r1', 'r2']));
    expect(rows.firstWhere((r) => r.id == 'r1').deletedAt, isA<int>());

    // Re-saving restores the reminder with its subtasks.
    await repository.saveReminders([
      buildReminder(id: 'r1', subtasks: buildSubtasks(['Süt', 'Ekmek'])),
      buildReminder(id: 'r2'),
    ]);
    final restored =
        (await repository.loadReminders()).firstWhere((r) => r.id == 'r1');
    expect(restored.subtasks.map((s) => s.title), ['Süt', 'Ekmek']);

    // clearAll deletes subtasks before reminders, so it is not refused.
    await repository.clearAll();
    expect(await db.select(db.reminders).get(), isEmpty);
    expect(await db.select(db.subtasks).get(), isEmpty);
  });
}
