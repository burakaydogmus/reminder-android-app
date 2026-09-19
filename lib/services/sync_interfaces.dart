import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

/// OS geofence kayıtlarını hatırlatıcılarla senkronlayan servis.
///
/// Gerçek uygulama: `GeofenceService`. `ReminderCubit`'e constructor ile
/// verilir; testlerde mock'lanır.
abstract interface class GeofenceSync {
  Future<void> syncWithReminders(
    List<Reminder> reminders, {
    required bool notificationsEnabled,
  });
}

/// Ana ekran widget'larına hatırlatıcı, doğum günü ve bildirim durumu
/// özetini yazan servis (F5.1: doğum günleri ve bildirim bayrağı da widget'ta
/// gösterildiği için zorunlu parametreler).
///
/// Gerçek uygulama: `PlatformHomeWidgetSync`. `ReminderCubit`'e constructor
/// ile verilir; testlerde mock'lanır.
abstract interface class HomeWidgetSync {
  /// [categories] resolves user categories' colour keys (F4.3); `null` →
  /// built-ins only (other ids show as "Diğer").
  Future<void> sync(
    List<Reminder> reminders, {
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
    CategoryCatalog? categories,
  });
}
