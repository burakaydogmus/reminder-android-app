import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../../helpers/test_database.dart';

/// Routines (F3.7) in backups. The format version stays **2**: `routines` and
/// the reminder's `routineId` / `routineItemId` are additive, so a v1/v2 file
/// still imports and an older build still reads a file written with routines
/// (it drops what it does not know instead of rejecting the file).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderRepository repository;
  late BackupService service;
  final now = DateTime(2026, 9, 26, 10, 30);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    repository = ReminderRepository(database: db, clock: () => now);
    service = BackupService(repository, clock: () => now);
  });

  tearDown(() => db.close());

  Routine morning() => buildRoutine(
        repeat: RecurrenceRule.weekly(const [DateTime.monday]),
        items: [
          buildRoutineStep(
            id: 'sport',
            title: 'Spor',
            time: '07:00',
            categoryId: ReminderCategoryIds.health,
            priority: ReminderPriority.medium,
            subtasks: buildSubtasks(['Havlu']),
          ),
          buildRoutineStep(id: 'water', title: 'Su iç'),
        ],
      );

  test('the written file keeps the version at 2 and carries routines',
      () async {
    await repository.saveRoutines([morning()]);
    final json = jsonDecode(await service.exportJson()) as Map<String, dynamic>;
    expect(json['version'], 2);
    expect(BackupFormat.version, 2);
    final routines = json['routines'] as List;
    expect(routines, hasLength(1));
    expect((routines.single as Map)['name'], 'Sabah rutini');
    expect(
      ((routines.single as Map)['items'] as List).length,
      2,
    );
  });

  test('a routine and the reminder link survive a round trip', () async {
    await repository.saveRoutines([morning()]);
    await repository.saveReminders([
      buildReminder(
        id: 'r1',
        title: 'Spor',
        remindAt: DateTime(2026, 9, 28, 7),
        categoryId: ReminderCategoryIds.health,
        recurrence: RecurrenceRule.weekly(const [DateTime.monday]),
        routineId: 'morning',
        routineItemId: 'sport',
      ),
    ]);

    final raw = await service.exportJson();
    await repository.clearAll();
    expect(await repository.loadRoutines(), isEmpty);

    final document = BackupFormat.decode(raw);
    expect(document.routines, [morning()]);
    expect(document.skippedRoutines, 0);
    final result = await service.apply(document, BackupImportMode.replace);
    expect(result.routines, 1);

    final restored = (await repository.loadRoutines()).single;
    expect(restored, morning());
    expect(restored.repeat, RecurrenceRule.weekly(const [DateTime.monday]));
    expect(restored.items.first.subtasks.map((s) => s.title), ['Havlu']);
    final reminder = (await repository.loadReminders()).single;
    expect(reminder.routineId, 'morning');
    expect(reminder.routineItemId, 'sport');
  });

  test('merge keeps local routines and upserts by id', () async {
    await repository.saveRoutines([
      buildRoutine(id: 'morning', name: 'Sabah (yerel)'),
      buildRoutine(id: 'local', name: 'Yerel rutin'),
    ]);

    final document = BackupDocument(
      version: BackupFormat.version,
      reminders: const [],
      birthdays: const [],
      routines: [
        morning(),
        buildRoutine(id: 'weekend', name: 'Hafta sonu'),
      ],
    );
    final result = await service.apply(document, BackupImportMode.merge);
    expect(result.routines, 2);

    final routines = await repository.loadRoutines();
    expect(routines.map((r) => r.id), ['morning', 'local', 'weekend']);
    expect(routines.first.name, 'Sabah rutini');
    expect(routines.first.items, hasLength(2));
    expect(routines.map((r) => r.position), [0, 1, 2]);
  });

  test('replace drops local routines that the file does not have', () async {
    await repository.saveRoutines([buildRoutine(id: 'local', name: 'Yerel')]);
    await service.apply(
      BackupDocument(
        version: BackupFormat.version,
        reminders: const [],
        birthdays: const [],
        routines: [morning()],
      ),
      BackupImportMode.replace,
    );
    expect((await repository.loadRoutines()).map((r) => r.id), ['morning']);
  });

  group('older files', () {
    test('a v2 file without routines imports with no routines', () {
      final document = BackupFormat.decode(jsonEncode({
        'format': BackupFormat.formatId,
        'version': 2,
        'reminders': [buildReminder(id: 'r1').toJson()],
        'birthdays': <Object?>[],
        'categories': <Object?>[],
      }));
      expect(document.routines, isEmpty);
      expect(document.reminders.single.routineId, isNull);
      expect(document.skippedRoutines, 0);
    });

    test('a v1 file imports and has no routines', () {
      final document = BackupFormat.decode(jsonEncode({
        'format': BackupFormat.formatId,
        'version': 1,
        'reminders': [
          {
            'id': 'r1',
            'title': 'Spor',
            'isDone': false,
            'createdAt': '2026-01-01T12:00:00.000',
            'categoryId': 'other',
            'customCategoryLabel': 'Spor salonu',
          },
        ],
        'birthdays': <Object?>[],
      }));
      expect(document.version, 1);
      expect(document.routines, isEmpty);
      // The F4.3 label migration still runs for v1 files.
      expect(document.categories.map((c) => c.name), ['Spor salonu']);
      expect(document.reminders.single.categoryId, isNot('other'));
    });

    test('unreadable routines are skipped and counted', () {
      final document = BackupFormat.decode(jsonEncode({
        'format': BackupFormat.formatId,
        'version': 2,
        'reminders': <Object?>[],
        'birthdays': <Object?>[],
        'routines': [
          morning().toJson(),
          {'name': 'Kimliksiz'},
          {'id': '', 'name': 'Boş kimlik'},
          morning().toJson(),
          'metin',
        ],
      }));
      expect(document.routines.map((r) => r.id), ['morning']);
      // Missing id, empty id, repeated id and a non-object.
      expect(document.skippedRoutines, 4);
      expect(document.skippedCount, 4);
    });

    test('a non-list routines key rejects the whole file', () {
      expect(
        () => BackupFormat.decode(jsonEncode({
          'format': BackupFormat.formatId,
          'version': 2,
          'reminders': <Object?>[],
          'birthdays': <Object?>[],
          'routines': {'id': 'morning'},
        })),
        throwsA(
          isA<BackupFormatException>()
              .having((e) => e.kind, 'kind', BackupErrorKind.invalid),
        ),
      );
    });

    test('routines are renumbered on import', () {
      final document = BackupFormat.decode(jsonEncode({
        'format': BackupFormat.formatId,
        'version': 2,
        'reminders': <Object?>[],
        'birthdays': <Object?>[],
        'routines': [
          buildRoutine(id: 'b', name: 'Akşam', position: 9).toJson(),
          buildRoutine(id: 'a', name: 'Sabah', position: 4).toJson(),
        ],
      }));
      expect(document.routines.map((r) => r.id), ['a', 'b']);
      expect(document.routines.map((r) => r.position), [0, 1]);
    });
  });
}
