// Schema migration tests (drift schema verification).
//
// `generated/` is produced from `drift_schemas/` with
//   dart run drift_dev schema generate --data-classes --companions \
//     drift_schemas/ test/data/db/generated/
// Regenerate after exporting a new schema version (see CLAUDE.md, Data).
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/db/row_mapping.dart';
import 'package:reminder/domain/model/recurrence.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2 yields the v2 schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('a fresh database matches the exported v2 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('v1 → v2 keeps reminders, birthdays, settings and meta', () async {
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
    await verifier.migrateAndValidate(db, 2);
    await db.close();

    final migrated = v2.DatabaseAtV2(schema.newConnection());
    final rows = await (migrated.select(migrated.reminders)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    expect(rows.map((r) => r.toJson()..remove('recurrence')).toList(), [
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
}
