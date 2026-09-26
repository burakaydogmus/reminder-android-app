// Shared helpers for the on-device end-to-end suite (`integration_test/`).
//
// These tests drive the **real** app on a real Android emulator, so every
// platform integration the host suite has to fake is exercised for real: the
// `sqlite3` + `path_provider` database, `flutter_local_notifications`
// scheduling, `home_widget` storage, `share_plus`/`file_selector`-free backup
// file IO and the `reminderwidget://` launch routing.
//
// Rules of the house:
// - **Never** `Future.delayed` / `sleep` to wait for something. Use
//   [settle] (an animation-aware `pumpAndSettle`) or [pumpUntil] /
//   [pumpUntilTrue] (a polling expectation with a deadline and a readable
//   failure message). Real devices are slow and irregular; fixed waits are
//   how emulator suites become flaky.
// - Assert on `Key`s and widget types, not on localized literals. The one
//   language decision is made here: [launchApp] pins the app language to
//   Turkish so the quick-capture grammar (F4.6a/F4.6c picks its grammar from
//   the **app** language) is deterministic whatever locale the emulator boots
//   with.

import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/main.dart' as app;
import 'package:reminder/services/notification_fingerprint_store.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/today/today_page.dart';

/// How often a polling expectation looks again.
const Duration kPollInterval = Duration(milliseconds: 100);

/// Deadline for polling expectations. Generous: a cold emulator frame can
/// take a hundred times longer than a host frame.
const Duration kPollTimeout = Duration(seconds: 40);

/// `pumpAndSettle` that does not take the whole test down when something in
/// the tree keeps animating (a repeating indicator, the shell's minute tick
/// rebuilding into a transition, …). A timeout here is not the interesting
/// failure — the expectation that follows is.
Future<void> settle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  } on FlutterError {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

/// Pumps until [condition] holds, then returns; fails with [reason] on the
/// deadline. This is the only sanctioned way to wait for something the
/// platform does asynchronously (a plugin round trip, a database write).
Future<void> pumpUntilTrue(
  WidgetTester tester,
  FutureOr<bool> Function() condition, {
  required String reason,
  Duration timeout = kPollTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  Object? lastError;
  while (DateTime.now().isBefore(deadline)) {
    try {
      if (await condition()) return;
      lastError = null;
    } catch (error) {
      // A plugin can legitimately be not ready yet; keep the last error for
      // the failure message instead of aborting on the first attempt.
      lastError = error;
    }
    await tester.pump(kPollInterval);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting $reason'
    '${lastError == null ? '' : ' (last error: $lastError)'}',
  );
}

/// Pumps until [finder] matches at least one widget.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  String? reason,
  Duration timeout = kPollTimeout,
}) =>
    pumpUntilTrue(
      tester,
      () => finder.evaluate().isNotEmpty,
      reason: reason ?? 'for $finder',
      timeout: timeout,
    );

/// Starts the real app the way the launcher does: `main()` and `runApp`.
///
/// [language] is written to SharedPreferences first, so the quick-capture
/// grammar and every user-visible string are deterministic.
Future<void> launchApp(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.turkish,
}) async {
  await AppLanguageStore().save(language);
  await app.main();
  await settle(tester);
}

/// Waits for either the onboarding or Bugün, skips the onboarding when it is
/// showing, and returns once the Bugün tab is on screen.
Future<void> reachToday(WidgetTester tester) async {
  await pumpUntilTrue(
    tester,
    () =>
        find.byType(OnboardingFlow).evaluate().isNotEmpty ||
        find.byType(TodayPage).evaluate().isNotEmpty,
    reason: 'for the onboarding or the Bugün tab to appear',
  );
  if (find.byType(OnboardingFlow).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(OnboardingKeys.skip));
    await settle(tester);
  }
  await pumpUntil(tester, find.byType(TodayPage),
      reason: 'for the Bugün tab after onboarding');
}

/// The live cubit with the real repository, notification, geofence and home
/// widget services (`app.dart` builds it).
ReminderCubit cubitOf(WidgetTester tester) =>
    BlocProvider.of<ReminderCubit>(tester.element(find.byType(HomeShell)));

/// Pops the topmost route (a modal sheet) through the real navigator.
Future<void> popRoute(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(HomeShell))).pop();
  await settle(tester);
}

/// Adds a reminder the way a user does: FAB → quick capture → type → save.
///
/// The capture sheet deliberately stays open after a save (F4.6b), so it is
/// popped again here.
Future<void> addViaQuickCapture(WidgetTester tester, String sentence) async {
  await tester.tap(find.byType(NewItemFab));
  await settle(tester);
  await pumpUntil(tester, find.byKey(QuickCaptureKeys.field),
      reason: 'for the quick capture field');
  await tester.enterText(find.byKey(QuickCaptureKeys.field), sentence);
  await settle(tester);
  await tester.tap(find.byKey(QuickCaptureKeys.save));
  await settle(tester);
  await pumpUntil(tester, find.byKey(QuickCaptureKeys.toast),
      reason: 'for the "Eklendi" toast of "$sentence"');
  await popRoute(tester);
}

/// Switches to the Listeler tab (the pill navigation carries no keys, but its
/// icons are stable tokens).
Future<void> openLists(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
  await settle(tester);
}

// --- Real platform state -----------------------------------------------

/// `flutter_local_notifications`' plugin object is a singleton, so this is the
/// very same channel `NotificationService.instance` schedules through.
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Ids currently scheduled with the OS alarm manager.
Future<Set<int>> pendingNotificationIds() async {
  final pending = await notificationsPlugin.pendingNotificationRequests();
  return {for (final request in pending) request.id};
}

/// Titles currently scheduled with the OS, by notification id.
Future<Map<int, String?>> pendingNotificationTitles() async {
  final pending = await notificationsPlugin.pendingNotificationRequests();
  return {for (final request in pending) request.id: request.title};
}

/// Whether Android would let this app set exact alarms right now (F6.2c).
/// `SCHEDULE_EXACT_ALARM` is denied by default for new installs on API 34+,
/// so on a fresh emulator this is `false` unless CI grants the app op.
Future<bool> canScheduleExactAlarms() async {
  final android = notificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return true;
  return await android.canScheduleExactNotifications() ?? true;
}

/// The stored schedule fingerprints (`NotificationFingerprintStore`).
Future<Map<int, String>?> storedFingerprints() =>
    const NotificationFingerprintStore().load();

/// The real database file `drift_flutter` opens
/// (`driftDatabase(name: 'reminder', databaseDirectory:
/// getApplicationSupportDirectory)`).
Future<File> databaseFile() async {
  final directory = await getApplicationSupportDirectory();
  return File('${directory.path}${Platform.pathSeparator}reminder.sqlite');
}

/// Reads reminder titles with an **independent** `sqlite3` connection to the
/// database file. Drift's own connection could still be holding the rows in
/// memory; this proves they reached the file on disk.
Future<List<String>> reminderTitlesOnDisk() async {
  final file = await databaseFile();
  if (!file.existsSync()) {
    fail('The database file does not exist at ${file.path}');
  }
  final database = sqlite3.open(file.path);
  try {
    final rows = database.select(
      'SELECT title FROM reminders WHERE deleted_at IS NULL ORDER BY position',
    );
    return [for (final row in rows) row['title'] as String];
  } finally {
    database.close();
  }
}
