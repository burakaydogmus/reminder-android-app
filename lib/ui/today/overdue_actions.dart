import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/reminders/undo_snack_bar.dart';
import 'package:reminder/ui/today/today_sections.dart';

/// Overdue reminders "Hepsini yarına al" moves.
///
/// Recurring reminders (F3.1) are skipped: their next occurrence comes from
/// the rule, so moving one would shift the whole series.
List<Reminder> movableOverdue(Iterable<Reminder> overdue) => [
      for (final r in overdue)
        if (!r.isDone && r.remindAt != null && !r.isRecurring) r
    ];

/// "Hepsini yarına al" (§3.3.2): moves every overdue reminder to tomorrow at
/// its original wall-clock time through [ReminderCubit.updateReminder] and
/// shows one "Geri al" snackbar that restores all of them (each only if it
/// still has the time this action gave it).
Future<void> moveOverdueToTomorrowWithUndo(
  BuildContext context, {
  required List<Reminder> overdue,
  required DateTime now,
}) async {
  final cubit = context.read<ReminderCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final targets = movableOverdue(overdue);
  if (targets.isEmpty) return;

  final moves = [
    for (final r in targets)
      (
        id: r.id,
        previous: r.remindAt,
        next: TodaySections.tomorrowAtSameTime(r.remindAt!, now),
      ),
  ];

  final updates = <Future<void>>[];
  for (final m in moves) {
    final current = cubit.state.reminders.where((r) => r.id == m.id);
    if (current.isEmpty) continue;
    updates.add(
      cubit.updateReminder(current.first.copyWith(remindAt: () => m.next)),
    );
  }

  final message = moves.length == 1
      ? '“${targets.first.title.trim()}” yarına alındı'
      : '${moves.length} hatırlatıcı yarına alındı';
  UndoSnackBar.show(
    messenger,
    message: message,
    onUndo: () {
      for (final m in moves) {
        final latest =
            cubit.state.reminders.where((r) => r.id == m.id).firstOrNull;
        if (latest != null && latest.remindAt == m.next) {
          unawaited(
            cubit.updateReminder(latest.copyWith(remindAt: () => m.previous)),
          );
        }
      }
    },
  );
  await Future.wait(updates);
}
