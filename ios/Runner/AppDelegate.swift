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
    registerA11yPrefsChannel(with: engineBridge.pluginRegistry)
  }

  // MARK: - Erişilebilirlik tercihleri (F5.4)

  // Flutter'ın MediaQuery'de vermediği iOS ayarları: Reduce Transparency,
  // Increase Contrast (darker system colors) ve Low Power Mode. Cam krom
  // (tab bar, arama düğmesi) bunlardan biri açıksa solid çizilir.
  // Dart tarafı: lib/ui/theme/adaptive/a11y_prefs.dart.
  private static let a11yPrefsChannelName = "com.burakaydogmus.reminder/a11y_prefs"
  private var a11yPrefsChannel: FlutterMethodChannel?

  private func registerA11yPrefsChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "ReminderA11yPrefs") else { return }
    let channel = FlutterMethodChannel(
      name: AppDelegate.a11yPrefsChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "get" {
        result(AppDelegate.currentA11yPrefs())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    a11yPrefsChannel = channel

    let center = NotificationCenter.default
    let names: [Notification.Name] = [
      UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
      Notification.Name.NSProcessInfoPowerStateDidChange,
    ]
    for name in names {
      center.removeObserver(self, name: name, object: nil)
      center.addObserver(
        self,
        selector: #selector(a11yPrefsDidChange),
        name: name,
        object: nil
      )
    }
  }

  // Güç modu bildirimi herhangi bir thread'den gelebilir; kanal ana
  // thread'de çağrılır.
  @objc private func a11yPrefsDidChange() {
    DispatchQueue.main.async { [weak self] in
      self?.a11yPrefsChannel?.invokeMethod(
        "changed",
        arguments: AppDelegate.currentA11yPrefs()
      )
    }
  }

  private static func currentA11yPrefs() -> [String: Bool] {
    return [
      "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
      "increaseContrast": UIAccessibility.isDarkerSystemColorsEnabled,
      "lowPower": ProcessInfo.processInfo.isLowPowerModeEnabled,
    ]
  }
}
