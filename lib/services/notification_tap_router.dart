import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:reminder/services/notification_payload.dart';

/// Bildirime dokunmayı (aksiyonsuz) arayüze iletir (F3.2).
///
/// Bildirim katmanı hedefi [open] ile bırakır; `HomeShell` dinler ve hedefi
/// [take] ile bir kez alır. Kabuk henüz yoksa (soğuk açılış, ilk kare
/// öncesi) hedef bekler ve kabuk açılınca işlenir.
class NotificationTapRouter extends ChangeNotifier {
  NotificationTapRouter();

  /// Uygulamanın kullandığı örnek.
  static final NotificationTapRouter instance = NotificationTapRouter();

  NotificationPayload? _pending;

  /// Henüz açılmamış hedef.
  NotificationPayload? get pending => _pending;

  /// [target]'ı açılmak üzere bırakır; önceki bekleyen hedefin yerini alır.
  void open(NotificationPayload? target) {
    if (target == null) return;
    _pending = target;
    notifyListeners();
  }

  /// Bekleyen hedefi döndürür ve temizler.
  NotificationPayload? take() {
    final target = _pending;
    _pending = null;
    return target;
  }

  /// Yalnızca bildirimin kendisine dokunma (aksiyon değil) hedef bırakır.
  void openResponse(NotificationResponse? response) {
    if (response == null) return;
    if (response.notificationResponseType !=
        NotificationResponseType.selectedNotification) {
      return;
    }
    open(NotificationPayload.parse(response.payload));
  }

  /// Soğuk açılış: uygulama bir bildirime dokunularak başlatıldıysa hedefi
  /// bırakır. [source] testlerde sahte bir kaynaktır.
  Future<void> openFromLaunch(
    Future<NotificationAppLaunchDetails?> Function() source,
  ) async {
    final details = await source();
    if (details == null || !details.didNotificationLaunchApp) return;
    openResponse(details.notificationResponse);
  }
}
