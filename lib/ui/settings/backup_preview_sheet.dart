import 'package:material_ui/material_ui.dart';

import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class BackupPreviewKeys {
  static const summary = Key('backupPreview.summary');
  static const confirm = Key('backupPreview.confirm');
  static const cancel = Key('backupPreview.cancel');
}

/// Shows what [backup] contains and lets the user choose Birleştir or
/// Değiştir. Resolves to the chosen mode, `null` when cancelled.
Future<BackupImportMode?> showBackupPreviewSheet(
  BuildContext context,
  BackupDocument backup,
) {
  return showModalBottomSheet<BackupImportMode>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BackupPreviewSheet(backup: backup),
  );
}

/// `12 hatırlatıcı, 4 doğum günü bulundu; 1 kayıt okunamadı.`
String backupSummary(BackupDocument backup, AppLocalizations l10n) {
  final reminders = backup.reminders.length;
  final birthdays = backup.birthdays.length;
  final skipped = backup.skippedCount;
  return skipped == 0
      ? l10n.backupFound(reminders, birthdays)
      : l10n.backupFoundSkipped(reminders, birthdays, skipped);
}

class BackupPreviewSheet extends StatefulWidget {
  const BackupPreviewSheet({super.key, required this.backup});

  final BackupDocument backup;

  @override
  State<BackupPreviewSheet> createState() => _BackupPreviewSheetState();
}

class _BackupPreviewSheetState extends State<BackupPreviewSheet> {
  BackupImportMode _mode = BackupImportMode.merge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final backup = widget.backup;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final exportedAt = backup.exportedAt?.toLocal();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        KorSpacing.s6,
        KorSpacing.s3,
        KorSpacing.s6,
        KorSpacing.s5 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: KorRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(KorSpacing.s4),
                child: Icon(
                  Icons.settings_backup_restore_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: KorSpacing.s5),
          Semantics(
            header: true,
            child: Text(
              context.l10n.backupRestoreTitle,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            backupSummary(backup, context.l10n),
            key: BackupPreviewKeys.summary,
            style: theme.textTheme.bodyLarge,
          ),
          if (exportedAt != null) ...[
            const SizedBox(height: KorSpacing.s2),
            Text(
              context.l10n.backupDate(
                KorFormat.dayMonth(exportedAt, DateTime.now(), context.l10n),
                KorFormat.time(exportedAt),
              ),
              style: muted,
            ),
          ],
          if (backup.skippedCount > 0) ...[
            const SizedBox(height: KorSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: KorSizes.iconSm,
                  color: scheme.error,
                ),
                const SizedBox(width: KorSpacing.s3),
                Expanded(
                  child: Text(
                    context.l10n.backupSkippedHint,
                    style: muted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: KorSpacing.s6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<BackupImportMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: BackupImportMode.merge,
                  icon: const Icon(Icons.merge_rounded),
                  label: Text(context.l10n.backupMerge),
                ),
                ButtonSegment(
                  value: BackupImportMode.replace,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(context.l10n.backupReplace),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            switch (_mode) {
              BackupImportMode.merge => context.l10n.backupMergeHint,
              BackupImportMode.replace => context.l10n.backupReplaceHint,
            },
            style: muted,
          ),
          const SizedBox(height: KorSpacing.s7),
          FilledButton(
            key: BackupPreviewKeys.confirm,
            onPressed: () => Navigator.of(context).pop(_mode),
            child: Text(context.l10n.backupRestore),
          ),
          const SizedBox(height: KorSpacing.s3),
          TextButton(
            key: BackupPreviewKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionDismiss),
          ),
        ],
      ),
    );
  }
}
