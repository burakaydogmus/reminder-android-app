import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/services/widget_launch_router.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_gate.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../onboarding/onboarding_test_utils.dart';
import '../ui_harness.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

final _reminder = buildReminder(
  id: 'market',
  title: 'Market alışverişi',
  remindAt: DateTime(2026, 9, 13, 18, 30),
);

Finder get _editorTitle => find.byKey(ReminderEditorKeys.title);
Finder get _capture => find.byKey(QuickCaptureKeys.field);

void main() {
  late WidgetLaunchRouter router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = WidgetLaunchRouter();
  });

  Future<UiHarness> pumpShell(
    WidgetTester tester, {
    List reminders = const [],
  }) async {
    final h = await UiHarness.create(reminders: [...reminders.cast()]);
    await tester.pumpWidget(
      h.app(home: HomeShell(clock: _clock, widgetRouter: router)),
    );
    return h;
  }

  String editorTitleText(WidgetTester tester) =>
      tester.widget<TextField>(_editorTitle).controller!.text;

  testWidgets('"+" (new) opens quick capture (F4.6b)', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    router.open(Uri.parse('reminderwidget://new'));
    await tester.pumpAndSettle();

    expect(_capture, findsOneWidget);
    expect(_editorTitle, findsNothing);
    expect(router.pending, isNull);
  });

  testWidgets('a row (open?id=) opens that reminder in the editor', (
    tester,
  ) async {
    await pumpShell(tester, reminders: [_reminder]);
    await tester.pumpAndSettle();

    router.open(Uri.parse('reminderwidget://open?id=market'));
    await tester.pumpAndSettle();

    expect(_editorTitle, findsOneWidget);
    expect(editorTitleText(tester), 'Market alışverişi');
  });

  testWidgets('cold start: a row tap waits for the first load', (
    tester,
  ) async {
    await router.attach(
      initialLaunch: () async => Uri.parse('reminderwidget://open?id=market'),
      clicks: const Stream.empty(),
    );
    final h = await pumpShell(tester);
    await tester.pumpAndSettle();
    expect(router.pending, isNull, reason: 'taken by the shell');
    expect(_editorTitle, findsNothing);

    when(() => h.repository.loadReminders())
        .thenAnswer((_) async => [_reminder]);
    unawaited(h.cubit.load());
    await tester.pumpAndSettle();

    expect(editorTitleText(tester), 'Market alışverişi');
  });

  testWidgets('a birthday row opens Doğum günleri', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    router.open(Uri.parse('reminderwidget://birthday?id=b1'));
    await tester.pumpAndSettle();

    expect(find.byType(BirthdaysPage), findsOneWidget);
  });

  testWidgets('notifications-off strip opens Ayarlar', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    router.open(Uri.parse('reminderwidget://permissions'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('a target stays queued until onboarding is done', (
    tester,
  ) async {
    usePhoneSurface(tester);
    router.open(Uri.parse('reminderwidget://new'));
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(
        home: OnboardingGate(
          home: HomeShell(clock: _clock, widgetRouter: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(router.pending, const NewReminderTarget());
    expect(_capture, findsNothing);

    await tester.tap(find.byKey(OnboardingKeys.skip));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(router.pending, isNull);
    expect(_capture, findsOneWidget);
  });
}
