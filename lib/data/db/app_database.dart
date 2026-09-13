import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

part 'app_database.g.dart';

// Zaman damgası sütunları (`*_at`): UTC epoch **mikrosaniye** (INTEGER).
// `DateTime.microsecondsSinceEpoch` saat diliminden bağımsızdır; okurken
// `DateTime.fromMicrosecondsSinceEpoch` yerel saate çevirir. Dönüşüm
// `ReminderRepository` içindedir; domain modelleri değişmez.
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
  IntColumn get createdAt => integer()();
  IntColumn get remindAt => integer().nullable()();
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
  IntColumn get createdAt => integer()();
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

@DriftDatabase(tables: [Reminders, Birthdays, Settings, AppMeta])
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Şema değişikliğinde: schemaVersion'ı artır, `drift_schemas/`
          // altına yeni dökümü al ve adımları buraya ekle (bkz. CLAUDE.md).
          throw UnsupportedError('No migration from v$from to v$to');
        },
      );

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
