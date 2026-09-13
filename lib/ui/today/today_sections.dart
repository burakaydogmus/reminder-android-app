import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Bugün screen grouping, computed in the UI layer from cubit state and an
/// injected [now].
///
/// - [overdue]: not done, `remindAt` before now (any earlier day or time).
/// - [today]: not done, due later today; sorted by time.
/// - [untimed]: not done, no time.
/// - [completed]: done and due today or untimed (there is no completion
///   timestamp yet; older done items live in Listeler › Tamamlananlar).
///
/// Reminders due on later days are not here; they appear in Takvim.
class TodaySections {
  const TodaySections({
    required this.overdue,
    required this.today,
    required this.untimed,
    required this.completed,
    required this.birthdays,
  });

  final List<Reminder> overdue;
  final List<Reminder> today;
  final List<Reminder> untimed;
  final List<Reminder> completed;

  /// Birthdays today or tomorrow, soonest first.
  final List<BirthdayOccurrence> birthdays;

  factory TodaySections.from({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required DateTime now,
  }) {
    final overdue = <Reminder>[];
    final today = <Reminder>[];
    final untimed = <Reminder>[];
    final completed = <Reminder>[];

    for (final r in reminders) {
      final at = r.remindAt?.toLocal();
      if (r.isDone) {
        if (at == null || KorFormat.isSameDay(at, now)) completed.add(r);
        continue;
      }
      if (at == null) {
        untimed.add(r);
      } else if (at.isBefore(now)) {
        overdue.add(r);
      } else if (KorFormat.isSameDay(at, now)) {
        today.add(r);
      }
    }

    overdue.sort(compareReminders);
    today.sort(compareReminders);
    untimed.sort(compareReminders);
    completed.sort(compareReminders);

    final soon = birthdays
        .map((b) => BirthdayOccurrence.next(b, now))
        .where((o) => o.daysUntil <= 1)
        .toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

    return TodaySections(
      overdue: List.unmodifiable(overdue),
      today: List.unmodifiable(today),
      untimed: List.unmodifiable(untimed),
      completed: List.unmodifiable(completed),
      birthdays: List.unmodifiable(soon),
    );
  }

  /// Open today (timed + untimed), excluding overdue.
  int get openCount => today.length + untimed.length;
  int get overdueCount => overdue.length;
  int get doneCount => completed.length;
  int get totalCount => openCount + overdueCount + doneCount;

  bool get hasOpen => openCount + overdueCount > 0;

  /// Nothing open and nothing completed today.
  bool get isEmpty => totalCount == 0;

  /// Everything for today is done.
  bool get allDone => !hasOpen && doneCount > 0;

  /// Completed share for the progress bar (0 when empty).
  double get progress => totalCount == 0 ? 0 : doneCount / totalCount;

  /// `6 açık · 1 gecikmiş · 2 tamam`.
  String get summary =>
      '$openCount açık · $overdueCount gecikmiş · $doneCount tamam';
}
