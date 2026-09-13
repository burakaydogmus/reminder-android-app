import 'package:reminder/domain/model/reminder.dart';

/// Hatırlatıcı listelerinin ortak sıralaması (`List.sort` karşılaştırıcısı).
///
/// 1. Tamamlanmamışlar tamamlananlardan önce.
/// 2. Zamanlılar `remindAt`'e göre artan.
/// 3. Zamanlılar zamansızlardan önce.
/// 4. Zamansızlar `createdAt`'e göre azalan (en yeni önce).
int compareReminders(Reminder a, Reminder b) {
  if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
  final ta = a.remindAt;
  final tb = b.remindAt;
  if (ta != null && tb != null) return ta.compareTo(tb);
  if (ta != null) return -1;
  if (tb != null) return 1;
  return b.createdAt.compareTo(a.createdAt);
}
