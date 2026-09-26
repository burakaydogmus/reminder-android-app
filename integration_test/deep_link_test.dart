// E2E 7a/7 — `reminderwidget://` deep links and app icon shortcuts.
//
// Two halves, in two places:
//
// * **Native delivery** — that Android really resolves the scheme, starts
//   `MainActivity` and that `quick_actions` really published launcher
//   shortcuts — is asserted by the workflow with `adb shell am start` and
//   `adb shell dumpsys shortcut`. A Dart test inside the app cannot observe
//   another process' intent.
// * **In-app routing** — what happens once a URI reaches the app — is
//   asserted here, by pushing the real URIs (the ones the widget's
//   PendingIntents and `ReminderWidgetStore.launchURL` build, `homeWidget=true`
//   parameter included) through the live `WidgetLaunchRouter` that `main()`
//   attached, and checking that the right screen opens on the real app.
//
// The host suite tests `WidgetLaunchTarget.parse` and a fake router; it cannot
// test that `main()` attached the router on a real Android build.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/app_shortcuts.dart';
import 'package:reminder/services/widget_launch_router.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/today/today_page.dart';

import 'helpers/e2e.dart';

/// `ReminderWidgetStore.launchURL` appends this; `WidgetLaunchTarget.parse`
/// must ignore it.
const String kHomeWidgetFlag = 'homeWidget=true';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widget and shortcut launch URIs open the right screen',
      (tester) async {
    await launchApp(tester);
    await reachToday(tester);
    final cubit = cubitOf(tester);

    final now = DateTime.now();
    const reminderId = 'e2e-deeplink-reminder';
    const birthdayId = 'e2e-deeplink-birthday';
    await cubit.addReminder(Reminder(
      id: reminderId,
      title: 'Kargoyu al',
      isDone: false,
      createdAt: now,
    ));
    await cubit.addBirthday(Birthday(
      id: birthdayId,
      name: 'Bora',
      month: 7,
      day: 14,
      createdAt: now,
    ));

    // `reminderwidget://open?id=…` → the reminder editor for that reminder.
    WidgetLaunchRouter.instance.open(
      Uri.parse('reminderwidget://open?id=$reminderId&$kHomeWidgetFlag'),
    );
    await settle(tester);
    await pumpUntil(tester, find.byKey(ReminderEditorKeys.title),
        reason: 'for the editor opened by reminderwidget://open');
    expect(find.text('Kargoyu al'), findsWidgets);
    await popRoute(tester);
    await pumpUntil(tester, find.byType(TodayPage),
        reason: 'for Bugün after closing the editor');

    // `reminderwidget://new` → quick capture (F4.6b).
    WidgetLaunchRouter.instance.open(
      Uri.parse('reminderwidget://new?$kHomeWidgetFlag'),
    );
    await settle(tester);
    await pumpUntil(tester, find.byKey(QuickCaptureKeys.field),
        reason: 'for quick capture opened by reminderwidget://new');
    await popRoute(tester);

    // `reminderwidget://birthday?id=…` → Doğum günleri.
    WidgetLaunchRouter.instance.open(
      Uri.parse('reminderwidget://birthday?id=$birthdayId&$kHomeWidgetFlag'),
    );
    await settle(tester);
    await pumpUntil(tester, find.byType(BirthdaysPage),
        reason: 'for Doğum günleri opened by reminderwidget://birthday');
    expect(find.text('Bora'), findsWidgets);
    await popRoute(tester);

    // `reminderwidget://permissions` → Ayarlar.
    WidgetLaunchRouter.instance.open(
      Uri.parse('reminderwidget://permissions?$kHomeWidgetFlag'),
    );
    await settle(tester);
    await pumpUntil(tester, find.byType(SettingsPage),
        reason: 'for Ayarlar opened by reminderwidget://permissions');
    await popRoute(tester);

    // An unknown address is ignored rather than crashing the shell.
    WidgetLaunchRouter.instance.open(Uri.parse('reminderwidget://nope'));
    await settle(tester);
    expect(find.byType(TodayPage), findsOneWidget);

    // App icon shortcuts (F5.3) take the same router. "Market listesi"
    // prefills quick capture with its category tag.
    WidgetLaunchRouter.instance.openTarget(AppShortcut.marketList.target);
    await settle(tester);
    await pumpUntil(tester, find.byKey(QuickCaptureKeys.field),
        reason: 'for quick capture opened by the "Market listesi" shortcut');
    await popRoute(tester);

    WidgetLaunchRouter.instance.openTarget(AppShortcut.today.target);
    await settle(tester);
    expect(find.byType(TodayPage), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
