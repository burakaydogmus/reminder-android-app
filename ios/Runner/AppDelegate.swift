import Flutter
import UIKit
import flutter_local_notifications
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // native_geofence: bölge olayları için başlatılan arka plan (headless)
    // engine'e plugin'leri kaydeder. Herhangi bir plugin kaydından ÖNCE,
    // mümkün olan en erken noktada ayarlanır: konum olayı uygulamayı arka
    // planda (sahne bağlanmadan) başlatabilir.
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // flutter_local_notifications: ön plandayken bildirim gösterimi.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene yaşam döngüsü: ana engine'in plugin'leri burada kaydedilir.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // flutter_local_notifications: bildirim aksiyonu isolate'i için
    // (UIScene'e geçmiş uygulamalarda README'nin önerdiği yer).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
