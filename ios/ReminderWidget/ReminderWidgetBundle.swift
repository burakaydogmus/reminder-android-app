import SwiftUI
import WidgetKit

/// iOS ana ekran ve kilit ekranı widget'ları (F5.2).
///
/// Aileler ve `kind` değerleri Dart tarafındaki `kIosWidgetKinds` ile **aynı**
/// olmalı (`lib/services/reminder_home_widget_sync.dart`): her senkrondan sonra
/// `WidgetCenter.reloadTimelines(ofKind:)` bu adlarla çağrılır.
///
/// Galerideki ad ve açıklamalar Android'deki `widget_*_label` /
/// `widget_*_description` kaynaklarının aynısıdır (`tr.lproj` / `en.lproj`,
/// cihaz dili — Android'de widget seçicinin cihaz dilini kullanması gibi).
@main
struct ReminderWidgetBundle: WidgetBundle {
  var body: some Widget {
    ReminderNextWidget()
    ReminderTodayWidget()
    ReminderListWidget()
    ReminderLockWidget()
  }
}

/// Sıradaki (systemSmall): saat + başlık + tamamla düğmesi.
struct ReminderNextWidget: Widget {
  static let kind = "ReminderNextWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: ReminderNextWidget.kind, provider: ReminderProvider()) { entry in
      NextWidgetView(entry: entry)
        .containerBackground(for: .widget) { WidgetTheme.surface }
    }
    .configurationDisplayName(Text("widget_next_label_name", bundle: .main))
    .description(Text("widget_next_description", bundle: .main))
    .supportedFamilies([.systemSmall])
  }
}

/// Bugün (systemMedium): "Bugün · N" + 3 satır.
struct ReminderTodayWidget: Widget {
  static let kind = "ReminderTodayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: ReminderTodayWidget.kind, provider: ReminderProvider()) { entry in
      TodayWidgetView(entry: entry)
        .containerBackground(for: .widget) { WidgetTheme.surface }
    }
    .configurationDisplayName(Text("widget_today_label", bundle: .main))
    .description(Text("widget_today_description", bundle: .main))
    .supportedFamilies([.systemMedium])
  }
}

/// Liste (systemLarge): bölümler + doğum günü satırı; "Yalnızca bugün"
/// seçeneği [ReminderListConfiguration] ile ayarlanır.
struct ReminderListWidget: Widget {
  static let kind = "ReminderListWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: ReminderListWidget.kind,
      intent: ReminderListConfiguration.self,
      provider: ReminderListProvider()
    ) { entry in
      ListWidgetView(entry: entry)
        .containerBackground(for: .widget) { WidgetTheme.surface }
    }
    .configurationDisplayName(Text("widget_list_label", bundle: .main))
    .description(Text("widget_list_description", bundle: .main))
    .supportedFamilies([.systemLarge])
  }
}

/// Kilit ekranı: dikdörtgen (sıradaki), daire (bugünün açık sayısı) ve satır.
struct ReminderLockWidget: Widget {
  static let kind = "ReminderLockWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: ReminderLockWidget.kind, provider: ReminderProvider()) { entry in
      LockWidgetEntryView(entry: entry)
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(Text("widget_lock_label", bundle: .main))
    .description(Text("widget_lock_description", bundle: .main))
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

struct LockWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family

  let entry: ReminderEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      LockCircularView(entry: entry)
    case .accessoryInline:
      LockInlineView(entry: entry)
    default:
      LockRectangularView(entry: entry)
    }
  }
}
