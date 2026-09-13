import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';

// Repository'nin kullandığı SharedPreferences anahtarları (private sabitler).
const _keyReminders = 'reminders_v1';
const _keySettings = 'app_settings_v1';
const _keyBirthdays = 'birthdays_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReminderRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = ReminderRepository();
  });

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

    test('empty strings are treated as empty storage', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: '',
        _keyBirthdays: '',
        _keySettings: '',
      });
      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect((await repository.loadSettings()).notificationsEnabled, isTrue);
    });
  });

  group('save/load round-trip', () {
    test('reminders', () async {
      final reminders = [
        buildReminder(id: 'a', title: 'A', remindAt: DateTime(2026, 5, 1, 9)),
        buildReminder(id: 'b', title: 'B', isDone: true, note: 'not'),
      ];

      await repository.saveReminders(reminders);
      final loaded = await repository.loadReminders();

      expect(loaded.map((r) => r.id), ['a', 'b']);
      expect(loaded[0].remindAt, DateTime(2026, 5, 1, 9));
      expect(loaded[1].isDone, isTrue);
      expect(loaded[1].note, 'not');
    });

    test('birthdays', () async {
      final birthdays = [
        buildBirthday(id: 'x', name: 'X', advanceOffsetsMinutes: const [60]),
        buildBirthday(id: 'y', name: 'Y', note: 'hediye'),
      ];

      await repository.saveBirthdays(birthdays);
      final loaded = await repository.loadBirthdays();

      expect(loaded.map((b) => b.id), ['x', 'y']);
      expect(loaded[0].advanceOffsetsMinutes, [60]);
      expect(loaded[1].note, 'hediye');
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
  });

  test('clearAll removes reminders, birthdays and settings', () async {
    await repository.saveReminders([buildReminder()]);
    await repository.saveBirthdays([buildBirthday()]);
    await repository
        .saveSettings(const AppSettings(notificationsEnabled: false));

    await repository.clearAll();

    expect(await repository.loadReminders(), isEmpty);
    expect(await repository.loadBirthdays(), isEmpty);
    expect((await repository.loadSettings()).notificationsEnabled, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_keyReminders), isFalse);
    expect(prefs.containsKey(_keyBirthdays), isFalse);
    expect(prefs.containsKey(_keySettings), isFalse);
  });

  test('corrupt settings JSON falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({_keySettings: '{not json'});
    expect((await repository.loadSettings()).themeMode, AppThemeModeIds.system);
  });

  group('corrupt stored list', () {
    String storedRemindersWithOneCorruptItem() => jsonEncode([
          buildReminder(id: 'ok-1', title: 'Geçerli').toJson(),
          {'id': 42}, // title/createdAt eksik, id yanlış tipte
          buildReminder(id: 'ok-2', title: 'Geçerli 2').toJson(),
        ]);

    String storedBirthdaysWithOneCorruptItem() => jsonEncode([
          buildBirthday(id: 'ok-1').toJson(),
          {'id': 'bad', 'name': 'Bozuk', 'date': 'not-a-date'},
        ]);

    test('corrupt reminder item keeps the valid items', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: storedRemindersWithOneCorruptItem(),
      });

      final loaded = await repository.loadReminders();

      expect(loaded.map((r) => r.id), ['ok-1', 'ok-2']);
    });

    test('corrupt birthday item keeps the valid items', () async {
      SharedPreferences.setMockInitialValues({
        _keyBirthdays: storedBirthdaysWithOneCorruptItem(),
      });

      final loaded = await repository.loadBirthdays();

      expect(loaded.map((b) => b.id), ['ok-1']);
    });

    test('non-object list items are skipped', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: jsonEncode([
          'string',
          7,
          null,
          buildReminder(id: 'ok').toJson(),
        ]),
      });

      expect((await repository.loadReminders()).map((r) => r.id), ['ok']);
    });

    test('undecodable or non-list JSON returns []', () async {
      SharedPreferences.setMockInitialValues({
        _keyReminders: '[{"id": "a", ',
        _keyBirthdays: '42',
      });

      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
    });
  });
}
