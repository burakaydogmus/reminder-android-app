import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/test_database.dart';

/// Subtasks (F3.3, schema v3) in the repository and in backups.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DateTime now;
  late ReminderRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    now = DateTime.utc(2026, 9, 1, 12);
    repository = ReminderRepository(database: db, clock: () => now);
  });

  tearDown(() => db.close());

  int micros(DateTime d) => d.microsecondsSinceEpoch;

  Future<List<SubtaskRow>> subtaskRows() => (db.select(db.subtasks)
        ..orderBy([
          (t) => OrderingTerm.asc(t.reminderId),
          (t) => OrderingTerm.asc(t.position),
        ]))
      .get();

  final market = buildReminder(
    id: 'r1',
    title: 'Market',
    subtasks: buildSubtasks(['Süt', 'Ekmek', 'Yumurta'], done: {1}),
  );

  group('ReminderRepository subtasks', () {
    test('round trip keeps order and done flags', () async {
      await repository.saveReminders([market, buildReminder(id: 'r2')]);
      final loaded = await repository.loadReminders();
      expect(loaded.first.subtasks, market.subtasks);
      expect(loaded.last.subtasks, isEmpty);
      final rows = await subtaskRows();
      expect(rows.map((r) => (r.reminderId, r.id, r.position)).toList(), [
        ('r1', 's1', 0),
        ('r1', 's2', 1),
        ('r1', 's3', 2),
      ]);
      expect(rows.every((r) => r.updatedAt == micros(now)), isTrue);
    });

    test('unchanged subtasks keep updated_at; changed ones are touched',
        () async {
      await repository.saveReminders([market]);
      final saved = now;
      now = now.add(const Duration(minutes: 5));

      final toggled = market.copyWith(
        subtasks: market.subtasks.toggled('s1'),
      );
      await repository.saveReminders([toggled]);

      final rows = {for (final r in await subtaskRows()) r.id: r};
      expect(rows['s1']!.isDone, isTrue);
      expect(rows['s1']!.updatedAt, micros(now));
      expect(rows['s2']!.updatedAt, micros(saved));
      expect(rows['s3']!.updatedAt, micros(saved));
    });

    test('reorder rewrites positions', () async {
      await repository.saveReminders([market]);
      await repository.saveReminders([
        market.copyWith(subtasks: market.subtasks.reordered(2, 0)),
      ]);
      final loaded = (await repository.loadReminders()).single;
      expect(loaded.subtasks.map((s) => s.title), [
        'Yumurta',
        'Süt',
        'Ekmek',
      ]);
    });

    test('a removed subtask is soft-deleted and comes back when re-added',
        () async {
      await repository.saveReminders([market]);
      now = now.add(const Duration(minutes: 1));
      await repository.saveReminders([
        market.copyWith(subtasks: market.subtasks.removed('s2')),
      ]);

      final deleted = (await subtaskRows()).firstWhere((r) => r.id == 's2');
      expect(deleted.deletedAt, micros(now));
      expect(
        (await repository.loadReminders()).single.subtasks.map((s) => s.id),
        ['s1', 's3'],
      );

      now = now.add(const Duration(minutes: 1));
      await repository.saveReminders([market]);
      final restored = (await subtaskRows()).firstWhere((r) => r.id == 's2');
      expect(restored.deletedAt, isNull);
      expect(
          (await repository.loadReminders()).single.subtasks, market.subtasks);
    });

    test('deleting a reminder soft-deletes its subtasks; undo restores them',
        () async {
      final other = buildReminder(
        id: 'r2',
        subtasks: buildSubtasks(['Kalem']),
      );
      await repository.saveReminders([market, other]);

      now = now.add(const Duration(minutes: 1));
      await repository.saveReminders([other]);
      final rows = await subtaskRows();
      expect(
        rows.where((r) => r.reminderId == 'r1').map((r) => r.deletedAt),
        everyElement(micros(now)),
      );
      expect(
        rows.where((r) => r.reminderId == 'r2').single.deletedAt,
        isNull,
      );

      // Undo (F3.5) re-adds the same object.
      now = now.add(const Duration(minutes: 1));
      await repository.saveReminders([market, other]);
      final loaded = await repository.loadReminders();
      expect(loaded.first.subtasks, market.subtasks);
      expect(
        (await subtaskRows()).map((r) => r.deletedAt),
        everyElement(isNull),
      );
    });

    test('the same subtask id in two reminders is stored separately', () async {
      final a = buildReminder(id: 'a', subtasks: buildSubtasks(['A1']));
      final b = buildReminder(id: 'b', subtasks: buildSubtasks(['B1']));
      await repository.saveReminders([a, b]);
      final loaded = await repository.loadReminders();
      expect(loaded.map((r) => r.subtasks.single.title), ['A1', 'B1']);
    });

    test('the one-time prefs migration also imports subtasks', () async {
      SharedPreferences.setMockInitialValues({
        'reminders_v1': jsonEncode([market.toJson()]),
      });
      final loaded = await repository.loadReminders();
      expect(loaded.single.subtasks, market.subtasks);
    });

    test('clearAll removes subtask rows', () async {
      await repository.saveReminders([market]);
      await repository.clearAll();
      expect(await subtaskRows(), isEmpty);
      expect(await repository.loadReminders(), isEmpty);
    });
  });

  group('backup with subtasks', () {
    final exportedAt = DateTime.utc(2026, 9, 13, 10, 30);

    test('export → import (replace) round-trips subtasks', () async {
      await repository.saveReminders([market]);
      final service = BackupService(repository, clock: () => now);
      final raw = await service.exportJson(appVersion: '1.0.0');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final exported = (json['reminders'] as List).single as Map;
      expect((exported['subtasks'] as List).length, 3);

      await repository.clearAll();
      final backup = BackupFormat.decode(raw);
      expect(backup.reminders.single.subtasks, market.subtasks);
      await service.apply(backup, BackupImportMode.replace);
      expect(
          (await repository.loadReminders()).single.subtasks, market.subtasks);
    });

    test('a backup written before F3.3 (no subtasks key) imports empty', () {
      final legacyReminder = buildReminder(id: 'old').toJson()
        ..remove('subtasks');
      final raw = jsonEncode({
        'format': BackupFormat.formatId,
        'version': 1,
        'exportedAt': exportedAt.toIso8601String(),
        'reminders': [legacyReminder],
        'birthdays': <Object?>[],
        'settings': const AppSettings().toJson(),
      });
      final backup = BackupFormat.decode(raw);
      expect(backup.skippedCount, 0);
      expect(backup.reminders.single.id, 'old');
      expect(backup.reminders.single.subtasks, isEmpty);
    });

    test('an unreadable subtask is dropped, the reminder is kept', () {
      final json = market.toJson();
      json['subtasks'] = [
        ...(json['subtasks'] as List),
        {'title': 'kimliksiz'},
      ];
      final raw = jsonEncode({
        'format': BackupFormat.formatId,
        'version': 1,
        'reminders': [json],
        'birthdays': <Object?>[],
      });
      final backup = BackupFormat.decode(raw);
      expect(backup.reminders.single.subtasks, market.subtasks);
      expect(backup.reminders.single.subtasks, isA<List<Subtask>>());
    });
  });
}
