import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_selector/file_selector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result of handing the backup file to the system share sheet.
enum BackupShareOutcome {
  /// The user picked a target (Android may report this as [unknown]).
  shared,

  /// The sheet was closed without choosing a target.
  dismissed,

  /// The platform does not report the result.
  unknown,
}

/// Thrown by [BackupIo.pickBackupFile] when the chosen file is too large to
/// be a backup of this app.
class BackupFileTooLargeException implements Exception {
  const BackupFileTooLargeException(this.bytes);

  final int bytes;

  @override
  String toString() => 'BackupFileTooLargeException($bytes bytes)';
}

/// Platform side of backups (share sheet, document picker, app version),
/// behind an interface so widget tests don't touch plugins.
abstract interface class BackupIo {
  /// App version for the backup header (`2.1.0+8`), `null` if unknown.
  Future<String?> appVersion();

  /// Writes [contents] to a temporary [fileName] and opens the share sheet.
  /// [origin] anchors the iPad popover.
  Future<BackupShareOutcome> shareBackupFile({
    required String fileName,
    required String contents,
    Rect? origin,
  });

  /// Lets the user pick a JSON file and returns its text, or `null` when the
  /// picker was cancelled.
  Future<String?> pickBackupFile();
}

class PlatformBackupIo implements BackupIo {
  const PlatformBackupIo();

  /// A year of heavy use is well below 1 MB; anything this large is not ours.
  static const maxFileBytes = 20 * 1024 * 1024;

  static const _jsonTypes = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    // Drive/Files often report JSON as octet-stream or plain text; the
    // content is validated after picking anyway.
    mimeTypes: ['application/json', 'application/octet-stream', 'text/plain'],
    uniformTypeIdentifiers: ['public.json', 'public.plain-text'],
  );

  @override
  Future<String?> appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BackupShareOutcome> shareBackupFile({
    required String fileName,
    required String contents,
    Rect? origin,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(contents, flush: true);
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      fileNameOverrides: [fileName],
      subject: fileName,
      sharePositionOrigin: origin,
    ));
    return switch (result.status) {
      ShareResultStatus.success => BackupShareOutcome.shared,
      ShareResultStatus.dismissed => BackupShareOutcome.dismissed,
      ShareResultStatus.unavailable => BackupShareOutcome.unknown,
    };
  }

  @override
  Future<String?> pickBackupFile() async {
    final file = await openFile(acceptedTypeGroups: const [_jsonTypes]);
    if (file == null) return null;
    final bytes = await file.length();
    if (bytes > maxFileBytes) throw BackupFileTooLargeException(bytes);
    return file.readAsString();
  }
}
