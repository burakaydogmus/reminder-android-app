import Foundation

/// Ana ekran widget'larının veri sözleşmesi (F5.1/F5.2), Dart tarafı
/// `lib/home/widget_payload.dart` (`WidgetPayload.build`) ve Kotlin tarafı
/// `android/.../WidgetPayload.kt` ile **ortak**.
///
/// Dart eşitleme anında yazar; widget'lar uygulama açılmadan saatlerce
/// yaşadığı için zamana bağlı her şey (bölüm, "Gecikti", "Yarın", sayılar,
/// sıradaki, doğum günü etiketi) burada çizim anında `dueAt` / `date` ile
/// yeniden hesaplanır. Okunamayan veri boş duruma düşer, widget çökmez.
///
/// Dil (F6.1): verideki `lang` (uygulamanın "Dil" seçimi) widget'ın kendi
/// metinlerini `tr.lproj` / `en.lproj` içinden çözer ([WidgetStrings]); cihaz
/// dili farklı olsa da widget uygulamayla aynı dildedir.

/// Bölüm kimlikleri; Dart ve Kotlin tarafıyla ortak (burada yalnız
/// belgelendirme için: bölümler `dueAt`'tan yeniden hesaplanır).
enum WidgetSection: String {
  case overdue
  case today
  case untimed
  case later
}

struct WidgetItem: Identifiable, Equatable {
  let id: String
  let title: String
  /// `nil` = zamansız.
  let dueAt: Date?
  /// Kor renk anahtarı (`market`, `ev`, `is`, …).
  let category: String
  /// "2/6" veya `nil`.
  let subtasks: String?
  let recurring: Bool
  /// Dart'taki sıra (bölüm içi `compareReminders`).
  let order: Int
}

struct WidgetBirthday: Identifiable, Equatable {
  let id: String
  let name: String
  let date: Date
  let age: Int?
}

/// Doğum günü satırı; `isToday` false ise yarın.
struct WidgetBirthdayRow: Identifiable, Equatable {
  let birthday: WidgetBirthday
  let isToday: Bool

  var id: String { birthday.id }
}

/// Ham veri (eşitleme anındaki hali).
struct WidgetRaw: Equatable {
  let notificationsEnabled: Bool
  let items: [WidgetItem]
  let birthdays: [WidgetBirthday]
  /// Uygulama dili (`tr` / `en`); eski veride `nil` (cihaz dili).
  let lang: String?

  static let empty = WidgetRaw(
    notificationsEnabled: true, items: [], birthdays: [], lang: nil)
}

/// Çizim anındaki görünüm.
struct WidgetSnapshot {
  let notificationsEnabled: Bool
  let overdue: [WidgetItem]
  let today: [WidgetItem]
  let untimed: [WidgetItem]
  let later: [WidgetItem]
  /// Bugün ve yarın olan doğum günleri (yakın olan önce).
  let birthdays: [WidgetBirthdayRow]
  let lang: String?
  let now: Date

  /// Bugünün açık işleri: gecikmiş + bugün + zamansız (Bugün ekranı sırası).
  var todayOpen: [WidgetItem] { overdue + today + untimed }

  /// Sıradaki: bugünün ilk zamanlı işi → sonraki günler → en eski gecikmiş →
  /// zamansız.
  var next: WidgetItem? {
    today.first ?? later.first ?? overdue.first ?? untimed.first
  }

  /// "+N daha": bugünün sıradaki dışındaki açık işleri.
  var moreThanNext: Int {
    guard let next = next else { return 0 }
    let open = todayOpen.count
    if later.contains(where: { $0.id == next.id }) { return open }
    return max(0, open - 1)
  }

  /// Bugünün tamamlanan işleri bilinmediği için gösterge açık işleri sayar.
  var isEmpty: Bool {
    overdue.isEmpty && today.isEmpty && untimed.isEmpty && later.isEmpty
  }

  static func empty(now: Date) -> WidgetSnapshot {
    WidgetSnapshot(
      notificationsEnabled: true, overdue: [], today: [], untimed: [], later: [],
      birthdays: [], lang: nil, now: now)
  }
}

enum WidgetPayload {
  /// App Group'taki JSON'u okur; yok/bozuksa boş veri.
  static func read() -> WidgetRaw {
    parse(ReminderWidgetStore.payloadJSON())
  }

