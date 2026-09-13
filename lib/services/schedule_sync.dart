import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/sync_interfaces.dart';

/// Zamanlanmış bildirimleri saklanan durumla eşitleyen servis.
///
/// Gerçek uygulama: `NotificationService`. Sözleşme: çağrıdan sonra bekleyen
/// hatırlatıcı **ve** doğum günü bildirimleri tam olarak verilen listelere
/// karşılık gelir; biri diğerini silemez.
abstract interface class NotificationSync {
  Future<void> syncSchedules({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  });
}

/// Tüm zamanlamaları (bildirimler, geofence'ler, ana ekran widget'ı) saklanan
/// durumla eşitleyen **tek giriş noktası** (F1.2).
///
/// `ReminderCubit` (ana isolate) ve widget arka plan callback'i (ayrı isolate)
/// aynı sırayı ve aynı kuralları kullansın diye buradan geçer. Yeni bir
/// zamanlama türü eklenirse buraya eklenir; çağıranlar tek tek servis
/// çağırmaz.
///
/// F1.7 notu: eşzamanlı çağrıların sıraya alınması (serialisation) bu sınıfta
/// yapılabilir; tüm senkronlar zaten buradan geçer.
class ScheduleSync {
  const ScheduleSync({
    required NotificationSync notifications,
    required GeofenceSync geofence,
    required HomeWidgetSync homeWidget,
  })  : _notifications = notifications,
        _geofence = geofence,
        _homeWidget = homeWidget;

  final NotificationSync _notifications;
  final GeofenceSync _geofence;
  final HomeWidgetSync _homeWidget;

  /// Sırasıyla bildirimleri, geofence'leri ve widget'ı günceller.
  Future<void> syncAll({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required AppSettings settings,
  }) async {
    await _notifications.syncSchedules(
      reminders: reminders,
      birthdays: birthdays,
      notificationsEnabled: settings.notificationsEnabled,
    );
    await _geofence.syncWithReminders(
      reminders,
      notificationsEnabled: settings.notificationsEnabled,
    );
    await _homeWidget.sync(reminders);
  }

  /// Zamanlamalara dokunmadan yalnızca widget'ı yeniler (veri değişmediğinde).
  Future<void> refreshHomeWidget(List<Reminder> reminders) =>
      _homeWidget.sync(reminders);
}
