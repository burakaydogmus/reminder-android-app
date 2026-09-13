import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/steps/capture_demo_step.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../ui_harness.dart';
import 'onboarding_test_utils.dart';

/// Records what the flow asked its host to do.
class _Host {
  int skips = 0;
  int finishes = 0;
  int pins = 0;
  final followUps = <OnboardingFollowUp>[];
  late BuildContext context;

  Widget flow({int initialPage = 0}) => Builder(
        builder: (context) {
          this.context = context;
          return OnboardingFlow(
            initialPage: initialPage,
            onSkip: () => skips++,
            onFinish: ([then]) {
              finishes++;
              if (then != null) followUps.add(then);
            },
            pinWidget: (_) async => pins++,
          );
        },
      );
}

Future<UiHarness> _pump(
  WidgetTester tester,
  _Host host, {
  int initialPage = 0,
  ThemeData Function()? theme,
  TargetPlatform platform = TargetPlatform.android,
  NotificationPermissionState? notifications,
}) async {
  usePhoneSurface(tester);
  final h = await UiHarness.create();
  if (notifications != null) {
    h.permissions.snapshot =
        h.permissions.snapshot.copyWith(notifications: notifications);
  }
  await tester.pumpWidget(
    h.app(
      home: host.flow(initialPage: initialPage),
      theme: theme ?? korThemes.first.$2,
      platform: platform,
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Onboarding steps ($themeName)', () {
      testWidgets('every step is announced as "Adım n / 4"', (tester) async {
        final semantics = tester.ensureSemantics();
        final host = _Host();
        await _pump(tester, host, theme: theme);

        expect(find.bySemanticsLabel('Adım 1 / 4'), findsOneWidget);
        await tester.tap(find.byKey(OnboardingKeys.start));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Adım 2 / 4'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('targets are at least 48 dp (steps 1 and 4)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final host = _Host();
        await _pump(tester, host, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

        await _pump(tester, _Host(), initialPage: 3, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('step 3 requests notifications and shows granted', (
        tester,
      ) async {
        final host = _Host();
        final h = await _pump(
          tester,
          host,
          initialPage: 2,
          theme: theme,
          notifications: NotificationPermissionState.notRequested,
        );
        expect(find.text('Bildirimlere izin ver'), findsOneWidget);
        expect(find.text('Şimdi değil'), findsOneWidget);

        await tester.tap(find.byKey(OnboardingKeys.allowNotifications));
        await tester.pumpAndSettle();

        expect(h.permissions.calls, ['requestNotifications']);
        expect(find.text('Bildirimler açık.'), findsOneWidget);
        expect(find.byKey(OnboardingKeys.allowNotifications), findsNothing);

        await tester.tap(find.byKey(OnboardingKeys.next));
        await tester.pumpAndSettle();
        expect(find.text('Hazırsın.'), findsOneWidget);
      });
    });
  }

  group('Step 3 — notification permission', () {
    testWidgets('denied request shows the settings hint and "Devam"', (
      tester,
    ) async {
      final host = _Host();
      final h = await _pump(
        tester,
        host,
        initialPage: 2,
        notifications: NotificationPermissionState.notRequested,
      );
      h.permissions.notificationRequestResult =
          NotificationPermissionState.denied;

      await tester.tap(find.byKey(OnboardingKeys.allowNotifications));
      await tester.pumpAndSettle();

      expect(h.permissions.calls, ['requestNotifications']);
      expect(find.textContaining('Bildirimler kapalı.'), findsOneWidget);
      await tester.tap(find.byKey(OnboardingKeys.next));
      await tester.pumpAndSettle();
      expect(find.text('Hazırsın.'), findsOneWidget);
    });

    testWidgets('already granted shows the granted state, no request', (
      tester,
    ) async {
      final host = _Host();
      final h = await _pump(tester, host, initialPage: 2);

      expect(find.text('Bildirimler açık.'), findsOneWidget);
      expect(find.byKey(OnboardingKeys.allowNotifications), findsNothing);
      expect(find.byKey(OnboardingKeys.next), findsOneWidget);
      expect(h.permissions.calls, isEmpty);
    });

    testWidgets('"Şimdi değil" moves on without asking', (tester) async {
      final host = _Host();
      final h = await _pump(
        tester,
        host,
        initialPage: 2,
        notifications: NotificationPermissionState.notRequested,
      );

      await tester.tap(find.byKey(OnboardingKeys.notNow));
      await tester.pumpAndSettle();

      expect(find.text('Hazırsın.'), findsOneWidget);
      expect(h.permissions.calls, isEmpty);
      expect(h.permissions.shownPrompts, isEmpty);
    });

    testWidgets('asked before: primary opens system settings', (tester) async {
      final host = _Host();
      final h = await _pump(
        tester,
        host,
        initialPage: 2,
        notifications: NotificationPermissionState.denied,
      );

      expect(find.text('Ayarları aç'), findsOneWidget);
      await tester.tap(find.byKey(OnboardingKeys.allowNotifications));
      await tester.pumpAndSettle();
      expect(h.permissions.calls, ['openNotificationSettings']);
    });

    testWidgets('never asks for exact alarms or location', (tester) async {
      final host = _Host();
      final h = await _pump(
        tester,
        host,
        initialPage: 2,
        notifications: NotificationPermissionState.notRequested,
      );
      h.permissions.snapshot = h.permissions.snapshot.copyWith(
        exactAlarms: ExactAlarmState.denied,
        location: LocationPermissionState.notRequested,
      );

      await tester.tap(find.byKey(OnboardingKeys.allowNotifications));
      await tester.pumpAndSettle();

      expect(h.permissions.calls, ['requestNotifications']);
    });
  });

  group('Step 4 — suggestions', () {
    testWidgets('"Market listesi oluştur" opens the editor with Market', (
      tester,
    ) async {
      final host = _Host();
      await _pump(tester, host, initialPage: 3);

      await tester.tap(find.byKey(OnboardingKeys.marketSuggestion));
      await tester.pumpAndSettle();
      expect(host.finishes, 1);
      expect(host.followUps, hasLength(1));

      host.followUps.single(host.context);
      await tester.pumpAndSettle();

      expect(find.byKey(ReminderEditorKeys.title), findsOneWidget);
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(
          FilterChip,
          ReminderCategoryIds.defaultLabel(ReminderCategoryIds.market),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('"Bir doğum günü ekle" opens the birthday editor', (
      tester,
    ) async {
      final host = _Host();
      await _pump(tester, host, initialPage: 3);

      await tester.tap(find.byKey(OnboardingKeys.birthdaySuggestion));
      await tester.pumpAndSettle();
      expect(host.finishes, 1);

      host.followUps.single(host.context);
      await tester.pumpAndSettle();
      expect(find.byKey(BirthdayEditorKeys.name), findsOneWidget);
    });

    testWidgets('"Ana ekrana widget ekle" pins on Android and stays', (
      tester,
    ) async {
      final host = _Host();
      await _pump(tester, host, initialPage: 3);

      await tester.tap(find.byKey(OnboardingKeys.widgetSuggestion));
      await tester.pumpAndSettle();

      expect(host.pins, 1);
      expect(host.finishes, 0);
      expect(find.text('Hazırsın.'), findsOneWidget);
    });

    testWidgets('widget row is hidden on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final host = _Host();
        await _pump(
          tester,
          host,
          initialPage: 3,
          platform: TargetPlatform.iOS,
        );

        expect(find.byKey(OnboardingKeys.marketSuggestion), findsOneWidget);
        expect(find.byKey(OnboardingKeys.birthdaySuggestion), findsOneWidget);
        expect(find.byKey(OnboardingKeys.widgetSuggestion), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('"Uygulamaya geç" finishes without a follow-up', (
      tester,
    ) async {
      final host = _Host();
      await _pump(tester, host, initialPage: 3);

      await tester.tap(find.byKey(OnboardingKeys.enterApp));
      await tester.pumpAndSettle();
      expect(host.finishes, 1);
      expect(host.followUps, isEmpty);
    });
  });

  group('Motion and text scaling', () {
    testWidgets('demo types itself: card appears only at the end', (
      tester,
    ) async {
      usePhoneSurface(tester);
      final h = await UiHarness.create();
      await tester.pumpWidget(h.app(home: _Host().flow(initialPage: 1)));
      await tester.pump();

      expect(find.text(CaptureDemo.cardTitle), findsNothing);
      expect(
        find.text(CaptureDemo.sentence, findRichText: true),
        findsNothing,
      );

      await tester.pumpAndSettle();
      expect(find.text(CaptureDemo.cardTitle), findsOneWidget);
      expect(
        find.text(CaptureDemo.sentence, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Reduce Motion shows the finished demo at once', (
      tester,
    ) async {
      useReduceMotion(tester);
      usePhoneSurface(tester);
      final h = await UiHarness.create();
      await tester.pumpWidget(h.app(home: _Host().flow(initialPage: 1)));
      await tester.pump();

      expect(find.text(CaptureDemo.cardTitle), findsOneWidget);
      expect(find.text(CaptureDemo.cardMeta), findsOneWidget);
      expect(
        find.text(CaptureDemo.sentence, findRichText: true),
        findsOneWidget,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    for (final (page, marker) in [(0, 'Aklında kalmasın.'), (3, 'Hazırsın.')]) {
      testWidgets('Reduce Motion: step ${page + 1} is static at once', (
        tester,
      ) async {
        useReduceMotion(tester);
        usePhoneSurface(tester);
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _Host().flow(initialPage: page)));
        await tester.pump();
        expect(find.text(marker), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      });
    }

    for (final (themeName, theme) in korThemes) {
      testWidgets('200% text: all steps without overflow ($themeName)', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final host = _Host();
        await _pump(
          tester,
          host,
          theme: theme,
          notifications: NotificationPermissionState.notRequested,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(OnboardingKeys.start));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(OnboardingKeys.next));
        await tester.pumpAndSettle();
        expect(find.text('Bildirimlere izin ver'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(OnboardingKeys.notNow));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.byKey(OnboardingKeys.birthdaySuggestion),
          100,
          scrollable: find
              .descendant(
                of: find.byType(OnboardingFlow),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        expect(find.byKey(OnboardingKeys.birthdaySuggestion), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
