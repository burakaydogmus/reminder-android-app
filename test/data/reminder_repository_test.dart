import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/prefs_migration.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/test_database.dart';

// Eski SharedPreferences anahtarları (geçiş kaynağı ve F1.4 yedekleri).
const _keyReminders = 'reminders_v1';
const _keySettings = 'app_settings_v1';
const _keyBirthdays = 'birthdays_v1';
const _backupReminders = 'reminders_v1_backup';
const _backupSettings = 'app_settings_v1_backup';
const _backupBirthdays = 'birthdays_v1_backup';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DateTime now;
  late ReminderRepository repository;

  ReminderRepository newRepository() =>
      ReminderRepository(database: db, clock: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    now = DateTime.utc(2026, 9, 1, 12);
    repository = newRepository();
  });

  tearDown(() => db.close());

  Future<String?> stored(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  int micros(DateTime d) => d.microsecondsSinceEpoch;

  group('empty storage', () {
    test('loadReminders returns empty list', () async {
      expect(await repository.loadReminders(), isEmpty);
    });

    test('loadBirthdays returns empty list', () async {
      expect(await repository.loadBirthdays(), isEmpty);
    });

    test('loadSettings returns defaults', () async {
      final settings = await repository.loadSettings();
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.themeMode, AppThemeModeIds.system);
    });

    test('empty legacy strings are treated as empty storage', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: '',
        _keyBirthdays: '',
        _keySettings: '',
      });
      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect((await repository.loadSettings()).notificationsEnabled, isTrue);
      expect(await repository.hasRecoveryBackup(), isFalse);
      expect(await db.select(db.settings).get(), isEmpty);
    });
  });

  group('recurrence (F3.1, schema v2)', () {
    test('rules round-trip and none is stored as NULL', () async {
      final rules = [
        RecurrenceRule.none,
        RecurrenceRule.daily(interval: 3),
        RecurrenceRule.weekly([1, 3], interval: 2, until: DateTime(2027, 1, 1)),
        RecurrenceRule.monthly(dayOfMonth: 31),
      ];
      await repository.saveReminders([
        for (var i = 0; i < rules.length; i++)
          buildReminder(
            id: 'r$i',
            remindAt: DateTime(2026, 9, 13, 18),
            recurrence: rules[i],
          ),
      ]);

      final loaded = await newRepository().loadReminders();
      expect(loaded.map((r) => r.recurrence).toList(), rules);

      final rows = await db.select(db.reminders).get();
      expect(rows.firstWhere((r) => r.id == 'r0').recurrence, isNull);
      expect(
        jsonDecode(rows.firstWhere((r) => r.id == 'r1').recurrence!),
        {'frequency': 'daily', 'interval': 3},
      );
    });

    test('changing only the rule updates the row', () async {
      final r = buildReminder(remindAt: DateTime(2026, 9, 13, 18));
      await repository.saveReminders([r]);
      now = now.add(const Duration(minutes: 1));
      await repository
          .saveReminders([r.copyWith(recurrence: RecurrenceRule.daily())]);

      final row = await db.select(db.reminders).getSingle();
      expect(row.updatedAt, micros(now));
      expect(
        (await repository.loadReminders()).single.recurrence,
        RecurrenceRule.daily(),
      );
    });

    test('an unreadable stored rule loads as no recurrence', () async {
      await repository.saveReminders([buildReminder(id: 'bad')]);
      await (db.update(db.reminders)..where((t) => t.id.equals('bad')))
          .write(const RemindersCompanion(recurrence: Value('{oops')));

      final loaded = await repository.loadReminders();
      expect(loaded.single.id, 'bad');
      expect(loaded.single.recurrence, RecurrenceRule.none);
    });
  });

  group('save/load round-trip', () {
    test('reminders', () async {
      final reminders = [
        buildReminder(id: 'a', title: 'A', remindAt: DateTime(2026, 5, 1, 9)),
        buildReminder(
          id: 'b',
          title: 'B',
          isDone: true,
          note: 'not',
          categoryId: 'shopping',
          customCategoryLabel: 'Market',
          locationTriggerEnabled: true,
          locationLatitude: 41.0082,
          locationLongitude: 28.9784,
          locationRadiusMeters: 250,
          locationPlaceLabel: 'Sultanahmet',
        ),
      ];

      await repository.saveReminders(reminders);
      final loaded = await repository.loadReminders();

      expect(loaded.map((r) => r.id), ['a', 'b']);
      expect(loaded[0].remindAt, DateTime(2026, 5, 1, 9));
      expect(loaded[0].createdAt, reminders[0].createdAt);
      expect(loaded[1].remindAt, isNull);
      expect(loaded[1].isDone, isTrue);
      expect(loaded[1].note, 'not');
      expect(loaded[1].categoryId, 'shopping');
      expect(loaded[1].customCategoryLabel, 'Market');
      expect(loaded[1].locationTriggerEnabled, isTrue);
      expect(loaded[1].locationLatitude, 41.0082);
      expect(loaded[1].locationLongitude, 28.9784);
      expect(loaded[1].locationRadiusMeters, 250);
      expect(loaded[1].locationPlaceLabel, 'Sultanahmet');
    });

    test('local wall-clock time round-trips unchanged', () async {
      final wallClock = DateTime(2026, 9, 13, 18, 30);
      await repository.saveReminders([
        buildReminder(id: 'a', createdAt: wallClock, remindAt: wallClock),
      ]);
      await repository.saveBirthdays([
        buildBirthday(
            id: 'x', date: DateTime(1990, 5, 10), createdAt: wallClock),
      ]);

      // Eski JSON ile aynı metin: saat dilimi eki yok (duvar saati).
      final row = (await db.select(db.reminders).get()).single;
      expect(row.remindAt, '2026-09-13T18:30:00.000');
      expect(row.createdAt, wallClock.toIso8601String());

      final loaded = (await newRepository().loadReminders()).single;
      expect(loaded.remindAt, wallClock);
      expect(loaded.remindAt!.isUtc, isFalse);
      expect(loaded.remindAt!.hour, 18);
      expect(loaded.remindAt!.minute, 30);
      expect(loaded.createdAt, wallClock);
      final birthday = (await newRepository().loadBirthdays()).single;
      expect(birthday.date, DateTime(1990, 5, 10));
      expect(birthday.createdAt, wallClock);
    });

    test('UTC and sub-millisecond values keep isUtc and precision', () async {
      final utc = DateTime.utc(2026, 3, 4, 5, 6, 7, 8, 9);
      await repository.saveReminders([
        buildReminder(id: 'a', createdAt: utc, remindAt: utc),
      ]);

      final loaded = (await repository.loadReminders()).single;
      expect(loaded.createdAt, utc);
      expect(loaded.createdAt.isUtc, isTrue);
      expect(loaded.remindAt, utc);
      expect(loaded.remindAt!.microsecond, 9);
    });

    test('birthdays', () async {
      final birthdays = [
        buildBirthday(id: 'x', name: 'X', advanceOffsetsMinutes: const [60]),
        buildBirthday(
          id: 'y',
          name: 'Y',
          note: 'hediye',
          date: DateTime(2000, 2, 29),
          notifyHour: 8,
          notifyMinute: 30,
        ),
      ];

      await repository.saveBirthdays(birthdays);
      final loaded = await repository.loadBirthdays();

      expect(loaded.map((b) => b.id), ['x', 'y']);
      expect(loaded[0].advanceOffsetsMinutes, [60]);
      expect(loaded[1].note, 'hediye');
      expect(loaded[1].date, DateTime(2000, 2, 29));
      expect(loaded[1].notifyHour, 8);
      expect(loaded[1].notifyMinute, 30);
      expect(loaded[1].advanceOffsetsMinutes, [0, 1440]);
      expect(loaded[1].createdAt, birthdays[1].createdAt);
    });

    test('settings', () async {
      await repository.saveSettings(
        const AppSettings(
          notificationsEnabled: false,
          themeMode: AppThemeModeIds.dark,
        ),
      );
      final loaded = await repository.loadSettings();

      expect(loaded.notificationsEnabled, isFalse);
      expect(loaded.themeMode, AppThemeModeIds.dark);
    });

    test('list order follows the last saved list', () async {
      await repository.saveReminders([
        buildReminder(id: 'a'),
        buildReminder(id: 'b'),
        buildReminder(id: 'c'),
      ]);
      await repository.saveReminders([
        buildReminder(id: 'c'),
        buildReminder(id: 'a'),
        buildReminder(id: 'b'),
      ]);

      expect(
        (await repository.loadReminders()).map((r) => r.id),
        ['c', 'a', 'b'],
      );
    });

    test('data survives a new repository on the same database', () async {
      await repository.saveReminders([buildReminder(id: 'a')]);
      await repository.saveBirthdays([buildBirthday(id: 'x')]);
      await repository
          .saveSettings(const AppSettings(themeMode: AppThemeModeIds.light));

      final other = newRepository();
      expect((await other.loadReminders()).map((r) => r.id), ['a']);
      expect((await other.loadBirthdays()).map((b) => b.id), ['x']);
      expect((await other.loadSettings()).themeMode, AppThemeModeIds.light);
    });

    test('all-valid data writes no backup and no legacy keys', () async {
      await repository.saveReminders([buildReminder()]);
      await repository.saveBirthdays([buildBirthday()]);
      await repository
          .saveSettings(const AppSettings(themeMode: AppThemeModeIds.light));

      await repository.loadReminders();
      await repository.loadBirthdays();
      await repository.loadSettings();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_backupReminders), isFalse);
      expect(prefs.containsKey(_backupBirthdays), isFalse);
      expect(prefs.containsKey(_backupSettings), isFalse);
      expect(prefs.containsKey(_keyReminders), isFalse);
      expect(await repository.hasRecoveryBackup(), isFalse);
    });

    test('close keeps an injected database open', () async {
      await repository.saveReminders([buildReminder(id: 'a')]);
      await repository.close();

      expect((await repository.loadReminders()).map((r) => r.id), ['a']);
    });
  });

  group('soft delete and updated_at', () {
    test('items missing from a saved list are soft deleted', () async {
      await repository.saveReminders([
        buildReminder(id: 'a'),
        buildReminder(id: 'b'),
      ]);
      final deleteTime = now.add(const Duration(minutes: 5));
      now = deleteTime;

      await repository.saveReminders([buildReminder(id: 'b')]);

      expect((await repository.loadReminders()).map((r) => r.id), ['b']);
      final rows = {
        for (final r in await db.select(db.reminders).get()) r.id: r,
      };
      expect(rows.keys, containsAll(['a', 'b']));
      expect(rows['a']!.deletedAt, micros(deleteTime));
      expect(rows['a']!.updatedAt, micros(deleteTime));
      expect(rows['b']!.deletedAt, isNull);
    });

    test('soft deleted birthdays are hidden, deletion time is kept', () async {
      await repository.saveBirthdays([
        buildBirthday(id: 'x'),
        buildBirthday(id: 'y'),
      ]);
      final deleteTime = now.add(const Duration(hours: 1));
      now = deleteTime;
      await repository.saveBirthdays([buildBirthday(id: 'y')]);

      now = deleteTime.add(const Duration(hours: 1));
      await repository.saveBirthdays([buildBirthday(id: 'y')]);

      expect((await repository.loadBirthdays()).map((b) => b.id), ['y']);
      final x = await (db.select(db.birthdays)..where((t) => t.id.equals('x')))
          .getSingle();
      expect(x.deletedAt, micros(deleteTime));
    });

    test('saving an empty list soft deletes everything', () async {
      await repository.saveReminders([buildReminder(id: 'a')]);
      await repository.saveReminders([]);

      expect(await repository.loadReminders(), isEmpty);
      expect((await db.select(db.reminders).get()).single.deletedAt, isNotNull);
    });

    test('a soft deleted item saved again is restored', () async {
      await repository.saveReminders([buildReminder(id: 'a')]);
      await repository.saveReminders([]);
      final restoreTime = now.add(const Duration(days: 1));
      now = restoreTime;

      await repository.saveReminders([buildReminder(id: 'a', title: 'Yeni')]);

      final loaded = await repository.loadReminders();
      expect(loaded.single.title, 'Yeni');
      final row = (await db.select(db.reminders).get()).single;
      expect(row.deletedAt, isNull);
      expect(row.updatedAt, micros(restoreTime));
    });

    test('clearing nullable fields is persisted', () async {
      await repository.saveReminders([
        buildReminder(id: 'a', note: 'not', remindAt: DateTime(2026, 5, 1)),
      ]);
      await repository.saveBirthdays([buildBirthday(id: 'x', note: 'hediye')]);

      await repository.saveReminders([buildReminder(id: 'a')]);
      await repository.saveBirthdays([buildBirthday(id: 'x')]);

      final reminder = (await repository.loadReminders()).single;
      expect(reminder.note, isNull);
      expect(reminder.remindAt, isNull);
      expect((await repository.loadBirthdays()).single.note, isNull);
    });

    test('updated_at is set on insert, kept for unchanged rows', () async {
      final insertTime = now;
      await repository.saveReminders([
        buildReminder(id: 'a'),
        buildReminder(id: 'b'),
      ]);
      final changeTime = now.add(const Duration(minutes: 1));
      now = changeTime;

      await repository.saveReminders([
        buildReminder(id: 'a'),
        buildReminder(id: 'b', isDone: true),
      ]);

      final rows = {
        for (final r in await db.select(db.reminders).get()) r.id: r,
      };
      expect(rows['a']!.updatedAt, micros(insertTime));
      expect(rows['b']!.updatedAt, micros(changeTime));
    });

    test('birthday updated_at changes only with content', () async {
      final insertTime = now;
      await repository.saveBirthdays([buildBirthday(id: 'x')]);
      now = now.add(const Duration(minutes: 1));
      await repository.saveBirthdays([buildBirthday(id: 'x')]);
      expect(
        (await db.select(db.birthdays).get()).single.updatedAt,
        micros(insertTime),
      );

      await repository.saveBirthdays([
        buildBirthday(id: 'x', advanceOffsetsMinutes: const [0]),
      ]);
      expect(
        (await db.select(db.birthdays).get()).single.updatedAt,
        micros(now),
      );
    });

    test('settings updated_at changes only with content', () async {
      final insertTime = now;
      await repository.saveSettings(const AppSettings());
      now = now.add(const Duration(minutes: 1));
      await repository.saveSettings(const AppSettings());
      expect(
        (await db.select(db.settings).get()).single.updatedAt,
        micros(insertTime),
      );

      await repository
          .saveSettings(const AppSettings(notificationsEnabled: false));
      final row = (await db.select(db.settings).get()).single;
      expect(row.updatedAt, micros(now));
      expect(row.id, AppDatabase.settingsRowId);
    });
  });

  group('clearAll', () {
    test('hard deletes reminders, birthdays and settings', () async {
      await repository.saveReminders([
        buildReminder(id: 'a'),
        buildReminder(id: 'b'),
      ]);
      await repository.saveReminders([buildReminder(id: 'b')]); // a: silindi
      await repository.saveBirthdays([buildBirthday()]);
      await repository
          .saveSettings(const AppSettings(notificationsEnabled: false));

      await repository.clearAll();

      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect((await repository.loadSettings()).notificationsEnabled, isTrue);
      expect(await db.select(db.reminders).get(), isEmpty);
      expect(await db.select(db.birthdays).get(), isEmpty);
      expect(await db.select(db.settings).get(), isEmpty);
    });

    test('removes legacy keys and keeps the migration marker', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: jsonEncode([buildReminder(id: 'old').toJson()]),
        _keySettings: jsonEncode(const AppSettings().toJson()),
      });
      expect(await repository.loadReminders(), isNotEmpty);

      await repository.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_keyReminders), isFalse);
      expect(prefs.containsKey(_keySettings), isFalse);
      expect(await PrefsMigration.isDone(db), isTrue);
      expect(await newRepository().loadReminders(), isEmpty);
    });

    test('removes recovery backups', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: '{not json',
        _keyBirthdays: '{not json',
        _keySettings: '{not json',
      });
      await repository.loadReminders();
      expect(await repository.hasRecoveryBackup(), isTrue);

      await repository.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_backupReminders), isFalse);
      expect(prefs.containsKey(_backupBirthdays), isFalse);
      expect(prefs.containsKey(_backupSettings), isFalse);
      expect(await repository.hasRecoveryBackup(), isFalse);
    });
  });

  group('migration from SharedPreferences', () {
    Map<String, Object> legacyValues() => {
          _keyReminders: jsonEncode([
            buildReminder(
              id: 'r1',
              title: 'Eski',
              remindAt: DateTime(2026, 5, 1, 9),
            ).toJson(),
            buildReminder(id: 'r2', isDone: true).toJson(),
          ]),
          _keyBirthdays: jsonEncode([
            buildBirthday(id: 'b1', advanceOffsetsMinutes: const [60]).toJson(),
          ]),
          _keySettings: jsonEncode(
            const AppSettings(
              notificationsEnabled: false,
              themeMode: AppThemeModeIds.dark,
            ).toJson(),
          ),
        };

    test('JSON times come back identical to the old fromJson', () async {
      final raw = jsonEncode([
        {
          'id': 'local',
          'title': 'Yerel',
          'isDone': false,
          'createdAt': '2026-01-01T12:00:00.000',
          'remindAt': '2026-09-13T18:30:00.000',
        },
        {
          'id': 'utc',
          'title': 'UTC',
          'isDone': false,
          'createdAt': '2026-01-01T12:00:00.123456Z',
          'remindAt': '2026-09-13T15:30:00.000Z',
        },
        {
          'id': 'untimed',
          'title': 'Zamansız',
          'isDone': false,
          'createdAt': '2026-02-02T08:15:30.250',
          'remindAt': null,
        },
      ]);
      SharedPreferences.setMockInitialValues({_keyReminders: raw});
      final expected = [
        for (final item in jsonDecode(raw) as List)
          Reminder.fromJson(Map<String, dynamic>.from(item as Map)),
      ];

      final migrated = await repository.loadReminders();
      final reloaded = await newRepository().loadReminders();

      for (final loaded in [migrated, reloaded]) {
        expect(loaded.map((r) => r.id), expected.map((r) => r.id));
        for (var i = 0; i < expected.length; i++) {
          final e = expected[i];
          final a = loaded[i];
          expect(a.remindAt, e.remindAt, reason: e.id);
          expect(a.remindAt?.isUtc, e.remindAt?.isUtc, reason: e.id);
          expect(a.createdAt, e.createdAt, reason: e.id);
          expect(a.createdAt.isUtc, e.createdAt.isUtc, reason: e.id);
          expect(a.toJson(), e.toJson(), reason: e.id);
        }
      }
      expect(migrated.first.remindAt, DateTime(2026, 9, 13, 18, 30));
    });

    test('valid data is imported and legacy keys are kept', () async {
      final legacy = legacyValues();
      SharedPreferences.setMockInitialValues(legacy);

      final reminders = await repository.loadReminders();
      final birthdays = await repository.loadBirthdays();
      final settings = await repository.loadSettings();

      expect(reminders.map((r) => r.id), ['r1', 'r2']);
      expect(reminders[0].title, 'Eski');
      expect(reminders[0].remindAt, DateTime(2026, 5, 1, 9));
      expect(reminders[1].isDone, isTrue);
      expect(birthdays.single.advanceOffsetsMinutes, [60]);
      expect(settings.notificationsEnabled, isFalse);
      expect(settings.themeMode, AppThemeModeIds.dark);

      expect(await PrefsMigration.isDone(db), isTrue);
      expect((await db.select(db.reminders).get()).length, 2);
      final rows = await db.select(db.reminders).get();
      expect(rows.every((r) => r.updatedAt == micros(now)), isTrue);
      for (final key in legacy.keys) {
        expect(await stored(key), legacy[key], reason: key);
      }
      expect(await repository.hasRecoveryBackup(), isFalse);
    });

    test('re-running does not duplicate or overwrite', () async {
      SharedPreferences.setMockInitialValues(legacyValues());
      await repository.loadReminders();

      await repository.saveReminders([buildReminder(id: 'r1', title: 'Yeni')]);
      await PrefsMigration(clock: () => now).runIfNeeded(db);
      final second = newRepository();

      expect(
        (await second.loadReminders()).map((r) => r.title),
        ['Yeni'],
      );
      expect((await db.select(db.reminders).get()).length, 2); // r2 silindi
      expect((await db.select(db.birthdays).get()).length, 1);
    });

    test('an already migrated database ignores legacy keys', () async {
      await repository.loadReminders(); // boş geçiş, işaret yazılır
      SharedPreferences.setMockInitialValues(legacyValues());

      final other = newRepository();
      expect(await other.loadReminders(), isEmpty);
      expect(await other.loadBirthdays(), isEmpty);
      expect((await other.loadSettings()).notificationsEnabled, isTrue);
    });

    test('corrupt item: valid items imported, exact raw backed up', () async {
      final raw = jsonEncode([
        buildReminder(id: 'ok-1', title: 'Geçerli').toJson(),
        {'id': 42}, // title/createdAt eksik, id yanlış tipte
        buildReminder(id: 'ok-2', title: 'Geçerli 2').toJson(),
      ]);
      SharedPreferences.setMockInitialValues({_keyReminders: raw});

      expect(
        (await repository.loadReminders()).map((r) => r.id),
        ['ok-1', 'ok-2'],
      );
      expect(await stored(_backupReminders), raw);
      expect(await stored(_keyReminders), raw);
      expect(await repository.hasRecoveryBackup(), isTrue);
      expect(await PrefsMigration.isDone(db), isTrue);
    });

    test('failure falls back to SharedPreferences and retries later', () async {
      SharedPreferences.setMockInitialValues(legacyValues());
      // Geçişin ortasında (doğum günü eklerken) hata: tablo yok.
      await db.customStatement('DROP TABLE birthdays');

      final reminders = await repository.loadReminders();
      expect(reminders.map((r) => r.id), ['r1', 'r2']);
      expect((await repository.loadBirthdays()).single.id, 'b1');
      expect((await repository.loadSettings()).themeMode, AppThemeModeIds.dark);

      // Transaction geri alındı, işaret yok.
      expect(await db.select(db.reminders).get(), isEmpty);
      expect(await PrefsMigration.isDone(db), isFalse);

      // Bu oturumdaki yazmalar eski anahtarlara gider, kaybolmaz.
      await repository.saveReminders([reminders.first.copyWith(isDone: true)]);
      final legacyReminders = jsonDecode((await stored(_keyReminders))!);
      expect((legacyReminders as List).single['isDone'], isTrue);

      // Sonraki açılış: tablo onarıldı, geçiş yeniden denenir.
      await db.createMigrator().createTable(db.birthdays);
      final nextLaunch = newRepository();
      final migrated = await nextLaunch.loadReminders();
      expect(migrated.map((r) => r.id), ['r1']);
      expect(migrated.single.isDone, isTrue);
      expect((await nextLaunch.loadBirthdays()).single.id, 'b1');
      expect(await PrefsMigration.isDone(db), isTrue);
    });
  });

  group('corrupt legacy settings', () {
    test('undecodable JSON falls back to defaults and backs up raw', () async {
      SharedPreferences.setMockInitialValues({_keySettings: '{not json'});

      final settings = await repository.loadSettings();

      expect(settings.themeMode, AppThemeModeIds.system);
      expect(settings.notificationsEnabled, isTrue);
      expect(await stored(_backupSettings), '{not json');
    });

    test('non-object JSON falls back to defaults and backs up raw', () async {
      SharedPreferences.setMockInitialValues({_keySettings: '[1, 2]'});

      expect((await repository.loadSettings()).notificationsEnabled, isTrue);
      expect(await stored(_backupSettings), '[1, 2]');
    });

    test('one bad field falls back alone, other fields are kept', () async {
      final raw = jsonEncode({
        'notificationsEnabled': 'yes', // yanlış tip
        'themeMode': AppThemeModeIds.dark,
      });
      SharedPreferences.setMockInitialValues({_keySettings: raw});

      final settings = await repository.loadSettings();

      expect(settings.notificationsEnabled, isTrue);
      expect(settings.themeMode, AppThemeModeIds.dark);
      expect(await stored(_backupSettings), raw);
    });

    test('missing fields use defaults without a backup', () async {
      SharedPreferences.setMockInitialValues({
        _keySettings: jsonEncode({'notificationsEnabled': false}),
      });

      final settings = await repository.loadSettings();

      expect(settings.notificationsEnabled, isFalse);
      expect(settings.themeMode, AppThemeModeIds.system);
      expect(await repository.hasRecoveryBackup(), isFalse);
    });
  });

  group('corrupt legacy list', () {
    String storedRemindersWithOneCorruptItem() => jsonEncode([
          buildReminder(id: 'ok-1', title: 'Geçerli').toJson(),
          {'id': 42},
          buildReminder(id: 'ok-2', title: 'Geçerli 2').toJson(),
        ]);

    String storedBirthdaysWithOneCorruptItem() => jsonEncode([
          buildBirthday(id: 'ok-1').toJson(),
          {'id': 'bad', 'name': 'Bozuk', 'date': 'not-a-date'},
        ]);

    test('corrupt birthday item: valid kept and exact raw backed up', () async {
      final raw = storedBirthdaysWithOneCorruptItem();
      SharedPreferences.setMockInitialValues({_keyBirthdays: raw});

      final loaded = await repository.loadBirthdays();

      expect(loaded.map((b) => b.id), ['ok-1']);
      expect(await stored(_backupBirthdays), raw);
    });

    test('saving after recovery keeps valid items and the backup', () async {
      final raw = storedRemindersWithOneCorruptItem();
      SharedPreferences.setMockInitialValues({_keyReminders: raw});

      await repository.saveReminders(await repository.loadReminders());

      expect(
        (await repository.loadReminders()).map((r) => r.id),
        ['ok-1', 'ok-2'],
      );
      expect(await stored(_backupReminders), raw);
    });

    test('non-object list items are skipped', () async {
      final raw = jsonEncode([
        'string',
        7,
        null,
        buildReminder(id: 'ok').toJson(),
      ]);
      SharedPreferences.setMockInitialValues({_keyReminders: raw});

      expect((await repository.loadReminders()).map((r) => r.id), ['ok']);
      expect(await stored(_backupReminders), raw);
    });

    test('undecodable JSON returns [] and backs up raw', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: '[{"id": "a", ',
        _keyBirthdays: 'garbage',
      });

      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect(await stored(_backupReminders), '[{"id": "a", ');
      expect(await stored(_backupBirthdays), 'garbage');
    });

    test('non-list JSON returns [] and backs up raw', () async {
      final raw = jsonEncode({'id': 'a'});
      SharedPreferences.setMockInitialValues({
        _keyReminders: raw,
        _keyBirthdays: '42',
      });

      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect(await stored(_backupReminders), raw);
      expect(await stored(_backupBirthdays), '42');
    });

    test('a newer corrupt payload replaces the previous backup', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: 'old garbage',
        _backupReminders: 'older garbage',
      });

      await repository.loadReminders();

      expect(await stored(_backupReminders), 'old garbage');
    });
  });

  group('corrupt database row', () {
    test('unreadable birthday row is skipped', () async {
      await repository.saveBirthdays([
        buildBirthday(id: 'ok'),
        buildBirthday(id: 'bad'),
      ]);
      await (db.update(db.birthdays)..where((t) => t.id.equals('bad')))
          .write(const BirthdaysCompanion(date: Value('not-a-date')));

      expect((await repository.loadBirthdays()).map((b) => b.id), ['ok']);
    });
  });
}
