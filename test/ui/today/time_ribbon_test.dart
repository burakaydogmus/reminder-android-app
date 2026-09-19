import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/today/time_ribbon.dart';
import 'package:reminder/ui/today/today_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

List<Reminder> _reminders() => [
      buildReminder(
        id: 'vitamin',
        title: 'Vitamin iç',
        categoryId: ReminderCategoryIds.health,
        isDone: true,
        remindAt: DateTime(2026, 9, 13, 9),
      ),
      buildReminder(
        id: 'cargo',
        title: 'Kargoyu teslim al',
        isDone: true,
        remindAt: DateTime(2026, 9, 13, 11, 30),
      ),
      buildReminder(
        id: 'ali',
        title: "Ali'yi kurstan al",
        categoryId: ReminderCategoryIds.errands,
        remindAt: DateTime(2026, 9, 13, 16),
      ),
      buildReminder(
        id: 'slides',
        title: 'Sunum slaytlarını gözden geçir',
        categoryId: ReminderCategoryIds.work,
        remindAt: DateTime(2026, 9, 13, 20),
      ),
      buildReminder(
        id: 'bill',
        title: 'Elektrik faturasını öde',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 12, 18),
      ),
      buildReminder(
        id: 'pharmacy',
        title: 'Eczaneye uğra',
        remindAt: DateTime(2026, 9, 12, 9, 15),
      ),
      buildReminder(id: 'book', title: 'Kütüphane kitabını iade et'),
    ];

Future<UiHarness> _pump(
  WidgetTester tester, {
  ThemeData Function() theme = KorTheme.light,
  List<Reminder>? reminders,
}) async {
  final h = await UiHarness.create(
    reminders: reminders ?? _reminders(),
    now: _clock,
  );
  await tester.pumpWidget(
    h.app(home: const HomeShell(clock: _clock), theme: theme),
  );
  await tester.pumpAndSettle();
  return h;
}

/// Makes the Bugün list tall enough to lay every row out.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 5400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

double _top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

