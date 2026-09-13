import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

/// Sahte plugin'de bekleyen (zamanlanmış) bir bildirim.
class FakePendingNotification {
  const FakePendingNotification({
    required this.id,
    required this.title,
    required this.scheduledDate,
    this.payload,
    this.matchDateTimeComponents,
  });

  final int id;
  final String? title;
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
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  int cancelCalls = 0;
  int scheduleCalls = 0;

  /// Bekleyen bildirimleri değiştiren toplam çağrı sayısı.
  int get writeCalls => cancelAllCalls + cancelCalls + scheduleCalls;

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
    pending.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    pending.clear();
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
    pending[id] = FakePendingNotification(
      id: id,
      title: title,
      scheduledDate: scheduledDate,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}
