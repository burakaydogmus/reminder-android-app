import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/lists/smart_list_page.dart';
import 'package:reminder/ui/lists/smart_lists.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

List<Reminder> _reminders() => [
      buildReminder(
        id: 'overdue',
        title: 'Elektrik faturasını öde',
        remindAt: DateTime(2026, 9, 12, 18),
      ),
      buildReminder(
        id: 'today',
        title: "Ali'yi kurstan al",
        remindAt: DateTime(2026, 9, 13, 16),
      ),
      buildReminder(
        id: 'tomorrow',
        title: 'Kahvaltı rezervasyonu',
        remindAt: DateTime(2026, 9, 14, 9, 30),
      ),
      buildReminder(id: 'untimed', title: 'Kitabı iade et'),
      buildReminder(
        id: 'located',
        title: 'Market alışverişi',
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
      ),
      buildReminder(
        id: 'done',
        title: 'Vitamin iç',
        isDone: true,
        remindAt: DateTime(2026, 9, 13, 9),
      ),
      buildReminder(
        id: 'done-located',
        title: 'Eski konum',
        isDone: true,
        locationTriggerEnabled: true,
      ),
    ];

List<String> _ids(List<Reminder> items) => [for (final r in items) r.id];

Future<UiHarness> _openListeler(
  WidgetTester tester, {
  ThemeData Function()? theme,
  List<Reminder>? reminders,
}) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  final h = await UiHarness.create(
    reminders: reminders ?? _reminders(),
    birthdays: [buildBirthday(), buildBirthday(id: 'b2', name: 'Zeynep')],
  );
  await tester.pumpWidget(
    theme == null
        ? h.app(home: const HomeShell(clock: _clock))
        : h.app(home: const HomeShell(clock: _clock), theme: theme),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(KorPillNavigation),
      matching: find.bySemanticsLabel('Listeler'),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('SmartList (pure)', () {
    final reminders = _reminders();

    test('membership of open reminders', () {
      expect(_ids(SmartList.overdue.filter(reminders, _now)), ['overdue']);
      expect(_ids(SmartList.today.filter(reminders, _now)), ['today']);
      expect(
        _ids(SmartList.scheduled.filter(reminders, _now)),
        ['today', 'tomorrow'],
      );
      expect(
        _ids(SmartList.untimed.filter(reminders, _now)),
        ['untimed', 'located'],
      );
      expect(_ids(SmartList.located.filter(reminders, _now)), ['located']);
      expect(SmartList.birthdays.filter(reminders, _now), isEmpty);
    });

    test('due exactly now is today and scheduled, not overdue', () {
      final r = buildReminder(remindAt: _now);
      expect(SmartList.overdue.contains(r, _now), isFalse);
      expect(SmartList.today.contains(r, _now), isTrue);
      expect(SmartList.scheduled.contains(r, _now), isTrue);
    });
  });

  for (final (themeName, theme) in korThemes) {
    testWidgets(
        'bento shows 6 tiles with counts and button semantics '
        '($themeName)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _openListeler(tester, theme: theme);

      for (final label in [
        'Gecikmiş, 1 hatırlatıcı',
        'Bugün, 1 hatırlatıcı',
        'Planlı, 2 hatırlatıcı',
        'Zamansız, 2 hatırlatıcı',
        'Doğum günleri, 2 doğum günü',
        'Konumlu, 1 hatırlatıcı',
      ]) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isButton: true, label: label),
          reason: label,
        );
      }
      // Two columns, three rows.
      final overdue = tester
          .getRect(find.byKey(ListsPageKeys.smartTile(SmartList.overdue)));
      final today =
          tester.getRect(find.byKey(ListsPageKeys.smartTile(SmartList.today)));
      final scheduled = tester
          .getRect(find.byKey(ListsPageKeys.smartTile(SmartList.scheduled)));
      expect(today.top, overdue.top);
      expect(today.left, greaterThan(overdue.right));
      expect(scheduled.top, greaterThan(overdue.bottom));
      expect(overdue.height, greaterThanOrEqualTo(SmartListTile.minHeight));
      // Categories and Tamamlananlar stay below.
      expect(find.text('Kategorilerim'), findsOneWidget);
      expect(find.text('Tamamlananlar'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  }

  testWidgets('tiles open filtered lists with ReminderCard', (tester) async {
    await _openListeler(tester);

    await tester.tap(find.byKey(ListsPageKeys.smartTile(SmartList.scheduled)));
    await tester.pumpAndSettle();
    expect(find.byType(SmartListPage), findsOneWidget);
    expect(find.text('Planlı'), findsOneWidget);
    expect(find.text('2 açık'), findsOneWidget);
    expect(find.byType(ReminderCard), findsNWidgets(2));
    expect(find.text("Ali'yi kurstan al"), findsOneWidget);
    expect(find.text('Kahvaltı rezervasyonu'), findsOneWidget);
    expect(find.text('Vitamin iç'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ListsPageKeys.smartTile(SmartList.untimed)));
    await tester.pumpAndSettle();
    expect(find.text('Kitabı iade et'), findsOneWidget);
    expect(find.text('Market alışverişi'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ListsPageKeys.smartTile(SmartList.birthdays)));
    await tester.pumpAndSettle();
    expect(find.byType(BirthdaysPage), findsOneWidget);
  });

  testWidgets('empty smart list shows its empty state', (tester) async {
    await _openListeler(tester, reminders: const []);
    await tester.tap(find.byKey(ListsPageKeys.smartTile(SmartList.located)));
    await tester.pumpAndSettle();
    expect(find.text('Konumlu hatırlatma yok'), findsOneWidget);
    expect(
      find.text(
          "Bir yere varınca hatırlatmak için hatırlatıcıda 'Nerede'yi aç."),
      findsOneWidget,
    );
  });

  testWidgets('text scale 2.0: bento tiles grow without overflow',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openListeler(tester);
    expect(tester.takeException(), isNull);
    expect(
        find.byKey(ListsPageKeys.smartTile(SmartList.located)), findsOneWidget);
  });
}
