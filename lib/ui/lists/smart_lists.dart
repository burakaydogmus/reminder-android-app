import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Listeler › akıllı listeler (§3.2, §3.3.6). Reminder lists only contain
/// open (not done) reminders; [birthdays] is counted from birthdays and opens
/// the Doğum günleri screen.
enum SmartList {
  /// Due before now.
  overdue,

  /// Due today, not yet overdue.
  today,

  /// Due now or later (today included).
  scheduled,

  /// No time.
  untimed,

  /// Birthdays (not reminders).
  birthdays,

  /// Location trigger on.
  located;

  /// "Gecikmiş", "Bugün", "Planlı", "Zamansız", "Doğum günleri", "Konumlu".
  String labelIn(AppLocalizations l10n) => switch (this) {
        overdue => l10n.smartListOverdue,
        today => l10n.smartListToday,
        scheduled => l10n.smartListScheduled,
        untimed => l10n.smartListUntimed,
        birthdays => l10n.smartListBirthdays,
        located => l10n.smartListLocated,
      };

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
