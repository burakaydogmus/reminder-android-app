import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';

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
    return AlertDialog(
      title: const Text('Tüm verileri sıfırla'),
      content: const Text(
        'Tüm hatırlatmalar ve ayarlar silinir. Bu işlem geri alınamaz. '
        'Silmeden önce bir yedek alabilirsin.',
      ),
      actions: [
        TextButton(
          onPressed: () => pop(ResetDataChoice.cancel),
          child: const Text('İptal'),
        ),
        TextButton(
          key: ResetDataDialogKeys.backupFirst,
          onPressed: () => pop(ResetDataChoice.backupFirst),
          child: const Text('Önce yedekle'),
        ),
        FilledButton(
          key: ResetDataDialogKeys.confirm,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => pop(ResetDataChoice.reset),
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
