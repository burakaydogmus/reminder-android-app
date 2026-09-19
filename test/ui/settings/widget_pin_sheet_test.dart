import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/settings/widget_pin_sheet.dart';

import '../ui_harness.dart';

class _FakePinner implements HomeWidgetPinner {
  _FakePinner({this.supported = true});

  final bool supported;
  final List<ReminderHomeWidget> pinned = [];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<void> pin(ReminderHomeWidget widget) async => pinned.add(widget);
}

void main() {
  Future<void> openSheet(WidgetTester tester, _FakePinner pinner) async {
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(home: SettingsPage(widgetPinner: pinner)),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(SettingsPageKeys.pinWidget);
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('Settings describes the four widgets', (tester) async {
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(home: SettingsPage(widgetPinner: _FakePinner())),
    );
    await tester.pumpAndSettle();
    final text = find.textContaining('Dört widget var');
    await tester.scrollUntilVisible(
      text,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(text, findsOneWidget);
  });

  testWidgets('"Widget ekle" lists four widgets, Bugün first', (
    tester,
  ) async {
    final pinner = _FakePinner();
    await openSheet(tester, pinner);

    expect(find.text('Hangi widget?'), findsOneWidget);
    final tops = [
      for (final w in ReminderHomeWidget.values)
        tester.getTopLeft(find.byKey(WidgetPinSheetKeys.option(w))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(ReminderHomeWidget.values.first, ReminderHomeWidget.today);
    for (final w in ReminderHomeWidget.values) {
      expect(
        find.descendant(
          of: find.byKey(WidgetPinSheetKeys.option(w)),
          matching: find.text(w.labelIn(AppL10n.turkish)),
        ),
        findsOneWidget,
      );
    }
    expect(pinner.pinned, isEmpty);
  });

  for (final choice in ReminderHomeWidget.values) {
    testWidgets('choosing ${choice.labelIn(AppL10n.turkish)} pins its provider',
        (tester) async {
      final pinner = _FakePinner();
      await openSheet(tester, pinner);

      await tester.tap(find.byKey(WidgetPinSheetKeys.option(choice)));
      await tester.pumpAndSettle();

      expect(pinner.pinned, [choice]);
      expect(find.text('Hangi widget?'), findsNothing);
    });
  }

  testWidgets('dismissing the sheet pins nothing', (tester) async {
    final pinner = _FakePinner();
    await openSheet(tester, pinner);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Hangi widget?'), findsNothing);
    expect(pinner.pinned, isEmpty);
  });

  testWidgets('without pin support it explains the manual way', (
    tester,
  ) async {
    final pinner = _FakePinner(supported: false);
    await openSheet(tester, pinner);

    expect(find.text('Hangi widget?'), findsNothing);
    expect(find.textContaining('uzun basın'), findsOneWidget);
    expect(pinner.pinned, isEmpty);
  });

  test('providers: Liste keeps the pre-F5.1 class, all are distinct', () {
    expect(
      ReminderHomeWidget.list.qualifiedName,
      'com.burakaydogmus.reminder.ReminderListWidgetProvider',
    );
    expect(
      ReminderHomeWidget.values.map((w) => w.qualifiedName).toSet(),
      hasLength(ReminderHomeWidget.values.length),
    );
  });
}
