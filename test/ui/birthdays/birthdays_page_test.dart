import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// Sunday 13 Sep 2026.
final _now = DateTime(2026, 9, 13, 14, 32);

final _birthdays = [
  buildBirthday(id: 'deniz', name: 'Deniz Yılmaz', date: DateTime(2000, 2, 29)),
  buildBirthday(id: 'mert', name: 'Mert Kaya', date: DateTime(1999, 9, 21)),
  buildBirthday(
      id: 'zeynep', name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
  buildBirthday(
    id: 'annem',
    name: 'Annem',
    date: DateTime(1990, 10, 3),
    yearKnown: false,
  ),
];

Future<UiHarness> _pump(
  WidgetTester tester, {
  List<Birthday>? birthdays,
  ThemeData Function() theme = KorTheme.light,
}) async {
  final h = await UiHarness.create(
    birthdays: birthdays ?? _birthdays,
    now: () => _now,
  );
  await tester.pumpWidget(
    h.app(
      theme: theme,
      home: NowScope(clock: () => _now, child: const BirthdaysPage()),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

void main() {
  for (final (themeName, theme) in korThemes) {
    testWidgets('hero, month groups, year-less and 29 Şubat rows ($themeName)',
        (tester) async {
      _tallView(tester);
      final semantics = tester.ensureSemantics();
      await _pump(tester, theme: theme);

      expect(find.text('SIRADAKİ'), findsOneWidget);
      expect(find.text('Yarın · 30 yaşına giriyor'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('^Sıradaki doğum günü: Zeynep Aydın, Yarın · 30 yaşına'),
        ),
        findsOneWidget,
      );

      for (final header in ['EYLÜL', 'EKİM', 'ŞUBAT 2027']) {
        expect(find.text(header), findsOneWidget, reason: header);
      }
      expect(find.text('14 Eylül · 30 yaşına'), findsOneWidget);
      expect(find.text('Yarın'), findsOneWidget);
      expect(find.text('8 gün'), findsOneWidget);
      expect(find.text('3 Ekim · yaş bilinmiyor'), findsOneWidget);
      expect(find.text('29 Şubat · 27 yaşına'), findsOneWidget);
      expect(
        find.text("Artık yıl değil: 28 Şubat'ta hatırlatılır"),
        findsOneWidget,
      );
      // Order: Eylül rows before Ekim before Şubat.
      final ys = [
        for (final name in [
          'Zeynep Aydın',
          'Mert Kaya',
          'Annem',
          'Deniz Yılmaz'
        ])
          tester.getTopLeft(find.text(name).last).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('a birthday today shows "Bugün" in the hero', (tester) async {
    await _pump(tester, birthdays: [
      buildBirthday(name: 'Ece', date: DateTime(1990, 9, 13)),
    ]);
    expect(find.text('Bugün · 36 yaşına giriyor'), findsOneWidget);
    expect(find.text('Bugün'), findsWidgets);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, birthdays: const []);
    expect(find.text('Henüz doğum günü yok'), findsOneWidget);
    expect(find.text('SIRADAKİ'), findsNothing);
  });

  testWidgets('tapping a row opens the editor', (tester) async {
    _tallView(tester);
    await _pump(tester);
    await tester.tap(find.text('Mert Kaya'));
    await tester.pumpAndSettle();
    expect(find.text('Doğum günü düzenle'), findsOneWidget);
  });

  for (final (themeName, theme) in korThemes) {
    testWidgets('text scale 2.0 without overflow ($themeName)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, theme: theme);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
