import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/db/app_database_host.dart';
import 'package:reminder/data/db/row_mapping.dart';
import 'package:reminder/data/legacy_prefs_store.dart';
import 'package:reminder/data/prefs_migration.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

/// Hatırlatıcı, doğum günü ve ayarları Drift (SQLite) veritabanında saklar
/// (F2.1). Genel arayüz ve anlamı SharedPreferences dönemiyle aynıdır.
///
/// **Açılış:** veritabanı ilk çağrıda tembelce açılır ve gerekirse
/// SharedPreferences'tan tek seferlik geçiş ([PrefsMigration]) çalışır.
/// Açılış veya geçiş başarısız olursa depo **o nesnenin ömrü boyunca** eski
/// [LegacyPrefsStore] ile çalışır (eski veri görünür kalır, yazmalar eski
/// anahtarlara gider); geçiş işareti yazılmadığı için bir sonraki açılışta
/// yeniden denenir.
///
/// **Kaydetme:** `saveX(list)` tek transaction'da listeyi upsert eder ve
/// listede olmayan satırları `deleted_at` ile yumuşak siler. İçeriği (veya
/// sırası) değişmeyen satırlara dokunulmaz; değişen, yeni veya geri gelen
/// satırlarda `updated_at` güncellenir. Yüklemeler silinmiş satırları süzer.
///
/// **Bozuk veri (F1.4):** eski JSON anahtarları geçişte toleranslı çözülür ve
/// sorunlu ham veri `<anahtar>_backup` anahtarına yedeklenir ([backupKeyFor],
/// [hasRecoveryBackup]). Veritabanında bozuk bir doğum günü satırı atlanır.
class ReminderRepository {
  /// [database] verilirse depo onu kullanır ve kapatmaz (sahibi çağırandır).
  /// Verilmezse isolate'in paylaşılan veritabanı ([AppDatabaseHost]) ilk
  /// kullanımda alınır ve [close] ile bırakılır.
  ReminderRepository({
    AppDatabase? database,
    LegacyPrefsStore? legacy,
    PrefsMigration? migration,
    DateTime Function()? clock,
  })  : _injectedDatabase = database,
        _legacy = legacy ?? LegacyPrefsStore(),
        _clock = clock ?? DateTime.now,
        _migration = migration;

  final AppDatabase? _injectedDatabase;
  final LegacyPrefsStore _legacy;
  final PrefsMigration? _migration;
  final DateTime Function() _clock;

  Future<_Storage>? _storage;
  bool _acquiredHostDatabase = false;

  /// [key] için ham verinin yedeklendiği `SharedPreferences` anahtarı.
  static String backupKeyFor(String key) => LegacyPrefsStore.backupKeyFor(key);

