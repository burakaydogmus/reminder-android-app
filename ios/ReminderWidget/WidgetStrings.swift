import Foundation

/// Widget metinlerinin dili (F6.1).
///
/// Kotlin tarafındaki `WidgetPayload.localized(context, lang)` ile aynı iş:
/// veri içindeki `lang` (uygulamanın "Dil" seçimi) `tr.lproj` / `en.lproj`
/// içinden çözülür, böylece cihaz dili farklı olsa da widget uygulamayla aynı
/// dilde yazar. `lang` yoksa cihaz dili kullanılır.
///
/// Widget galerisindeki ad ve açıklama (`configurationDisplayName`,
/// `description`) veriyi bilmeden çizildiği için cihaz dilini kullanır —
/// Android'de widget seçicinin cihaz dilini kullanması gibi.
struct WidgetStrings {
  private let bundle: Bundle

  /// Tarih ve büyük harf biçimi için.
  let locale: Locale

  init(lang: String?) {
    let code = WidgetStrings.resolve(lang)
    if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
      let localized = Bundle(path: path)
    {
      bundle = localized
    } else {
      bundle = .main
    }
    locale = Locale(identifier: code == "tr" ? "tr_TR" : "en_US")
  }

  /// `lang` geçerliyse onu, değilse cihazın ilk dilini ("tr" ya da "en")
  /// döndürür.
  static func resolve(_ lang: String?) -> String {
    if lang == "tr" || lang == "en" { return lang! }
    let preferred = Locale.preferredLanguages.first ?? "en"
    return preferred.hasPrefix("tr") ? "tr" : "en"
  }

  func callAsFunction(_ key: String) -> String {
    bundle.localizedString(forKey: key, value: key, table: nil)
  }

  /// "Bugün · 6" gibi tek argümanlı biçimler.
  func format(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: self(key), locale: locale, arguments: arguments)
  }

  // MARK: - Zamana bağlı etiketler (Kotlin `WidgetPayload` ile aynı kural)

  /// Satırdaki zaman etiketi: "Gecikti" / "16:00" / "Yarın" / "12 Eki";
  /// zamansız → `nil`.
  func timeLabel(_ dueAt: Date?, now: Date, calendar: Calendar = .current) -> String? {
    guard let dueAt = dueAt else { return nil }
    if dueAt < now { return self("widget_overdue") }
    if dueAt < WidgetPayload.startOfDay(now, plusDays: 1, calendar: calendar) {
      return WidgetStrings.clock(dueAt, calendar: calendar)
    }
    return dayLabel(dueAt, now: now, calendar: calendar)
  }

  /// "Bugün" / "Yarın" / "12 Eki" (yıl farklıysa "12 Oca 2027"); İngilizce
  /// "Today" / "Tomorrow" / "Oct 12".
  func dayLabel(_ at: Date, now: Date, calendar: Calendar = .current) -> String {
    let todayStart = WidgetPayload.startOfDay(now, plusDays: 0, calendar: calendar)
    let tomorrowStart = WidgetPayload.startOfDay(now, plusDays: 1, calendar: calendar)
    let dayAfterStart = WidgetPayload.startOfDay(now, plusDays: 2, calendar: calendar)
    if at >= todayStart && at < tomorrowStart { return self("widget_today") }
    if at >= tomorrowStart && at < dayAfterStart { return self("widget_tomorrow") }
    let sameYear =
      calendar.component(.year, from: at) == calendar.component(.year, from: now)
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.calendar = calendar
    formatter.dateFormat = self(sameYear ? "widget_date_short" : "widget_date_short_year")
    return formatter.string(from: at)
  }

  /// Büyük harf (Türkçe İ/I kuralıyla).
  func upper(_ text: String) -> String {
    text.uppercased(with: locale)
  }

  /// Liste başlığının alt satırı: "Cumartesi 13 Eylül".
  func weekdayAndDate(_ at: Date, calendar: Calendar = .current) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.calendar = calendar
    formatter.dateFormat = self("widget_date_header")
    return formatter.string(from: at)
  }

  /// "09:05" — 24 saat, her iki dilde aynı.
  static func clock(_ at: Date, calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.hour, .minute], from: at)
    return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
  }
}
