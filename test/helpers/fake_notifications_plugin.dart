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
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
  final DateTimeComponents? matchDateTimeComponents;
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

  int initializeCalls = 0;
  int cancelAllCalls = 0;
  int cancelCalls = 0;
  int scheduleCalls = 0;

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
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls++;
    return true;
  }

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
    scheduleCalls++;
    scheduledIds.add(id);
    pending[id] = FakePendingNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}
