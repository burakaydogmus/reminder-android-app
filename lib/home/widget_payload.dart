import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';

/// Android ana ekran widget'larının veri sözleşmesi (F5.1).
///
/// `syncRemindersToHomeWidget` bu yapıyı JSON olarak [kHomeWidgetPayloadKey]
/// anahtarına yazar; dört Kotlin `AppWidgetProvider`'ı (Sıradaki, Bugün,
/// Liste, Hızlı ekle) aynı anahtarı okur. Alanlar eşitleme anındaki duruma
/// göredir; Kotlin tarafı zamana bağlı alanları (gecikme, "Yarın" → saat,
/// bölüm, sayılar, sıradaki) çizim anında `dueAt` / `date` ile yeniden
/// hesaplar, çünkü widget uygulama açılmadan saatler boyunca yaşar.
///
/// Biçim (`v: 2`):
///
/// ```json
/// {
///   "v": 2,
///   "generatedAt": 1789999200000,
///   "notificationsEnabled": true,
///   "counts": {"today": 3, "overdue": 1, "open": 7},
///   "next": {"id": "…", "title": "…", "clock": "16:00", "day": "Bugün",
///            "dueAt": 1790002800000, "overdue": false, "more": 3},
///   "items": [{"id": "…", "title": "…", "section": "today",
///              "time": "16:00", "clock": "16:00", "dueAt": 1790002800000,
///              "overdue": false, "category": "market",
///              "subtasks": "2/6", "recurring": true}],
///   "birthdays": [{"id": "…", "name": "Ayşe", "label": "Bugün",
///                  "date": 1789941600000, "age": 36}]
/// }
/// ```
///
/// Alan eklemek geriye uyumludur; anlamı değişen bir değişiklikte [version]
/// ve anahtar artırılır.
abstract final class WidgetPayload {
  /// Sözleşme sürümü.
  static const int version = 2;

  /// Widget'a yazılan en fazla hatırlatıcı (kaydırılabilir Liste için yeter,
  /// SharedPreferences'ı şişirmez).
  static const int maxItems = 60;

  /// Bölüm kimlikleri; Kotlin tarafıyla ortak.
  static const String sectionOverdue = 'overdue';
  static const String sectionToday = 'today';
  static const String sectionUntimed = 'untimed';
  static const String sectionLater = 'later';

  /// Gecikmiş öğenin zaman etiketi.
  static const String overdueLabel = 'Gecikti';
  static const String todayLabel = 'Bugün';
  static const String tomorrowLabel = 'Yarın';

  static const List<String> _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// Widget verisini üretir (saf fonksiyon).
  ///
  /// Açık (tamamlanmamış) hatırlatıcılar bölümlere ayrılır — Bugün
  /// ekranındaki `TodaySections` ile aynı kural: `remindAt` şu andan önce →
  /// `overdue`; bugün, daha sonra → `today`; zamansız → `untimed`; sonraki
  /// günler → `later`. Sıra: bölüm sırası, bölüm içinde [compareReminders].
  /// En fazla [maxItems] öğe yazılır; sayılar her zaman tüm listeden
  /// hesaplanır. Doğum günleri: bugün veya yarın olanlar, yakın olan önce.
  static Map<String, Object?> build({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
    required DateTime now,
    CategoryCatalog? categories,
  }) {
    final catalog = categories ?? CategoryCatalog.builtIns;
    final overdue = <Reminder>[];
    final today = <Reminder>[];
    final untimed = <Reminder>[];
    final later = <Reminder>[];
    for (final r in reminders) {
      if (r.isDone) continue;
      final at = r.remindAt?.toLocal();
      if (at == null) {
        untimed.add(r);
      } else if (at.isBefore(now)) {
        overdue.add(r);
      } else if (_isSameDay(at, now)) {
        today.add(r);
      } else {
        later.add(r);
      }
    }
    for (final list in [overdue, today, untimed, later]) {
      list.sort(compareReminders);
    }

    final items = <Map<String, Object?>>[
      for (final r in overdue) _item(r, sectionOverdue, now, catalog),
      for (final r in today) _item(r, sectionToday, now, catalog),
      for (final r in untimed) _item(r, sectionUntimed, now, catalog),
      for (final r in later) _item(r, sectionLater, now, catalog),
    ];

    final todayCount = today.length + untimed.length;
    final next = _next(
      overdue: overdue,
      today: today,
      untimed: untimed,
      later: later,
      now: now,
    );

    return {
      'v': version,
      'generatedAt': now.millisecondsSinceEpoch,
      'notificationsEnabled': notificationsEnabled,
      'counts': {
        'today': todayCount,
        'overdue': overdue.length,
        'open': items.length,
      },
      'next': next,
      'items': items.take(maxItems).toList(growable: false),
      'birthdays': _birthdays(birthdays, now),
    };
  }

