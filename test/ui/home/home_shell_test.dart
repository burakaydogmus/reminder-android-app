import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/components/kor_glass_surface.dart';
import 'package:reminder/ui/home/kor_glass_tab_bar.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/today/today_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';
import 'ios_platform.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Finder _header(String title) => find.widgetWithText(TabHeader, title);

/// Bugün with the time ribbon is taller than the default test view.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 5400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

Finder _navItem(String label) => find.descendant(
      of: find.byType(KorPillNavigation),
      matching: find.bySemanticsLabel(label),
    );

void main() {
  for (final (themeName, theme) in korThemes) {
    group('HomeShell ($themeName, Android)', () {
      testWidgets('has three destinations and switches tabs', (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        for (final label in ['Bugün', 'Takvim', 'Listeler']) {
          expect(_navItem(label), findsOneWidget);
        }
        expect(find.byType(NewItemFab), findsOneWidget);
        expect(_header('Bugün'), findsOneWidget);

        await tester.tap(_navItem('Takvim'));
        await tester.pumpAndSettle();
        expect(_header('Takvim'), findsOneWidget);
        expect(find.text('Yaklaşan bir şey yok'), findsOneWidget);

        await tester.tap(_navItem('Listeler'));
        await tester.pumpAndSettle();
        expect(_header('Listeler'), findsOneWidget);
        expect(find.text('Kategorilerim'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('nav targets are at least 48 dp', (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('nav and FAB sit at the bottom of the screen', (
        tester,
      ) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();
        final screen = tester.getSize(find.byType(HomeShell));
        final nav = tester.getRect(find.byType(KorPillNavigation));
        final fab = tester.getRect(find.byType(NewItemFab));
        // Regression: the bottom slot used to fill the screen, centring
        // the nav vertically and pushing floating snackbars off screen.
        expect(screen.height - nav.bottom, lessThan(40));
        expect(screen.height - fab.bottom, lessThan(40));
      });

      testWidgets('gear opens Ayarlar', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Ayarlar'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('back from Listeler returns to Bugün', (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        await tester.tap(_navItem('Listeler'));
        await tester.pumpAndSettle();
        expect(_header('Listeler'), findsOneWidget);

        final handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(handled, isTrue);
        expect(_header('Bugün'), findsOneWidget);
        expect(find.text('Kategorilerim'), findsNothing);
        semantics.dispose();
      });

      testWidgets('FAB long-press offers Hatırlatıcı and Doğum günü', (
        tester,
      ) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.text('Hatırlatıcı'), findsOneWidget);
        expect(find.text('Doğum günü'), findsOneWidget);
      });
    });
  }

  group('HomeShell (iOS glass chrome)', () {
    Finder tab(String label) => find.descendant(
          of: find.byKey(KorGlassTabBar.capsuleKey),
          matching: find.bySemanticsLabel(label),
        );
    final collapsed = find.byKey(KorGlassTabBar.collapsedKey);
    Finder scrollOf(Type page) => find
        .descendant(of: find.byType(page), matching: find.byType(Scrollable))
        .first;
    // Enough rows to scroll Bugün (untimed) and Takvim (tomorrow).
    final many = [
      for (var i = 0; i < 30; i++)
        buildReminder(id: 'u$i', title: 'Zamansız $i'),
      for (var i = 0; i < 30; i++)
        buildReminder(
          id: 't$i',
          title: 'Yarın $i',
          remindAt: DateTime(2026, 9, 14, 8, i),
        ),
    ];

    Future<void> pumpShell(
      WidgetTester tester, {
      A11yPrefsData prefs = A11yPrefsData.none,
      bool enableGlassScope = false,
      List<Reminder> reminders = const [],
      ThemeData Function() theme = KorTheme.light,
    }) async {
      final h = await UiHarness.create(reminders: reminders);
      final a11y = A11yPrefs(prefs);
      addTearDown(a11y.dispose);
      await tester.pumpWidget(
        h.app(
          home: HomeShell(
            clock: _clock,
            enableGlassScope: enableGlassScope,
            a11yPrefs: a11y,
          ),
          theme: theme,
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final (themeName, theme) in korThemes) {
      iosTestWidgets('glass tab bar switches pages ($themeName)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpShell(tester, theme: theme);

        expect(find.byType(KorGlassTabBar), findsOneWidget);
        expect(find.byType(KorPillNavigation), findsNothing);
        expect(find.byType(NewItemFab), findsOneWidget);
        for (final label in ['Bugün', 'Takvim', 'Listeler']) {
          expect(tab(label), findsOneWidget);
        }
        expect(find.byKey(KorGlassSurface.glassKey), findsWidgets);
        // The search circle waits for F3.6's search page.
        expect(
          find.byKey(KorGlassTabBar.searchKey),
          kShellSearchEnabled ? findsOneWidget : findsNothing,
        );

        await tester.tap(tab('Listeler'));
        await tester.pumpAndSettle();
        expect(_header('Listeler'), findsOneWidget);
        expect(
          tester.getSemantics(tab('Listeler')),
          isSemantics(isSelected: true),
        );

        await tester.tap(tab('Takvim'));
        await tester.pumpAndSettle();
        expect(_header('Takvim'), findsOneWidget);
        semantics.dispose();
      });
    }

    iosTestWidgets('tab bar floats at the bottom over the body', (
      tester,
    ) async {
      await pumpShell(tester);
      final screen = tester.getSize(find.byType(HomeShell));
      final capsule = tester.getRect(find.byKey(KorGlassTabBar.capsuleKey));
      expect(capsule.height, 62);
      expect(capsule.width, lessThanOrEqualTo(290));
      expect(screen.height - capsule.bottom, lessThan(40));
      final scaffold = tester.widget<Scaffold>(
        find
            .descendant(
              of: find.byType(HomeShell),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(scaffold.extendBody, isTrue);
    });

    iosTestWidgets('targets are at least 48pt', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpShell(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });

    iosTestWidgets('shrinks on scroll down and expands on scroll up', (
      tester,
    ) async {
      await pumpShell(tester, reminders: many);
      expect(collapsed, findsNothing);

      await tester.drag(scrollOf(TodayPage), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(collapsed, findsOneWidget);
      expect(
        tester.getSize(find.byKey(KorGlassTabBar.capsuleKey)).width,
        lessThan(100),
      );

      await tester.drag(scrollOf(TodayPage), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(collapsed, findsNothing);
      expect(tab('Bugün'), findsOneWidget);
    });

    iosTestWidgets('collapsed tab bar expands on tap and on tab switch', (
      tester,
    ) async {
      await pumpShell(tester, reminders: many);
      await tester.drag(scrollOf(TodayPage), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(collapsed);
      await tester.pumpAndSettle();
      expect(collapsed, findsNothing);

      // Collapse on Takvim; back selects Bugün with the tab bar expanded.
      await tester.tap(tab('Takvim'));
      await tester.pumpAndSettle();
      await tester.drag(scrollOf(CalendarPage), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(collapsed, findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Bugün's header is scrolled away; the page index tells the tab.
      final pages = tester.widget<IndexedStack>(
        find
            .descendant(
              of: find.byType(HomeShell),
              matching: find.byType(IndexedStack),
            )
            .first,
      );
      expect(pages.index, 0);
      expect(collapsed, findsNothing);
    });

    iosTestWidgets('stays expanded with VoiceOver', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpShell(tester, reminders: many);

      await tester.drag(scrollOf(TodayPage), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(collapsed, findsNothing);
      expect(tab('Takvim'), findsOneWidget);
    });

    iosTestWidgets('Reduce Transparency renders solid chrome', (tester) async {
      await pumpShell(
        tester,
        prefs: const A11yPrefsData(reduceTransparency: true),
      );
      expect(find.byKey(KorGlassSurface.glassKey), findsNothing);
      expect(find.byKey(KorGlassSurface.solidKey), findsWidgets);
    });

    iosTestWidgets('builds with the adaptive glass scope (default)', (
      tester,
    ) async {
      await pumpShell(tester, enableGlassScope: true);
      expect(find.byType(KorGlassTabBar), findsOneWidget);
      await tester.tap(tab('Takvim'));
      await tester.pumpAndSettle();
      expect(_header('Takvim'), findsOneWidget);
    });
  });

  group('Bugün and Takvim content (fixed clock)', () {
    final reminders = [
      buildReminder(
        id: 'overdue',
        title: 'Elektrik faturasını öde',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 12, 18),
      ),
      buildReminder(
        id: 'today',
        title: "Ali'yi kurstan al",
        categoryId: ReminderCategoryIds.errands,
        remindAt: DateTime(2026, 9, 13, 16),
      ),
      buildReminder(id: 'untimed', title: 'Kitabı iade et'),
      buildReminder(
        id: 'done',
        title: 'Vitamin iç',
        isDone: true,
        remindAt: DateTime(2026, 9, 13, 9),
      ),
      buildReminder(
        id: 'tomorrow',
        title: 'Kahvaltı rezervasyonu',
        remindAt: DateTime(2026, 9, 14, 9, 30),
      ),
      buildReminder(
        id: 'located',
        title: 'Market alışverişi',
        categoryId: ReminderCategoryIds.market,
        locationTriggerEnabled: true,
        locationLatitude: 41.0082,
        locationLongitude: 28.9784,
      ),
    ];

    for (final (themeName, theme) in korThemes) {
      testWidgets('Bugün sections ($themeName)', (tester) async {
        _tallView(tester);
        final semantics = tester.ensureSemantics();
        final h = await UiHarness.create(
          reminders: reminders,
          birthdays: [
            buildBirthday(name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
          ],
        );
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pazar, 13 Eylül'), findsOneWidget);
        expect(find.text('3 açık · 1 gecikmiş · 1 tamam'), findsOneWidget);
        expect(find.text('Zeynep Aydın'), findsOneWidget);

        for (final title in [
          'Kaçanlar',
          'Zaman çizelgesi',
          'Bugün bir ara',
        ]) {
          expect(
            find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.text(title),
            ),
            findsWidgets,
          );
        }
        expect(find.text('Elektrik faturasını öde'), findsOneWidget);
        expect(
          find.textContaining('Gecikti', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Dün 18:00'), findsOneWidget);
        expect(find.text("Ali'yi kurstan al"), findsOneWidget);
        expect(find.text('16:00'), findsOneWidget);
        expect(find.text('Kitabı iade et'), findsOneWidget);
        // Location label without a place name, never coordinates.
        expect(
          find.textContaining('Konum', findRichText: true),
          findsWidgets,
        );
        expect(find.textContaining('41.0', findRichText: true), findsNothing);
        // Later days belong to Takvim.
        expect(find.text('Kahvaltı rezervasyonu'), findsNothing);
        // Completed timed items stay on the ribbon; the toggle hides them.
        expect(find.text('Vitamin iç'), findsOneWidget);
        await tester.tap(find.text('Tamamlananları gizle'));
        await tester.pumpAndSettle();
        expect(find.text('Vitamin iç'), findsNothing);
        await tester.tap(find.text('Tamamlananları göster'));
        await tester.pumpAndSettle();
        expect(find.text('Vitamin iç'), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('Takvim groups by day with Turkish headers', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await UiHarness.create(
        reminders: reminders,
        birthdays: [
          buildBirthday(name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
        ],
      );
      await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
      await tester.pumpAndSettle();

      await tester.tap(_navItem('Takvim'));
      await tester.pumpAndSettle();

      expect(find.text('BUGÜN · PAZAR 13 EYLÜL'), findsOneWidget);
      expect(find.text('YARIN · PAZARTESİ 14 EYLÜL'), findsOneWidget);
      expect(find.text('Kahvaltı rezervasyonu'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('Zeynep Aydın'), findsOneWidget);
      expect(find.text('30 yaşına giriyor'), findsOneWidget);
      // Overdue and untimed items are not in the agenda.
      expect(find.text('Elektrik faturasını öde'), findsNothing);
      expect(find.text('Kitabı iade et'), findsNothing);
      semantics.dispose();
    });

    testWidgets('card checkbox toggles done', (tester) async {
      _tallView(tester);
      final h = await UiHarness.create(reminders: reminders);
      await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
      await tester.pumpAndSettle();

      final toggle = find.descendant(
        of: find
            .ancestor(
              of: find.text('Kitabı iade et'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byType(InkResponse),
      );
      await tester.tap(toggle.first);
      await tester.pumpAndSettle();
      expect(
        h.cubit.state.reminders.firstWhere((r) => r.id == 'untimed').isDone,
        isTrue,
      );
    });
  });
}
