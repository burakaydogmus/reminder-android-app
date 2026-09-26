import AppIntents
import WidgetKit

/// Widget'tan "Tamamla" (F5.2), Android'deki `reminderwidget://toggle?id=`
/// yolunun karşılığı.
///
/// Etkileşimli widget düğmeleri intent'i widget extension'ının sürecinde
/// çalıştırır; orada Flutter motoru yoktur. Bu yüzden intent hatırlatıcıyı
/// kendisi tamamlamaz: paylaşılan App Group'a bir istek bırakır
/// ([ReminderWidgetStore.addPendingCompletion]) ve widget'ı yeniler. Satır
/// hemen kaybolur (widget kuyruktaki id'leri çizmez); gerçek tamamlama
/// uygulama bir sonraki açılışta / ön plana dönüşte Android ile **aynı**
/// kuralla (`completeReminder`; tekrarlayan hatırlatıcı bir sonraki tekrara
/// ilerler) yapılır — `lib/services/ios_widget_completions.dart`.
///
/// Sınır: uygulama hiç açılmazsa zamanlamalar değişmez, yani tamamlanan
/// hatırlatıcının bildirimi yine gelebilir. Android'de bu iş arka plan
/// isolate'inde anında yapılır; iOS'ta widget extension'ına Flutter motoru
/// gömmemek için bilinçli olarak uygulamaya bırakıldı
/// (`docs/ios-widget-setup.md`).
struct CompleteReminderIntent: AppIntent {
  static var title: LocalizedStringResource { "Tamamla" }

  /// Kısayollar uygulamasında görünmesin: widget'a özel bir işlemdir.
  static var isDiscoverable: Bool { false }

  /// Uygulamayı açmaz; widget'ta kalır.
  static var openAppWhenRun: Bool { false }

  @Parameter(title: "Reminder")
  var reminderId: String

  init() {}

  init(reminderId: String) {
    self.reminderId = reminderId
  }

  func perform() async throws -> some IntentResult {
    ReminderWidgetStore.addPendingCompletion(id: reminderId)
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}

/// "Liste" widget'ının ayarı (uzun basıp "Widget'ı düzenle").
///
/// `AppIntentConfiguration` ile tek bir seçenek sunulur: yalnız bugünün işleri
/// (Kaçanlar + Bugün + zamansız) mı, sonraki günler de mi görünsün.
struct ReminderListConfiguration: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Liste" }

  static var description: IntentDescription {
    IntentDescription("Widget'ta hangi işlerin görüneceğini seç.")
  }

  @Parameter(title: "Yalnızca bugün", default: true)
  var todayOnly: Bool

  init() {}

  init(todayOnly: Bool) {
    self.todayOnly = todayOnly
  }
}
