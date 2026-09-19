import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/test_database.dart';

/// Priority and pinning (F3.4, schema v4) in the repository and in backups.
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

  final urgent = buildReminder(
    id: 'r1',
    title: 'Faturayı öde',
    priority: ReminderPriority.high,
    pinned: true,
    subtasks: buildSubtasks(['Elektrik', 'Su']),
  );
  final plain = buildReminder(id: 'r2', title: 'Kitap iade');

  group('ReminderRepository priority and pinned', () {
    test('round trip keeps both fields', () async {
      await repository.saveReminders([urgent, plain]);
      final loaded = await repository.loadReminders();
      expect(loaded.map((r) => (r.id, r.priority, r.pinned)).toList(), [
        ('r1', 3, true),
        ('r2', 0, false),
      ]);
      expect(loaded.first.subtasks, urgent.subtasks);

      final rows = await db.select(db.reminders).get();
      final byId = {for (final r in rows) r.id: r};
      expect(byId['r1']!.priority, 3);
      expect(byId['r1']!.pinned, isTrue);
      expect(byId['r2']!.priority, 0);
      expect(byId['r2']!.pinned, isFalse);
    });

    test('changing only priority or pin touches that row', () async {
      Future<Map<String, ReminderRow>> rows() async => {
            for (final r in await db.select(db.reminders).get()) r.id: r,
          };
      final changed = [
        urgent.copyWith(pinned: false),
        plain.copyWith(priority: ReminderPriority.low),
      ];

      await repository.saveReminders([urgent, plain]);
      now = now.add(const Duration(minutes: 5));
      final touched = now.microsecondsSinceEpoch;
      await repository.saveReminders(changed);

      var current = await rows();
      expect(current['r1']!.pinned, isFalse);
      expect(current['r1']!.updatedAt, touched);
      expect(current['r2']!.priority, 1);
      expect(current['r2']!.updatedAt, touched);

      // Saving the same values again leaves updated_at alone.
      now = now.add(const Duration(minutes: 5));
      await repository.saveReminders(changed);
      current = await rows();
      expect(current['r1']!.updatedAt, touched);
      expect(current['r2']!.updatedAt, touched);
    });
  });

  group('backup with priority and pinned', () {
    test('export → import (replace) round-trips both fields', () async {
      await repository.saveReminders([urgent, plain]);
      final service = BackupService(repository, clock: () => now);
      final raw = await service.exportJson(appVersion: '1.0.0');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final exported = (json['reminders'] as List).first as Map;
      expect(exported['priority'], 3);
      expect(exported['pinned'], true);

      await repository.clearAll();
      final backup = BackupFormat.decode(raw);
      await service.apply(backup, BackupImportMode.replace);
      final loaded = await repository.loadReminders();
      expect(loaded.map((r) => (r.id, r.priority, r.pinned)).toList(), [
        ('r1', 3, true),
        ('r2', 0, false),
      ]);
    });

    test('a backup written before F3.4 imports unpinned, no priority', () {
      final legacyReminder = urgent.toJson()
        ..remove('priority')
        ..remove('pinned');
      final raw = jsonEncode({
        'format': BackupFormat.formatId,
        'version': 1,
        'exportedAt': DateTime.utc(2026, 9, 13).toIso8601String(),
        'reminders': [legacyReminder],
        'birthdays': <Object?>[],
        'settings': const AppSettings().toJson(),
      });
      final backup = BackupFormat.decode(raw);
      expect(backup.skippedCount, 0);
      expect(backup.reminders.single.priority, ReminderPriority.none);
      expect(backup.reminders.single.pinned, isFalse);
      expect(backup.reminders.single.subtasks, urgent.subtasks);
    });
  });
}
