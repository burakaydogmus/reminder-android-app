import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

/// How a backup is applied.
enum BackupImportMode {
  /// Upsert by id: existing items stay (in their order), items with the same
  /// id are overwritten by the backup's version, new ones are appended.
  /// Settings are **not** changed.
  merge,

  /// Reminders and birthdays become exactly the backup's lists (the others
  /// are soft-deleted by the repository); settings come from the backup when
  /// it has readable settings, otherwise the current ones are kept.
  replace,
}

/// Counts written by [BackupService.apply].
class BackupApplyResult {
  const BackupApplyResult({
    required this.reminders,
    required this.birthdays,
    required this.settingsApplied,
  });

  /// Reminders / birthdays taken from the backup.
  final int reminders;
  final int birthdays;
  final bool settingsApplied;
}

/// Builds and applies backups through the public [ReminderRepository] API.
///
/// The caller reloads `ReminderCubit` afterwards (`load()` re-syncs
/// notifications, geofences and the home widget with the stored state).
///
/// **Atomicity:** [apply] only writes after the whole file was parsed, so a
/// top-level parse error never applies anything. The writes themselves are
/// three repository calls (`saveReminders`, `saveBirthdays`, `saveSettings`),
/// each in its own transaction; if a later call fails, the earlier lists stay
/// applied. Re-importing the same file repairs that (both modes are
/// idempotent).
class BackupService {
  BackupService(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ReminderRepository _repository;
  final DateTime Function() _clock;

  /// Local date used in the file name.
  String fileName() => BackupFormat.fileNameFor(_clock());

  /// The stored data as backup JSON.
  Future<String> exportJson({String? appVersion}) async {
    final reminders = await _repository.loadReminders();
    final birthdays = await _repository.loadBirthdays();
    final settings = await _repository.loadSettings();
    return BackupFormat.encode(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
      exportedAt: _clock(),
      appVersion: appVersion,
    );
  }

  Future<BackupApplyResult> apply(
    BackupDocument backup,
    BackupImportMode mode,
  ) async {
    switch (mode) {
      case BackupImportMode.merge:
        final reminders = mergeById<Reminder>(
          await _repository.loadReminders(),
          backup.reminders,
          (r) => r.id,
        );
        final birthdays = mergeById<Birthday>(
          await _repository.loadBirthdays(),
          backup.birthdays,
          (b) => b.id,
        );
        await _repository.saveReminders(reminders);
        await _repository.saveBirthdays(birthdays);
        return BackupApplyResult(
          reminders: backup.reminders.length,
          birthdays: backup.birthdays.length,
          settingsApplied: false,
        );
      case BackupImportMode.replace:
        final AppSettings? settings = backup.settings;
        await _repository.saveReminders(backup.reminders);
        await _repository.saveBirthdays(backup.birthdays);
        if (settings != null) await _repository.saveSettings(settings);
        return BackupApplyResult(
          reminders: backup.reminders.length,
          birthdays: backup.birthdays.length,
          settingsApplied: settings != null,
        );
    }
  }

  /// [existing] in order with same-id items replaced by [imported]; imported
  /// items with new ids are appended in backup order.
  static List<T> mergeById<T>(
    List<T> existing,
    List<T> imported,
    String Function(T item) idOf,
  ) {
    final byId = {for (final item in imported) idOf(item): item};
    final result = <T>[];
    final seen = <String>{};
    for (final item in existing) {
      final id = idOf(item);
      seen.add(id);
      result.add(byId[id] ?? item);
    }
    for (final item in imported) {
      if (!seen.contains(idOf(item))) result.add(item);
    }
    return result;
  }
}
