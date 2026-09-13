import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_gate.dart';
import 'package:reminder/ui/onboarding/onboarding_store.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';
import 'onboarding_test_utils.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Future<bool?> _flag() async => (await SharedPreferences.getInstance())
    .getBool(OnboardingStore.completedKey);

Widget _gate() => const OnboardingGate(home: HomeShell(clock: _clock));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (themeName, theme) in korThemes) {
    group('OnboardingGate ($themeName)', () {
      testWidgets('shows onboarding when the flag is missing and no data', (
        tester,
      ) async {
        usePhoneSurface(tester);
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _gate(), theme: theme));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingFlow), findsOneWidget);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.text('Aklında kalmasın.'), findsOneWidget);
        expect(await _flag(), isNull);
      });

      testWidgets('existing data skips onboarding and sets the flag', (
        tester,
      ) async {
        usePhoneSurface(tester);
        final h = await UiHarness.create(reminders: [buildReminder()]);
        await tester.pumpWidget(h.app(home: _gate(), theme: theme));
        await tester.pumpAndSettle();

        expect(find.byType(HomeShell), findsOneWidget);
        expect(find.byType(OnboardingFlow), findsNothing);
        expect(await _flag(), isTrue);
      });

      testWidgets('"Atla" sets the flag and lands on HomeShell',
          (tester) async {
        usePhoneSurface(tester);
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _gate(), theme: theme));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(OnboardingKeys.skip));
        await tester.pumpAndSettle();

        expect(find.byType(HomeShell), findsOneWidget);
        expect(find.byType(OnboardingFlow), findsNothing);
        expect(await _flag(), isTrue);
      });

      testWidgets('full walk-through ends in the app', (tester) async {
        usePhoneSurface(tester);
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _gate(), theme: theme));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(OnboardingKeys.start));
        await tester.pumpAndSettle();
        expect(find.text('Yazman yeterli.'), findsOneWidget);
        await tester.tap(find.byKey(OnboardingKeys.next));
        await tester.pumpAndSettle();
        // Harness permissions are granted: granted state + "Devam".
        expect(find.text('Bildirimler açık.'), findsOneWidget);
        await tester.tap(find.byKey(OnboardingKeys.next));
        await tester.pumpAndSettle();
        expect(find.text('Hazırsın.'), findsOneWidget);
        expect(find.byKey(OnboardingKeys.skip), findsOneWidget);
        expect(
          tester.widget<TextButton>(find.byKey(OnboardingKeys.skip)).onPressed,
          isNull,
        );

        await tester.tap(find.byKey(OnboardingKeys.enterApp));
        await tester.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget);
        expect(await _flag(), isTrue);
      });
    });
  }

  testWidgets('completed flag goes straight to HomeShell', (tester) async {
    SharedPreferences.setMockInitialValues(
        {OnboardingStore.completedKey: true});
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(home: _gate()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });

  testWidgets('data loaded while step 1 is shown still skips', (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(home: _gate()));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingFlow), findsOneWidget);

    await h.cubit.addBirthday(buildBirthday());
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(await _flag(), isTrue);
  });

  testWidgets('data added after the user moved on does not skip', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(home: _gate()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OnboardingKeys.start));
    await tester.pumpAndSettle();

    await h.cubit.addBirthday(buildBirthday());
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(await _flag(), isNull);
  });

  testWidgets('"Market listesi oluştur" opens the editor over the app', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(home: _gate()));
    await tester.pumpAndSettle();
    for (final key in [
      OnboardingKeys.start,
      OnboardingKeys.next,
      OnboardingKeys.next,
    ]) {
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(OnboardingKeys.marketSuggestion));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byKey(ReminderEditorKeys.title), findsOneWidget);
    expect(await _flag(), isTrue);
  });
}
