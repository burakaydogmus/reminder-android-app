import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import 'package:reminder/domain/category_label_migration.dart';
import 'package:reminder/domain/model/reminder_category.dart';

part 'app_database.g.dart';

// Zaman sütunları iki türdür (dönüşüm `row_mapping.dart` içinde; domain
// modelleri değişmez):
// - Kullanıcı/model zamanları (`created_at`, `remind_at`, `birthdays.date`):
//   JSON dönemindeki gibi `DateTime.toIso8601String()` metni (TEXT). Yerel
//   değerde saat dilimi eki yoktur, yani **duvar saati** olarak saklanır: saat
//   dilimi değişince "18:30" yine 18:30 kalır; `DateTime.parse` aynı alanları
//   ve aynı `isUtc` değerini döndürür.
// - Depo defter alanları (`updated_at`, `deleted_at`): UTC epoch
//   **mikrosaniye** (INTEGER).
//
// `position`: kaydedilen listedeki sıra (SharedPreferences JSON'daki liste
// sırasının karşılığı). `updated_at` / `deleted_at`: senkrona hazır alanlar
// (F7.1); yalnızca depo yönetir, yüklemeler `deleted_at IS NULL` süzer.

/// `Reminder` satırları.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDone => boolean()();
  TextColumn get createdAt => text()();
  TextColumn get remindAt => text().nullable()();
  TextColumn get categoryId => text()();
  TextColumn get customCategoryLabel => text().nullable()();
  BoolColumn get locationTriggerEnabled => boolean()();
  RealColumn get locationLatitude => real().nullable()();
  RealColumn get locationLongitude => real().nullable()();
  RealColumn get locationRadiusMeters => real()();
  TextColumn get locationPlaceLabel => text().nullable()();
  IntColumn get position => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  /// Tekrar kuralı (v2, F3.1): `RecurrenceRule.toJson()` JSON metni;
  /// `NULL` = tekrar yok (v1 satırları).
  TextColumn get recurrence => text().nullable()();

  /// Öncelik (v4, F3.4): 0 yok … 3 yüksek (`ReminderPriority`). Eski
  /// satırlar 0 alır.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Sabitlenmiş (v4, F3.4). Eski satırlar `false` alır.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// `Subtask` satırları (v3, F3.3): hatırlatıcının maddeleri.
///
/// Birincil anahtar `(reminder_id, id)`: madde kimliği yalnızca kendi
/// hatırlatıcısı içinde tekildir. `position` hatırlatıcı içindeki sıra.
/// Hatırlatıcıyla aynı transaction'da yazılır; hatırlatıcı yumuşak
/// silinince maddeleri de `deleted_at` alır, geri gelince onlar da gelir.
@DataClassName('SubtaskRow')
class Subtasks extends Table {
  TextColumn get reminderId => text().references(Reminders, #id)();
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean()();
  IntColumn get position => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {reminderId, id};
}

/// `ReminderCategory` satırları (v5, F4.3).
///
/// Kullanıcı kategorileri ve (sıralama kaydedildiyse) yerleşik kategorilerin
/// sırası. Yerleşiklerin adı/rengi/ikonu koddan gelir (`CategoryCatalog`);
/// yerleşik satır yoksa yerleşikler başta varsayılır. `color_key`
/// `KorColorKey.storageKey`, `icon_key` `CategoryIconKeys` değeridir; hex
/// saklanmaz. Kullanıcı kategorisi silinince `deleted_at` alır, hatırlatıcıları
/// "Diğer"e taşınır.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorKey => text()();
  TextColumn get iconKey => text()();
  IntColumn get position => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// `Birthday` satırları.
@DataClassName('BirthdayRow')
class Birthdays extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();

  /// Takvim tarihi: `DateTime.toIso8601String()` (yerel değer için saat dilimi
  /// eki yok). Anlık zaman değil; saat dilimi değişince gün kaymasın diye
  /// JSON dönemindeki biçimle aynen saklanır.
  TextColumn get date => text()();
  IntColumn get notifyHour => integer()();
  IntColumn get notifyMinute => integer()();

