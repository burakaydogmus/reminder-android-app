import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:reminder/services/app_shortcuts.dart';
import 'package:reminder/services/widget_launch_router.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_gate.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/onboarding_test_utils.dart';
import '../ui_harness.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Finder get _capture => find.byKey(QuickCaptureKeys.field);
Finder get _birthdayName => find.byKey(BirthdayEditorKeys.name);
Finder _header(String title) => find.widgetWithText(TabHeader, title);
Finder _navItem(String label) => find.descendant(
      of: find.byType(KorPillNavigation),
      matching: find.bySemanticsLabel(label),
    );

/// The plugin as the shell sees it: [launchType] started the app, [tap]
/// is a later (warm) shortcut tap.
class _FakeQuickActions implements QuickActionsPlatform {
  _FakeQuickActions({this.launchType});

  final String? launchType;
  void Function(String type)? _handler;

  void tap(AppShortcut shortcut) => _handler!(shortcut.type);

  @override
  Future<void> initialize(void Function(String type) handler) async {
    _handler = handler;
    if (launchType != null) handler(launchType!);
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {}
}

void main() {
  late WidgetLaunchRouter router;
  late _FakeQuickActions quickActions;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    router = WidgetLaunchRouter();
    quickActions = _FakeQuickActions();
    await ShortcutRouter(router: router).attach(quickActions);
  });

  Future<UiHarness> pumpShell(WidgetTester tester) async {
    final h = await UiHarness.create(now: _clock);
    await tester.pumpWidget(
      h.app(home: HomeShell(clock: _clock, widgetRouter: router)),
    );
    await tester.pumpAndSettle();
    return h;
  }

  String captureText(WidgetTester tester) =>
      tester.widget<TextField>(_capture).controller!.text;

  testWidgets('"Yeni hatırlatıcı" opens an empty quick capture', (
    tester,
  ) async {
    await pumpShell(tester);

    quickActions.tap(AppShortcut.newReminder);
    await tester.pumpAndSettle();

    expect(_capture, findsOneWidget);
    expect(captureText(tester), isEmpty);
    expect(router.pending, isNull);
  });

  testWidgets('"Market listesi" opens quick capture with #market', (
    tester,
  ) async {
    await pumpShell(tester);

    quickActions.tap(AppShortcut.marketList);
    await tester.pumpAndSettle();

    expect(_capture, findsOneWidget);
    expect(captureText(tester), '#market ');
    expect(
      find.descendant(
        of: find.byKey(QuickCaptureKeys.categoryChip),
        matching: find.text('Market'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Bugün" closes pushed pages and selects Bugün', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(_navItem('Listeler'));
    await tester.pumpAndSettle();
    expect(_header('Listeler'), findsOneWidget);
    router.openTarget(const PermissionsTarget());
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    quickActions.tap(AppShortcut.today);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsNothing);
    expect(_header('Bugün'), findsOneWidget);
    expect(_header('Listeler'), findsNothing);
  });

  testWidgets('"Yeni doğum günü" opens the birthday editor', (tester) async {
    await pumpShell(tester);

    quickActions.tap(AppShortcut.newBirthday);
    await tester.pumpAndSettle();

    expect(_birthdayName, findsOneWidget);
    expect(
      tester.widget<TextField>(_birthdayName).controller!.text,
      isEmpty,
    );
  });

  testWidgets('cold start: the launching shortcut waits for onboarding', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final coldRouter = WidgetLaunchRouter();
    await ShortcutRouter(
      router: coldRouter,
    ).attach(_FakeQuickActions(launchType: 'new_birthday'));
    final h = await UiHarness.create(now: _clock);
    await tester.pumpWidget(
      h.app(
        home: OnboardingGate(
          home: HomeShell(clock: _clock, widgetRouter: coldRouter),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(coldRouter.pending, const NewBirthdayTarget());
    expect(_birthdayName, findsNothing);

    await tester.tap(find.byKey(OnboardingKeys.skip));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(coldRouter.pending, isNull);
    expect(_birthdayName, findsOneWidget);
  });
}
