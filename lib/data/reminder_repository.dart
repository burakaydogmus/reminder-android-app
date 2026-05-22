import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

class ReminderRepository {
  static const _keyReminders = 'reminders_v1';
  static const _keySettings = 'app_settings_v1';
  static const _keyBirthdays = 'birthdays_v1';

  Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReminders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(reminders.map((r) => r.toJson()).toList(growable: false));
    await prefs.setString(_keyReminders, encoded);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  Future<List<Birthday>> loadBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyBirthdays);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Birthday.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBirthdays(List<Birthday> birthdays) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(birthdays.map((b) => b.toJson()).toList(growable: false));
    await prefs.setString(_keyBirthdays, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReminders);
    await prefs.remove(_keySettings);
    await prefs.remove(_keyBirthdays);
  }
}
