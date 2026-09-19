import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';

/// Choice in the "Tüm verileri sıfırla" dialog.
enum ResetDataChoice { cancel, backupFirst, reset }

/// Keys for tests.
abstract final class ResetDataDialogKeys {
  static const backupFirst = Key('resetData.backupFirst');
  static const confirm = Key('resetData.confirm');
}

Future<ResetDataChoice> showResetDataDialog(BuildContext context) async {
  final choice = await showModal<ResetDataChoice>(
    context: context,
    builder: (_) => const ResetDataDialog(),
  );
  return choice ?? ResetDataChoice.cancel;
}

/// Destructive confirmation with a secondary "Önce yedekle" (§3.3.9).
class ResetDataDialog extends StatelessWidget {
  const ResetDataDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void pop(ResetDataChoice c) => Navigator.of(context).pop(c);
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.resetTitle),
      content: Text(l10n.resetBody),
      actions: [
        TextButton(
          onPressed: () => pop(ResetDataChoice.cancel),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          key: ResetDataDialogKeys.backupFirst,
          onPressed: () => pop(ResetDataChoice.backupFirst),
          child: Text(l10n.resetBackupFirst),
        ),
        FilledButton(
          key: ResetDataDialogKeys.confirm,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => pop(ResetDataChoice.reset),
          child: Text(l10n.actionConfirm),
        ),
      ],
    );
  }
}
