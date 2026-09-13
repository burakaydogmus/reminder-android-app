import 'package:drift/drift.dart';

import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/db/row_mapping.dart';
import 'package:reminder/data/legacy_prefs_store.dart';

/// SharedPreferences JSON → Drift tek seferlik geçişi (F2.1).
///
/// - Eski anahtarlar (`reminders_v1`, `birthdays_v1`, `app_settings_v1`)
///   [LegacyPrefsStore] ile F1.4'ün toleranslı ayrıştırmasıyla okunur; bozuk
///   veri yine `<anahtar>_backup` anahtarına yedeklenir.
/// - Tüm satırlar ve [AppDatabase.prefsMigrationKey] işareti **tek
///   transaction**'da yazılır: ya hepsi ya hiçbiri. Hata olursa işaret
///   yazılmaz, bir sonraki açılışta yeniden denenir.
/// - İdempotent: işaret varsa hiçbir şey yapılmaz; transaction içinde işaret
///   yeniden kontrol edilir ve satırlar `INSERT OR IGNORE` ile yazılır (başka
///   bir engine aynı anda geçirmişse kopya oluşmaz, yeni veri ezilmez).
/// - Eski anahtarlar **silinmez** (bir sürüm boyunca güvenlik ağı).
class PrefsMigration {
  PrefsMigration({LegacyPrefsStore? legacy, DateTime Function()? clock})
      : _legacy = legacy ?? LegacyPrefsStore(),
        _clock = clock ?? DateTime.now;

  final LegacyPrefsStore _legacy;
  final DateTime Function() _clock;

  static Future<bool> isDone(AppDatabase db) async {
    final row = await (db.select(db.appMeta)
          ..where((t) => t.key.equals(AppDatabase.prefsMigrationKey)))
        .getSingleOrNull();
    return row != null;
  }

  /// Geçiş gerekiyorsa çalıştırır. Hata fırlatırsa veritabanı değişmemiştir.
  Future<void> runIfNeeded(AppDatabase db) async {
    if (await isDone(db)) return;

    final reminders = await _legacy.loadReminders();
    final birthdays = await _legacy.loadBirthdays();
    final hasSettings = await _legacy.hasSettings();
    final settings = await _legacy.loadSettings();
    final now = toEpochMicros(_clock());

    await db.transaction(() async {
      if (await isDone(db)) return;
      await db.batch((b) {
        b.insertAll(
          db.reminders,
          [
            for (var i = 0; i < reminders.length; i++)
              reminderToRow(reminders[i], position: i, updatedAt: now),
          ],
          mode: InsertMode.insertOrIgnore,
        );
        b.insertAll(
          db.birthdays,
          [
            for (var i = 0; i < birthdays.length; i++)
              birthdayToRow(birthdays[i], position: i, updatedAt: now),
          ],
          mode: InsertMode.insertOrIgnore,
        );
        if (hasSettings) {
          b.insert(
            db.settings,
            settingsToRow(settings, updatedAt: now),
            mode: InsertMode.insertOrIgnore,
          );
        }
        b.insert(
          db.appMeta,
          AppMetaRow(
            key: AppDatabase.prefsMigrationKey,
            value: _clock().toUtc().toIso8601String(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }
}