  static func parse(_ json: String?) -> WidgetRaw {
    guard let json = json, !json.isEmpty, let data = json.data(using: .utf8) else {
      return .empty
    }
    guard let root = (try? JSONSerialization.jsonObject(with: data, options: []))
      as? [String: Any]
    else { return .empty }

    var items: [WidgetItem] = []
    if let array = root["items"] as? [Any] {
      for (index, element) in array.enumerated() {
        guard let object = element as? [String: Any] else { continue }
        guard let id = object["id"] as? String, !id.isEmpty else { continue }
        let title = (object["title"] as? String) ?? ""
        items.append(
          WidgetItem(
            id: id,
            title: title.isEmpty ? "…" : title,
            dueAt: date(object["dueAt"]),
            category: (object["category"] as? String) ?? "diger",
            subtasks: object["subtasks"] as? String,
            recurring: (object["recurring"] as? Bool) ?? false,
            order: index
          ))
      }
    }

    var birthdays: [WidgetBirthday] = []
    if let array = root["birthdays"] as? [Any] {
      for element in array {
        guard let object = element as? [String: Any] else { continue }
        guard let id = object["id"] as? String, !id.isEmpty else { continue }
        guard let at = date(object["date"]) else { continue }
        birthdays.append(
          WidgetBirthday(
            id: id,
            name: (object["name"] as? String) ?? "",
            date: at,
            age: object["age"] as? Int
          ))
      }
    }

    let lang = object(root["lang"])
    return WidgetRaw(
      notificationsEnabled: (root["notificationsEnabled"] as? Bool) ?? true,
      items: items,
      birthdays: birthdays,
      lang: lang
    )
  }

  /// [raw]'ı [now] anına göre bölümlere ayırır (Dart `WidgetPayload.build`
  /// kuralı). [completed] uygulamanın henüz işlemediği tamamlamalardır; o
  /// satırlar hemen kaybolur.
  static func snapshot(
    _ raw: WidgetRaw,
    now: Date = Date(),
    completed: Set<String> = [],
    calendar: Calendar = .current
  ) -> WidgetSnapshot {
    var overdue: [WidgetItem] = []
    var today: [WidgetItem] = []
    var untimed: [WidgetItem] = []
    var later: [WidgetItem] = []
    let tomorrowStart = startOfDay(now, plusDays: 1, calendar: calendar)
    for item in raw.items where !completed.contains(item.id) {
      guard let at = item.dueAt else {
        untimed.append(item)
        continue
      }
      if at < now {
        overdue.append(item)
      } else if at < tomorrowStart {
        today.append(item)
      } else {
        later.append(item)
      }
    }
    // Dart sırası (bölüm sırası, bölüm içinde `compareReminders`) korunur:
    // bugünden gecikmişe geçen öğeler zaten gecikmişlerden sonra ve saat
    // sırasındadır.

    let todayStart = startOfDay(now, plusDays: 0, calendar: calendar)
    let dayAfterStart = startOfDay(now, plusDays: 2, calendar: calendar)
    let rows =
      raw.birthdays
      .compactMap { birthday -> WidgetBirthdayRow? in
        if birthday.date >= todayStart && birthday.date < tomorrowStart {
          return WidgetBirthdayRow(birthday: birthday, isToday: true)
        }
        if birthday.date >= tomorrowStart && birthday.date < dayAfterStart {
          return WidgetBirthdayRow(birthday: birthday, isToday: false)
        }
        return nil
      }
      .sorted { lhs, rhs in
        if lhs.isToday != rhs.isToday { return lhs.isToday }
        return lhs.birthday.name < rhs.birthday.name
      }

    return WidgetSnapshot(
      notificationsEnabled: raw.notificationsEnabled,
      overdue: overdue,
      today: today,
      untimed: untimed,
      later: later,
      birthdays: rows,
      lang: raw.lang,
      now: now
    )
  }

  /// Görünümün değiştiği sonraki anlar (ilk gelecek `dueAt`'lar ve gece
  /// yarısı), WidgetKit zaman çizelgesi için sıralı ve tekil.
  static func changePoints(
    _ raw: WidgetRaw,
    now: Date,
    limit: Int = 8,
    calendar: Calendar = .current
  ) -> [Date] {
    let midnight = startOfDay(now, plusDays: 1, calendar: calendar)
    var points = raw.items.compactMap(\.dueAt).filter { $0 > now && $0 < midnight }
    points.append(midnight)
    let unique = Array(Set(points)).sorted()
    return Array(unique.prefix(limit))
  }

  /// [now]'un gününden [plusDays] gün sonraki gece yarısı (yerel saat).
  static func startOfDay(_ now: Date, plusDays: Int, calendar: Calendar = .current) -> Date {
    let start = calendar.startOfDay(for: now)
    return calendar.date(byAdding: .day, value: plusDays, to: start) ?? start
  }

  // MARK: - JSON yardımcıları

  /// Epoch milisaniye → `Date`; sayı değilse `nil`.
  private static func date(_ value: Any?) -> Date? {
    guard let number = value as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: number.doubleValue / 1000)
  }

  /// Boş metni `nil` sayar.
  private static func object(_ value: Any?) -> String? {
    guard let text = value as? String, !text.isEmpty else { return nil }
    return text
  }
}
