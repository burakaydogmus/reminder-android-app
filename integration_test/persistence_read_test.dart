// E2E 3/7 (phase 2 of 2) — the reminders written by
// `persistence_write_test.dart` survive a real app restart.
//
// This is the only check in the suite that spans two **processes**: the
// workflow runs phase 1, then this file without clearing the app data, so the
// app is launched again from scratch against the `reminder.sqlite` the first
// phase left behind. `tester.restartAndRestore()` would only rebuild the
// widget tree inside the same process (and the app declares no restoration
// scopes), so it cannot show that anything reached the file system.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_store.dart';

import 'helpers/e2e.dart';
import 'persistence_write_test.dart'
    show kSecondUntimedTitle, kTimedTitleFragment, kUntimedTitle;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the reminders of the previous run are still there after a restart',
    (tester) async {
      // Guard: if the app data was cleared between the two phases this test
      // would silently pass on an empty database.
      final beforeLaunch = await reminderTitlesOnDisk();
      expect(
        beforeLaunch,
        hasLength(3),
        reason: 'expected the 3 rows persistence_write_test.dart created; the '
            'app data was cleared between the two phases',
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
      expect(find.text(kUntimedTitle), findsOneWidget);
      expect(find.text(kSecondUntimedTitle), findsOneWidget);

      final repository = ReminderRepository();
      addTearDown(repository.close);
      final stored = await repository.loadReminders();
      expect(stored.map((r) => r.title), contains(kUntimedTitle));
      expect(
        stored.any((r) => r.title.contains(kTimedTitleFragment)),
        isTrue,
      );

      // The wall-clock time survived the TEXT round trip (CLAUDE.md → Data:
      // "18:30" must still be 18:30, never converted to UTC).
      final timed = stored.where((r) => r.remindAt != null).toList();
      expect(timed, hasLength(1));
      expect(timed.single.remindAt!.hour, 9);
      expect(timed.single.remindAt!.minute, 0);
      expect(timed.single.remindAt!.isUtc, isFalse);

      expect(tester.takeException(), isNull);
    },
  );
}
