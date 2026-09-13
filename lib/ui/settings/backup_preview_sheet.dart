import 'package:material_ui/material_ui.dart';

import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
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
String backupSummary(BackupDocument backup) {
  final found = '${backup.reminders.length} hatırlatıcı, '
      '${backup.birthdays.length} doğum günü bulundu';
  final skipped = backup.skippedCount;
  return skipped == 0 ? '$found.' : '$found; $skipped kayıt okunamadı.';
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
              'Yedeği geri yükle',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            backupSummary(backup),
            key: BackupPreviewKeys.summary,
            style: theme.textTheme.bodyLarge,
          ),
          if (exportedAt != null) ...[
            const SizedBox(height: KorSpacing.s2),
            Text(
              'Yedek tarihi: '
              '${KorFormat.dayMonth(exportedAt, DateTime.now())} '
              '${KorFormat.time(exportedAt)}',
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
                    'Okunamayan kayıtlar atlanır; diğerleri geri yüklenir.',
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
              segments: const [
                ButtonSegment(
                  value: BackupImportMode.merge,
                  icon: Icon(Icons.merge_rounded),
                  label: Text('Birleştir'),
                ),
                ButtonSegment(
                  value: BackupImportMode.replace,
                  icon: Icon(Icons.swap_horiz_rounded),
                  label: Text('Değiştir'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            switch (_mode) {
              BackupImportMode.merge =>
                'Mevcut kayıtların kalır, yedektekiler eklenir. Aynı kayıt '
                    'iki tarafta da varsa yedekteki sürüm kullanılır. '
                    'Ayarlar değişmez.',
              BackupImportMode.replace =>
                'Mevcut hatırlatıcıların ve doğum günlerin silinir, yerine '
                    'yedektekiler gelir. Ayarlar da yedekten alınır.',
            },
            style: muted,
          ),
          const SizedBox(height: KorSpacing.s7),
          FilledButton(
            key: BackupPreviewKeys.confirm,
            onPressed: () => Navigator.of(context).pop(_mode),
            child: const Text('Geri yükle'),
          ),
          const SizedBox(height: KorSpacing.s3),
          TextButton(
            key: BackupPreviewKeys.cancel,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );
  }
}
