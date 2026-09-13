import 'package:reminder/domain/model/reminder.dart';

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

/// Ana ekran widget'ına hatırlatıcı özetini yazan servis.
///
/// Gerçek uygulama: `PlatformHomeWidgetSync`. `ReminderCubit`'e constructor
/// ile verilir; testlerde mock'lanır.
abstract interface class HomeWidgetSync {
  Future<void> sync(List<Reminder> reminders);
}
