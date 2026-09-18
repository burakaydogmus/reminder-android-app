import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reminder/config/app_licenses.dart';
import 'package:reminder/config/app_links.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../ui_harness.dart';

/// Records opened links; returns [result].
class _FakeOpener {
  _FakeOpener({this.result = true});

  final bool result;
  final opened = <Uri>[];

  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hatırlatıcı',
      packageName: 'com.burakaydogmus.reminder',
      version: '2.1.0',
      buildNumber: '8',
      buildSignature: '',
    );
  });

  for (final (themeName, theme) in korThemes) {
    group('SettingsPage › Diğer ($themeName)', () {
      testWidgets('Gizlilik politikası opens the policy URL', (tester) async {
        final h = await UiHarness.create();
        final opener = _FakeOpener();
        await tester.pumpWidget(
          h.app(home: SettingsPage(linkOpener: opener.call), theme: theme),
        );
        await tester.pumpAndSettle();

        final row = find.byKey(SettingsPageKeys.privacyPolicy);
        await _scrollTo(tester, row);
        expect(
          find.descendant(of: row, matching: find.text('Gizlilik politikası')),
          findsOneWidget,
        );
        await tester.tap(row);
        await tester.pumpAndSettle();

        expect(opener.opened, [AppLinks.privacyPolicy]);
        expect(find.text('Bağlantı açılamadı.'), findsNothing);
      });

      testWidgets('a failed launch shows a snackbar', (tester) async {
        final h = await UiHarness.create();
        final opener = _FakeOpener(result: false);
        await tester.pumpWidget(
          h.app(home: SettingsPage(linkOpener: opener.call), theme: theme),
        );
        await tester.pumpAndSettle();

        final row = find.byKey(SettingsPageKeys.privacyPolicy);
        await _scrollTo(tester, row);
        await tester.tap(row);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Bağlantı açılamadı.'), findsOneWidget);
      });

      testWidgets('Lisanslar opens the licence page with app info',
          (tester) async {
        final h = await UiHarness.create();
        final opener = _FakeOpener();
        await tester.pumpWidget(
          h.app(home: SettingsPage(linkOpener: opener.call), theme: theme),
        );
        await tester.pumpAndSettle();

        final row = find.byKey(SettingsPageKeys.licenses);
        await _scrollTo(tester, row);
        expect(
          find.descendant(of: row, matching: find.text('Lisanslar')),
          findsOneWidget,
        );
        await tester.tap(row);
        // The licence list loads asynchronously (spinner), so no settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(LicensePage), findsOneWidget);
        expect(find.text('Hatırlatıcı'), findsWidgets);
        expect(find.text('2.1.0'), findsOneWidget);
        expect(find.text(appLegalese), findsOneWidget);
        expect(opener.opened, isEmpty);
      });
    });
  }
}
