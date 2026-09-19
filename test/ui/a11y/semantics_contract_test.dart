import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../ui_harness.dart';
import 'a11y_sample_data.dart';

/// F4.5: §3.6 rules the guidelines cannot see — state in semantics
/// (selected / checked), colour never the only signal, one node per card
/// with the drag/swipe alternatives as custom actions, Turkish time labels.

Finder _card(String title) => find.byWidgetPredicate(
      (w) => w is ReminderCard && w.reminder.title == title,
    );

List<String> _actions(WidgetTester tester, Finder finder) {
  final data = tester
      .getSemantics(
        find.descendant(of: finder, matching: find.byType(Semantics)).first,
      )
      .getSemanticsData();
  return [
    for (final id in data.customSemanticsActionIds ?? const <int>[])
      CustomSemanticsAction.getAction(id)!.label!,
  ];
}

Future<void> _pumpCard(
  WidgetTester tester,
  String id, {
  double textScale = 1,
}) async {
  final reminder = auditReminders().firstWhere((r) => r.id == id);
  final h = await UiHarness.create(reminders: [reminder], now: auditClock);
  await tester.pumpWidget(
    h.app(
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: NowScope(
          clock: auditClock,
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [ReminderCard(reminder: reminder, now: auditNow)],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('overdue card: one node, Turkish time, text + icon, actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, 'overdue');

    final card = _card('Elektrik faturasını öde');
    expect(
      tester.getSemantics(
        find.descendant(of: card, matching: find.byType(Semantics)).first,
      ),
      isSemantics(
        label:
            'Elektrik faturasını öde, Ev İşleri, 11 Eyl saat 09:15, gecikti, '
            'tamamlanmadı',
      ),
    );
    // Colour is not the only overdue signal: "Gecikti" is written.
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Gecikti', findRichText: true),
      ),
      findsOneWidget,
    );
    // WCAG 2.5.7: every swipe / long-press action has a semantics twin.
    expect(
      _actions(tester, card),
      ['Tamamla', 'Ertele', 'Sabitle', 'Düzenle', 'Sil'],
    );
    semantics.dispose();
  });

  testWidgets('priority and pin are written, not only coloured',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, 'pinned');

    final card = _card("Ali'yi kurstan al");
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('!!! Yüksek', findRichText: true),
      ),
      findsOneWidget,
    );
    final label = tester
        .getSemantics(
          find.descendant(of: card, matching: find.byType(Semantics)).first,
        )
        .label;
    expect(label, contains('sabitlendi'));
    expect(label, contains('Yüksek öncelik'));
    expect(_actions(tester, card), contains('Sabitlemeyi kaldır'));
    semantics.dispose();
  });

  testWidgets('at 200 % the card time moves under the title', (tester) async {
    await _pumpCard(tester, 'overdue', textScale: 2);

    final title = tester.getRect(
      find.textContaining('Elektrik', findRichText: true),
    );
    final time = tester.getRect(find.text('11 Eyl 09:15'));
    expect(time.top, greaterThanOrEqualTo(title.bottom));
    expect(tester.takeException(), isNull);

    await _pumpCard(tester, 'overdue');
    final wideTime = tester.getRect(find.text('11 Eyl 09:15'));
    final wideTitle = tester.getRect(
      find.textContaining('Elektrik', findRichText: true),
    );
    expect(wideTime.left, greaterThan(wideTitle.right));
  });

  testWidgets('Android nav marks only the current tab as selected',
      (tester) async {
    final semantics = tester.ensureSemantics();
    // Phone width, laid out like HomeShell (nav + gap + 64 dp FAB).
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Flexible(
                  child: Align(
                    heightFactor: 1,
                    alignment: AlignmentDirectional.centerStart,
                    child: KorPillNavigation(
                      selectedIndex: 1,
                      onSelected: (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: 12, height: 64),
                const SizedBox(width: 64, height: 64),
              ],
            ),
          ),
        ),
      ),
    );
    for (final (label, selected) in [
      ('Bugün', false),
      ('Takvim', true),
      ('Listeler', false),
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasSelectedState: true,
          isSelected: selected,
        ),
        reason: label,
      );
    }
    // The selected label is fully visible on a phone-width bar.
    final text = tester.renderObject<RenderParagraph>(find.text('Takvim'));
    expect(text.didExceedMaxLines, isFalse);
    expect(text.size.width, greaterThan(40));
    semantics.dispose();
  });

  testWidgets('calendar filters and days expose their selected state',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await UiHarness.create(
      reminders: auditReminders(),
      now: auditClock,
    );
    await tester.pumpWidget(
      h.app(
        home: const NowScope(
          clock: auditClock,
          child: Scaffold(body: CalendarPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final f in CalendarFilter.values) {
      expect(
        tester.getSemantics(find.byKey(CalendarPageKeys.filter(f))),
        isSemantics(
          isSelected: f == CalendarFilter.all,
          hasSelectedState: true,
        ),
        reason: f.name,
      );
    }
    semantics.dispose();
  });

  testWidgets('category swatches say their colour and selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(
        home: auditOpener((context) => showCategoryEditorSheet(context)),
      ),
    );
    await tapAuditOpener(tester);

    final selected = KorColorKey.values.where(
      (k) => isSemantics(isSelected: true).matches(
        tester.getSemantics(find.byKey(CategoryEditorKeys.swatch(k))),
        {},
      ),
    );
    expect(selected, hasLength(1));
    expect(
      tester
          .getSemantics(find.byKey(CategoryEditorKeys.swatch(selected.first))),
      isSemantics(isSelected: true, hasSelectedState: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('SectionHeader puts a long action under the title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: Scaffold(
            body: SizedBox(
              width: 300,
              child: SectionHeader(
                title: 'Zaman çizelgesi',
                icon: Icons.schedule_rounded,
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Tamamlananları gizle'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text('Zaman çizelgesi'));
    final action = tester.getRect(find.text('Tamamlananları gizle'));
    expect(action.top, greaterThanOrEqualTo(title.bottom));
    // The title keeps its width (it is not squeezed to a column).
    expect(title.width, greaterThan(100));
  });
}
