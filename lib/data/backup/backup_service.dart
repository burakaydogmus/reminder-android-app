import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';

/// How a backup is applied.
enum BackupImportMode {
  /// Upsert by id: existing items stay (in their order), items with the same
  /// id are overwritten by the backup's version, new ones are appended.
  /// Settings are **not** changed. A backup user category whose name matches
  /// a local category with another id (case/Turkish-diacritic insensitive)
  /// is not added; its reminders move to the local one.
  merge,

  /// Reminders, birthdays, categories and routines become exactly the
  /// backup's lists
  /// (the others are soft-deleted by the repository; built-in categories
  /// always exist); settings come from the backup when
  /// it has readable settings, otherwise the current ones are kept.
  replace,
}

/// Counts written by [BackupService.apply].
class BackupApplyResult {
  const BackupApplyResult({
    required this.reminders,
    required this.birthdays,
    this.routines = 0,
    required this.settingsApplied,
  });

  /// Reminders / birthdays / routines taken from the backup.
  final int reminders;
  final int birthdays;
  final int routines;
  final bool settingsApplied;
}

/// Builds and applies backups through the public [ReminderRepository] API.
///
/// The caller reloads `ReminderCubit` afterwards (`load()` re-syncs
/// notifications, geofences and the home widget with the stored state).
///
/// **Atomicity:** [apply] only writes after the whole file was parsed, so a
/// top-level parse error never applies anything. The writes themselves are
/// separate repository calls (`saveReminders`, `saveBirthdays`,
/// `saveRoutines`, `saveSettings`),
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
    final categories =
        CategoryCatalog(await _repository.loadCategories()).ordered;
    final routines = await _repository.loadRoutines();
    return BackupFormat.encode(
      reminders: reminders,
      birthdays: birthdays,
      categories: categories,
      routines: routines,
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
        final local = CategoryCatalog(await _repository.loadCategories());
        final (:categories, :remap) = mergeCategories(local, backup.categories);
        final imported = [
          for (final r in backup.reminders)
            if (remap[r.categoryId] case final id?)
              r.copyWith(categoryId: id)
            else
              r,
        ];
        final reminders = mergeById<Reminder>(
          await _repository.loadReminders(),
          imported,
          (r) => r.id,
        );
        final birthdays = mergeById<Birthday>(
          await _repository.loadBirthdays(),
          backup.birthdays,
          (b) => b.id,
        );
        // Routines (F3.7) merge by id like the other lists; the reminders they
        // created keep their loose link, which points at the merged routine.
        final routines = RoutineList.inOrder(mergeById<Routine>(
          await _repository.loadRoutines(),
          backup.routines,
          (r) => r.id,
        ));
        await _repository.saveCategories(categories);
        await _repository.saveReminders(reminders);
        await _repository.saveBirthdays(birthdays);
        await _repository.saveRoutines(routines);
        return BackupApplyResult(
          reminders: backup.reminders.length,
          birthdays: backup.birthdays.length,
          routines: backup.routines.length,
          settingsApplied: false,
        );
      case BackupImportMode.replace:
        final AppSettings? settings = backup.settings;
        await _repository
            .saveCategories(CategoryCatalog(backup.categories).ordered);
        await _repository.saveReminders(backup.reminders);
        await _repository.saveBirthdays(backup.birthdays);
        await _repository.saveRoutines(RoutineList.inOrder(backup.routines));
        if (settings != null) await _repository.saveSettings(settings);
        return BackupApplyResult(
          reminders: backup.reminders.length,
          birthdays: backup.birthdays.length,
          routines: backup.routines.length,
          settingsApplied: settings != null,
        );
    }
  }

  /// Merge-mode categories: local order kept, same-id backup categories
  /// overwrite (built-ins stay fixed), new ones appended. A new backup
  /// category whose folded name matches a local one is dropped and listed in
  /// `remap` (backup id → local id).
  static ({List<ReminderCategory> categories, Map<String, String> remap})
      mergeCategories(CategoryCatalog local, List<ReminderCategory> imported) {
    final remap = <String, String>{};
    final accepted = <ReminderCategory>[];
    for (final c in imported) {
      if (!c.isBuiltIn && !local.contains(c.id)) {
        final match = local.byFoldedName(c.name);
        if (match != null) {
          remap[c.id] = match.id;
          continue;
        }
      }
      accepted.add(c);
    }
    final merged = mergeById<ReminderCategory>(
      local.ordered,
      accepted,
      (c) => c.id,
    );
    return (
      categories: CategoryCatalog([
        for (var i = 0; i < merged.length; i++) merged[i].copyWith(position: i),
      ]).ordered,
      remap: remap,
    );
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
