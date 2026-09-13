import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

/// Hatırlatıcı, doğum günü ve ayarları `SharedPreferences` içinde JSON olarak
/// saklar.
///
/// **Bozuk veri politikası (F1.4):**
/// - Listeler kayıt bazında çözülür; çözülemeyen öğeler atlanır, geçerli
///   öğeler döner. Böylece sonraki `save*` çağrısı yalnızca bozuk öğeleri
///   kaybeder, geçerli verinin üzerine `[]` yazılmaz.
/// - Yükleme sırasında herhangi bir sorun görülürse (JSON çözülemiyor, beklenen
///   tipte değil veya en az bir öğe/alan bozuk) ham dize **dokunulmadan**
///   `<anahtar>_backup` anahtarına yazılır ([backupKeyFor]).
/// - Anahtar başına tek yedek tutulur: en son sorunlu ham veri kazanır. Mevcut
///   yedek aynı içerikteyse tekrar yazılmaz. Sorunsuz yüklemeler yedeğe
///   dokunmaz; yedek, [clearAll] çağrılana kadar kalır (F2.1/F2.2 kurtarma için
///   kullanabilir).
/// - Ayarlarda bozuk alanlar tek tek varsayılana düşer; diğer alanlar korunur.
class ReminderRepository {
  static const _keyReminders = 'reminders_v1';
  static const _keySettings = 'app_settings_v1';
  static const _keyBirthdays = 'birthdays_v1';

  static const _backupSuffix = '_backup';

  /// [key] için ham verinin yedeklendiği `SharedPreferences` anahtarı.
  static String backupKeyFor(String key) => '$key$_backupSuffix';

  static const _dataKeys = [_keyReminders, _keySettings, _keyBirthdays];

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

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      await _backupRaw(prefs, _keySettings, raw);
      return const AppSettings();
    }
    if (decoded is! Map) {
      await _backupRaw(prefs, _keySettings, raw);
      return const AppSettings();
    }

    const defaults = AppSettings();
    var hadProblem = false;

    var notificationsEnabled = defaults.notificationsEnabled;
    final rawNotifications = decoded['notificationsEnabled'];
    if (rawNotifications is bool) {
      notificationsEnabled = rawNotifications;
    } else if (rawNotifications != null) {
      hadProblem = true;
    }

    var themeMode = defaults.themeMode;
    final rawTheme = decoded['themeMode'];
    if (rawTheme is String && AppThemeModeIds.values.contains(rawTheme)) {
      themeMode = rawTheme;
    } else if (rawTheme != null) {
      hadProblem = true;
    }

    if (hadProblem) await _backupRaw(prefs, _keySettings, raw);
    return AppSettings(
      notificationsEnabled: notificationsEnabled,
      themeMode: themeMode,
    );
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

  /// Herhangi bir anahtar için kurtarma yedeği varsa `true` (salt okunur).
  Future<bool> hasRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return _dataKeys.any((k) => prefs.containsKey(backupKeyFor(k)));
  }

  /// Tüm verileri ve kurtarma yedeklerini siler ("Tüm verileri sıfırla").
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _dataKeys) {
      await prefs.remove(key);
      await prefs.remove(backupKeyFor(key));
    }
  }

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
      await _backupRaw(prefs, key, raw);
      return [];
    }
    if (decoded is! List) {
      await _backupRaw(prefs, key, raw);
      return [];
    }

    final result = <T>[];
    var hadProblem = false;
    for (final item in decoded) {
      try {
        result.add(fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        // Model fromJson'ları TypeError/FormatException fırlatabilir; öğe atlanır.
        hadProblem = true;
      }
    }
    if (hadProblem) await _backupRaw(prefs, key, raw);
    return result;
  }

  Future<void> _backupRaw(
    SharedPreferences prefs,
    String key,
    String raw,
  ) async {
    final backupKey = backupKeyFor(key);
    if (prefs.getString(backupKey) == raw) return;
    await prefs.setString(backupKey, raw);
  }
}
