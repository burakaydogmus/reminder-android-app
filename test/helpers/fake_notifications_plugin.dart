import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

/// Sahte plugin'de bekleyen (zamanlanmış) bir bildirim.
class FakePendingNotification {
  const FakePendingNotification({
    required this.id,
    required this.title,
    required this.scheduledDate,
    this.body,
    this.payload,
    this.matchDateTimeComponents,
    this.details,
    this.scheduleMode,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
  final DateTimeComponents? matchDateTimeComponents;
  final NotificationDetails? details;

  /// `zonedSchedule` ile verilen Android zamanlama modu.
  final AndroidScheduleMode? scheduleMode;
}

/// Platform kanalına dokunmayan, bekleyen bildirimleri bellekte tutan
/// `FlutterLocalNotificationsPlugin`. `NotificationService.forTesting` ile
/// kullanılır; uygulanmayan metotlar çağrılırsa test hata verir.
class FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  /// id → bekleyen bildirim.
  final Map<int, FakePendingNotification> pending = {};

  /// Bildirim çekmecesinde gösterilen (anlık `show` ile) bildirimlerin id'leri.
  /// Android'deki gibi `cancel`/`cancelAll` bunları da kaldırır.
  final Set<int> shown = {};

  /// Gösterilen bildirimlerin ayrıntıları ve payload'ları (id → değer).
  final Map<int, NotificationDetails?> shownDetails = {};
  final Map<int, String?> shownPayloads = {};

  /// Title and body of shown notifications (F6.1 language checks).
  final Map<int, (String?, String?)> shownTexts = {};

  int initializeCalls = 0;
  int cancelAllCalls = 0;
  int cancelCalls = 0;
  int scheduleCalls = 0;

  /// `false` ise tam zamanlı modlar (`exact*`, `alarmClock`) Android 12+'daki
  /// gibi `exact_alarms_not_permitted` hatası verir.
  bool exactAlarmsPermitted = true;

  /// Reddedilen tam zamanlı kurulum denemelerinin id'leri.
  final List<int> rejectedExactIds = [];

  /// Son `initialize` çağrısının ayarları ve işleyicileri.
  InitializationSettings? initializeSettings;
  DidReceiveNotificationResponseCallback? foregroundCallback;
  DidReceiveBackgroundNotificationResponseCallback? backgroundCallback;

  /// `getNotificationAppLaunchDetails` sonucu.
  NotificationAppLaunchDetails? launchDetails;

  /// Sırasıyla `cancel` edilen ve `zonedSchedule` edilen id'ler.
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];

  /// Bekleyen bildirimleri değiştiren toplam çağrı sayısı.
  int get writeCalls => cancelAllCalls + cancelCalls + scheduleCalls;

  /// Sayaçları ve kayıtlı id listelerini sıfırlar (durum korunur).
  void resetCounters() {
    cancelAllCalls = 0;
    cancelCalls = 0;
    scheduleCalls = 0;
    cancelledIds.clear();
    scheduledIds.clear();
    rejectedExactIds.clear();
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls++;
    initializeSettings = settings;
    foregroundCallback = onDidReceiveNotificationResponse;
    backgroundCallback = onDidReceiveBackgroundNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async => launchDetails;

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelCalls++;
    cancelledIds.add(id);
    pending.remove(id);
    shown.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    pending.clear();
    shown.clear();
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add(id);
    shownDetails[id] = notificationDetails;
    shownPayloads[id] = payload;
    shownTexts[id] = (title, body);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [
      for (final n in pending.values)
        PendingNotificationRequest(n.id, n.title, n.body, n.payload),
    ];
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!exactAlarmsPermitted &&
        androidScheduleMode != AndroidScheduleMode.inexact &&
        androidScheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
      rejectedExactIds.add(id);
      throw PlatformException(
        code: 'exact_alarms_not_permitted',
        message: 'Exact alarms are not permitted',
      );
    }
    scheduleCalls++;
    scheduledIds.add(id);
    pending[id] = FakePendingNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
      details: notificationDetails,
      scheduleMode: androidScheduleMode,
    );
  }
}
