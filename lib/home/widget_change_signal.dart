import 'dart:ui' show IsolateNameServer;

/// Ana isolate'in widget değişikliği sinyalini dinlediği port adı (F1.3).
const String widgetChangePortName = 'reminder.home_widget.changed';

/// Widget arka plan isolate'i bir değişikliği kaydettikten sonra çağırır.
///
/// Uygulama aynı süreçte çalışıyorsa (ön planda veya arka planda açık)
/// `AppStateReloader` portu kaydetmiştir ve durumu depodan yeniden yükler.
/// Süreç yoksa port da yoktur; sinyal sessizce düşer (uygulama açılışta zaten
/// depodan yükler).
void notifyAppOfWidgetChange() {
  IsolateNameServer.lookupPortByName(widgetChangePortName)?.send(null);
}
