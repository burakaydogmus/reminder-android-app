import 'package:reminder/domain/model/reminder.dart';

/// Hatırlatıcı listelerinin ortak sıralaması (`List.sort` karşılaştırıcısı),
/// §3.3.2: "pinned → saat → öncelik; zamansız: pinned → öncelik →
/// oluşturulma".
///
/// 1. Tamamlanmamışlar tamamlananlardan önce.
/// 2. Sabitlenmişler (F3.4) sabitlenmemişlerden önce.
/// 3. Zamanlılar zamansızlardan önce.
/// 4. Zamanlılar `remindAt`'e göre artan; aynı saatte öncelik azalan.
/// 5. Zamansızlar önceliğe göre azalan, sonra `createdAt`'e göre azalan (en
///    yeni önce).
///
/// Bugün şeridi saat sırasını ayrıca korur (`TodaySections.timeline`);
/// sabitleme orada yalnızca aynı saatteki öğeleri etkiler.
int compareReminders(Reminder a, Reminder b) {
  if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
  if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
  final ta = a.remindAt;
  final tb = b.remindAt;
  if (ta != null && tb != null) {
    final byTime = ta.compareTo(tb);
    return byTime != 0 ? byTime : b.priority.compareTo(a.priority);
  }
  if (ta != null) return -1;
  if (tb != null) return 1;
  final byPriority = b.priority.compareTo(a.priority);
  if (byPriority != 0) return byPriority;
  return b.createdAt.compareTo(a.createdAt);
}
