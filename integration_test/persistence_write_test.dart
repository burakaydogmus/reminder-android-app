// E2E 2/7 (phase 1 of 2) — the real Drift/sqlite3 write path.
//
// Reminders are created **through the UI** (FAB → quick capture → Kaydet), so
// the whole chain runs for real: quick-capture parser → `ReminderCubit` →
// `ReminderRepository` → drift → `sqlite3` on the device's file system.
// The rows are then read back with an independent `sqlite3` connection to the
// same file, which drift's in-process connection cannot fake.
//
// `persistence_read_test.dart` is phase 2: it launches the app again in a new
// process **without clearing the app data** and asserts the rows survived.
// The two files must run in this order and only phase 1 may be preceded by
// `adb shell pm clear` (see `.github/workflows/e2e.yml`).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/data/reminder_repository.dart';

import 'helpers/e2e.dart';

/// Titles phase 2 expects to find again.
const String kUntimedTitle = 'Süt al';
const String kSecondUntimedTitle = 'Ekmek al';

/// Typed into quick capture; the parser moves "yarın 09:00" out of the title.
const String kTimedSentence = 'yarın 09:00 Doktor randevusu';
const String kTimedTitleFragment = 'Doktor randevusu';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reminders created through the UI land in the real sqlite database',
    (tester) async {
      await launchApp(tester);
      await reachToday(tester);

      await addViaQuickCapture(tester, kUntimedTitle);
      await addViaQuickCapture(tester, kSecondUntimedTitle);
      await addViaQuickCapture(tester, kTimedSentence);

      // The two untimed ones belong to "Bugün bir ara" and are on screen.
      await pumpUntil(tester, find.text(kUntimedTitle),
          reason: 'for "$kUntimedTitle" on Bugün');
      expect(find.text(kSecondUntimedTitle), findsOneWidget);

      final cubit = cubitOf(tester);
      expect(cubit.state.reminders, hasLength(3));

      // Independent connection to reminder.sqlite: the rows are on disk.
      final onDisk = await reminderTitlesOnDisk();
      expect(onDisk, hasLength(3));
      expect(onDisk, contains(kUntimedTitle));
      expect(onDisk, contains(kSecondUntimedTitle));
      expect(
        onDisk.any((title) => title.contains(kTimedTitleFragment)),
        isTrue,
        reason: 'expected a row whose title contains "$kTimedTitleFragment", '
            'got $onDisk',
      );

      // A fresh repository reads the same three rows back through drift.
      final repository = ReminderRepository();
      addTearDown(repository.close);
      final stored = await repository.loadReminders();
      expect(stored, hasLength(3));
      final timed = stored.where((r) => r.remindAt != null).toList();
      expect(timed, hasLength(1),
          reason: 'expected exactly the parsed "yarın 09:00" reminder to be '
              'timed, got ${stored.map((r) => '${r.title}@${r.remindAt}')}');
      expect(timed.single.remindAt!.hour, 9);
      expect(timed.single.remindAt!.minute, 0);
      expect(timed.single.remindAt!.isUtc, isFalse,
          reason: 'model times are stored as wall clock (CLAUDE.md → Data)');

      expect(tester.takeException(), isNull);
    },
  );
}
