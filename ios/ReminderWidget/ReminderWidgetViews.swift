import SwiftUI
import WidgetKit

// MARK: - Ortak parçalar

/// "Tamamla" dairesi (F5.2): `CompleteReminderIntent` düğmesi.
///
/// Accented / tinted modlarda vurgu grubunda kalması için tek
/// `widgetAccentable()` öğe budur (tasarım §3.4).
struct CompleteButton: View {
  let item: WidgetItem
  let strings: WidgetStrings
  var diameter: CGFloat = 34

  var body: some View {
    Button(intent: CompleteReminderIntent(reminderId: item.id)) {
      Image(systemName: "circle")
        .font(.system(size: diameter * 0.55, weight: .regular))
        .foregroundStyle(WidgetTheme.category(item.category))
        .widgetAccentable()
    }
    .buttonStyle(.plain)
    .frame(width: diameter, height: diameter)
    .contentShape(Rectangle())
    .accessibilityLabel(strings.format("widget_cd_complete", item.title))
  }
}

/// Hap "+" (Bugün / Sıradaki) — hızlı yakalamayı açar.
struct AddButton: View {
  let strings: WidgetStrings
  var wide: Bool = false

  var body: some View {
    Link(destination: ReminderWidgetStore.launchURL(host: "new")) {
      Image(systemName: "plus")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(WidgetTheme.onPill)
        .frame(width: wide ? 44 : 30, height: 30)
        .background(WidgetTheme.pill, in: Capsule())
    }
    .accessibilityLabel(strings("widget_cd_add"))
  }
}

/// "Bildirimler kapalı — açmak için dokun" → Ayarlar › İzinler.
struct NotificationsOffBanner: View {
  let strings: WidgetStrings

