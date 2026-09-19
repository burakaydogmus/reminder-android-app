import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/calendar/agenda_rows.dart';
import 'package:reminder/ui/components/kor_checkbox.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/today/today_sections.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Priority and pinning in the UI (F3.4): editor top-bar pin and "Öncelik"
/// segments, card markers + ring, semantics and long-press actions.

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

Widget _opener({Reminder? existing}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showReminderEditorSheet(
              context,
              existing: existing,
              now: _clock,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
  await tester.tap(find.byKey(ReminderEditorKeys.save));
  await tester.pumpAndSettle();
}

Future<void> _pickPriority(WidgetTester tester, String label) async {
  final segment = find.descendant(
    of: find.byKey(ReminderEditorKeys.priority),
    matching: find.text(label),
  );
  await tester.ensureVisible(segment);
  await tester.tap(segment);
  await tester.pumpAndSettle();
}

Set<int> _selectedPriority(WidgetTester tester) => tester
    .widget<SegmentedButton<int>>(find.byKey(ReminderEditorKeys.priority))
    .selected;

Reminder _byId(UiHarness h, String id) =>
    h.cubit.state.reminders.firstWhere((r) => r.id == id);

SemanticsNode _node(WidgetTester tester, String title) => tester
    .getSemantics(find.bySemanticsLabel(RegExp('^${RegExp.escape(title)},')));

List<String> _actions(SemanticsNode node) => [
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label ?? '',
    ];

void _perform(SemanticsNode node, String label) {
  final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
        (id) => CustomSemanticsAction.getAction(id)!.label == label,
      );
  node.owner!.performAction(node.id, SemanticsAction.customAction, id);
}

/// A title inside a [ReminderCard] (not the snackbar quoting it).
Finder _inCard(String title) => find.descendant(
      of: find.byType(ReminderCard),
      matching: find.textContaining(title, findRichText: true),
    );

