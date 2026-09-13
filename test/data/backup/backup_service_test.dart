import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../../helpers/test_database.dart';

List<Map<String, dynamic>> _reminderJson(List<Reminder> list) =>
    [for (final r in list) r.toJson()];

List<Map<String, dynamic>> _birthdayJson(List<Birthday> list) =>
    [for (final b in list) b.toJson()];

BackupDocument _backup({
  List<Reminder> reminders = const [],
  List<Birthday> birthdays = const [],
  AppSettings? settings,
}) =>
    BackupDocument(
      version: BackupFormat.version,
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
    );

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

  test('file name comes from the clock', () {
    expect(service.fileName(), 'hatirlatici-yedek-2026-09-13.json');
  });

  test('export → import (replace) on a fresh database restores everything',
      () async {
    final reminders = [
      buildReminder(id: 'r1', remindAt: DateTime(2026, 9, 20, 9)),
      buildReminder(id: 'r2', title: 'Fatura', note: 'Elektrik', isDone: true),
    ];
    final birthdays = [
      buildBirthday(id: 'b1'),
      buildBirthday(id: 'b2', name: 'Can', advanceOffsetsMinutes: const [60]),
    ];
    const settings = AppSettings(
      notificationsEnabled: false,
      themeMode: AppThemeModeIds.light,
    );
    await repository.saveReminders(reminders);
    await repository.saveBirthdays(birthdays);
    await repository.saveSettings(settings);

    final json = await service.exportJson(appVersion: '2.1.0+8');

    // "Fresh install": another empty database (a second AppDatabase on
    // purpose, each on its own in-memory executor).
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
    );
    final freshDb = openTestDatabase();
    addTearDown(freshDb.close);
    final fresh = ReminderRepository(database: freshDb, clock: () => now);
    final result = await BackupService(fresh).apply(
      BackupFormat.decode(json),
      BackupImportMode.replace,
    );

    expect(result.reminders, 2);
    expect(result.birthdays, 2);
    expect(result.settingsApplied, isTrue);
    expect(
        _reminderJson(await fresh.loadReminders()), _reminderJson(reminders));
    expect(
        _birthdayJson(await fresh.loadBirthdays()), _birthdayJson(birthdays));
    expect((await fresh.loadSettings()).toJson(), settings.toJson());
  });

  group('merge', () {
    test('upserts by id, keeps local-only items and settings', () async {
      await repository.saveReminders([
        buildReminder(id: 'r1', title: 'Yerel'),
        buildReminder(id: 'r2', title: 'Eski başlık'),
      ]);
      await repository.saveBirthdays([buildBirthday(id: 'b1', name: 'Ayşe')]);
      const local = AppSettings(themeMode: AppThemeModeIds.dark);
      await repository.saveSettings(local);

      final result = await service.apply(
        _backup(
          reminders: [
            buildReminder(id: 'r3', title: 'Yeni'),
            buildReminder(id: 'r2', title: 'Yedekteki başlık', isDone: true),
          ],
          birthdays: [
            buildBirthday(id: 'b1', name: 'Ayşe Y.'),
            buildBirthday(id: 'b2', name: 'Can'),
          ],
          settings: const AppSettings(notificationsEnabled: false),
        ),
        BackupImportMode.merge,
      );

      final loaded = await repository.loadReminders();
      expect(loaded.map((r) => (r.id, r.title, r.isDone)), [
        ('r1', 'Yerel', false),
        ('r2', 'Yedekteki başlık', true),
        ('r3', 'Yeni', false),
      ]);
      final loadedBirthdays = await repository.loadBirthdays();
      expect(
        loadedBirthdays.map((b) => (b.id, b.name)),
        [('b1', 'Ayşe Y.'), ('b2', 'Can')],
      );
      expect((await repository.loadSettings()).toJson(), local.toJson());
      expect(result.settingsApplied, isFalse);
    });

    test('is idempotent', () async {
      final backup = _backup(reminders: [buildReminder(id: 'r1')]);
      await service.apply(backup, BackupImportMode.merge);
      await service.apply(backup, BackupImportMode.merge);
      expect((await repository.loadReminders()).map((r) => r.id), ['r1']);
    });

    test('mergeById keeps order and appends new ids', () {
      final merged = BackupService.mergeById<String>(
        ['a', 'b', 'c'],
        ['d', 'b'],
        (s) => s,
      );
      expect(merged, ['a', 'b', 'c', 'd']);
    });
  });

  group('replace', () {
    test('removes items missing from the backup and applies settings',
        () async {
      await repository.saveReminders([
        buildReminder(id: 'r1'),
        buildReminder(id: 'r2'),
      ]);
      await repository.saveBirthdays([buildBirthday(id: 'b1')]);

      await service.apply(
        _backup(
          reminders: [buildReminder(id: 'r2', title: 'Yedek')],
          settings: const AppSettings(themeMode: AppThemeModeIds.dark),
        ),
        BackupImportMode.replace,
      );

      final loaded = await repository.loadReminders();
      expect(loaded.map((r) => (r.id, r.title)), [('r2', 'Yedek')]);
      expect(await repository.loadBirthdays(), isEmpty);
      expect((await repository.loadSettings()).themeMode, AppThemeModeIds.dark);
    });

    test('keeps current settings when the backup has none', () async {
      const local = AppSettings(notificationsEnabled: false);
      await repository.saveSettings(local);

      final result = await service.apply(
        _backup(reminders: [buildReminder(id: 'r1')]),
        BackupImportMode.replace,
      );

      expect(result.settingsApplied, isFalse);
      expect((await repository.loadSettings()).toJson(), local.toJson());
    });
  });
}
