import 'package:reminder/data/db/app_database.dart';

/// Isolate başına tek, referans sayımlı [AppDatabase].
///
/// `ReminderRepository()` veritabanını ilk kullanımda [acquire] ile alır,
/// `close()` ile [release] eder; son kullanıcı bırakınca bağlantı kapanır.
/// Ana uygulamanın deposu kapanmaz (uygulama ömrü boyunca açık kalır); arka
/// plan callback'leri (geofence, ana ekran widget'ı) işleri bitince kapatır.
/// Aynı engine'de üst üste binen callback'ler aynı bağlantıyı paylaşır.
class AppDatabaseHost {
  AppDatabaseHost._();

  static AppDatabase? _database;
  static int _users = 0;

  static AppDatabase acquire() {
    _users++;
    return _database ??= AppDatabase();
  }

  static Future<void> release() async {
    if (_users == 0) return;
    _users--;
    if (_users > 0) return;
    final database = _database;
    _database = null;
    await database?.close();
  }
}
