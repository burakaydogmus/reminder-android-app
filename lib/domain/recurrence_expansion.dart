import 'package:reminder/domain/model/reminder.dart';

/// Occurrence times of [reminder] in `[from, to)`, in order.
///
/// - No `remindAt` → none.
/// - One-off → its `remindAt` when inside the range.
/// - Recurring (F3.1) → the stored `remindAt` (the current occurrence) when
///   inside the range, then every following occurrence from
///   `RecurrenceRule.nextOccurrence` with the stored `remindAt` as anchor
///   (time of day from the anchor, month-end clamp, `until` inclusive). When
///   the stored `remindAt` is before [from], the series is picked up at its
///   first occurrence on or after [from].
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

  if (!reminder.isRecurring) {
    return inRange(anchor) ? [anchor] : const [];
  }

  final rule = reminder.recurrence;
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
