import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

/// F2.1 öncesi `SharedPreferences` JSON deposu.
///
/// Artık yalnızca iki yerde kullanılır:
/// - SharedPreferences → Drift **tek seferlik geçişi** (`PrefsMigration`)
///   eski verileri buradan okur.
/// - Geçiş (veya veritabanı açılışı) başarısız olursa `ReminderRepository` o
///   oturum boyunca bu depoyla çalışır; bir sonraki açılışta geçiş yeniden
///   denenir.
///
/// **Bozuk veri politikası (F1.4, değişmedi):**
/// - Listeler kayıt bazında çözülür; çözülemeyen öğeler atlanır, geçerli
///   öğeler döner.
/// - Yükleme sırasında herhangi bir sorun görülürse (JSON çözülemiyor, beklenen
///   tipte değil veya en az bir öğe/alan bozuk) ham dize **dokunulmadan**
///   `<anahtar>_backup` anahtarına yazılır ([backupKeyFor]).
/// - Anahtar başına tek yedek tutulur: en son sorunlu ham veri kazanır. Mevcut
///   yedek aynı içerikteyse tekrar yazılmaz. Yedek `clearAll` çağrılana kadar
///   kalır.
/// - Ayarlarda bozuk alanlar tek tek varsayılana düşer; diğer alanlar korunur.
class LegacyPrefsStore {
  static const keyReminders = 'reminders_v1';
  static const keySettings = 'app_settings_v1';
  static const keyBirthdays = 'birthdays_v1';

  static const _backupSuffix = '_backup';

  /// [key] için ham verinin yedeklendiği `SharedPreferences` anahtarı.
  static String backupKeyFor(String key) => '$key$_backupSuffix';

  static const dataKeys = [keyReminders, keySettings, keyBirthdays];

  /// Ayar anahtarı doluysa `true` (boş ayarlar varsayılandır, geçişe gerek yok).
  Future<bool> hasSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(keySettings) ?? '').isNotEmpty;
  }

  Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadList(prefs, keyReminders, Reminder.fromJson);
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(reminders.map((r) => r.toJson()).toList(growable: false));
    await prefs.setString(keyReminders, encoded);
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keySettings);
    if (raw == null || raw.isEmpty) return const AppSettings();

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      await _backupRaw(prefs, keySettings, raw);
      return const AppSettings();
    }
    if (decoded is! Map) {
      await _backupRaw(prefs, keySettings, raw);
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

    if (hadProblem) await _backupRaw(prefs, keySettings, raw);
    return AppSettings(
      notificationsEnabled: notificationsEnabled,
      themeMode: themeMode,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySettings, jsonEncode(settings.toJson()));
  }

  Future<List<Birthday>> loadBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadList(prefs, keyBirthdays, Birthday.fromJson);
  }

  Future<void> saveBirthdays(List<Birthday> birthdays) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(birthdays.map((b) => b.toJson()).toList(growable: false));
    await prefs.setString(keyBirthdays, encoded);
  }

  /// Herhangi bir anahtar için kurtarma yedeği varsa `true` (salt okunur).
  Future<bool> hasRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return dataKeys.any((k) => prefs.containsKey(backupKeyFor(k)));
  }

  /// Eski veri anahtarlarını ve kurtarma yedeklerini siler.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in dataKeys) {
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