  /// Önbildirim dakikaları, JSON dizi metni (örn. `[0,1440]`).
  TextColumn get advanceOffsetsMinutes => text()();
  TextColumn get createdAt => text()();
  IntColumn get position => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tek satırlık `AppSettings` tablosu (`id` her zaman
/// [AppDatabase.settingsRowId]).
@DataClassName('SettingsRow')
class Settings extends Table {
  IntColumn get id => integer()();
  BoolColumn get notificationsEnabled => boolean()();
  TextColumn get themeMode => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Depo iç durumu (anahtar/değer), örn. SharedPreferences geçiş işareti.
/// `clearAll` bu tabloyu silmez.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Reminders, Subtasks, Categories, Birthdays, Settings, AppMeta],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] verilmezse cihazdaki `reminder.sqlite` dosyası açılır
  /// ([openDefaultConnection]). Testler `NativeDatabase.memory()` geçer.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? openDefaultConnection());

  static const settingsRowId = 1;

  /// SharedPreferences → Drift tek seferlik geçişinin tamamlandığını gösteren
  /// [AppMeta] anahtarı.
  static const prefsMigrationKey = 'prefs_migration_v1';

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Şema değişikliğinde: schemaVersion'ı artır, `drift_schemas/`
          // altına yeni dökümü al ve adımları buraya ekle (bkz. CLAUDE.md).
          // Adımlar sırayla çalışır; her biri yalnızca kendi sürümünü ekler.
          if (from < 2) {
            // v2 (F3.1): tekrar kuralı. Eski satırlar NULL = tekrar yok.
            await m.addColumn(reminders, reminders.recurrence);
          }
          if (from < 3) {
            // v3 (F3.3): maddeler tablosu. Eski hatırlatıcıların maddesi yok.
            await m.createTable(subtasks);
          }
          if (from < 4) {
            // v4 (F3.4): öncelik ve sabitleme. Varsayılanlar (0, false)
            // mevcut satırlara uygulanır.
            await m.addColumn(reminders, reminders.priority);
            await m.addColumn(reminders, reminders.pinned);
          }
          if (from < 5) {
            // v5 (F4.3): kategoriler tablosu; "Diğer + özel ad" kayıtları
            // kullanıcı kategorilerine dönüşür. `custom_category_label`
            // geri dönüş güvenliği için olduğu gibi kalır.
            await m.createTable(categories);
            await migrateCustomCategoryLabels(this);
          }
          if (to > 5) {
            throw UnsupportedError('No migration from v$from to v$to');
          }
        },
      );

  /// v4 → v5 adımı (F4.3): silinmemiş `other` hatırlatıcılarının
  /// `custom_category_label` değerlerini [CategoryLabelMigration] kuralıyla
  /// kullanıcı kategorilerine çevirir ve bu hatırlatıcıların `category_id`
  /// değerini yeni kategoriye yönlendirir.
  ///
  /// Şema sınıflarına değil ham SQL'e dayanır; böylece ileride tablolar
  /// değişse de bu adım v5 şekliyle çalışır.
  static Future<void> migrateCustomCategoryLabels(
    GeneratedDatabase db, {
    DateTime Function() clock = DateTime.now,
  }) async {
    final rows = await db
        .customSelect(
          "SELECT id, custom_category_label FROM reminders "
          "WHERE category_id = 'other' AND deleted_at IS NULL "
          "AND custom_category_label IS NOT NULL ORDER BY position",
        )
        .get();
    final existing = await db
        .customSelect(
          'SELECT id, name, color_key, icon_key, position FROM categories '
          'WHERE deleted_at IS NULL',
        )
        .get();
    final plan = CategoryLabelMigration.plan(
      [
        for (final row in rows)
          (
            row.read<String>('id'),
            row.readNullable<String>('custom_category_label'),
          ),
      ],
      existing: CategoryCatalog([
        for (final row in existing)
          ReminderCategory(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            colorKey: row.read<String>('color_key'),
            iconKey: row.read<String>('icon_key'),
            position: row.read<int>('position'),
          ),
      ]),
    );
    if (plan.isEmpty) return;
    final now = clock().microsecondsSinceEpoch;
    for (final c in plan.created) {
      await db.customStatement(
        'INSERT OR IGNORE INTO categories '
        '(id, name, color_key, icon_key, position, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, NULL)',
        [c.id, c.name, c.colorKey, c.iconKey, c.position, now],
      );
    }
    for (final MapEntry(key: reminderId, value: categoryId)
        in plan.assignments.entries) {
      await db.customStatement(
        'UPDATE reminders SET category_id = ?, updated_at = ? WHERE id = ?',
        [categoryId, now, reminderId],
      );
    }
  }

  /// Uygulama veritabanı bağlantısı.
  ///
  /// Ana uygulama, geofence callback'i ve ana ekran widget callback'i **ayrı
  /// Flutter engine'lerinde** çalışır. `shareAcrossIsolates` yalnızca aynı
  /// engine içindeki isolate'leri buluşturur; bu yüzden her engine aynı dosyaya
  /// kendi bağlantısını açar. Eşzamanlı erişim için drift belgelerinin önerdiği
  /// gibi WAL günlüğü ve `busy_timeout` açılır: okuyucular yazanı engellemez,
  /// kilitli yazma hemen hata vermek yerine bekleyip yeniden dener.
  static QueryExecutor openDefaultConnection() {
    return driftDatabase(
      name: 'reminder',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        setup: configureConnection,
      ),
    );
  }

  /// Her yeni SQLite bağlantısında çalışan PRAGMA'lar.
  static void configureConnection(CommonDatabase database) {
    database
      ..execute('PRAGMA journal_mode = WAL;')
      ..execute('PRAGMA busy_timeout = 5000;');
  }
}
