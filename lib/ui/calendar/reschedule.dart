import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/calendar_dates.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/undo_snack_bar.dart';

// Takvim "Taşı" (F4.4): drag a card onto a week-strip / month-grid day, or
// menu › "Taşı…" / the semantics action (WCAG 2.5.7), which open a date
// picker. All three end in [rescheduleReminderWithUndo].

/// [reminder] moved to [day], keeping its wall-clock time.
///
/// A recurring reminder moves as a **whole series**: its `remindAt` is the
/// series anchor, so the new date becomes the anchor and the rule is adapted
/// with `RecurrenceRule.alignedTo` (the same rule as changing the date in
/// the editor). Returns `null` for an untimed reminder.
Reminder? rescheduledToDay(Reminder reminder, DateTime day) {
  final at = reminder.remindAt?.toLocal();
  if (at == null) return null;
  final moved = CalendarDates.onDayKeepingTime(day, at);
  return reminder.copyWith(
    remindAt: () => moved,
    recurrence:
        reminder.isRecurring ? reminder.recurrence.alignedTo(moved) : null,
  );
}

/// Whether [reminder] may be dropped on [day]: timed, another day, and the
/// new time is not in the past (a move never creates an overdue reminder).
bool canRescheduleToDay(Reminder reminder, DateTime day, DateTime now) {
  final at = reminder.remindAt?.toLocal();
  if (at == null || reminder.isDone) return false;
  if (CalendarDates.isSameDay(at, day)) return false;
  return !CalendarDates.onDayKeepingTime(day, at).isBefore(now);
}

/// Snackbar text: `“Market” taşındı · Çar 16 Eyl 18:30`.
String rescheduledMessage(Reminder moved, DateTime now) {
  final at = moved.remindAt!.toLocal();
  return '“${moved.title.trim()}” taşındı · '
      '${RecurrenceFormat.day(at, now)} ${KorFormat.time(at)}';
}

/// Moves [reminder] to [day] through `ReminderCubit.updateReminder` and shows
/// one "Geri al" snackbar that restores the previous `remindAt` and rule.
Future<void> rescheduleReminderWithUndo(
  BuildContext context,
  Reminder reminder,
  DateTime day, {
  DateTime Function()? now,
}) async {
  final cubit = context.read<ReminderCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final clock = now ?? NowScope.clockOf(context);
  final current =
      cubit.state.reminders.where((r) => r.id == reminder.id).firstOrNull;
  if (current == null || !canRescheduleToDay(current, day, clock())) return;
  final moved = rescheduledToDay(current, day)!;

  final updated = cubit.updateReminder(moved);
  UndoSnackBar.show(
    messenger,
    message: rescheduledMessage(moved, clock()),
    onUndo: () {
      final latest =
          cubit.state.reminders.where((r) => r.id == reminder.id).firstOrNull;
      if (latest != null && latest.remindAt == moved.remindAt) {
        unawaited(cubit.updateReminder(latest.copyWith(
          remindAt: () => current.remindAt,
          recurrence: current.recurrence,
        )));
      }
    },
  );
  await updated;
}

/// "Taşı…": date picker (today onwards), then [rescheduleReminderWithUndo].
/// Picking a day where the kept time is already past shows a short message
/// instead of moving.
Future<void> pickDayAndReschedule(
  BuildContext context,
  Reminder reminder, {
  DateTime Function()? now,
}) async {
  final clock = now ?? NowScope.clockOf(context);
  final at = reminder.remindAt?.toLocal();
  if (at == null) return;
  final today = CalendarDates.dateOnly(clock());
  final initial = at.isBefore(today) ? today : CalendarDates.dateOnly(at);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    currentDate: today,
    firstDate: today,
    lastDate: DateTime(today.year + 2, 12, 31),
    helpText: 'Hangi güne taşınsın?',
    confirmText: 'Taşı',
  );
  if (picked == null || !context.mounted) return;
  if (CalendarDates.isSameDay(picked, at)) return;
  if (!canRescheduleToDay(reminder, picked, clock())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bu saat geçti; başka bir gün seç.')),
    );
    return;
  }
  await rescheduleReminderWithUndo(context, reminder, picked, now: clock);
}
