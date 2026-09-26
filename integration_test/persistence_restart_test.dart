// E2E 2/7 — the real Drift/sqlite3 path, across a real app restart.
//
// Reminders are created **through the UI** (FAB → quick capture → Kaydet), so
// the whole chain runs for real: quick-capture parser → `ReminderCubit` →
// `ReminderRepository` → drift → `sqlite3` on the device's file system. They
// are then read back with an independent `sqlite3` connection to the same
// file, which drift's in-process connection cannot fake, and finally by a
// **second app process**.
//
// ## Why this file runs twice instead of restarting itself
//
// Neither in-process trick proves durability:
// - `tester.restartAndRestore()` rebuilds the widget tree inside the same
//   process, and the app declares no restoration scopes, so it never reopens
//   the database.
// - Dropping the `AppDatabaseHost` reference count by hand would close a
//   connection the live cubit still holds; that tests the harness, not the app.
//
// So `.github/scripts/e2e.sh` runs **this same file twice** with
// `adb shell am force-stop` in between and **no** `pm clear`. Two things make
// the data survive: `flutter test --no-uninstall` (its
// `DebuggingOptions.uninstallApp` defaults to **true**, so it removes the app —
// and with it the database — as soon as an integration test finishes; that is
// exactly how the first version of this test failed), and running the *same*
// file, so the installed build never changes either.
//
// The phase is picked from a marker the first run leaves in SharedPreferences.
// To make a false green impossible, the test prints `E2E_PHASE=write|read` and
// the workflow asserts the first run printed `write` and the second `read`: if
// the data is wiped again, the second run takes the write branch and the
// workflow fails loudly instead of quietly passing on an empty database.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_store.dart';

import 'helpers/e2e.dart';

/// Set by the write phase; its presence selects the read phase. A test-only
/// key, never read by the app.
const String kPhaseMarkerKey = 'e2e_persistence_phase_v1';

const String kUntimedTitle = 'Süt al';
const String kSecondUntimedTitle = 'Ekmek al';

/// Typed into quick capture; the parser moves "yarın 09:00" out of the title.
const String kTimedSentence = 'yarın 09:00 Doktor randevusu';
const String kTimedTitleFragment = 'Doktor randevusu';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reminders created through the UI survive a real app restart',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final isReadPhase = preferences.getBool(kPhaseMarkerKey) ?? false;
      // The workflow greps this line; see the header.
      // ignore: avoid_print
      print('E2E_PHASE=${isReadPhase ? 'read' : 'write'}');

      if (isReadPhase) {
        await _readPhase(tester);
      } else {
        await _writePhase(tester);
        await preferences.setBool(kPhaseMarkerKey, true);
      }
    },
  );
}

/// Creates the reminders through the UI and proves they reached the file.
Future<void> _writePhase(WidgetTester tester) async {
  final file = await databaseFile();
  expect(
    file.existsSync(),
    isFalse,
    reason: 'expected no ${file.path} before the write phase — the app data '
        'was not cleared, so this is not a first run',
  );

  await launchApp(tester);
  await reachToday(tester);

  await addViaQuickCapture(tester, kUntimedTitle);
  await addViaQuickCapture(tester, kSecondUntimedTitle);
  await addViaQuickCapture(tester, kTimedSentence);

  // The two untimed ones belong to "Bugün bir ara" and are on screen.
  await pumpUntil(tester, find.text(kUntimedTitle),
      reason: 'for "$kUntimedTitle" on Bugün');
  expect(find.text(kSecondUntimedTitle), findsWidgets);

  final cubit = cubitOf(tester);
  expect(cubit.state.reminders, hasLength(3));

  // Independent connection to reminder.sqlite: the rows are committed to disk,
  // not just held in drift's own connection.
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

  _expectStoredShape(await _loadStored());
  expect(tester.takeException(), isNull);
}

/// A new process: the rows must still be there and still be readable.
Future<void> _readPhase(WidgetTester tester) async {
  // Guard: if the app data had been wiped, the marker would be gone too and we
  // would not be in this branch — but the file could still have been removed
  // on its own, so say which failure it is.
  final beforeLaunch = await reminderTitlesOnDisk();
  expect(
    beforeLaunch,
    hasLength(3),
    reason: 'the phase marker survived but the 3 rows did not',
  );
  expect(await OnboardingStore().isCompleted(), isTrue);

  await launchApp(tester);
  await reachToday(tester);
  // An existing user never sees the onboarding again.
  expect(find.byType(OnboardingFlow), findsNothing);

  // The new process' cubit loaded them from the file.
  final cubit = cubitOf(tester);
  await pumpUntilTrue(
    tester,
    () => cubit.state.reminders.length == 3,
    reason: 'for the restarted app to load 3 reminders from sqlite, got '
        '${cubit.state.reminders.length}',
  );
  expect(find.text(kUntimedTitle), findsWidgets);
  expect(find.text(kSecondUntimedTitle), findsWidgets);

  _expectStoredShape(await _loadStored());
  expect(tester.takeException(), isNull);
}

/// Reads the reminders back through a **fresh** repository (its own drift
/// query, closed again right after).
Future<List<Reminder>> _loadStored() async {
  final repository = ReminderRepository();
  try {
    return await repository.loadReminders();
  } finally {
    await repository.close();
  }
}

/// The three reminders as both phases must see them.
void _expectStoredShape(List<Reminder> stored) {
  expect(stored, hasLength(3));
  final titles = stored.map((r) => r.title).toList();
  expect(titles, contains(kUntimedTitle));
  expect(titles, contains(kSecondUntimedTitle));
  expect(titles.any((t) => t.contains(kTimedTitleFragment)), isTrue);

  final timed = stored.where((r) => r.remindAt != null).toList();
  expect(
    timed,
    hasLength(1),
    reason: 'expected exactly the parsed "yarın 09:00" reminder to be timed, '
        'got ${stored.map((r) => '${r.title}@${r.remindAt}')}',
  );
  final remindAt = timed.single.remindAt!;
  // The wall-clock time survives the TEXT round trip (CLAUDE.md → Data:
  // "18:30" must still be 18:30, never converted to UTC).
  expect(remindAt.hour, 9);
  expect(remindAt.minute, 0);
  expect(remindAt.isUtc, isFalse);
}
