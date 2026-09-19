import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/l10n/l10n.dart';
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
  String summary(AppLocalizations l10n) =>
      l10n.todaySummary(openCount, overdueCount, doneCount);

  /// Completed items with a time today; they stay on the time ribbon.
  List<Reminder> get completedTimed => [
        for (final r in completed)
          if (r.remindAt != null) r
      ];

  /// Completed items without a time (collapsible Tamamlananlar).
  List<Reminder> get completedUntimed => [
        for (final r in completed)
          if (r.remindAt == null) r
      ];

  /// Time ribbon (§3.3.2): open timed items of today plus, with
  /// [includeCompleted], today's completed timed items, in chronological
  /// order, with one [TimelineNow] marker placed before the first item due
  /// after [now] (items due exactly at [now] come before it).
  List<TimelineEntry> timeline({
    required DateTime now,
    bool includeCompleted = true,
  }) {
    final items = [
      ...today,
      if (includeCompleted) ...completedTimed,
    ]..sort((a, b) {
        final byTime = a.remindAt!.toLocal().compareTo(b.remindAt!.toLocal());
        return byTime != 0 ? byTime : compareReminders(a, b);
      });
    final entries = <TimelineEntry>[];
    var nowPlaced = false;
    for (final r in items) {
      if (!nowPlaced && r.remindAt!.toLocal().isAfter(now)) {
        entries.add(TimelineNow(now));
        nowPlaced = true;
      }
      entries.add(TimelineReminder(r));
    }
    if (!nowPlaced) entries.add(TimelineNow(now));
    return List.unmodifiable(entries);
  }

  /// "Hepsini yarına al": tomorrow (relative to [now]) at the wall-clock
  /// time of [at].
  static DateTime tomorrowAtSameTime(DateTime at, DateTime now) {
    final local = at.toLocal();
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      local.hour,
      local.minute,
      local.second,
    );
  }
}

/// One row of the time ribbon.
sealed class TimelineEntry {
  const TimelineEntry();
}

/// A reminder on the ribbon.
final class TimelineReminder extends TimelineEntry {
  const TimelineReminder(this.reminder);
  final Reminder reminder;
}

/// The ŞİMDİ line.
final class TimelineNow extends TimelineEntry {
  const TimelineNow(this.now);
  final DateTime now;
}
