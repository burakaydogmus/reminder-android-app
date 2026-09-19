import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';

/// Destructive confirmation (M3 dialog, confirm in `error`).
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: const Size(48, 48),
          ),
          onPressed: onConfirm,
          child: Text(context.l10n.actionConfirm),
        ),
      ],
    );
  }
}
