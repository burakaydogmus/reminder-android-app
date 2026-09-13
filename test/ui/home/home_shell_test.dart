import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Finder _header(String title) => find.widgetWithText(TabHeader, title);

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

  testWidgets('iOS uses the bottom tab bar', (tester) async {
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(
        home: const HomeShell(clock: _clock),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KorTabBar), findsOneWidget);
    expect(find.byType(KorPillNavigation), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.byType(NewItemFab), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Listeler'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_header('Listeler'), findsOneWidget);
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

        for (final title in ['Kaçanlar', 'Bugün', 'Zamansız']) {
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
        // Completed is collapsed.
        expect(find.text('Vitamin iç'), findsNothing);

        final todayScroll = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        final toggle = find.bySemanticsLabel(RegExp('^Tamamlananlar, 1'));
        await tester.scrollUntilVisible(
          toggle,
          200,
          scrollable: todayScroll,
        );
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Vitamin iç'),
          200,
          scrollable: todayScroll,
        );
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
