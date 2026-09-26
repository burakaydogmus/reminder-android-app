import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/subtask.dart';

/// "Tamamla" kuralı (F3.1); uygulama içi ([ReminderCubit.toggleDone]), ana
/// ekran widget'ı ve bildirim aksiyonları aynı fonksiyonu kullanır.
///
/// - Zaten tamamlanmışsa [reminder] aynen döner (aynı nesne).
/// - Tekrarlayan ([Reminder.isRecurring]) hatırlatıcı tamamlanmış sayılmaz:
///   **takvime bağlı** kuralda (`RecurrenceAnchor.schedule`) `remindAt`,
///   `max(now, remindAt)` anından **sonraki** ilk tekrara ilerler. Böylece
///   erken tamamlama (vakti gelmeden) bu seferi atlar, gecikmiş bir
///   hatırlatıcı ise kaçırılan tekrarları atlayıp gelecekteki ilk tekrara
///   gider. Yeni tekrar için maddeler (F3.3) tamamlanmamış hale döner.
/// - **Tamamlamaya bağlı** kuralda (`RecurrenceAnchor.completion`, F3.1c)
///   sıradaki tekrar takvimden değil **[now]'dan** — gerçekten tamamlandığı
///   günden — sayılır (`RecurrenceRule.nextAfterCompletion`): geç tamamlamak
///   sıradakini ileri iter, erken tamamlamak geri çeker. Saat hatırlatıcının
///   kendi saatinden gelir, tamamlama anından değil.
/// - Seri bittiyse (bitiş tarihi geçti) ve tekrarsız hatırlatıcılarda
///   `isDone = true`; maddelere dokunulmaz (hatırlatıcıyı tamamlamak
///   maddeleri tamamlamaz).
Reminder completeReminder(Reminder reminder, DateTime now) {
  if (reminder.isDone) return reminder;
  final at = reminder.remindAt;
  if (reminder.isRecurring && at != null) {
    final rule = reminder.recurrence;
    final next = rule.isCompletionAnchored
        ? rule.nextAfterCompletion(completedAt: now, anchor: at)
        : rule.nextOccurrence(after: now.isAfter(at) ? now : at, anchor: at);
    if (next != null) {
      return reminder.copyWith(
        remindAt: () => next,
        subtasks: reminder.subtasks.reset,
      );
    }
  }
  return reminder.copyWith(isDone: true);
}
