import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/search/recent_search_store.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

List<Reminder> _reminders() => [
      buildReminder(
        id: 'electric',
        title: 'Elektrik faturasını öde',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 12, 18),
      ),
      buildReminder(
        id: 'water',
        title: 'Su faturası',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 17, 19),
      ),
      buildReminder(
        id: 'internet',
        title: 'İnternet itirazı',
        categoryId: ReminderCategoryIds.work,
        note: 'Geçen ayki faturada fazladan ücret var',
      ),
      buildReminder(
        id: 'light',
        title: 'Işıkları kapat',
        categoryId: ReminderCategoryIds.home,
      ),
      buildReminder(
        id: 'archive',
        title: 'Eski fatura arşivi',
        isDone: true,
      ),
    ];

Future<UiHarness> _openSearch(
  WidgetTester tester, {
  ThemeData Function()? theme,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final h = await UiHarness.create(reminders: _reminders());
  await tester.pumpWidget(
    theme == null
        ? h.app(home: const HomeShell(clock: _clock))
        : h.app(home: const HomeShell(clock: _clock), theme: theme),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Ara'));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(SearchPageKeys.field), text);
  await tester.pumpAndSettle();
}

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Arama ($themeName)', () {
      testWidgets('opens from Bugün with autofocus and an empty state',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await _openSearch(tester, theme: theme);

        expect(find.byType(SearchPage), findsOneWidget);
        final field =
            tester.widget<TextField>(find.byKey(SearchPageKeys.field));
        expect(field.autofocus, isTrue);
        expect(find.text('Hatırlatıcılarında ara'), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('typing groups results and highlights matches',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await _openSearch(tester, theme: theme);
        await _type(tester, 'FATURA');

        expect(find.text('Hatırlatıcılar · 2'), findsOneWidget);
        expect(find.text('Notlarda · 1'), findsOneWidget);
        expect(find.text('3 sonuç'), findsOneWidget);
        expect(
          tester.getSemantics(find.byKey(SearchPageKeys.resultCount)),
          isSemantics(isLiveRegion: true, label: '3 sonuç'),
        );

        // Highlighted span: weight 700 on primaryContainer.
        final scheme =
            Theme.of(tester.element(find.byType(SearchPage))).colorScheme;
        final title = tester.widget<RichText>(
          find.descendant(
            of: find.byKey(const ValueKey('electric')),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is RichText &&
                  w.text.toPlainText() == 'Elektrik faturasını öde',
            ),
          ),
        );
        TextSpan? highlighted;
        title.text.visitChildren((span) {
          if (span is TextSpan && span.text == 'fatura') highlighted = span;
          return highlighted == null;
        });
        expect(highlighted, isNotNull);
        expect(highlighted!.style!.fontWeight, FontWeight.w700);
        expect(highlighted!.style!.backgroundColor, scheme.primaryContainer);

        // Note context line for the note match.
        expect(
          find.textContaining('faturada fazladan', findRichText: true),
          findsOneWidget,
        );
        // Completed item is filtered out by default.
        expect(
          find.textContaining('arşivi', findRichText: true),
          findsNothing,
        );
        semantics.dispose();
      });
    });
  }

  testWidgets('Turkish-insensitive: "isik" finds "Işıkları kapat"',
      (tester) async {
    await _openSearch(tester);
    await _type(tester, 'isik');
    expect(find.text('Hatırlatıcılar · 1'), findsOneWidget);
    expect(
      find.textContaining('Işıkları kapat', findRichText: true),
      findsOneWidget,
    );
    await _type(tester, 'INTERNET');
    expect(
      find.textContaining('İnternet itirazı', findRichText: true),
      findsOneWidget,
    );
    await _type(tester, 'ev işleri');
    expect(find.text('Hatırlatıcılar · 3'), findsOneWidget);
  });

  testWidgets('chips: Tamamlanan and Kategori', (tester) async {
    await _openSearch(tester);
    await _type(tester, 'fatura');

    await tester.tap(find.byKey(SearchPageKeys.completedChip));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 3'), findsOneWidget);
    expect(
      find.textContaining('Eski fatura arşivi', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byKey(SearchPageKeys.openChip));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 1'), findsOneWidget);
    expect(find.text('Notlarda · 1'), findsNothing);

    await tester.tap(find.byKey(SearchPageKeys.openChip));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchPageKeys.categoryChip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İş').last);
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 1'), findsNothing);
    expect(find.text('Notlarda · 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SearchPageKeys.categoryChip),
        matching: find.text('İş'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no results offers "Tamamlananlarda ara"', (tester) async {
    await _openSearch(tester);
    await _type(tester, 'arşiv');

    expect(find.text('“arşiv” için sonuç yok'), findsOneWidget);
    expect(
      find.text('Yazımı kontrol et veya tamamlananlarda ara.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tamamlananlarda ara'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Eski fatura arşivi', findRichText: true),
      findsOneWidget,
    );

    await _type(tester, 'faturaa');
    expect(find.text('“faturaa” için sonuç yok'), findsOneWidget);
    expect(find.text('Tamamlananlarda ara'), findsNothing);
  });

  testWidgets('recent searches: saved on submit, reused, cleared',
      (tester) async {
    await _openSearch(tester, prefs: {
      RecentSearchStore.key: <String>['doktor'],
    });
    expect(find.text('Son aramalar'), findsOneWidget);
    expect(find.text('doktor'), findsOneWidget);

    await _type(tester, 'su fatura');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(RecentSearchStore.key), ['su fatura', 'doktor']);

    // Clear the field: recent list is back, newest first.
    await tester.tap(find.byTooltip('Temizle'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('su fatura')).dy,
      lessThan(tester.getTopLeft(find.text('doktor')).dy),
    );

    // Tapping a recent search runs it.
    await tester.tap(find.text('su fatura'));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcılar · 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Temizle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchPageKeys.clearRecent));
    await tester.pumpAndSettle();
    expect(find.text('Son aramalar'), findsNothing);
    expect(prefs.getStringList(RecentSearchStore.key), isNull);
  });

  testWidgets('Listeler header has Ara too; back returns', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final h = await UiHarness.create(reminders: _reminders());
    await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(KorPillNavigation),
        matching: find.bySemanticsLabel('Listeler'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ara'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsOneWidget);
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(find.text('Kategorilerim'), findsOneWidget);
  });
}
