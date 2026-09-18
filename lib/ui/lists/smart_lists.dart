import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Listeler › akıllı listeler (§3.2, §3.3.6). Reminder lists only contain
/// open (not done) reminders; [birthdays] is counted from birthdays and opens
/// the Doğum günleri screen.
enum SmartList {
  /// Due before now.
  overdue('Gecikmiş'),

  /// Due today, not yet overdue.
  today('Bugün'),

  /// Due now or later (today included).
  scheduled('Planlı'),

  /// No time.
  untimed('Zamansız'),

  /// Birthdays (not reminders).
  birthdays('Doğum günleri'),

  /// Location trigger on.
  located('Konumlu');

  const SmartList(this.label);

  final String label;

  /// Whether open reminder [r] belongs to this list at [now]. Always false
  /// for [birthdays].
  bool contains(Reminder r, DateTime now) {
    if (r.isDone) return false;
    final at = r.remindAt?.toLocal();
    return switch (this) {
      SmartList.overdue => at != null && at.isBefore(now),
      SmartList.today =>
        at != null && !at.isBefore(now) && KorFormat.isSameDay(at, now),
      SmartList.scheduled => at != null && !at.isBefore(now),
      SmartList.untimed => at == null,
      SmartList.birthdays => false,
      SmartList.located => r.locationTriggerEnabled,
    };
  }

  /// Members of this list, in [compareReminders] order.
  List<Reminder> filter(Iterable<Reminder> reminders, DateTime now) =>
      List.unmodifiable(
        reminders.where((r) => contains(r, now)).toList()
          ..sort(compareReminders),
      );
}