Reminder _byId(UiHarness h, String id) =>
    h.cubit.state.reminders.firstWhere((r) => r.id == id);

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Bugün time ribbon ($themeName)', () {
      testWidgets('rows are chronological with ŞİMDİ between 11:30 and 16:00',
          (tester) async {
        _tallView(tester);
        final semantics = tester.ensureSemantics();
        await _pump(tester, theme: theme);

        final vitamin = _top(tester, find.text('Vitamin iç'));
        final cargo = _top(tester, find.text('Kargoyu teslim al'));
        final nowLine = _top(tester, find.byKey(TimeRibbonKeys.nowLine));
        final ali = _top(tester, find.text("Ali'yi kurstan al"));
        final slides = _top(
          tester,
          find.text('Sunum slaytlarını gözden geçir'),
        );
        expect(vitamin, lessThan(cargo));
        expect(cargo, lessThan(nowLine));
        expect(nowLine, lessThan(ali));
        expect(ali, lessThan(slides));

        // Kaçanlar above the ribbon, Bugün bir ara below it.
        expect(
          _top(tester, find.text('Elektrik faturasını öde')),
          lessThan(vitamin),
        );
        expect(
          _top(tester, find.text('Kütüphane kitabını iade et')),
          greaterThan(slides),
        );

        // Gutter times with the ŞİMDİ pill, and its semantics label.
        for (final id in ['vitamin', 'cargo', 'ali', 'slides']) {
          expect(find.byKey(TimeRibbonKeys.gutter(id)), findsOneWidget);
        }
        expect(
          find.descendant(
            of: find.byKey(TimeRibbonKeys.nowPill),
            matching: find.text('14:32'),
          ),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Şimdi, saat 14:32'), findsOneWidget);
        // The open card on the ribbon does not repeat the time.
        expect(find.text('16:00'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('completed items are compact; the toggle hides them',
          (tester) async {
        _tallView(tester);
        await _pump(tester, theme: theme);

        Finder compact(String title) => find.ancestor(
              of: find.text(title),
              matching: find.byType(ReminderCompactCard),
            );
        expect(compact('Vitamin iç'), findsOneWidget);
        expect(compact('Kargoyu teslim al'), findsOneWidget);
        expect(
          tester.getSize(compact('Vitamin iç')).height,
          lessThan(
            tester
                .getSize(
                  find.ancestor(
                    of: find.text("Ali'yi kurstan al"),
                    matching: find.byType(ReminderCard),
                  ),
                )
                .height,
          ),
        );

        await tester.tap(find.byKey(TodayPageKeys.ribbonCompletedToggle));
        await tester.pumpAndSettle();
        expect(find.text('Vitamin iç'), findsNothing);
        expect(find.byKey(TimeRibbonKeys.gutter('vitamin')), findsNothing);
        expect(find.text('Tamamlananları göster'), findsOneWidget);
        // ŞİMDİ stays, now before the first open item.
        expect(find.byKey(TimeRibbonKeys.nowLine), findsOneWidget);

        await tester.tap(find.byKey(TodayPageKeys.ribbonCompletedToggle));
        await tester.pumpAndSettle();
        expect(compact('Vitamin iç'), findsOneWidget);
      });
    });
  }

  testWidgets('ribbon cards keep one semantics node with F3.5 actions',
      (tester) async {
    _tallView(tester);
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    List<String> actions(String title) {
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(title)},')),
      );
      return [
        for (final id in node.getSemanticsData().customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)!.label ?? '',
      ];
    }

    expect(
      actions("Ali'yi kurstan al"),
      unorderedEquals(['Tamamla', 'Ertele', 'Sabitle', 'Düzenle', 'Sil']),
    );
    expect(
      actions('Vitamin iç'),
      unorderedEquals(['Geri aç', 'Sabitle', 'Düzenle', 'Sil']),
    );
    expect(
      find.bySemanticsLabel(
        RegExp('^Vitamin iç, Sağlık, Bugün saat 09:00, tamamlandı'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('ŞİMDİ moves with the clock (minute tick, no animation)',
      (tester) async {
    _tallView(tester);
    var now = DateTime(2026, 9, 13, 10);
    final h = await UiHarness.create(reminders: _reminders());
    await tester.pumpWidget(
      h.app(home: HomeShell(clock: () => now)),
    );
    await tester.pumpAndSettle();

    // 10:00: between 09:00 and 11:30.
    expect(
      _top(tester, find.byKey(TimeRibbonKeys.nowLine)),
      lessThan(_top(tester, find.text('Kargoyu teslim al'))),
    );
    expect(find.text('10:00'), findsOneWidget);

    now = DateTime(2026, 9, 13, 12, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('12:01'), findsOneWidget);
    expect(
      _top(tester, find.byKey(TimeRibbonKeys.nowLine)),
      greaterThan(_top(tester, find.text('Kargoyu teslim al'))),
    );
  });

  testWidgets('glow plays once on open, not under Reduce Motion',
      (tester) async {
    final h = await UiHarness.create(reminders: _reminders());
    await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    final reduced = await UiHarness.create(reminders: _reminders());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: reduced.app(
          home: const HomeShell(clock: _clock),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state(find.byType(NowLine));
    expect(state, isNotNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('Hepsini yarına al', () {
    testWidgets('moves every overdue item to tomorrow, same time; undo all',
        (tester) async {
      final h = await _pump(tester);
      final billBefore = _byId(h, 'bill').remindAt;
      final pharmacyBefore = _byId(h, 'pharmacy').remindAt;

      await tester.tap(find.byKey(TodayPageKeys.moveOverdue));
      await tester.pumpAndSettle();

      expect(_byId(h, 'bill').remindAt, DateTime(2026, 9, 14, 18));
      expect(_byId(h, 'pharmacy').remindAt, DateTime(2026, 9, 14, 9, 15));
      // Untouched: today's and untimed items.
      expect(_byId(h, 'ali').remindAt, DateTime(2026, 9, 13, 16));
      expect(_byId(h, 'book').remindAt, isNull);
      expect(find.text('2 hatırlatıcı yarına alındı'), findsOneWidget);
      expect(find.text('Kaçanlar'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'bill').remindAt, billBefore);
      expect(_byId(h, 'pharmacy').remindAt, pharmacyBefore);
      expect(find.text('Kaçanlar'), findsOneWidget);
    });

    testWidgets('single item message quotes the title', (tester) async {
      await _pump(
        tester,
        reminders: [
          buildReminder(
            id: 'bill',
            title: 'Elektrik faturasını öde',
            remindAt: DateTime(2026, 9, 12, 18),
          ),
        ],
      );
      await tester.tap(find.text('Hepsini yarına al'));
      await tester.pumpAndSettle();
      expect(
        find.text('“Elektrik faturasını öde” yarına alındı'),
        findsOneWidget,
      );
    });

    testWidgets('recurring overdue items stay; undo restores only moved ones',
        (tester) async {
      final h = await _pump(
        tester,
        reminders: [
          buildReminder(
            id: 'bill',
            title: 'Elektrik faturasını öde',
            remindAt: DateTime(2026, 9, 12, 18),
          ),
          buildReminder(
            id: 'pill',
            title: 'İlaç iç',
            remindAt: DateTime(2026, 9, 13, 8),
            recurrence: RecurrenceRule.daily(),
          ),
        ],
      );
      await tester.tap(find.byKey(TodayPageKeys.moveOverdue));
      await tester.pumpAndSettle();

      expect(_byId(h, 'bill').remindAt, DateTime(2026, 9, 14, 18));
      expect(_byId(h, 'pill').remindAt, DateTime(2026, 9, 13, 8));
      expect(
        find.text('“Elektrik faturasını öde” yarına alındı'),
        findsOneWidget,
      );
      // The recurring item is still overdue, so Kaçanlar stays without the
      // button (nothing left to move).
      expect(find.text('Kaçanlar'), findsOneWidget);
      expect(find.byKey(TodayPageKeys.moveOverdue), findsNothing);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'bill').remindAt, DateTime(2026, 9, 12, 18));
      expect(_byId(h, 'pill').remindAt, DateTime(2026, 9, 13, 8));
      expect(find.byKey(TodayPageKeys.moveOverdue), findsOneWidget);
    });
  });

  testWidgets('completing a recurring ribbon item advances it off the ribbon',
      (tester) async {
    _tallView(tester);
    final semantics = tester.ensureSemantics();
    final h = await _pump(
      tester,
      reminders: [
        buildReminder(
          id: 'walk',
          title: 'Yürüyüş',
          remindAt: DateTime(2026, 9, 13, 18),
          recurrence: RecurrenceRule.daily(),
        ),
      ],
    );
    final node =
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Yürüyüş,')));
    final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
          (id) => CustomSemanticsAction.getAction(id)!.label == 'Tamamla',
        );
    node.owner!.performAction(node.id, SemanticsAction.customAction, id);
    await tester.pumpAndSettle();

    final walk = _byId(h, 'walk');
    expect(walk.isDone, isFalse);
    expect(walk.remindAt, DateTime(2026, 9, 14, 18));
    // Not shown as a completed compact row; it left today's ribbon.
    expect(find.byType(ReminderCompactCard), findsNothing);
    expect(find.byKey(TimeRibbonKeys.gutter('walk')), findsNothing);
    expect(find.textContaining('Sonraki:'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(_byId(h, 'walk').remindAt, DateTime(2026, 9, 13, 18));
    expect(find.byKey(TimeRibbonKeys.gutter('walk')), findsOneWidget);
    semantics.dispose();
  });

  for (final (themeName, theme) in korThemes) {
    testWidgets(
        'text scale 2.0: no gutter or rail, time in the card, no '
        'overflow ($themeName)', (tester) async {
      _tallView(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, theme: theme);

      expect(tester.takeException(), isNull);
      for (final id in ['vitamin', 'cargo', 'ali', 'slides']) {
        expect(find.byKey(TimeRibbonKeys.gutter(id)), findsNothing);
      }
      expect(find.byKey(TimeRibbonKeys.nowLine), findsOneWidget);
      // The open card shows its own time; the compact one in its meta line.
      expect(find.text('16:00'), findsOneWidget);
      expect(
        find.textContaining('09:00', findRichText: true),
        findsOneWidget,
      );
      // Cards use the full width (no 80 px ribbon inset).
      final card = tester.getRect(
        find.ancestor(
          of: find.text("Ali'yi kurstan al"),
          matching: find.byType(ReminderCard),
        ),
      );
      expect(card.left, lessThan(40));
    });
  }
}
