import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/category_label_migration.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../../helpers/test_database.dart';

/// Categories in backups (format version 2, F4.3) and version 1 imports.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderRepository repository;
  late BackupService service;
  final now = DateTime(2026, 9, 13, 10, 30);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    repository = ReminderRepository(database: db, clock: () => now);
    service = BackupService(repository, clock: () => now);
  });

  tearDown(() => db.close());

  Future<Map<String, String>> categoryOf() async => {
        for (final r in await repository.loadReminders()) r.id: r.categoryId,
      };

  test('export → replace import on a fresh database keeps categories',
      () async {
    final categories = [
      buildCategory(id: 'gym', name: 'Spor', position: 0),
      ...CategoryCatalog.builtIns.ordered,
    ];
    await repository.saveCategories(CategoryCatalog(categories).ordered);
    await repository.saveReminders([buildReminder(categoryId: 'gym')]);

    final raw = await service.exportJson();
    expect((jsonDecode(raw) as Map)['version'], 2);

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
    );
    final freshDb = openTestDatabase();
    addTearDown(freshDb.close);
    final fresh = ReminderRepository(database: freshDb, clock: () => now);
    await BackupService(fresh, clock: () => now)
        .apply(BackupFormat.decode(raw), BackupImportMode.replace);

    final loaded = CategoryCatalog(await fresh.loadCategories());
    expect(loaded.ordered.first.id, 'gym');
    expect(loaded.ordered.first.colorKey, 'lacivert');
    expect((await fresh.loadReminders()).single.categoryId, 'gym');
  });

  test('replace drops local user categories not in the backup', () async {
    await repository.saveCategories(
      CategoryCatalog([buildCategory(id: 'local', name: 'Yerel')]).ordered,
    );
    await service.apply(
      BackupDocument(
        version: 2,
        reminders: const [],
        birthdays: const [],
        categories: [buildCategory(id: 'gym')],
      ),
      BackupImportMode.replace,
    );
    final ids = (await repository.loadCategories()).map((c) => c.id);
    expect(ids, contains('gym'));
    expect(ids, isNot(contains('local')));
    expect(ids, containsAll(ReminderCategoryIds.orderedIds));
  });

  test('merge keeps local order, adds new ones, reuses same-name ones',
      () async {
    await repository.saveCategories(CategoryCatalog([
      buildCategory(id: 'local-spor', name: 'Spor', position: 0),
    ]).ordered);
    await repository.saveReminders([buildReminder(id: 'l1')]);

    await service.apply(
      BackupDocument(
        version: 2,
        reminders: [
          buildReminder(id: 'b1', categoryId: 'backup-spor'),
          buildReminder(id: 'b2', categoryId: 'yoga'),
        ],
        birthdays: const [],
        categories: [
          buildCategory(id: 'yoga', name: 'Yoga', position: 0),
          buildCategory(id: 'backup-spor', name: 'SPOR', position: 1),
        ],
      ),
      BackupImportMode.merge,
    );

    final catalog = CategoryCatalog(await repository.loadCategories());
    expect(catalog.ordered.skip(6).map((c) => c.id), ['local-spor', 'yoga']);
    expect(catalog.contains('backup-spor'), isFalse);
    expect(await categoryOf(), {
      'l1': ReminderCategoryIds.other,
      'b1': 'local-spor',
      'b2': 'yoga',
    });
  });

  test('a version 1 backup imports "Diğer + özel ad" as categories', () async {
    final raw = jsonEncode({
      'format': BackupFormat.formatId,
      'version': 1,
      'reminders': [
        buildReminder(id: 'a', customCategoryLabel: 'Kitap kulübü').toJson(),
        buildReminder(id: 'b', customCategoryLabel: 'kitap KULÜBÜ').toJson(),
        buildReminder(id: 'c').toJson(),
      ],
      'birthdays': [],
    });

    await service.apply(BackupFormat.decode(raw), BackupImportMode.merge);

    final user = CategoryCatalog(await repository.loadCategories())
        .userCategories
        .single;
    expect(user.name, 'Kitap kulübü');
    expect(user.id, CategoryLabelMigration.idFor('Kitap kulübü'));
    expect(await categoryOf(), {'a': user.id, 'b': user.id, 'c': 'other'});

    // Importing the same file again creates no duplicate.
    await service.apply(BackupFormat.decode(raw), BackupImportMode.merge);
    expect(
      CategoryCatalog(await repository.loadCategories()).userCategories,
      hasLength(1),
    );
  });

  test('a version 1 label matching a local category joins it', () async {
    await repository.saveCategories(
      CategoryCatalog([buildCategory(id: 'mine', name: 'Hobi')]).ordered,
    );
    final raw = jsonEncode({
      'format': BackupFormat.formatId,
      'version': 1,
      'reminders': [
        buildReminder(id: 'a', customCategoryLabel: 'HOBİ').toJson(),
      ],
    });
    await service.apply(BackupFormat.decode(raw), BackupImportMode.merge);
    final reminders = await repository.loadReminders();
    expect(reminders.map((Reminder r) => r.categoryId), ['mine']);
    expect(
      CategoryCatalog(await repository.loadCategories()).userCategories,
      hasLength(1),
    );
  });
}
