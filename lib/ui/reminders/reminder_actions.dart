import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

enum _ReminderMenuAction { edit, delete }

/// Long-press menu for a reminder card: Düzenle / Sil. Anchored to the
/// widget of [context].
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

  final action = await showMenu<_ReminderMenuAction>(
    context: context,
    position: position,
    items: [
      const PopupMenuItem(
        value: _ReminderMenuAction.edit,
        child: Row(
          children: [
            Icon(Icons.edit_rounded),
            SizedBox(width: 12),
            Text('Düzenle'),
          ],
        ),
      ),
      PopupMenuItem(
        value: _ReminderMenuAction.delete,
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: scheme.error),
            const SizedBox(width: 12),
            Text('Sil', style: TextStyle(color: scheme.error)),
          ],
        ),
      ),
    ],
  );
  if (!context.mounted) return;
  switch (action) {
    case _ReminderMenuAction.edit:
      await showReminderEditorSheet(context, existing: reminder);
    case _ReminderMenuAction.delete:
      await confirmAndDeleteReminder(context, reminder);
    case null:
      break;
  }
}

/// "Silinsin mi?" confirmation, then permanent delete (undo is F3.5).
Future<void> confirmAndDeleteReminder(
  BuildContext context,
  Reminder reminder,
) async {
  final cubit = context.read<ReminderCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu hatırlatıcı kalıcı olarak silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      );
    },
  );
  if (ok == true) {
    await cubit.deleteReminder(reminder.id);
  }
}
