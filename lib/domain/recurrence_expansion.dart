import 'package:reminder/domain/model/reminder.dart';

/// Occurrence times of [reminder] in `[from, to)`, in order.
///
/// - No `remindAt` → none.
/// - One-off → its `remindAt` when inside the range.
/// - Recurring **on schedule** (F3.1, `RecurrenceAnchor.schedule`) → the stored
///   `remindAt` (the current occurrence) when inside the range, then every
///   following occurrence from `RecurrenceRule.nextOccurrence` with the stored
///   `remindAt` as anchor (time of day from the anchor, month-end clamp,
///   `until` inclusive). When the stored `remindAt` is before [from], the
///   series is picked up at its first occurrence on or after [from].
/// - Recurring **after completion** (F3.1c, `RecurrenceAnchor.completion`) →
///   **only the current occurrence**, exactly like a one-off. Such a series has
///   no known future dates: the next one is "completion + interval" and the
///   completion has not happened yet. Projecting one from the current date
///   would be a guess the calendar then shows as fact — and every later date
///   would move the moment the user completes it. So the calendar shows the one
///   date that is real, and the rest appears as the reminder is completed.
///
/// Occurrences never come before the stored `remindAt`: completing a
/// recurring reminder moves the anchor forward, so earlier dates are done.
/// At most [limit] dates are returned (guards daily rules on long ranges).
List<DateTime> reminderOccurrences(
  Reminder reminder, {
  required DateTime from,
  required DateTime to,
  int limit = 400,
}) {
  final anchor = reminder.remindAt?.toLocal();
  if (anchor == null || !to.isAfter(from)) return const [];
  bool inRange(DateTime t) => !t.isBefore(from) && t.isBefore(to);

  final rule = reminder.recurrence;
  // A completion-anchored series (F3.1c) has no projectable future: show the
  // current occurrence alone. (`nextOccurrence` returns null for such a rule,
  // so the loop below would do the same — this says why.)
  if (!reminder.isRecurring || rule.isCompletionAnchored) {
    return inRange(anchor) ? [anchor] : const [];
  }

  final result = <DateTime>[];
  DateTime? next = anchor.isBefore(from)
      ? rule.firstOnOrAfter(from: from, anchor: anchor)
      : anchor;
  while (next != null && next.isBefore(to) && result.length < limit) {
    if (inRange(next)) result.add(next);
    next = rule.nextOccurrence(after: next, anchor: anchor);
  }
  return result;
}
