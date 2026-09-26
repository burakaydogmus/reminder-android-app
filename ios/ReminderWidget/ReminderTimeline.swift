import AppIntents
import Foundation
import WidgetKit

/// Bir çizim anı.
///
/// WidgetKit widget'ı biz istemesek de günlerce yeniden çizer, bu yüzden
/// zamana bağlı her şey [snapshot] içinde `date`'e göre yeniden hesaplanır
/// (Kotlin tarafındaki çizim anı hesabının karşılığı).
struct ReminderEntry: TimelineEntry {
  let date: Date
  let raw: WidgetRaw
  /// Uygulamanın henüz işlemediği "tamamla" istekleri; bu satırlar çizilmez.
  let completed: Set<String>
  /// "Liste" widget'ının ayarı; diğer ailelerde `true`.
  let todayOnly: Bool

  var snapshot: WidgetSnapshot {
    WidgetPayload.snapshot(raw, now: date, completed: completed)
  }

  var strings: WidgetStrings { WidgetStrings(lang: raw.lang) }

  static func placeholder(todayOnly: Bool = true) -> ReminderEntry {
    ReminderEntry(date: Date(), raw: .empty, completed: [], todayOnly: todayOnly)
  }

  /// App Group'tan okuyup [now] için bir giriş üretir.
  static func current(
    now: Date = Date(),
    todayOnly: Bool = true,
    raw: WidgetRaw? = nil,
    completed: Set<String>? = nil
  ) -> ReminderEntry {
    ReminderEntry(
      date: now,
      raw: raw ?? WidgetPayload.read(),
      completed: completed ?? ReminderWidgetStore.pendingCompletionIds(),
      todayOnly: todayOnly
    )
  }
}

/// [ReminderEntry]'lerin zaman çizelgesi: şimdi + görünümün değiştiği anlar
/// (ilk gelecek `dueAt`'lar ve gece yarısı). Gece yarısından sonrası için
/// WidgetKit yeniden çizim ister (`.after`).
enum ReminderTimeline {
  static func build(now: Date = Date(), todayOnly: Bool) -> Timeline<ReminderEntry> {
    let raw = WidgetPayload.read()
    let completed = ReminderWidgetStore.pendingCompletionIds()
    var entries: [ReminderEntry] = [
      ReminderEntry.current(now: now, todayOnly: todayOnly, raw: raw, completed: completed)
    ]
    for point in WidgetPayload.changePoints(raw, now: now) {
      entries.append(
        ReminderEntry(date: point, raw: raw, completed: completed, todayOnly: todayOnly))
    }
    let last = entries.last?.date ?? now
    return Timeline(entries: entries, policy: .after(last.addingTimeInterval(60)))
  }
}

/// Yapılandırması olmayan aileler (Sıradaki, Bugün, kilit ekranı).
struct ReminderProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReminderEntry {
    ReminderEntry.placeholder()
  }

  func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
    completion(ReminderEntry.current())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
    completion(ReminderTimeline.build(todayOnly: true))
  }
}

/// "Liste" widget'ı: [ReminderListConfiguration] ile ayarlanır.
struct ReminderListProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ReminderEntry {
    ReminderEntry.placeholder()
  }

  func snapshot(
    for configuration: ReminderListConfiguration,
    in context: Context
  ) async -> ReminderEntry {
    ReminderEntry.current(todayOnly: configuration.todayOnly)
  }

  func timeline(
    for configuration: ReminderListConfiguration,
    in context: Context
  ) async -> Timeline<ReminderEntry> {
    ReminderTimeline.build(todayOnly: configuration.todayOnly)
  }
}
