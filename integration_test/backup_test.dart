// E2E 6/7 — backup round trip over the device's real file system.
//
// The host suite exports to a string and imports from a fake `BackupIo`. Here
// the JSON is written to a real file in the app's temporary directory (the
// same `getTemporaryDirectory()` `PlatformBackupIo.shareBackupFile` uses),
// the database is wiped through `clearAllData` and the file is read back and
// applied — so `path_provider`, `dart:io` and the real repository all take
// part. The share sheet and the document picker themselves are system UI and
// cannot be driven on a CI emulator; everything between them is covered.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/subtask.dart';

import 'helpers/e2e.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('export to a real file, wipe, import — the data comes back',
      (tester) async {
    await launchApp(tester);
    await reachToday(tester);
    final cubit = cubitOf(tester);

    final now = DateTime.now();
    await cubit.saveCategory(const ReminderCategory(
      id: 'e2e-category',
      name: 'Spor',
      colorKey: CategoryColorKeys.saglik,
      iconKey: CategoryIconKeys.fitness,
    ));
    await cubit.addReminder(Reminder(
      id: 'e2e-backup-1',
      title: 'Ayakkabı al',
      note: 'Koşu için',
      isDone: false,
      createdAt: now,
      remindAt: now.add(const Duration(hours: 5)),
      categoryId: 'e2e-category',
      priority: 3,
      pinned: true,
      subtasks: [
        const Subtask(
            id: 's1', title: 'Numara ölç', isDone: false, position: 0),
        const Subtask(
            id: 's2', title: 'Fiyat karşılaştır', isDone: true, position: 1),
      ],
    ));
    await cubit.addReminder(Reminder(
      id: 'e2e-backup-2',
      title: 'Kitap oku',
      isDone: false,
      createdAt: now,
    ));
    await cubit.addBirthday(Birthday(
      id: 'e2e-backup-b',
      name: 'Ada',
      month: 5,
      day: 3,
      createdAt: now,
    ));

    final repository = ReminderRepository();
    addTearDown(repository.close);
    final service = BackupService(repository);

    // --- export to a real file -----------------------------------------
    final json = await service.exportJson(appVersion: 'e2e');
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${service.fileName()}',
    );
    await file.writeAsString(json, flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    expect(file.existsSync(), isTrue);
    expect(await file.length(), greaterThan(0));

    // --- wipe -----------------------------------------------------------
    await cubit.clearAllData();
    await pumpUntilTrue(
      tester,
      () => cubit.state.reminders.isEmpty && cubit.state.birthdays.isEmpty,
      reason: 'for "Tüm verileri sıfırla" to empty the state',
    );
    expect(await reminderTitlesOnDisk(), isEmpty,
        reason: 'clearAll hard-deletes the rows from the real database');
    expect(await pendingNotificationIds(), isEmpty,
        reason: 'clearAllData cancels every notification of the app');

    // --- import from the file on disk -----------------------------------
    final decoded = BackupFormat.decode(await file.readAsString());
    expect(decoded.version, BackupFormat.version);
    expect(decoded.reminders, hasLength(2));
    expect(decoded.birthdays, hasLength(1));

    final result = await service.apply(decoded, BackupImportMode.replace);
    expect(result.reminders, 2);
    expect(result.birthdays, 1);
    await cubit.load();

    await pumpUntilTrue(
      tester,
      () => cubit.state.reminders.length == 2,
      reason: 'for the imported reminders to load',
    );
    final restored =
        cubit.state.reminders.firstWhere((r) => r.id == 'e2e-backup-1');
    expect(restored.title, 'Ayakkabı al');
    expect(restored.note, 'Koşu için');
    expect(restored.categoryId, 'e2e-category');
    expect(restored.priority, 3);
    expect(restored.pinned, isTrue);
    expect(restored.subtasks.map((s) => s.title),
        ['Numara ölç', 'Fiyat karşılaştır']);
    expect(restored.subtasks.last.isDone, isTrue);
    expect(restored.remindAt, isNotNull);
    expect(cubit.state.birthdays.single.name, 'Ada');
    expect(cubit.state.categories.ordered.map((c) => c.id),
        contains('e2e-category'));

    // The restored timed reminder is scheduled with the OS again.
    await pumpUntilTrue(
      tester,
      () async =>
          (await pendingNotificationIds()).contains(restored.notificationId),
      reason: 'for the imported timed reminder to be rescheduled',
    );

    // …and it is back on disk, readable by an independent connection.
    expect(await reminderTitlesOnDisk(),
        containsAll(<String>['Ayakkabı al', 'Kitap oku']));

    expect(tester.takeException(), isNull);
  });
}
