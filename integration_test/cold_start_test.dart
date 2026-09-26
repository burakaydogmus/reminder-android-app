// E2E 1/7 — cold start on an empty device.
//
// What only a device can show: `path_provider` resolves a real application
// support directory, `drift_flutter` + `sqlite3` create `reminder.sqlite`
// there and run the schema from scratch (`onCreate`, not a migration), the
// onboarding gate reads its real SharedPreferences flag, and `main()`
// completes with the real notification, geofence, shortcut and home-widget
// plugins attached. On the host every one of those is a fake or in memory.
//
// Runs on a freshly cleared app (`adb shell pm clear`), so the database does
// not exist yet when the test starts.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_store.dart';
import 'package:reminder/ui/onboarding/steps/notification_step.dart';
import 'package:reminder/ui/today/today_page.dart';

import 'helpers/e2e.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a cold start with no database creates it, shows the onboarding and '
    'reaches Bugün',
    (tester) async {
      // The real Drift database is opened lazily by the first repository
      // call. Before the app runs, the file does not exist.
      final file = await databaseFile();
      expect(
        file.existsSync(),
        isFalse,
        reason: 'expected no ${file.path} before the first launch — the app '
            'data was not cleared, so this run is not a cold start',
      );
      expect(await OnboardingStore().isCompleted(), isFalse);

      await launchApp(tester);

      await pumpUntil(tester, find.byType(OnboardingFlow),
          reason: 'for the first-launch onboarding on an empty database');
      expect(find.byType(TodayPage), findsNothing);

      // Walk all four steps rather than skipping, so the notification step's
      // real permission state is exercised too.
      await tester.tap(find.byKey(OnboardingKeys.start));
      await settle(tester);
      await tester.tap(find.byKey(OnboardingKeys.next).first);
      await settle(tester);

      // POST_NOTIFICATIONS is granted by the harness (see e2e.yml), so the
      // step shows "Devam"; without the grant it shows "Şimdi değil".
      final continueOnNotificationStep = find.descendant(
        of: find.byType(NotificationStep),
        matching: find.byKey(OnboardingKeys.next),
      );
      await pumpUntilTrue(
        tester,
        () =>
            continueOnNotificationStep.evaluate().isNotEmpty ||
            find.byKey(OnboardingKeys.notNow).evaluate().isNotEmpty,
        reason: 'for the notification onboarding step',
      );
      if (continueOnNotificationStep.evaluate().isNotEmpty) {
        await tester.tap(continueOnNotificationStep);
      } else {
        await tester.tap(find.byKey(OnboardingKeys.notNow));
      }
      await settle(tester);

      await pumpUntil(tester, find.byKey(OnboardingKeys.enterApp),
          reason: 'for the last onboarding step');
      await tester.tap(find.byKey(OnboardingKeys.enterApp));
      await settle(tester);

      await pumpUntil(tester, find.byType(TodayPage),
          reason: 'for the Bugün tab after finishing the onboarding');
      // Android chrome: the pill navigation and the "+" FAB (§3.3.2).
      expect(find.byType(NewItemFab), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The flag is persisted, so the next launch goes straight to Bugün.
      await pumpUntilTrue(
        tester,
        () async => OnboardingStore().isCompleted(),
        reason: 'for onboarding_completed_v1 to be persisted',
      );

      // The real sqlite file now exists and is readable by an independent
      // connection: the schema really ran on the device.
      expect(
        (await databaseFile()).existsSync(),
        isTrue,
        reason: 'expected drift_flutter to have created reminder.sqlite',
      );
      expect(await reminderTitlesOnDisk(), isEmpty);

      // …and the repository reads it without falling back to the legacy
      // SharedPreferences store (that fallback is silent, so assert it).
      final repository = ReminderRepository();
      addTearDown(repository.close);
      expect(await repository.loadReminders(), isEmpty);
      expect(await repository.loadBirthdays(), isEmpty);
      expect(await repository.hasRecoveryBackup(), isFalse);
    },
  );
}