/// The priority ring passed to the card's [KorCheckbox] (`null` = none).
BorderSide? _checkboxRing(WidgetTester tester, String title) => tester
    .widget<KorCheckbox>(
      find.descendant(
        of: find.ancestor(
          of: find.textContaining(title, findRichText: true),
          matching: find.byType(ReminderCard),
        ),
        matching: find.byType(KorCheckbox),
      ),
    )
    .ring;

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Editor pin and priority ($themeName)', () {
      testWidgets('new reminder: pin + Yüksek are saved', (tester) async {
        final h = await UiHarness.create(now: _clock);
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Öncelik'), findsOneWidget);
        expect(_selectedPriority(tester), {ReminderPriority.none});
        expect(find.byTooltip('Sabitle'), findsOneWidget);

        await tester.enterText(
          find.byKey(ReminderEditorKeys.title),
          'Faturayı öde',
        );
        await tester.tap(find.byKey(ReminderEditorKeys.pin));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Sabitlemeyi kaldır'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(find.byKey(ReminderEditorKeys.pin))
              .isSelected,
          isTrue,
        );

        await _pickPriority(tester, 'Yüksek');
        expect(_selectedPriority(tester), {ReminderPriority.high});
        await _tapSave(tester);

        final saved = h.cubit.state.reminders.single;
        expect(saved.title, 'Faturayı öde');
        expect(saved.pinned, isTrue);
        expect(saved.priority, ReminderPriority.high);
      });

      testWidgets('existing reminder: shows and clears both', (tester) async {
        final existing = buildReminder(
          id: 'r1',
          title: 'Sunum',
          priority: ReminderPriority.medium,
          pinned: true,
        );
        final h = await UiHarness.create(reminders: [existing], now: _clock);
        await tester.pumpWidget(
          h.app(home: _opener(existing: existing), theme: theme),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(_selectedPriority(tester), {ReminderPriority.medium});
        expect(find.byTooltip('Sabitlemeyi kaldır'), findsOneWidget);

        await tester.tap(find.byKey(ReminderEditorKeys.pin));
        await tester.pumpAndSettle();
        await _pickPriority(tester, 'Yok');
        await _tapSave(tester);

        final saved = _byId(h, 'r1');
        expect(saved.pinned, isFalse);
        expect(saved.priority, ReminderPriority.none);
      });
    });

    group('Card markers ($themeName)', () {
      testWidgets('pinned high: pin icon, "!!! Yüksek", 2.5 px primary ring',
          (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(
              id: 'bill',
              title: 'Elektrik faturası',
              priority: ReminderPriority.high,
              pinned: true,
            ),
            buildReminder(id: 'plain', title: 'Kitap iade'),
          ],
          now: _clock,
        );
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  ReminderCard(reminder: _byId(h, 'bill'), now: _now),
                  ReminderCard(reminder: _byId(h, 'plain'), now: _now),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scheme =
            Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
        expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
        expect(
          find.textContaining('!!! Yüksek', findRichText: true),
          findsOneWidget,
        );
        final ring = _checkboxRing(tester, 'Elektrik faturası')!;
        expect(ring.width, 2.5);
        expect(ring.color, scheme.primary);

        expect(_checkboxRing(tester, 'Kitap iade'), isNull);
        expect(find.textContaining('!', findRichText: true), findsOneWidget);
      });

      testWidgets('low and medium: text marker without the ring',
          (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(id: 'low', title: 'Düşük iş', priority: 1),
            buildReminder(id: 'mid', title: 'Orta iş', priority: 2),
          ],
          now: _clock,
        );
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  ReminderCard(reminder: _byId(h, 'low'), now: _now),
                  ReminderCard(reminder: _byId(h, 'mid'), now: _now),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('! Düşük', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('!! Orta', findRichText: true),
          findsOneWidget,
        );
        expect(_checkboxRing(tester, 'Düşük iş'), isNull);
        expect(_checkboxRing(tester, 'Orta iş'), isNull);
        expect(find.byIcon(Icons.push_pin_rounded), findsNothing);
      });

      testWidgets('done high-priority card has no ring', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(
              id: 'd',
              title: 'Bitti',
              isDone: true,
              priority: ReminderPriority.high,
            ),
          ],
          now: _clock,
        );
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: Scaffold(
              body: ReminderCard(reminder: _byId(h, 'd'), now: _now),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_checkboxRing(tester, 'Bitti'), isNull);
      });

      testWidgets('compact row: pin icon and trailing marker', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(
              id: 'c',
              title: 'Sunum slaytları',
              priority: ReminderPriority.medium,
              pinned: true,
            ),
          ],
          now: _clock,
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: Scaffold(
              body: ReminderCompactCard(reminder: _byId(h, 'c'), now: _now),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
        expect(find.text('!!'), findsOneWidget);
        final node = _node(tester, 'Sunum slaytları');
        expect(node.label, contains('sabitlendi, Orta öncelik'));
        expect(_actions(node), contains('Sabitlemeyi kaldır'));
        expect(
            tester.widget<KorCheckbox>(find.byType(KorCheckbox)).ring, isNull);
        semantics.dispose();
      });

      testWidgets('compact row: high priority gets the ring', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(
              id: 'c',
              title: 'Fatura',
              priority: ReminderPriority.high,
            ),
          ],
          now: _clock,
        );
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: Scaffold(
              body: ReminderCompactCard(reminder: _byId(h, 'c'), now: _now),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scheme =
            Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
        final ring = tester.widget<KorCheckbox>(find.byType(KorCheckbox)).ring;
        expect(ring?.width, 2.5);
        expect(ring?.color, scheme.primary);
        expect(find.text('!!!'), findsOneWidget);
      });
    });
  }

  group('Card semantics and actions', () {
    testWidgets('label and Sabitle custom action with undo', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await UiHarness.create(
        reminders: [
          buildReminder(
            id: 'r',
            title: 'Faturayı öde',
            priority: ReminderPriority.high,
          ),
        ],
        now: _clock,
      );
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: Builder(
              builder: (context) => ReminderCard(
                reminder: _byId(h, 'r'),
                now: _now,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var node = _node(tester, 'Faturayı öde');
      expect(node.label, contains('Yüksek öncelik'));
      expect(node.label, isNot(contains('sabitlendi')));
      expect(
        _actions(node),
        ['Tamamla', 'Ertele', 'Sabitle', 'Düzenle', 'Sil'],
      );

      _perform(node, 'Sabitle');
      await tester.pumpAndSettle();
      expect(_byId(h, 'r').pinned, isTrue);
      expect(find.text('“Faturayı öde” sabitlendi'), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'r').pinned, isFalse);

      // A card built from the pinned state offers "Sabitlemeyi kaldır".
      await h.cubit.updateReminder(_byId(h, 'r').copyWith(pinned: true));
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: ReminderCard(reminder: _byId(h, 'r'), now: _now),
          ),
        ),
      );
      await tester.pumpAndSettle();
      node = _node(tester, 'Faturayı öde');
      expect(node.label, contains('sabitlendi, Yüksek öncelik'));
      _perform(node, 'Sabitlemeyi kaldır');
      await tester.pumpAndSettle();
      expect(_byId(h, 'r').pinned, isFalse);
      expect(
        find.text('“Faturayı öde” sabitlemesi kaldırıldı'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('long-press menu Sabitle moves the item to the top',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final h = await UiHarness.create(
        reminders: [
          buildReminder(
            id: 'new',
            title: 'Yeni not',
            createdAt: DateTime(2026, 9, 10),
          ),
          buildReminder(
            id: 'old',
            title: 'Eski not',
            createdAt: DateTime(2026, 9, 1),
          ),
        ],
        now: _clock,
      );
      await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
      await tester.pumpAndSettle();

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      expect(top('Yeni not'), lessThan(top('Eski not')));

      await tester.longPress(find.text('Eski not'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabitle'));
      await tester.pumpAndSettle();

      expect(_byId(h, 'old').pinned, isTrue);
      expect(
        h.cubit.state.reminders.map((r) => r.id).toList(),
        ['old', 'new'],
      );
      expect(
        tester.getTopLeft(_inCard('Eski not')).dy,
        lessThan(top('Yeni not')),
      );

      await tester.longPress(
        _inCard('Eski not'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sabitlemeyi kaldır'), findsOneWidget);
    });

    testWidgets('calendar agenda row: label and Sabitle action',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final at = DateTime(2026, 9, 13, 16);
      final h = await UiHarness.create(
        reminders: [
          buildReminder(
            id: 'slides',
            title: 'Sunum slaytları',
            remindAt: at,
            priority: ReminderPriority.low,
          ),
        ],
        now: _clock,
      );
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: AgendaReminderRow(
              occurrence: ReminderOccurrence(
                reminder: _byId(h, 'slides'),
                at: at,
              ),
              now: _now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.byKey(AgendaRowKeys.reminder('slides')),
      );
      expect(node.label, contains('Düşük öncelik'));
      expect(_actions(node), contains('Sabitle'));
      _perform(node, 'Sabitle');
      await tester.pumpAndSettle();
      expect(_byId(h, 'slides').pinned, isTrue);
      semantics.dispose();
    });
  });

  group('Bugün ribbon keeps time order', () {
    test('a pinned later item does not jump ahead on the ribbon', () {
      final sections = TodaySections.from(
        reminders: [
          buildReminder(
            id: 'late-pinned',
            pinned: true,
            priority: 3,
            remindAt: DateTime(2026, 9, 13, 20),
          ),
          buildReminder(id: 'early', remindAt: DateTime(2026, 9, 13, 16)),
          buildReminder(
            id: 'early-high',
            priority: 3,
            remindAt: DateTime(2026, 9, 13, 16),
          ),
        ],
        birthdays: const [],
        now: _now,
      );
      final ribbon = [
        for (final e in sections.timeline(now: _now))
          if (e is TimelineReminder) e.reminder.id,
      ];
      expect(ribbon, ['early-high', 'early', 'late-pinned']);
    });
  });
}
