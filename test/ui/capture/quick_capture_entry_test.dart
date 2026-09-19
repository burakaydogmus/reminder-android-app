import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/capture/capture_bar.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_glass_tab_bar.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/today/today_page.dart';

import '../../helpers/factories.dart';
import '../home/ios_platform.dart';
import '../ui_harness.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Finder get _sheet => find.byType(QuickCaptureSheet);

void main() {
  group('Android FAB', () {
    for (final (themeName, theme) in korThemes) {
      testWidgets('tap opens quick capture ($themeName)', (tester) async {
        final h = await UiHarness.create(now: _clock);
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(NewItemFab));
        await tester.pumpAndSettle();
        expect(_sheet, findsOneWidget);

        await tester.enterText(
          find.byKey(QuickCaptureKeys.field),
          'yarın 18:00 süt al',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(QuickCaptureKeys.save));
        await tester.pumpAndSettle();
        final saved = h.cubit.state.reminders.single;
        expect(saved.title, 'Süt al');
        expect(saved.remindAt, DateTime(2026, 9, 14, 18));
      });
    }

    testWidgets('long-press "Hızlı ekle" and "Hatırlatıcı"', (tester) async {
      final h = await UiHarness.create(now: _clock);
      await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hızlı ekle'));
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
      Navigator.of(tester.element(_sheet)).pop();
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatıcı'));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
    });
  });

  group('iOS capture bar', () {
    Future<UiHarness> pumpShell(
      WidgetTester tester, {
      ThemeData Function() theme = KorTheme.light,
      int reminders = 0,
    }) async {
      final h = await UiHarness.create(
        now: _clock,
        reminders: [
          for (var i = 0; i < reminders; i++)
            buildReminder(id: 'u$i', title: 'Zamansız $i'),
        ],
      );
      final a11y = A11yPrefs(A11yPrefsData.none);
      addTearDown(a11y.dispose);
      await tester.pumpWidget(
        h.app(
          home: HomeShell(
            clock: _clock,
            enableGlassScope: false,
            a11yPrefs: a11y,
          ),
          theme: theme,
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pumpAndSettle();
      return h;
    }

    for (final (themeName, theme) in korThemes) {
      iosTestWidgets('sits above the tab bar, no FAB ($themeName)', (
        tester,
      ) async {
        await pumpShell(tester, theme: theme);
        expect(find.byType(NewItemFab), findsNothing);
        expect(find.text('Ne hatırlatayım?'), findsOneWidget);
        final bar = tester.getRect(find.byType(CaptureBar));
        final capsule = tester.getRect(find.byKey(KorGlassTabBar.capsuleKey));
        expect(bar.height, 52);
        expect(bar.bottom, lessThanOrEqualTo(capsule.top));
        expect(bar.width, greaterThan(capsule.width));
      });
    }

    iosTestWidgets('tap opens quick capture', (tester) async {
      await pumpShell(tester);
      await tester.tap(find.byType(CaptureBar));
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
    });

    iosTestWidgets('long-press offers Doğum günü', (tester) async {
      await pumpShell(tester);
      await tester.longPress(find.byType(CaptureBar));
      await tester.pumpAndSettle();
      expect(find.text('Hızlı ekle'), findsOneWidget);
      await tester.tap(find.text('Doğum günü'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni doğum günü'), findsOneWidget);
    });

    iosTestWidgets('shrinks down with the tab bar on scroll', (tester) async {
      await pumpShell(tester, reminders: 40);
      final expanded = tester.getRect(find.byType(CaptureBar));

      await tester.drag(
        find
            .descendant(
              of: find.byType(TodayPage),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      final collapsed = tester.getRect(find.byType(CaptureBar));
      expect(collapsed.height, 48);
      expect(collapsed.top, greaterThan(expanded.top));
      final tab = tester.getRect(find.byKey(KorGlassTabBar.collapsedKey));
      expect(collapsed.left, greaterThan(tab.right));
    });
  });
}