  var body: some View {
    Link(destination: ReminderWidgetStore.launchURL(host: "permissions")) {
      HStack(spacing: 4) {
        Image(systemName: "bell.slash.fill").font(.system(size: 10))
        Text(strings("widget_notifications_off"))
          .font(.caption2)
          .lineLimit(2)
        Spacer(minLength: 0)
      }
      .foregroundStyle(WidgetTheme.onPill)
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(WidgetTheme.pill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
  }
}

/// Bir hatırlatıcı satırı: tamamla dairesi + başlık + meta (saat, maddeler,
/// tekrar). Satıra dokunmak hatırlatıcıyı uygulamada açar.
struct ReminderRow: View {
  let item: WidgetItem
  let entry: ReminderEntry
  var diameter: CGFloat = 34

  private var strings: WidgetStrings { entry.strings }

  private var isOverdue: Bool {
    guard let at = item.dueAt else { return false }
    return at < entry.date
  }

  private var meta: String? {
    var parts: [String] = []
    if let label = strings.timeLabel(item.dueAt, now: entry.date) { parts.append(label) }
    if let subtasks = item.subtasks, !subtasks.isEmpty {
      parts.append(strings.format("widget_cd_subtasks", subtasks))
    }
    if item.recurring { parts.append(strings("widget_cd_recurring")) }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  var body: some View {
    HStack(spacing: 6) {
      CompleteButton(item: item, strings: strings, diameter: diameter)
      Link(destination: ReminderWidgetStore.launchURL(host: "open", id: item.id)) {
        VStack(alignment: .leading, spacing: 1) {
          Text(item.title)
            .font(.subheadline)
            .lineLimit(1)
            .foregroundStyle(WidgetTheme.onSurface)
          if let meta = meta {
            Text(meta)
              .font(.caption2)
              .lineLimit(1)
              .foregroundStyle(isOverdue ? WidgetTheme.primary : WidgetTheme.onSurfaceVariant)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
    }
  }
}

/// "🎂 Zeynep Aydın · Yarın" alt satırı.
struct BirthdayRowView: View {
  let row: WidgetBirthdayRow
  let strings: WidgetStrings

  private var label: String {
    let when = row.isToday ? strings("widget_today") : strings("widget_tomorrow")
    if let age = row.birthday.age {
      return strings.format("widget_birthday_age", when, age)
    }
    return when
  }

  var body: some View {
    Link(destination: ReminderWidgetStore.launchURL(host: "birthday", id: row.birthday.id)) {
      HStack(spacing: 6) {
        Image(systemName: "gift")
          .font(.system(size: 13))
          .foregroundStyle(WidgetTheme.category("dogumgunu"))
        Text(row.birthday.name)
          .font(.caption)
          .foregroundStyle(WidgetTheme.onSurface)
        Text("· \(label)")
          .font(.caption2)
          .foregroundStyle(WidgetTheme.onSurfaceVariant)
        Spacer(minLength: 0)
      }
      .lineLimit(1)
      .contentShape(Rectangle())
    }
    .accessibilityLabel(strings.format("widget_cd_birthday", row.birthday.name, label))
  }
}

/// "Bugün boş. Eklemek için +"
struct EmptyTodayView: View {
  let strings: WidgetStrings

  var body: some View {
    Text(strings("widget_empty_today"))
      .font(.caption)
      .foregroundStyle(WidgetTheme.onSurfaceVariant)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - systemSmall · Sıradaki

struct NextWidgetView: View {
  let entry: ReminderEntry

  var body: some View {
    let snapshot = entry.snapshot
    let strings = entry.strings
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(strings("widget_next_label"))
          .font(.caption2.weight(.semibold))
          .foregroundStyle(WidgetTheme.onSurfaceVariant)
        Spacer(minLength: 0)
        AddButton(strings: strings)
      }
      Spacer(minLength: 4)
      if let next = snapshot.next {
        if let at = next.dueAt {
          Text(WidgetStrings.clock(at))
            .font(.title.weight(.semibold).monospacedDigit())
            .foregroundStyle(at < entry.date ? WidgetTheme.primary : WidgetTheme.onSurface)
        }
        if let label = dayLabel(next, snapshot: snapshot, strings: strings) {
          Text(label)
            .font(.caption2)
            .foregroundStyle(WidgetTheme.primary)
        }
        Text(next.title)
          .font(.subheadline)
          .lineLimit(2)
          .foregroundStyle(WidgetTheme.onSurface)
        Spacer(minLength: 2)
        HStack(spacing: 6) {
          CompleteButton(item: next, strings: strings, diameter: 30)
          if snapshot.moreThanNext > 0 {
            Text(strings.format("widget_more", snapshot.moreThanNext))
              .font(.caption2)
              .foregroundStyle(WidgetTheme.onSurfaceVariant)
          }
          Spacer(minLength: 0)
        }
      } else {
        EmptyTodayView(strings: strings)
        Spacer(minLength: 0)
      }
      if !snapshot.notificationsEnabled {
        NotificationsOffBanner(strings: strings)
      }
    }
    .widgetURL(ReminderWidgetStore.openURL(for: snapshot.next))
  }

  /// Saatin altındaki bağlam: gecikmişse "Gecikti", başka bir günse "Yarın" /
  /// "12 Eki"; bugünse (saat yeterli) `nil`.
  private func dayLabel(
    _ item: WidgetItem, snapshot: WidgetSnapshot, strings: WidgetStrings
  ) -> String? {
    guard let at = item.dueAt else { return nil }
    if at < entry.date { return strings("widget_overdue") }
    if at < WidgetPayload.startOfDay(entry.date, plusDays: 1) { return nil }
    return strings.dayLabel(at, now: entry.date)
  }
}

// MARK: - systemMedium · Bugün

struct TodayWidgetView: View {
  let entry: ReminderEntry

  var body: some View {
    let snapshot = entry.snapshot
    let strings = entry.strings
    let rows = Array(snapshot.todayOpen.prefix(3))
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(strings.format("widget_today_header", snapshot.todayOpen.count))
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(WidgetTheme.onSurface)
        Spacer(minLength: 0)
        AddButton(strings: strings, wide: true)
      }
      if rows.isEmpty {
        Spacer(minLength: 0)
        EmptyTodayView(strings: strings)
        Spacer(minLength: 0)
      } else {
        ForEach(rows) { item in
          ReminderRow(item: item, entry: entry)
        }
        if snapshot.todayOpen.count > rows.count {
          Text(strings.format("widget_more", snapshot.todayOpen.count - rows.count))
            .font(.caption2)
            .foregroundStyle(WidgetTheme.onSurfaceVariant)
        }
        Spacer(minLength: 0)
      }
      if !snapshot.notificationsEnabled {
        NotificationsOffBanner(strings: strings)
      }
    }
    .widgetURL(ReminderWidgetStore.launchURL(host: "new"))
    .accessibilityLabel(strings.format("widget_cd_today", snapshot.todayOpen.count))
  }
}

// MARK: - systemLarge · Liste

struct ListWidgetView: View {
  let entry: ReminderEntry

  /// Kaydırılamayan bir yüzey: sığdığı kadar satır + "+N daha".
  private static let maxRows = 6

  var body: some View {
    let snapshot = entry.snapshot
    let strings = entry.strings
    let visible = visibleSections(snapshot)
    VStack(alignment: .leading, spacing: 4) {
      VStack(alignment: .leading, spacing: 0) {
        Text(strings("widget_section_today"))
          .font(.headline)
          .foregroundStyle(WidgetTheme.onSurface)
        Text(strings.weekdayAndDate(entry.date))
          .font(.caption2)
          .foregroundStyle(WidgetTheme.onSurfaceVariant)
      }
      if visible.total == 0 {
        Spacer(minLength: 0)
        EmptyTodayView(strings: strings)
      } else {
        ForEach(visible.sections) { section in
          Text(strings(section.titleKey))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(WidgetTheme.onSurfaceVariant)
            .padding(.top, 2)
          ForEach(section.items) { item in
            ReminderRow(item: item, entry: entry, diameter: 30)
          }
        }
        if visible.total > visible.shown {
          Text(strings.format("widget_more", visible.total - visible.shown))
            .font(.caption2)
            .foregroundStyle(WidgetTheme.onSurfaceVariant)
        }
      }
      Spacer(minLength: 0)
      if !snapshot.birthdays.isEmpty {
        Divider().overlay(WidgetTheme.outline.opacity(0.4))
        ForEach(snapshot.birthdays.prefix(2)) { row in
          BirthdayRowView(row: row, strings: strings)
        }
      }
      if !snapshot.notificationsEnabled {
        NotificationsOffBanner(strings: strings)
      }
    }
    .widgetURL(ReminderWidgetStore.launchURL(host: "new"))
  }

  struct Section: Identifiable {
    let titleKey: String
    let items: [WidgetItem]
    var id: String { titleKey }
  }

  /// Sığdırılmış bölümler + toplam ve gösterilen satır sayısı.
  private func visibleSections(
    _ snapshot: WidgetSnapshot
  ) -> (sections: [Section], total: Int, shown: Int) {
    let all = buildSections(snapshot)
    let total = all.reduce(0) { $0 + $1.items.count }
    var budget = ListWidgetView.maxRows
    var trimmed: [Section] = []
    for section in all {
      if budget <= 0 { break }
      let take = Array(section.items.prefix(budget))
      budget -= take.count
      trimmed.append(Section(titleKey: section.titleKey, items: take))
    }
    let shown = trimmed.reduce(0) { $0 + $1.items.count }
    return (trimmed, total, shown)
  }

  private func buildSections(_ snapshot: WidgetSnapshot) -> [Section] {
    var sections: [Section] = []
    if !snapshot.overdue.isEmpty {
      sections.append(Section(titleKey: "widget_section_overdue", items: snapshot.overdue))
    }
    let todayItems = snapshot.today + snapshot.untimed
    if !todayItems.isEmpty {
      sections.append(Section(titleKey: "widget_section_today", items: todayItems))
    }
    if !entry.todayOnly && !snapshot.later.isEmpty {
      sections.append(Section(titleKey: "widget_section_later", items: snapshot.later))
    }
    return sections
  }
}

// MARK: - Kilit ekranı aileleri

struct LockRectangularView: View {
  let entry: ReminderEntry

  var body: some View {
    let snapshot = entry.snapshot
    let strings = entry.strings
    VStack(alignment: .leading, spacing: 1) {
      if let next = snapshot.next {
        Text(headline(next, strings: strings))
          .font(.headline.monospacedDigit())
          .lineLimit(1)
        Text(next.title)
          .font(.caption)
          .lineLimit(1)
        if snapshot.moreThanNext > 0 {
          Text(strings.format("widget_more", snapshot.moreThanNext))
            .font(.caption2)
        }
      } else {
        Text(strings("widget_section_today")).font(.headline)
        Text(strings("widget_empty_today")).font(.caption2).lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(ReminderWidgetStore.openURL(for: snapshot.next))
  }

  private func headline(_ item: WidgetItem, strings: WidgetStrings) -> String {
    guard let at = item.dueAt else { return strings("widget_section_today") }
    if at < entry.date { return strings("widget_overdue") }
    if at < WidgetPayload.startOfDay(entry.date, plusDays: 1) {
      return WidgetStrings.clock(at)
    }
    return "\(strings.dayLabel(at, now: entry.date)) \(WidgetStrings.clock(at))"
  }
}

/// Kilit ekranı dairesi: bugünün açık iş sayısı.
///
/// Tasarımdaki "2/8 tamamlandı" göstergesi çizilmiyor: paylaşılan veri
/// bilinçli olarak yalnız **açık** hatırlatıcıları taşır ve tamamlanan sayısı
/// çizim anında yeniden hesaplanamayacağı için bayatlardı (bkz. PR notu).
struct LockCircularView: View {
  let entry: ReminderEntry

  var body: some View {
    let snapshot = entry.snapshot
    VStack(spacing: -1) {
      Image(systemName: "checklist").font(.system(size: 11))
      Text("\(snapshot.todayOpen.count)")
        .font(.system(size: 17, weight: .semibold).monospacedDigit())
    }
    .widgetURL(ReminderWidgetStore.launchURL(host: "new"))
    .accessibilityLabel(entry.strings.format("widget_cd_today", snapshot.todayOpen.count))
  }
}

struct LockInlineView: View {
  let entry: ReminderEntry

  var body: some View {
    let snapshot = entry.snapshot
    let strings = entry.strings
    if let next = snapshot.next {
      if let at = next.dueAt, at >= entry.date {
        Text("\(WidgetStrings.clock(at)) · \(next.title)")
      } else if next.dueAt != nil {
        Text("\(strings("widget_overdue")) · \(next.title)")
      } else {
        Text(next.title)
      }
    } else {
      Text(strings("widget_empty_today"))
    }
  }
}
