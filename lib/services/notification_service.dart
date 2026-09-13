import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/schedule_sync.dart';

/// `flutter_local_notifications` üzerinden zamanlı hatırlatıcı ve yıllık doğum
/// günü bildirimlerini yönetir.
///
/// **Zamanlama politikası (F1.2):** zamanlanmış bildirimleri toplu olarak
/// kuran tek genel metot [syncSchedules]'tır; önce her şeyi iptal eder, sonra
/// hatırlatıcıları **ve** doğum günlerini birlikte yeniden kurar. Yalnızca
/// hatırlatıcıları kurup doğum günlerini silen bir yol yoktur. Uygulama
/// genelinde bu metot doğrudan değil, [ScheduleSync.syncAll] üzerinden
/// çağrılır.
class NotificationService implements NotificationSync {
  NotificationService._(this._plugin);

  static final NotificationService instance =
      NotificationService._(FlutterLocalNotificationsPlugin());

  /// Gerçek plugin yerine sahte bir plugin ile çalışan örnek (testler).
  @visibleForTesting
  factory NotificationService.forTesting(
    FlutterLocalNotificationsPlugin plugin,
  ) =>
      NotificationService._(plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // No prompt on initialize (also runs at launch and in background
    // isolates); permissions are requested in context (F1.6,
    // PermissionService).
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );

    _initialized = true;
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _plugin.cancel(id: reminder.notificationId);
    await _plugin.cancel(id: reminder.geoNotificationId);
  }

  Future<void> cancelBirthday(Birthday birthday) async {
    for (final preset in BirthdayAdvanceOffset.presets) {
      await _plugin.cancel(id: birthday.notificationIdFor(preset.minutes));
    }
  }

  /// Konum (geofence) ile tetiklenen anlık bildirim.
  Future<void> showGeofenceEntry(Reminder r) async {
    if (!_initialized) await initialize();

    const channelId = 'reminders_geo_v1';
    const channelName = 'Konum hatırlatmaları';
    const channelDescription = 'Seçtiğiniz yere geldiğinizde';

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final place = r.locationPlaceLabel?.trim();
    final body = (r.note != null && r.note!.trim().isNotEmpty)
        ? r.note!.trim()
        : (place != null && place.isNotEmpty)
            ? place
            : 'Kayıtlı konuma girdiniz';

    await _plugin.show(
      id: r.geoNotificationId,
      title: r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body: body,
      notificationDetails: details,
      payload: r.id,
    );
  }

  /// Bu uygulamanın tüm bildirimlerini (hatırlatıcı, doğum günü, konum) iptal
  /// eder. Yalnızca "Tüm verileri sıfırla" gibi her şeyin silindiği durumlar
  /// içindir; senkron için [syncSchedules] kullanın.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Zamanlanmış bildirimleri saklanan durumla eşitler.
  ///
  /// Önce tüm bildirimleri iptal eder (silinen hatırlatıcı/doğum günlerinin
  /// artıkları da gider), ardından bildirimler açıksa gelecekteki
  /// tamamlanmamış hatırlatıcıları ve tüm doğum günlerini yeniden kurar.
  /// İkisi her zaman birlikte kurulduğu için bir hatırlatıcı değişikliği doğum
  /// günü bildirimlerini silemez. Plugin başlatılmamışsa (ör. arka plan
  /// isolate'i) önce başlatılır.
  ///
  /// F1.7 bu metodun içini fark bazlı güncellemeye çevirebilir; sözleşme
  /// ("çağrıdan sonra zamanlamalar tam olarak bu listelere karşılık gelir")
  /// aynı kalır.
  @override
  Future<void> syncSchedules({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  }) async {
    if (!_initialized) await initialize();

    await cancelAll();
    if (!notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    for (final r in reminders) {
      if (r.isDone) continue;
      final at = r.remindAt;
      if (at == null) continue;
      final scheduled = tz.TZDateTime.from(at, tz.local);
      if (!scheduled.isAfter(now)) continue;
      await _scheduleOne(r, scheduled);
    }

    // Yıllık tekrarlayan doğum günü hatırlatmaları: her aktif offset için ayrı
    // bildirim, `DateTimeComponents.dateAndTime` ile her yıl yeniden tetiklenir.
    for (final b in birthdays) {
      await _scheduleBirthdayOne(b);
    }
  }

  Future<void> _scheduleBirthdayOne(Birthday b) async {
    const channelId = 'reminders_birthdays_v1';
    const channelName = 'Doğum günü hatırlatmaları';
    const channelDescription =
        'Yıllık olarak tekrarlayan doğum günü bildirimleri';

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final next = b.nextOccurrence();
    for (final offset in b.advanceOffsetsMinutes) {
      final fireDateTime = next.subtract(Duration(minutes: offset));
      var scheduled = tz.TZDateTime.from(fireDateTime, tz.local);

      // Eğer hesaplanan ilk tetik geçmişte kalmışsa (örn. bugün doğum günü ama
      // bildirim saati geçti ve offset 0), bir yıl ileri al.
      final now = tz.TZDateTime.now(tz.local);
      if (!scheduled.isAfter(now)) {
        scheduled = tz.TZDateTime(
          tz.local,
          scheduled.year + 1,
          scheduled.month,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
        );
      }

      final body = _birthdayNotificationBody(b, offset);

      await _plugin.zonedSchedule(
        id: b.notificationIdFor(offset),
        title: _birthdayNotificationTitle(b, offset),
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: 'birthday:${b.id}',
      );
    }
  }

  String _birthdayNotificationTitle(Birthday b, int offsetMinutes) {
    if (offsetMinutes == 0) return '🎂 ${b.name}';
    return '🎂 Yaklaşıyor: ${b.name}';
  }

  String _birthdayNotificationBody(Birthday b, int offsetMinutes) {
    if (offsetMinutes == 0) {
      final age = b.upcomingAge;
      if (age != null) return '$age. yaşı kutlu olsun!';
      return 'Bugün doğum günü.';
    }
    final hours = offsetMinutes ~/ 60;
    if (hours < 24) {
      return '$hours saat sonra ${b.name} doğum günü.';
    }
    final days = offsetMinutes ~/ 1440;
    return '$days gün sonra ${b.name} doğum günü.';
  }

  Future<void> _scheduleOne(Reminder r, tz.TZDateTime scheduled) async {
    const channelId = 'reminders_channel_v1';
    const channelName = 'Hatırlatmalar';
    const channelDescription = 'Zamanlanmış hatırlatıcı bildirimleri';

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final body = (r.note != null && r.note!.trim().isNotEmpty)
        ? r.note!.trim()
        : 'Hatırlatma zamanı';

    await _plugin.zonedSchedule(
      id: r.notificationId,
      title: r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
