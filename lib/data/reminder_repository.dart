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
    return _loadList(prefs, _keyReminders, Reminder.fromJson);
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
    return _loadList(prefs, _keyBirthdays, Birthday.fromJson);
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

  /// Listeyi kayıt bazında çözer: çözülemeyen öğeler atlanır, geçerli öğeler
  /// döner. Böylece tek bozuk öğe, sonraki kayıtta tüm listenin silinmesine yol
  /// açmaz.
  Future<List<T>> _loadList<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return [];
    }
    if (decoded is! List) return [];

    final result = <T>[];
    for (final item in decoded) {
      try {
        result.add(fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        // Model fromJson'ları TypeError/FormatException fırlatabilir; öğe atlanır.
      }
    }
    return result;
  }
}