  Future<List<Reminder>> loadReminders() async {
    final storage = await _open();
    if (storage.database case final db?) {
      return db.transaction(() async {
        final rows = await (db.select(db.reminders)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        final subtaskRows = await (db.select(db.subtasks)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        final byReminder = <String, List<SubtaskRow>>{};
        for (final row in subtaskRows) {
          (byReminder[row.reminderId] ??= []).add(row);
        }
        return [
          for (final row in rows)
            reminderFromRow(row, subtasks: byReminder[row.id] ?? const []),
        ];
      });
    }
    return _legacy.loadReminders();
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final storage = await _open();
    final db = storage.database;
    if (db == null) return _legacy.saveReminders(reminders);

    final now = toEpochMicros(_clock());
    await db.transaction(() async {
      final existing = {
        for (final row in await db.select(db.reminders).get()) row.id: row,
      };
      final kept = <String>{};
      for (var i = 0; i < reminders.length; i++) {
        final r = reminders[i];
        kept.add(r.id);
        final old = existing[r.id];
        final unchanged = old != null &&
            reminderToRow(r, position: i, updatedAt: old.updatedAt) == old;
        if (unchanged) continue;
        // toCompanion(false): null değerler de yazılır (deleted_at, note...);
        // satır nesnesi doğrudan verilirse null sütunlar atlanırdı.
        await db.into(db.reminders).insertOnConflictUpdate(
            reminderToRow(r, position: i, updatedAt: now).toCompanion(false));
      }
      await (db.update(db.reminders)
            ..where((t) => t.deletedAt.isNull() & t.id.isNotIn(kept)))
          .write(RemindersCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
      await _saveSubtasks(db, reminders, now);
    });
  }

  /// Maddeler (F3.3), hatırlatıcılarla aynı transaction'da ve aynı kuralla:
  /// değişen/yeni/geri gelen satır upsert (`updated_at` = now), listede
  /// olmayan madde — silinen hatırlatıcınınkiler dahil — yumuşak silinir.
  /// Geri alınan (yeniden kaydedilen) hatırlatıcının maddeleri de geri gelir.
  Future<void> _saveSubtasks(
    AppDatabase db,
    List<Reminder> reminders,
    int now,
  ) async {
    final existing = {
      for (final row in await db.select(db.subtasks).get())
        (row.reminderId, row.id): row,
    };
    final kept = <(String, String)>{};
    for (final r in reminders) {
      for (var i = 0; i < r.subtasks.length; i++) {
        final s = r.subtasks[i];
        final k = (r.id, s.id);
        // Aynı hatırlatıcıda tekrarlanan kimlik: ilki kazanır.
        if (!kept.add(k)) continue;
        final old = existing[k];
        final unchanged = old != null &&
            subtaskToRow(s,
                    reminderId: r.id, position: i, updatedAt: old.updatedAt) ==
                old;
        if (unchanged) continue;
        await db.into(db.subtasks).insertOnConflictUpdate(
              subtaskToRow(s, reminderId: r.id, position: i, updatedAt: now)
                  .toCompanion(false),
            );
      }
    }
    for (final entry in existing.entries) {
      if (entry.value.deletedAt != null || kept.contains(entry.key)) continue;
      await (db.update(db.subtasks)
            ..where((t) =>
                t.reminderId.equals(entry.value.reminderId) &
                t.id.equals(entry.value.id)))
          .write(SubtasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
    }
  }

  Future<AppSettings> loadSettings() async {
    final storage = await _open();
    if (storage.database case final db?) {
      final row = await (db.select(db.settings)
            ..where((t) => t.id.equals(AppDatabase.settingsRowId)))
          .getSingleOrNull();
      return row == null ? const AppSettings() : settingsFromRow(row);
    }
    return _legacy.loadSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final storage = await _open();
    final db = storage.database;
    if (db == null) return _legacy.saveSettings(settings);

    final now = toEpochMicros(_clock());
    await db.transaction(() async {
      final old = await (db.select(db.settings)
            ..where((t) => t.id.equals(AppDatabase.settingsRowId)))
          .getSingleOrNull();
      if (old != null &&
          settingsToRow(settings, updatedAt: old.updatedAt) == old) {
        return;
      }
      await db
          .into(db.settings)
          .insertOnConflictUpdate(settingsToRow(settings, updatedAt: now));
    });
  }

  Future<List<Birthday>> loadBirthdays() async {
    final storage = await _open();
    if (storage.database case final db?) {
      final rows = await (db.select(db.birthdays)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      final result = <Birthday>[];
      for (final row in rows) {
        try {
          result.add(birthdayFromRow(row));
        } catch (e) {
          debugPrint('Skipping unreadable birthday row ${row.id}: $e');
        }
      }
      return result;
    }
    return _legacy.loadBirthdays();
  }

  Future<void> saveBirthdays(List<Birthday> birthdays) async {
    final storage = await _open();
    final db = storage.database;
    if (db == null) return _legacy.saveBirthdays(birthdays);

    final now = toEpochMicros(_clock());
    await db.transaction(() async {
      final existing = {
        for (final row in await db.select(db.birthdays).get()) row.id: row,
      };
      final kept = <String>{};
      for (var i = 0; i < birthdays.length; i++) {
        final b = birthdays[i];
        kept.add(b.id);
        final old = existing[b.id];
        final unchanged = old != null &&
            birthdayToRow(b, position: i, updatedAt: old.updatedAt) == old;
        if (unchanged) continue;
        await db.into(db.birthdays).insertOnConflictUpdate(
            birthdayToRow(b, position: i, updatedAt: now).toCompanion(false));
      }
      await (db.update(db.birthdays)
            ..where((t) => t.deletedAt.isNull() & t.id.isNotIn(kept)))
          .write(BirthdaysCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }

  /// Herhangi bir anahtar için kurtarma yedeği varsa `true` (salt okunur).
  Future<bool> hasRecoveryBackup() => _legacy.hasRecoveryBackup();

  /// Tüm verileri siler ("Tüm verileri sıfırla"): tablolardaki satırlar
  /// (yumuşak silinmişler dahil) kalıcı silinir; eski SharedPreferences
  /// anahtarları ve kurtarma yedekleri de kaldırılır. Geçiş işareti korunur,
  /// böylece silinen veri bir sonraki açılışta eski anahtarlardan geri gelmez.
  Future<void> clearAll() async {
    final storage = await _open();
    if (storage.database case final db?) {
      await db.transaction(() async {
        await db.delete(db.subtasks).go();
        await db.delete(db.reminders).go();
        await db.delete(db.birthdays).go();
        await db.delete(db.settings).go();
      });
    }
    await _legacy.clearAll();
  }

  /// Paylaşılan veritabanını bırakır (arka plan callback'lerinin sonunda
  /// çağrılır). Sonraki bir çağrı veritabanını yeniden açar. Enjekte edilen
  /// veritabanı kapatılmaz.
  Future<void> close() async {
    final pending = _storage;
    _storage = null;
    if (pending != null) await pending;
    if (_acquiredHostDatabase) {
      _acquiredHostDatabase = false;
      await AppDatabaseHost.release();
    }
  }

  Future<_Storage> _open() => _storage ??= _openStorage();

  Future<_Storage> _openStorage() async {
    AppDatabase? db = _injectedDatabase;
    try {
      if (db == null) {
        db = AppDatabaseHost.acquire();
        _acquiredHostDatabase = true;
      }
      await (_migration ?? PrefsMigration(legacy: _legacy, clock: _clock))
          .runIfNeeded(db);
      return _Storage(db);
    } catch (e, st) {
      debugPrint(
        'Drift storage unavailable, using SharedPreferences for this '
        'session (migration retried on next launch): $e\n$st',
      );
      return const _Storage(null);
    }
  }
}

/// Açılış sonucu: `database == null` ise oturum SharedPreferences'ta çalışır.
class _Storage {
  const _Storage(this.database);

  final AppDatabase? database;
}
