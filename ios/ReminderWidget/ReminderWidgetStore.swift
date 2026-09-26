import Foundation

/// Dart ile paylaşılan App Group deposu (F5.2).
///
/// Dart tarafı `home_widget` üzerinden `UserDefaults(suiteName:)` içine yazar
/// (`lib/services/reminder_home_widget_sync.dart`, `WidgetPayload` v2).
/// Widget normalde yalnız okur; tek yazdığı şey "tamamla" kuyruğudur
/// ([addPendingCompletion]) — uygulama bir sonraki açılışta/ön plana dönüşte
/// bunu Android'deki arka plan callback'iyle aynı kuralla işler
/// (`completeReminder`, `lib/services/ios_widget_completions.dart`).
enum ReminderWidgetStore {
  /// Runner ve bu extension'ın entitlement'larındaki App Group.
  static let appGroupId = "group.com.burakaydogmus.reminder"

  /// `kHomeWidgetPayloadKey` (Dart) — `WidgetPayload` v2 JSON'u.
  static let payloadKey = "widget_payload_v2"

  /// `kWidgetCompletionsKey` (Dart) — uygulamanın işleyeceği tamamlamalar.
  static let completionsKey = "widget_completions_v1"

  /// Uygulamayı açan adreslerin şeması (`WidgetLaunchTarget.scheme`).
  static let urlScheme = "reminderwidget"

  static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

  /// Paylaşılan veri; henüz senkron yapılmadıysa `nil`.
  static func payloadJSON() -> String? {
    defaults?.string(forKey: payloadKey)
  }

  /// Uygulamanın henüz işlemediği tamamlamaların id'leri.
  ///
  /// Widget bunları çizim dışı bırakır, böylece dokunuş anında satır kaybolur
  /// ama gerçek tamamlama uygulamada yapılır.
  static func pendingCompletionIds() -> Set<String> {
    var ids = Set<String>()
    for entry in pendingCompletions() {
      if let id = entry["id"] as? String, !id.isEmpty { ids.insert(id) }
    }
    return ids
  }

  /// Kuyruğa bir tamamlama ekler; aynı id yalnız bir kez durur (en son
  /// dokunuşun zamanıyla).
  static func addPendingCompletion(id: String, at date: Date = Date()) {
    guard !id.isEmpty, let defaults = defaults else { return }
    var list = pendingCompletions().filter { ($0["id"] as? String) != id }
    list.append(["id": id, "at": Int(date.timeIntervalSince1970 * 1000)])
    guard let data = try? JSONSerialization.data(withJSONObject: list, options: []),
      let json = String(data: data, encoding: .utf8)
    else { return }
    defaults.set(json, forKey: completionsKey)
  }

  private static func pendingCompletions() -> [[String: Any]] {
    guard let json = defaults?.string(forKey: completionsKey),
      let data = json.data(using: .utf8)
    else { return [] }
    let object = try? JSONSerialization.jsonObject(with: data, options: [])
    return object as? [[String: Any]] ?? []
  }

  /// Uygulamayı açan adres: `reminderwidget://<host>?id=…&homeWidget=true`.
  ///
  /// `home_widget` yalnız `homeWidget` sorgu parametresi taşıyan adresleri
  /// uygulamaya iletir (`HomeWidgetPlugin.isWidgetUrl`); `WidgetLaunchTarget`
  /// fazladan parametreyi yok sayar.
  static func launchURL(host: String, id: String? = nil) -> URL {
    var components = URLComponents()
    components.scheme = urlScheme
    components.host = host
    var items: [URLQueryItem] = []
    if let id = id, !id.isEmpty { items.append(URLQueryItem(name: "id", value: id)) }
    items.append(URLQueryItem(name: "homeWidget", value: "true"))
    components.queryItems = items
    if let url = components.url { return url }
    // URLComponents yalnız geçersiz host'ta başarısız olur; sabit adreslere düş.
    return URL(string: "\(urlScheme)://\(host)?homeWidget=true")!
  }

  /// Bir satırın/yüzeyin açacağı adres: hatırlatıcı varsa düzenleyicisi, yoksa
  /// hızlı yakalama ("+"). `open` id'siz gelirse `WidgetLaunchTarget.parse`
  /// onu yok sayardı.
  static func openURL(for item: WidgetItem?) -> URL {
    guard let item = item else { return launchURL(host: "new") }
    return launchURL(host: "open", id: item.id)
  }
}
