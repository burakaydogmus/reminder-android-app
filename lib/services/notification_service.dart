import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );

    _initialized = true;
  }

  Future<bool?> requestPermissionsIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _plugin.cancel(reminder.notificationId);
    await _plugin.cancel(reminder.geoNotificationId);
  }

  Future<void> cancelBirthday(Birthday birthday) async {
    for (final preset in BirthdayAdvanceOffset.presets) {
      await _plugin.cancel(birthday.notificationIdFor(preset.minutes));
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
      r.geoNotificationId,
      r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body,
      details,
      payload: r.id,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> syncFromReminders(
    List<Reminder> reminders, {
    required bool notificationsEnabled,
  }) async {
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
  }

  /// Yıllık tekrarlayan doğum günü hatırlatmalarını planlar. Her aktif
  /// offset için ayrı bildirim oluşturulur ve `DateTimeComponents.dateAndTime`
  /// ile her yıl aynı ay-gün-saat-dakikada yeniden tetiklenir.
  Future<void> scheduleBirthdays(
    List<Birthday> birthdays, {
    required bool notificationsEnabled,
  }) async {
    for (final b in birthdays) {
      await cancelBirthday(b);
    }
    if (!notificationsEnabled) return;

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
        b.notificationIdFor(offset),
        _birthdayNotificationTitle(b, offset),
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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
      r.notificationId,
      r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
