import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/calendar/agenda_rows.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/calendar/week_strip.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday (last day of its Mon-first week).
final _sunday = DateTime(2026, 9, 13, 14, 32);

final _reminders = [
  buildReminder(
    id: 'slides',
    title: 'Sunum slaytları',
    categoryId: ReminderCategoryIds.work,
    remindAt: DateTime(2026, 9, 13, 16),
  ),
  buildReminder(
    id: 'breakfast',
    title: 'Kahvaltı rezervasyonu',
    categoryId: ReminderCategoryIds.errands,
    remindAt: DateTime(2026, 9, 14, 9, 30),
  ),
  buildReminder(
    id: 'meeting',
    title: 'Haftalık ekip toplantısı',
    categoryId: ReminderCategoryIds.work,
    remindAt: DateTime(2026, 9, 14, 8, 45),
    recurrence: RecurrenceRule.weekly([DateTime.monday]),
  ),
  buildReminder(
    id: 'market',
    title: 'Market alışverişi',
    categoryId: ReminderCategoryIds.market,
    remindAt: DateTime(2026, 9, 15, 18, 30),
    locationTriggerEnabled: true,
    locationLatitude: 41,
    locationLongitude: 29,
  ),
];

final _birthdays = [
  buildBirthday(name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
];

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

Future<UiHarness> _pump(
  WidgetTester tester, {
  DateTime? now,
  List<Reminder>? reminders,
  ThemeData Function() theme = KorTheme.light,
}) async {
  final clock = now ?? _sunday;
  final h = await UiHarness.create(
    reminders: reminders ?? _reminders,
    birthdays: _birthdays,
    now: () => clock,
  );
  await tester.pumpWidget(
    h.app(
      theme: theme,
      home: NowScope(
        clock: () => clock,
        child: const Scaffold(body: CalendarPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

Finder _day(DateTime d) => find.byKey(CalendarStripKeys.day(d));

List<KorColorKey> _dots(WidgetTester tester, DateTime d) => tester
    .widget<CategoryDots>(
      find.descendant(of: _day(d), matching: find.byType(CategoryDots)),
    )
    .keys;

Reminder _byId(UiHarness h, String id) =>
    h.cubit.state.reminders.firstWhere((r) => r.id == id);

List<String> _customActionLabels(SemanticsNode node) => [
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ?? const <int>[])
        CustomSemanticsAction.getAction(id)!.label ?? '',
    ];

void main() {
  for (final (themeName, theme) in korThemes) {
    testWidgets('week strip, dots and agenda ($themeName)', (tester) async {
      _tallView(tester);
      final semantics = tester.ensureSemantics();
      await _pump(tester, theme: theme);

      expect(find.text('Eylül 2026'), findsOneWidget);
      // Monday first: Pzt 7 … Paz 13.
      final xs = [
        for (var d = 7; d <= 13; d++)
          tester.getCenter(_day(DateTime(2026, 9, d))).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(find.text('Pzt'), findsOneWidget);
      expect(find.text('Paz'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pazar 13 Eylül, bugün, planlı kayıt var'),
        findsOneWidget,
      );
      expect(_dots(tester, DateTime(2026, 9, 13)), [KorColorKey.is_]);
      expect(_dots(tester, DateTime(2026, 9, 12)), isEmpty);

      // Sticky Turkish headers, birthday as all-day row, empty days.
      expect(find.text('BUGÜN · PAZAR 13 EYLÜL'), findsOneWidget);
      expect(find.text('YARIN · PAZARTESİ 14 EYLÜL'), findsOneWidget);
      expect(find.text('Zeynep Aydın'), findsOneWidget);
      expect(find.text('16 Eylül — boş gün'), findsOneWidget);
      // The weekly meeting: stored row on 14, read-only occurrence on 21.
      expect(find.byKey(AgendaRowKeys.reminder('meeting')), findsOneWidget);
      expect(
        find.byKey(AgendaRowKeys.occurrence(
          'meeting',
          DateTime(2026, 9, 21, 8, 45),
        )),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('swipe to the next week, Bugün jumps back', (tester) async {
    _tallView(tester);
    await _pump(tester);

    await tester.fling(
      find.byKey(CalendarStripKeys.strip),
      const Offset(-400, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(_day(DateTime(2026, 9, 13)), findsNothing);
    expect(_dots(tester, DateTime(2026, 9, 14)), [
      KorColorKey.dogumGunu,
      KorColorKey.is_,
      KorColorKey.gunluk,
    ]);

    await tester.tap(find.byKey(CalendarPageKeys.today));
    await tester.pumpAndSettle();
    expect(_day(DateTime(2026, 9, 13)), findsOneWidget);
  });

  testWidgets('chevrons page weeks; month label follows the week',
      (tester) async {
    _tallView(tester);
    await _pump(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(CalendarPageKeys.next));
      await tester.pumpAndSettle();
    }
    // Week of Mon 5 Oct.
    expect(_day(DateTime(2026, 10, 5)), findsOneWidget);
    expect(find.text('Ekim 2026'), findsOneWidget);
    await tester.tap(find.byKey(CalendarPageKeys.previous));
    await tester.pumpAndSettle();
    expect(_day(DateTime(2026, 9, 28)), findsOneWidget);
  });

  testWidgets('month grid: tap a day starts the agenda there and collapses',
      (tester) async {
    _tallView(tester);
    await _pump(tester);

    await tester.tap(find.byKey(CalendarPageKeys.toggleMonth));
    await tester.pumpAndSettle();
    expect(find.byKey(CalendarStripKeys.grid), findsOneWidget);
    expect(find.byKey(CalendarStripKeys.strip), findsNothing);
    // 6×7 cells from Mon 31 Aug to Sun 11 Oct.
    expect(_day(DateTime(2026, 8, 31)), findsOneWidget);
    expect(_day(DateTime(2026, 10, 11)), findsOneWidget);
    expect(_dots(tester, DateTime(2026, 9, 21)), [KorColorKey.is_]);

    await tester.tap(find.byKey(CalendarPageKeys.next));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsOneWidget);
    await tester.tap(find.byKey(CalendarPageKeys.previous));
    await tester.pumpAndSettle();

    await tester.tap(_day(DateTime(2026, 9, 24)));
    await tester.pumpAndSettle();
    expect(find.byKey(CalendarStripKeys.grid), findsNothing);
    expect(find.byKey(CalendarStripKeys.strip), findsOneWidget);
    expect(find.text('24 Eylül — boş gün'), findsOneWidget);
    expect(find.text('BUGÜN · PAZAR 13 EYLÜL'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('^Perşembe 24 Eylül')),
      findsOneWidget,
    );

    // Pull down on the handle opens the grid again.
    await tester.fling(
      find.byKey(CalendarStripKeys.handle),
      const Offset(0, 200),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(CalendarStripKeys.grid), findsOneWidget);
  });

  testWidgets('filter chips', (tester) async {
    _tallView(tester);
    await _pump(tester);

    await tester
        .tap(find.byKey(CalendarPageKeys.filter(CalendarFilter.birthdays)));
    await tester.pumpAndSettle();
    expect(find.text('Zeynep Aydın'), findsOneWidget);
    expect(find.text('Sunum slaytları'), findsNothing);
    expect(_dots(tester, DateTime(2026, 9, 13)), isEmpty);

    await tester
        .tap(find.byKey(CalendarPageKeys.filter(CalendarFilter.located)));
    await tester.pumpAndSettle();
    expect(find.text('Market alışverişi'), findsOneWidget);
    expect(find.text('Sunum slaytları'), findsNothing);
    expect(find.text('Zeynep Aydın'), findsNothing);

    await tester
        .tap(find.byKey(CalendarPageKeys.filter(CalendarFilter.reminders)));
    await tester.pumpAndSettle();
    expect(find.text('Sunum slaytları'), findsOneWidget);
    expect(find.text('Zeynep Aydın'), findsNothing);
  });

  testWidgets('empty day opens the editor preset to that day', (tester) async {
    _tallView(tester);
    await _pump(tester);

    await tester.tap(find.text('16 Eylül — boş gün'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
    expect(find.text('16 Eyl'), findsWidgets);
    expect(find.text('09:00'), findsWidgets);
  });

  testWidgets('empty agenda shows the empty state', (tester) async {
    final h = await UiHarness.create(now: () => _sunday);
    await tester.pumpWidget(h.app(
      home: NowScope(
        clock: () => _sunday,
        child: const Scaffold(body: CalendarPage()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Yaklaşan bir şey yok'), findsOneWidget);
  });

  group('reschedule (Tuesday 15 Sep, 10:00)', () {
    final tuesday = DateTime(2026, 9, 15, 10);
    final slides = buildReminder(
      id: 'slides',
      title: 'Sunum slaytları',
      categoryId: ReminderCategoryIds.work,
      remindAt: DateTime(2026, 9, 15, 16),
    );

    testWidgets('drag onto a strip day keeps the time; Geri al restores',
        (tester) async {
      _tallView(tester);
      final h = await _pump(tester, now: tuesday, reminders: [slides]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Sunum slaytları')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(_day(DateTime(2026, 9, 17))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_byId(h, 'slides').remindAt, DateTime(2026, 9, 17, 16));
      expect(
        find.text('“Sunum slaytları” taşındı · Per 17 Eyl 16:00'),
        findsOneWidget,
      );
      expect(_dots(tester, DateTime(2026, 9, 17)), [KorColorKey.is_]);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'slides').remindAt, DateTime(2026, 9, 15, 16));
    });

    testWidgets('a past day does not accept the drop', (tester) async {
      _tallView(tester);
      final h = await _pump(tester, now: tuesday, reminders: [slides]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Sunum slaytları')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(_day(DateTime(2026, 9, 14))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_byId(h, 'slides').remindAt, DateTime(2026, 9, 15, 16));
    });

    testWidgets('recurring series moves as a whole', (tester) async {
      _tallView(tester);
      final weekly = slides.copyWith(
        recurrence: RecurrenceRule.weekly([DateTime.tuesday]),
      );
      final h = await _pump(tester, now: tuesday, reminders: [weekly]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(AgendaRowKeys.reminder('slides'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(_day(DateTime(2026, 9, 18))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final moved = _byId(h, 'slides');
      expect(moved.remindAt, DateTime(2026, 9, 18, 16));
      expect(moved.recurrence, RecurrenceRule.weekly([DateTime.friday]));

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'slides').recurrence,
          RecurrenceRule.weekly([DateTime.tuesday]));
    });

    testWidgets('long-press menu › Taşı… picks a day', (tester) async {
      _tallView(tester);
      final h = await _pump(tester, now: tuesday, reminders: [slides]);

      await tester.longPress(find.text('Sunum slaytları'));
      await tester.pumpAndSettle();
      expect(find.text('Tamamla'), findsOneWidget);
      await tester.tap(find.text('Taşı…'));
      await tester.pumpAndSettle();

      final dialog = find.byType(DatePickerDialog);
      expect(dialog, findsOneWidget);
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('18')),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.descendant(of: dialog, matching: find.text('Taşı')));
      await tester.pumpAndSettle();

      expect(_byId(h, 'slides').remindAt, DateTime(2026, 9, 18, 16));
      expect(find.text('Geri al'), findsOneWidget);
    });

    testWidgets('semantics: one node with a Taşı… custom action',
        (tester) async {
      _tallView(tester);
      final semantics = tester.ensureSemantics();
      await _pump(tester, now: tuesday, reminders: [slides]);

      final node = tester.getSemantics(
        find.byKey(AgendaRowKeys.reminder('slides')),
      );
      expect(node.label, startsWith('Sunum slaytları, İş, Bugün saat 16:00'));
      expect(
        _customActionLabels(node),
        containsAll(['Tamamla', 'Ertele', 'Düzenle', 'Taşı…', 'Sil']),
      );
      final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
            (id) => CustomSemanticsAction.getAction(id)!.label == 'Taşı…',
          );
      node.owner!.performAction(node.id, SemanticsAction.customAction, id);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      semantics.dispose();
    });
  });

  for (final (themeName, theme) in korThemes) {
    testWidgets('text scale 2.0: no overflow, strip and grid ($themeName)',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, theme: theme);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(CalendarPageKeys.toggleMonth));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
