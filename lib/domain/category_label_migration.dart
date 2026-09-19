import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/notification_ids.dart';

/// "Diğer + özel ad" → kullanıcı kategorisi dönüşümünün planı (F4.3).
class CategoryLabelPlan {
  const CategoryLabelPlan({
    required this.created,
    required this.assignments,
  });

  static const empty = CategoryLabelPlan(created: [], assignments: {});

  /// Yeni kullanıcı kategorileri (renk `diger`, ikon `label`), ilk görülme
  /// sırasıyla ve mevcut kategorilerin arkasına konumlanmış.
  final List<ReminderCategory> created;

  /// Hatırlatıcı kimliği → yeni `categoryId`. Etiketi olmayan ya da "Diğer"
  /// adını taşıyan hatırlatıcılar burada yoktur (Diğer'de kalır).
  final Map<String, String> assignments;

  bool get isEmpty => created.isEmpty && assignments.isEmpty;
}

/// F4.3 öncesi `categoryId == other` + `customCategoryLabel` kayıtlarını
/// kullanıcı kategorilerine dönüştürür. Tek kural, üç yerde kullanılır:
/// şema v5 geçişi (`AppDatabase` `from < 5`), SharedPreferences geçişi
/// (`PrefsMigration`) ve v1 yedek içe aktarma (`BackupFormat.decode`).
///
/// - Her farklı ad bir kategori olur; adlar Türkçe katlanarak
///   ([CategoryNames.fold]) karşılaştırılır, yani `Spor`, `SPOR` ve ` spor `
///   tek kategoridir (ilk görülen yazım ad olur).
/// - Adı mevcut bir kategoriyle (yerleşikler dahil) aynı olan etiket o
///   kategoriye bağlanır: `market` → Market, `diğer` → Diğer (değişmez).
/// - Kimlik ada göre kararlıdır ([idFor]): aynı etiket her yerde aynı
///   kategoriye dönüşür, böylece aynı yedeği tekrar içe aktarmak kopya
///   üretmez.
abstract final class CategoryLabelMigration {
  /// Katlanmış ada göre kararlı kimlik: `label-<fnv1a32 hex>`.
  static String idFor(String label) {
    final hash = NotificationIds.fnv1a32(CategoryNames.fold(label));
    return 'label-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// [entries]: `categoryId == other` olan hatırlatıcıların (kimlik, etiket)
  /// çiftleri; diğer hatırlatıcılar verilmemelidir.
  static CategoryLabelPlan plan(
    Iterable<(String reminderId, String? label)> entries, {
    required CategoryCatalog existing,
  }) {
    final created = <String, ReminderCategory>{};
    final assignments = <String, String>{};
    var nextPosition = existing.ordered.length;
    final usedIds = {for (final c in existing.ordered) c.id};

    for (final (reminderId, rawLabel) in entries) {
      final label = rawLabel?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
      if (label.isEmpty) continue;
      final key = CategoryNames.fold(label);

      final match = existing.byFoldedName(label);
      final String categoryId;
      if (match != null) {
        categoryId = match.id;
      } else if (created[key] case final category?) {
        categoryId = category.id;
      } else {
        var id = idFor(label);
        // Aynı kimlikte farklı adlı bir kategori (çok düşük olasılık).
        for (var n = 2; usedIds.contains(id); n++) {
          id = '${idFor(label)}-$n';
        }
        usedIds.add(id);
        final category = ReminderCategory(
          id: id,
          name: label,
          colorKey: CategoryColorKeys.diger,
          iconKey: CategoryIconKeys.label,
          position: nextPosition++,
        );
        created[key] = category;
        categoryId = id;
      }
      if (categoryId != ReminderCategoryIds.other) {
        assignments[reminderId] = categoryId;
      }
    }
    return CategoryLabelPlan(
      created: List.unmodifiable(created.values),
      assignments: Map.unmodifiable(assignments),
    );
  }

  /// [reminders] üzerinde [plan] uygular: bağlanan hatırlatıcıların
  /// `categoryId`'si değişir, `customCategoryLabel` geri dönüş güvenliği için
  /// korunur.
  static ({List<Reminder> reminders, List<ReminderCategory> created}) apply(
    List<Reminder> reminders, {
    required CategoryCatalog existing,
  }) {
    final plan = CategoryLabelMigration.plan(
      [
        for (final r in reminders)
          if (r.categoryId == ReminderCategoryIds.other)
            (r.id, r.customCategoryLabel),
      ],
      existing: existing,
    );
    if (plan.isEmpty) return (reminders: reminders, created: const []);
    return (
      reminders: [
        for (final r in reminders)
          if (plan.assignments[r.id] case final id?)
            r.copyWith(categoryId: id)
          else
            r,
      ],
      created: plan.created,
    );
  }
}