  /// Sıradaki: en yakın gelecek zamanlı öğe (bugün veya sonra); yoksa en eski
  /// gecikmiş, o da yoksa ilk zamansız. `more`: bugünün diğer açık öğeleri
  /// (gecikmiş + bugün + zamansız, sıradaki hariç).
  static Map<String, Object?>? _next({
    required List<Reminder> overdue,
    required List<Reminder> today,
    required List<Reminder> untimed,
    required List<Reminder> later,
    required DateTime now,
  }) {
    final Reminder? next = today.isNotEmpty
        ? today.first
        : later.isNotEmpty
            ? later.first
            : overdue.isNotEmpty
                ? overdue.first
                : untimed.isNotEmpty
                    ? untimed.first
                    : null;
    if (next == null) return null;
    final todayOpen = overdue.length + today.length + untimed.length;
    final inToday = !later.contains(next);
    final at = next.remindAt?.toLocal();
    final isOverdue = at != null && at.isBefore(now);
    return {
      'id': next.id,
      'title': next.title,
      'clock': at == null ? null : clock(at),
      'day': at == null
          ? null
          : isOverdue
              ? overdueLabel
              : dayLabel(at, now),
      'dueAt': at?.millisecondsSinceEpoch,
      'overdue': isOverdue,
      'more': inToday ? todayOpen - 1 : todayOpen,
    };
  }

  static Map<String, Object?> _item(
    Reminder r,
    String section,
    DateTime now,
    CategoryCatalog catalog,
  ) {
    final at = r.remindAt?.toLocal();
    return {
      'id': r.id,
      'title': r.title,
      'section': section,
      'time': timeLabel(at, now),
      'clock': at == null ? null : clock(at),
      'dueAt': at?.millisecondsSinceEpoch,
      'overdue': section == sectionOverdue,
      // F4.3: user categories resolve through the catalog.
      'category': CategoryVisuals.colorKeyFor(r.categoryId, catalog).storageKey,
      'subtasks': subtaskProgress(r.subtasks),
      'recurring': r.isRecurring,
    };
  }

  /// Bugün (0) veya yarın (1) olan doğum günleri. `daysUntilNext` bildirim
  /// saati geçince gelecek yılı döndürdüğü için gün, takvim tarihinden
  /// hesaplanır: bugünün doğum günü bütün gün "Bugün" kalır.
  static List<Map<String, Object?>> _birthdays(
    List<Birthday> birthdays,
    DateTime now,
  ) {
    final soon = <(Birthday, int)>[];
    for (final b in birthdays) {
      for (var days = 0; days <= 1; days++) {
        final day = DateTime(now.year, now.month, now.day + days);
        final at = b.occurrenceInYear(day.year);
        if (at.month == day.month && at.day == day.day) {
          soon.add((b, days));
          break;
        }
      }
    }
    soon.sort((a, b) {
      final byDay = a.$2.compareTo(b.$2);
      return byDay != 0 ? byDay : a.$1.name.compareTo(b.$1.name);
    });
    return [
      for (final (b, days) in soon)
        {
          'id': b.id,
          'name': b.name,
          'label': days == 0 ? todayLabel : tomorrowLabel,
          'date': DateTime(now.year, now.month, now.day + days)
              .millisecondsSinceEpoch,
          'age': _ageOn(b, DateTime(now.year, now.month, now.day + days)),
        },
    ];
  }

  static int? _ageOn(Birthday b, DateTime day) {
    if (!b.hasYear) return null;
    final age = day.year - b.date.year;
    return age > 0 ? age : null;
  }

  /// Satırdaki zaman etiketi: gecikmiş → "Gecikti", bugün → "16:00", yarın
  /// → "Yarın", sonrası → "12 Eki"; zamansız → `null`.
  static String? timeLabel(DateTime? at, DateTime now) {
    if (at == null) return null;
    if (at.isBefore(now)) return overdueLabel;
    if (_isSameDay(at, now)) return clock(at);
    return dayLabel(at, now);
  }

  /// "Bugün" / "Yarın" / "12 Eki" (yıl farklıysa "12 Oca 2027").
  static String dayLabel(DateTime at, DateTime now) {
    if (_isSameDay(at, now)) return todayLabel;
    if (_isSameDay(at, DateTime(now.year, now.month, now.day + 1))) {
      return tomorrowLabel;
    }
    final base = '${at.day} ${_months[at.month - 1]}';
    return at.year == now.year ? base : '$base ${at.year}';
  }

  /// Tabular 24 saat biçimi: "09:05".
  static String clock(DateTime at) => '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// "2/6" (tamamlanan/toplam); madde yoksa `null`.
  static String? subtaskProgress(List<Subtask> subtasks) =>
      subtasks.isEmpty ? null : '${subtasks.doneCount}/${subtasks.length}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
