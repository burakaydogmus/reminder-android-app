import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';
import 'package:reminder/ui/reminders/snooze_sheet.dart';
import 'package:reminder/ui/reminders/undo_snack_bar.dart';
import 'package:reminder/ui/theme/haptics.dart';

// Reminder actions shared by swipe, long-press menu and semantics actions
// (§3.5). Each applies immediately and offers "Geri al"; there is no
// confirmation dialog. Callers' widgets may be gone after the action (a
// completed card leaves its section), so everything needed later is
// captured up front.

// The haptics setting arrives with F4.7; until then haptics are on.
const _haptics = KorHaptics();

Reminder? _find(ReminderCubit cubit, String id) =>
    cubit.state.reminders.where((r) => r.id == id).firstOrNull;

String _quoted(Reminder r) => '“${r.title.trim()}”';

/// Tamamla / Geri aç, then "“…” tamamlandı · Geri al".
///
/// A recurring reminder is not done after completing: it moves to its next
/// occurrence (F3.1), the snackbar reads "Sonraki: Cmt 20 Eyl 16:00 · Geri
/// al" and undo restores the previous `remindAt`.
Future<void> toggleReminderDoneWithUndo(
  BuildContext context,
  Reminder reminder, {
  DateTime Function()? now,
}) async {
  final cubit = context.read<ReminderCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final clock = now ?? NowScope.clockOf(context);
  final current = _find(cubit, reminder.id) ?? reminder;
  final completing = !current.isDone;
  if (completing) unawaited(_haptics.complete());

  final done = cubit.toggleDone(reminder.id);
  // toggleDone emits synchronously; the new state is readable right away.
  final after = _find(cubit, reminder.id);
  final advancedTo =
      completing && after != null && !after.isDone ? after.remindAt : null;
  UndoSnackBar.show(
    messenger,
    message: advancedTo != null
        ? RecurrenceFormat.next(advancedTo, clock())
        : completing
            ? '${_quoted(current)} tamamlandı'
            : '${_quoted(current)} geri açıldı',
    onUndo: () {
      unawaited(_haptics.undo());
      final latest = _find(cubit, reminder.id);
      if (latest == null) return;
      if (advancedTo != null) {
        if (!latest.isDone && latest.remindAt == advancedTo) {
          unawaited(cubit.updateReminder(
            latest.copyWith(remindAt: () => current.remindAt),
          ));
        }
      } else if (latest.isDone == completing) {
        unawaited(cubit.toggleDone(reminder.id));
      }
    },
  );
  await done;
}

/// Opens the Ertele sheet; applying sets `remindAt` (untimed reminders get a
/// time too) and offers undo back to the previous time.
Future<void> snoozeReminderWithUndo(
  BuildContext context,
  Reminder reminder, {
  DateTime Function()? now,
}) async {
  final cubit = context.read<ReminderCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final clock = now ?? NowScope.clockOf(context);
  final at = await showSnoozeSheet(context, reminder: reminder, now: clock);
  if (at == null) return;
  final current = _find(cubit, reminder.id);
  if (current == null) return;
  final previous = current.remindAt;

  final updated = cubit.updateReminder(current.copyWith(remindAt: () => at));
  UndoSnackBar.show(
    messenger,
    message: SnoozeOptions.snoozedMessage(at, clock()),
    onUndo: () {
      unawaited(_haptics.undo());
      final latest = _find(cubit, reminder.id);
      if (latest != null && latest.remindAt == at) {
        unawaited(
          cubit.updateReminder(latest.copyWith(remindAt: () => previous)),
        );
      }
    },
  );
  await updated;
}

/// Deletes without confirmation; "Geri al" re-adds the same reminder object
/// (same id and fields) through [ReminderCubit.addReminder].
Future<void> deleteReminderWithUndo(
  BuildContext context,
  Reminder reminder,
) async {
  final cubit = context.read<ReminderCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final original = _find(cubit, reminder.id) ?? reminder;
  unawaited(_haptics.delete());

  final deleted = cubit.deleteReminder(original.id);
  UndoSnackBar.show(
    messenger,
    message: '${_quoted(original)} silindi',
    onUndo: () {
      unawaited(_haptics.undo());
      if (_find(cubit, original.id) == null) {
        unawaited(cubit.addReminder(original));
      }
    },
  );
  await deleted;
}

enum _ReminderMenuAction { toggleDone, snooze, edit, delete }

/// Long-press menu for a reminder card: Tamamla / Geri aç, Ertele (open
/// reminders), Düzenle, Sil. Anchored to the widget of [context].
Future<void> showReminderMenu(BuildContext context, Reminder reminder) async {
  final scheme = Theme.of(context).colorScheme;
  final box = context.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomRight = box.localToGlobal(
    box.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );
  final position = RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    Offset.zero & overlay.size,
  );

  PopupMenuItem<_ReminderMenuAction> item(
    _ReminderMenuAction value,
    IconData icon,
    String label, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, style: color == null ? null : TextStyle(color: color)),
          ],
        ),
      );

  final action = await showMenu<_ReminderMenuAction>(
    context: context,
    position: position,
    items: [
      reminder.isDone
          ? item(_ReminderMenuAction.toggleDone, Icons.undo_rounded, 'Geri aç')
          : item(
              _ReminderMenuAction.toggleDone,
              Icons.check_circle_outline_rounded,
              'Tamamla',
            ),
      if (!reminder.isDone)
        item(_ReminderMenuAction.snooze, Icons.snooze_rounded, 'Ertele'),
      item(_ReminderMenuAction.edit, Icons.edit_rounded, 'Düzenle'),
      item(
        _ReminderMenuAction.delete,
        Icons.delete_outline_rounded,
        'Sil',
        color: scheme.error,
      ),
    ],
  );
  if (!context.mounted) return;
  switch (action) {
    case _ReminderMenuAction.toggleDone:
      await toggleReminderDoneWithUndo(context, reminder);
    case _ReminderMenuAction.snooze:
      await snoozeReminderWithUndo(context, reminder);
    case _ReminderMenuAction.edit:
      await showReminderEditorSheet(context, existing: reminder);
    case _ReminderMenuAction.delete:
      await deleteReminderWithUndo(context, reminder);
    case null:
      break;
  }
}
