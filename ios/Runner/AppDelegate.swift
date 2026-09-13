import Flutter
import UIKit
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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene yaşam döngüsü: ana engine'in plugin'leri burada kaydedilir.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
