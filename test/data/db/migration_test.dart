// Schema migration tests (drift schema verification).
//
// `generated/` is produced from `drift_schemas/` with
//   dart run drift_dev schema generate --data-classes --companions \
//     drift_schemas/ test/data/db/generated/
// Regenerate after exporting a new schema version (see CLAUDE.md, Data).
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/db/row_mapping.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/subtask.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // `AppDatabase` always migrates to its current `schemaVersion`, so every
  // older version is validated against the latest exported schema; the
  // data tests below read the migrated rows through the latest generated
  // classes (a database file at vN cannot be reopened with an older
  // version's classes) and the app mapping.
  const latest = 5;

  test('the app schema version is the latest exported one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, latest);
    expect(GeneratedHelper.versions.last, latest);
    await db.close();
  });

  for (final from in [1, 2, 3, 4]) {
    test('upgrade from v$from to v$latest yields the v$latest schema',
        () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, latest);
      await db.close();
    });
  }

  test('a fresh database matches the exported v$latest schema', () async {
    final connection = await verifier.startAt(latest);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, latest);
    await db.close();
  });

  test('v1 → latest keeps reminders, birthdays, settings and meta', () async {
    const reminder = v1.RemindersData(
      id: 'r1',
      title: 'Ekmek al',
      note: 'tam buğday',
      isDone: 0, // generated schema classes store booleans as 0/1
      createdAt: '2026-09-01T10:00:00.000',
      remindAt: '2026-09-13T18:30:00.000',
      categoryId: 'shopping',
      customCategoryLabel: null,
      locationTriggerEnabled: 1,
      locationLatitude: 41.0,
      locationLongitude: 29.0,
      locationRadiusMeters: 150.0,
      locationPlaceLabel: 'Market',
      position: 0,
      updatedAt: 1000,
      deletedAt: null,
    );
    const deleted = v1.RemindersData(
      id: 'gone',
      title: 'Silindi',
      isDone: 1,
      createdAt: '2026-08-01T10:00:00.000',
      categoryId: 'other',
      locationTriggerEnabled: 0,
      locationRadiusMeters: 150.0,
      position: 1,
      updatedAt: 2000,
      deletedAt: 2000,
    );
    const birthday = v1.BirthdaysData(
      id: 'b1',
      name: 'Ayşe',
      date: '1990-05-10T00:00:00.000',
      notifyHour: 9,
      notifyMinute: 0,
      advanceOffsetsMinutes: '[0,1440]',
      createdAt: '2026-01-01T12:00:00.000',
      position: 0,
      updatedAt: 1000,
    );
    const settings = v1.SettingsData(
      id: 1,
      notificationsEnabled: 0,
      themeMode: 'dark',
      updatedAt: 1000,
    );
    const meta = v1.AppMetaData(key: 'prefs_migration_v1', value: '1');

    final schema = await verifier.schemaAt(1);
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.batch((batch) {
      batch
        ..insert(oldDb.reminders, reminder)
        ..insert(oldDb.reminders, deleted)
        ..insert(oldDb.birthdays, birthday)
        ..insert(oldDb.settings, settings)
        ..insert(oldDb.appMeta, meta);
    });
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    await db.close();

    final migrated = v5.DatabaseAtV5(schema.newConnection());
    final rows = await (migrated.select(migrated.reminders)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(
        rows
            .map((r) => r.toJson()
              ..remove('recurrence')
              ..remove('priority')
              ..remove('pinned'))
            .toList(),
        [
          reminder.toJson(),
          deleted.toJson(),
        ]);
    expect(rows.map((r) => r.recurrence), [null, null]);
    expect(
      (await migrated.select(migrated.birthdays).getSingle()).toJson(),
      birthday.toJson(),
    );
    expect(
      (await migrated.select(migrated.settings).getSingle()).toJson(),
      settings.toJson(),
    );
    expect(
      (await migrated.select(migrated.appMeta).getSingle()).toJson(),
      meta.toJson(),
    );
    await migrated.close();

    // The app reads migrated rows as reminders without recurrence.
    final app = AppDatabase(schema.newConnection());
    final appRows = await app.select(app.reminders).get();
    final loaded = reminderFromRow(appRows.firstWhere((r) => r.id == 'r1'));
    expect(loaded.recurrence, RecurrenceRule.none);
    expect(loaded.remindAt, DateTime(2026, 9, 13, 18, 30));
    expect(loaded.locationPlaceLabel, 'Market');
    await app.close();
  });

  test('v2 → latest keeps rows and adds an empty subtasks table', () async {
    const reminder = v2.RemindersData(
      id: 'r1',
      title: 'Market',
      isDone: 0,
      createdAt: '2026-09-01T10:00:00.000',
      remindAt: '2026-09-13T18:30:00.000',
      categoryId: 'shopping',
      locationTriggerEnabled: 0,
      locationRadiusMeters: 150.0,
      position: 0,
      updatedAt: 1000,
      recurrence: '{"frequency":"weekly","interval":1,"weekdays":[6]}',
    );
    const birthday = v2.BirthdaysData(
      id: 'b1',
      name: 'Ayşe',
      date: '1990-05-10T00:00:00.000',
      notifyHour: 9,
      notifyMinute: 0,
      advanceOffsetsMinutes: '[0]',
      createdAt: '2026-01-01T12:00:00.000',
      position: 0,
      updatedAt: 1000,
    );
    const settings = v2.SettingsData(
      id: 1,
      notificationsEnabled: 1,
      themeMode: 'system',
      updatedAt: 1000,
    );
    const meta = v2.AppMetaData(key: 'prefs_migration_v1', value: '1');

    final schema = await verifier.schemaAt(2);
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.batch((batch) {
      batch
        ..insert(oldDb.reminders, reminder)
        ..insert(oldDb.birthdays, birthday)
        ..insert(oldDb.settings, settings)
        ..insert(oldDb.appMeta, meta);
    });
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    await db.close();

    final migrated = v5.DatabaseAtV5(schema.newConnection());
    expect(
      (await migrated.select(migrated.reminders).getSingle()).toJson()
        ..remove('priority')
        ..remove('pinned'),
      reminder.toJson(),
    );
    expect(
      (await migrated.select(migrated.birthdays).getSingle()).toJson(),
      birthday.toJson(),
    );
    expect(
      (await migrated.select(migrated.settings).getSingle()).toJson(),
      settings.toJson(),
    );
    expect(
      (await migrated.select(migrated.appMeta).getSingle()).toJson(),
      meta.toJson(),
    );
    expect(await migrated.select(migrated.subtasks).get(), isEmpty);

    // The new table accepts rows for existing reminders.
    await migrated.into(migrated.subtasks).insert(
          const v5.SubtasksData(
            reminderId: 'r1',
            id: 's1',
            title: 'Süt',
            isDone: 1,
            position: 0,
            updatedAt: 2000,
          ),
        );
    await migrated.close();

    final app = AppDatabase(schema.newConnection());
    final row = await app.select(app.reminders).getSingle();
    final loaded = reminderFromRow(row);
    expect(loaded.recurrence, RecurrenceRule.weekly(const [DateTime.saturday]));
    final subtaskRows = await app.select(app.subtasks).get();
    expect(
      subtaskRows.map(subtaskFromRow).toList(),
      const [Subtask(id: 's1', title: 'Süt', isDone: true)],
    );
    await app.close();
  });

  test('v3 → latest keeps rows and subtasks, defaults priority and pinned',
      () async {
    const reminder = v3.RemindersData(
      id: 'r1',
      title: 'Market',
      note: 'kart puanı',
      isDone: 0,
      createdAt: '2026-09-01T10:00:00.000',
      remindAt: '2026-09-13T18:30:00.000',
      categoryId: 'shopping',
      locationTriggerEnabled: 0,
      locationRadiusMeters: 150.0,
      position: 0,
      updatedAt: 1000,
      recurrence: '{"frequency":"weekly","interval":1,"weekdays":[6]}',
    );
    const deleted = v3.RemindersData(
      id: 'gone',
      title: 'Silindi',
      isDone: 1,
      createdAt: '2026-08-01T10:00:00.000',
      categoryId: 'other',
      locationTriggerEnabled: 0,
      locationRadiusMeters: 150.0,
      position: 1,
      updatedAt: 2000,
      deletedAt: 2000,
    );
    const subtasks = [
      v3.SubtasksData(
        reminderId: 'r1',
        id: 's1',
        title: 'Süt',
        isDone: 1,
        position: 0,
        updatedAt: 1000,
      ),
      v3.SubtasksData(
        reminderId: 'r1',
        id: 's2',
        title: 'Ekmek',
        isDone: 0,
        position: 1,
        updatedAt: 1000,
      ),
      v3.SubtasksData(
        reminderId: 'r1',
        id: 's3',
        title: 'Silinen madde',
        isDone: 0,
        position: 2,
        updatedAt: 1500,
        deletedAt: 1500,
      ),
    ];
    const birthday = v3.BirthdaysData(
      id: 'b1',
      name: 'Ayşe',
      date: '1990-05-10T00:00:00.000',
      notifyHour: 9,
      notifyMinute: 0,
      advanceOffsetsMinutes: '[0]',
      createdAt: '2026-01-01T12:00:00.000',
      position: 0,
      updatedAt: 1000,
    );
    const settings = v3.SettingsData(
      id: 1,
      notificationsEnabled: 1,
      themeMode: 'light',
      updatedAt: 1000,
    );
    const meta = v3.AppMetaData(key: 'prefs_migration_v1', value: '1');

    final schema = await verifier.schemaAt(3);
    final oldDb = v3.DatabaseAtV3(schema.newConnection());
    await oldDb.batch((batch) {
      batch
        ..insert(oldDb.reminders, reminder)
        ..insert(oldDb.reminders, deleted)
        ..insertAll(oldDb.subtasks, subtasks)
        ..insert(oldDb.birthdays, birthday)
        ..insert(oldDb.settings, settings)
        ..insert(oldDb.appMeta, meta);
    });
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    await db.close();

    final migrated = v5.DatabaseAtV5(schema.newConnection());
    final rows = await (migrated.select(migrated.reminders)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    // Every v3 column is unchanged; the new columns have their defaults.
    expect(
      rows.map((r) => r.toJson()
        ..remove('priority')
        ..remove('pinned')),
      [reminder.toJson(), deleted.toJson()],
    );
    expect(rows.map((r) => r.priority), [0, 0]);
    expect(rows.map((r) => r.pinned), [0, 0]);
    final subtaskRows = await (migrated.select(migrated.subtasks)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(
      subtaskRows.map((r) => r.toJson()).toList(),
      subtasks.map((s) => s.toJson()).toList(),
    );
    expect(
      (await migrated.select(migrated.birthdays).getSingle()).toJson(),
      birthday.toJson(),
    );
    expect(
      (await migrated.select(migrated.settings).getSingle()).toJson(),
      settings.toJson(),
    );
    expect(
      (await migrated.select(migrated.appMeta).getSingle()).toJson(),
      meta.toJson(),
    );

    // The new columns accept values.
    await (migrated.update(migrated.reminders)
          ..where((t) => t.id.equals('gone')))
        .write(
            const v5.RemindersCompanion(priority: Value(3), pinned: Value(1)));
    await migrated.close();

    // The app reads migrated rows with no priority and not pinned.
    final app = AppDatabase(schema.newConnection());
    final appRows = await app.select(app.reminders).get();
    final loaded = reminderFromRow(
      appRows.firstWhere((r) => r.id == 'r1'),
      subtasks: (await app.select(app.subtasks).get())
          .where((s) => s.deletedAt == null)
          .toList(),
    );
    expect(loaded.priority, ReminderPriority.none);
    expect(loaded.pinned, isFalse);
    expect(loaded.recurrence, RecurrenceRule.weekly(const [DateTime.saturday]));
    expect(loaded.note, 'kart puanı');
    expect(loaded.subtasks.map((s) => s.title), ['Süt', 'Ekmek']);
    final updated = reminderFromRow(appRows.firstWhere((r) => r.id == 'gone'));
    expect(updated.priority, ReminderPriority.high);
    expect(updated.pinned, isTrue);
    await app.close();
  });

  test('v4 → v5 turns "Diğer + özel ad" into user categories', () async {
    v4.RemindersData reminder(
      String id,
      int position, {
      String categoryId = 'other',
      String? label,
      int? deletedAt,
      int priority = 0,
      int pinned = 0,
    }) =>
        v4.RemindersData(
          id: id,
          title: 'Hatırlatıcı $id',
          note: 'not $id',
          isDone: 0,
          createdAt: '2026-09-01T10:00:00.000',
          remindAt: '2026-09-13T18:30:00.000',
          categoryId: categoryId,
          customCategoryLabel: label,
          locationTriggerEnabled: 0,
          locationRadiusMeters: 150.0,
          position: position,
          updatedAt: 1000,
          deletedAt: deletedAt,
          recurrence: '{"frequency":"daily","interval":1}',
          priority: priority,
          pinned: pinned,
        );
    final reminders = [
      reminder('gym', 0, label: 'Spor salonu', priority: 3, pinned: 1),
      reminder('gym2', 1, label: ' SPOR  SALONU '),
      reminder('book', 2, label: 'Kitap kulübü'),
      reminder('light', 3, label: 'Işık'),
      reminder('light2', 4, label: 'ışık'),
      reminder('plain', 5),
      reminder('blank', 6, label: '  '),
      reminder('diger', 7, label: 'diğer'),
      reminder('market', 8, label: 'MARKET'),
      // A label on a fixed category is ignored (it was never shown).
      reminder('work', 9, categoryId: 'work', label: 'Yoga'),
      // Soft-deleted rows don't create categories.
      reminder('gone', 10, label: 'Eski', deletedAt: 2000),
    ];
    const subtask = v4.SubtasksData(
      reminderId: 'gym',
      id: 's1',
      title: 'Havlu',
      isDone: 1,
      position: 0,
      updatedAt: 1000,
    );
    const birthday = v4.BirthdaysData(
      id: 'b1',
      name: 'Ayşe',
      date: '1990-05-10T00:00:00.000',
      notifyHour: 9,
      notifyMinute: 0,
      advanceOffsetsMinutes: '[0]',
      createdAt: '2026-01-01T12:00:00.000',
      position: 0,
      updatedAt: 1000,
    );

    final schema = await verifier.schemaAt(4);
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb.batch((batch) {
      batch
        ..insertAll(oldDb.reminders, reminders)
        ..insert(oldDb.subtasks, subtask)
        ..insert(oldDb.birthdays, birthday);
    });
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    await db.close();

    final migrated = v5.DatabaseAtV5(schema.newConnection());
    final categories = await (migrated.select(migrated.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(
        categories.map((c) => c.name), ['Spor salonu', 'Kitap kulübü', 'Işık']);
    expect(categories.map((c) => c.colorKey).toSet(), {'diger'});
    expect(categories.map((c) => c.iconKey).toSet(), {'label'});
    expect(categories.map((c) => c.position), [6, 7, 8]);
    expect(categories.every((c) => c.deletedAt == null), isTrue);
    final idOf = {for (final c in categories) c.name: c.id};

    final rows = await (migrated.select(migrated.reminders)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect({
      for (final r in rows) r.id: r.categoryId
    }, {
      'gym': idOf['Spor salonu'],
      'gym2': idOf['Spor salonu'],
      'book': idOf['Kitap kulübü'],
      'light': idOf['Işık'],
      'light2': idOf['Işık'],
      'plain': 'other',
      'blank': 'other',
      'diger': 'other',
      'market': 'market',
      'work': 'work',
      'gone': 'other',
    });
    // Everything else is untouched; the old label stays for rollback.
    for (var i = 0; i < rows.length; i++) {
      final before = reminders[i].toJson()
        ..remove('categoryId')
        ..remove('updatedAt');
      final after = rows[i].toJson()
        ..remove('categoryId')
        ..remove('updatedAt');
      expect(after, before, reason: rows[i].id);
    }
    // Repointed rows get a new updated_at, the others keep theirs.
    expect(rows.firstWhere((r) => r.id == 'plain').updatedAt, 1000);
    expect(rows.firstWhere((r) => r.id == 'gym').updatedAt, greaterThan(1000));
    expect(
      (await migrated.select(migrated.subtasks).getSingle()).toJson(),
      subtask.toJson(),
    );
    expect(
      (await migrated.select(migrated.birthdays).getSingle()).toJson(),
      birthday.toJson(),
    );
    await migrated.close();

    // The app reads the migrated reminder with subtasks, priority and pin.
    final app = AppDatabase(schema.newConnection());
    final appRows = await app.select(app.reminders).get();
    final gym = reminderFromRow(
      appRows.firstWhere((r) => r.id == 'gym'),
      subtasks: await app.select(app.subtasks).get(),
    );
    expect(gym.categoryId, idOf['Spor salonu']);
    expect(gym.priority, ReminderPriority.high);
    expect(gym.pinned, isTrue);
    expect(gym.subtasks.single.title, 'Havlu');
    expect(gym.recurrence, RecurrenceRule.daily());
    await app.close();
  });

  test('v4 → v5 without labels creates no categories', () async {
    final schema = await verifier.schemaAt(4);
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb.into(oldDb.reminders).insert(const v4.RemindersData(
          id: 'r1',
          title: 'Ekmek',
          isDone: 0,
          createdAt: '2026-09-01T10:00:00.000',
          categoryId: 'other',
          locationTriggerEnabled: 0,
          locationRadiusMeters: 150.0,
          position: 0,
          updatedAt: 1000,
          priority: 0,
          pinned: 0,
        ));
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    expect(await db.select(db.categories).get(), isEmpty);
    expect((await db.select(db.reminders).getSingle()).updatedAt, 1000);
    await db.close();
  });
}
