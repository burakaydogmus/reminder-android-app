import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';

import 'a11y/a11y_sample_data.dart';
import 'onboarding/onboarding_test_utils.dart';
import 'ui_harness.dart';

/// F6.1 smoke tests: the main screens in English (the other UI tests run in
/// Turkish, `UiHarness` default). Sample data and clock of the a11y audit
/// (Sunday 13 September 2026, 14:32).
void main() {
  Future<UiHarness> pumpShell(WidgetTester tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create(
      reminders: auditReminders(),
      birthdays: auditBirthdays(),
      now: auditClock,
    );
    final prefs = A11yPrefs(A11yPrefsData.none);
    addTearDown(prefs.dispose);
    await tester.pumpWidget(
      h.app(
        language: AppLanguage.english,
        home: HomeShell(
          clock: auditClock,
          enableGlassScope: false,
          a11yPrefs: prefs,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    void Function(BuildContext context) show,
  ) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create(now: auditClock);
    await tester.pumpWidget(
      h.app(
        language: AppLanguage.english,
        home: NowScope(clock: auditClock, child: auditOpener(show)),
      ),
    );
    await tapAuditOpener(tester);
  }

  testWidgets('Today: header, sections and reminder cards', (tester) async {
    await pumpShell(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('SUNDAY, SEPTEMBER 13'), findsNothing);
    expect(find.text('Sunday, September 13'), findsOneWidget);
    expect(find.textContaining('open ·'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Move all to tomorrow'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.textContaining('Overdue', findRichText: true), findsWidgets);
    expect(find.textContaining('Every day', findRichText: true), findsWidgets);
    // No Turkish left on the page.
    expect(find.textContaining('Bugün'), findsNothing);
    expect(find.textContaining('Gecikti', findRichText: true), findsNothing);
  });

  testWidgets('Calendar: title, month and agenda headers', (tester) async {
    await pumpShell(tester);
    await selectTab(tester, 'Calendar');

    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('With location'), findsOneWidget);
    expect(
      find.textContaining('TODAY · SUNDAY, SEPTEMBER 13'),
      findsOneWidget,
    );
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets('Lists: smart lists and built-in category names', (tester) async {
    await pumpShell(tester);
    await selectTab(tester, 'Lists');

    expect(find.text('Lists'), findsWidgets);
    expect(find.text('Overdue'), findsWidgets);
    expect(find.text('Scheduled'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My categories'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My categories'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Market'), findsNothing);
  });

  testWidgets('Settings: groups and the language row', (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create(now: auditClock);
    await tester.pumpWidget(
      h.app(language: AppLanguage.english, home: const SettingsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    await tester.ensureVisible(find.byKey(SettingsPageKeys.language));
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('Reminder editor', (tester) async {
    await open(tester, (context) => showReminderEditorSheet(context));

    expect(find.text('New reminder'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('When'), findsOneWidget);
    await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Quick capture: English parsing (F4.6c)', (tester) async {
    await open(
      tester,
      (context) => showQuickCaptureSheet(context, now: auditClock),
    );

    expect(find.text('What should I remind you of?'), findsOneWidget);
    // The parser is no longer Turkish-only, so the old warning is gone and
    // the helper line shows English examples instead.
    expect(
      find.textContaining('Natural language: Turkish only'),
      findsNothing,
    );
    expect(
      find.text('Example: tomorrow at 9, every monday, #market'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(QuickCaptureKeys.field),
      'tomorrow at 16:00 buy milk #groceries',
    );
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow, 16:00'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('All details'), findsOneWidget);

    // A Turkish sentence is plain text while the app is in English.
    await tester.enterText(
      find.byKey(QuickCaptureKeys.field),
      'yarın 16:00 süt al',
    );
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow, 16:00'), findsNothing);
  });

  testWidgets('Birthdays page', (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create(
      birthdays: auditBirthdays(),
      now: auditClock,
    );
    await tester.pumpWidget(
      h.app(
        language: AppLanguage.english,
        home: const NowScope(clock: auditClock, child: BirthdaysPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.textContaining('Tomorrow'), findsWidgets);
    expect(find.text('SEPTEMBER'), findsOneWidget);
  });

  testWidgets('Onboarding welcome and capture demo', (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create(now: auditClock);
    await tester.pumpWidget(
      h.app(
        language: AppLanguage.english,
        home: OnboardingFlow(onSkip: () {}, onFinish: ([_]) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Don't keep it in your head."), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Just type it.'), findsOneWidget);
    expect(find.text('Stop by the pharmacy'), findsOneWidget);
    expect(find.text('Health · Tomorrow 09:00'), findsOneWidget);
  });
}
