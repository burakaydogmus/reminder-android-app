import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_io.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/ui/settings/backup_preview_sheet.dart';
import 'package:reminder/util/dialog.dart';

/// Export / import flows of Ayarlar › Yedekleme (F2.2).
class BackupActions {
  const BackupActions({required this.io, required this.service});

  final BackupIo io;
  final BackupService service;

  /// Builds the backup and opens the share sheet. Returns `false` only when
  /// the backup could not be created (a snackbar explains it).
  Future<bool> export(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final origin = _originOf(context);
    try {
      final json = await service.exportJson(appVersion: await io.appVersion());
      final outcome = await io.shareBackupFile(
        fileName: service.fileName(),
        contents: json,
        origin: origin,
      );
      if (outcome == BackupShareOutcome.shared) {
        _snack(messenger, 'Yedek dosyası paylaşıldı.');
      }
      return true;
    } catch (e) {
      debugPrint('Backup export failed: $e');
      _snack(messenger, 'Yedek oluşturulamadı. Tekrar dene.');
      return false;
    }
  }

  /// Pick → parse → preview → (confirm replace) → apply → reload.
  Future<void> import(BuildContext context, ReminderCubit cubit) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final String? raw;
    try {
      raw = await io.pickBackupFile();
    } on BackupFileTooLargeException {
      _snack(
          messenger, 'Bu dosya bir Hatırlatıcı yedeği olamayacak kadar büyük.');
      return;
    } catch (e) {
      debugPrint('Backup pick failed: $e');
      _snack(messenger, 'Dosya okunamadı.');
      return;
    }
    if (raw == null) return;

    final BackupDocument backup;
    try {
      backup = BackupFormat.decode(raw);
    } on BackupFormatException catch (e) {
      _snack(messenger, backupErrorMessage(e));
      return;
    }
    if (!context.mounted) return;

    final mode = await showBackupPreviewSheet(context, backup);
    if (mode == null || !context.mounted) return;
    if (mode == BackupImportMode.replace) {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Verileri değiştir',
        content: 'Mevcut hatırlatıcıların ve doğum günlerin silinip '
            'yedektekilerle değiştirilir. Bu işlem geri alınamaz.',
      );
      if (!confirmed) return;
    }

    try {
      final result = await service.apply(backup, mode);
      await cubit.load();
      _snack(
        messenger,
        'Geri yüklendi: ${result.reminders} hatırlatıcı, '
        '${result.birthdays} doğum günü.',
      );
    } catch (e) {
      debugPrint('Backup import failed: $e');
      try {
        await cubit.load();
      } catch (_) {}
      _snack(
        messenger,
        'Geri yükleme tamamlanamadı; veriler kısmen değişmiş olabilir. '
        'Aynı dosyayı tekrar geri yükleyebilirsin.',
      );
    }
  }

  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static void _snack(ScaffoldMessengerState? messenger, String text) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

/// User-facing text for a rejected backup file (nothing was applied).
String backupErrorMessage(BackupFormatException e) {
  switch (e.kind) {
    case BackupErrorKind.notJson:
      return 'Bu dosya okunamadı: geçerli bir yedek dosyası değil.';
    case BackupErrorKind.notBackup:
      return 'Bu dosya bir Hatırlatıcı yedeği değil.';
    case BackupErrorKind.unsupportedVersion:
      return 'Bu yedek uygulamanın daha yeni bir sürümüyle alınmış '
          '(sürüm ${e.foundVersion}). Geri yüklemek için uygulamayı güncelle.';
    case BackupErrorKind.invalid:
      return 'Yedek dosyası bozuk; hiçbir şey değiştirilmedi.';
  }
}
