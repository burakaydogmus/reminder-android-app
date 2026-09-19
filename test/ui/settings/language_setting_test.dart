import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../onboarding/onboarding_test_utils.dart';
import '../ui_harness.dart';

/// F6.1: Ayarlar › Görünüm › Dil.
void main() {
  Future<void> showLanguageRow(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(SettingsPageKeys.language));
    await tester.pumpAndSettle();
  }

  testWidgets('switching to English relabels the app and persists',
      (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    final changes = <AppLanguage>[];
    await tester.pumpWidget(
      h.app(home: const SettingsPage(), onLanguageChanged: changes.add),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);

    await showLanguageRow(tester);
    expect(find.text('Dil'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // The page header scrolled away; the rows around the segments show it.
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Dil'), findsNothing);
    expect(await h.languageStore.load(), AppLanguage.english);
    expect(changes, [AppLanguage.english]);

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();
    expect(find.text('Dil'), findsOneWidget);
    expect(await h.languageStore.load(), AppLanguage.turkish);
    expect(changes, [AppLanguage.english, AppLanguage.turkish]);
  });

  testWidgets('Sistem is stored as "system" and follows the device',
      (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(home: const SettingsPage(), language: AppLanguage.english),
    );
    await tester.pumpAndSettle();
    await showLanguageRow(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(SettingsPageKeys.language),
        matching: find.text('System'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await h.languageStore.load(), AppLanguage.system);
    // The harness device is Turkish.
    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('Sistem'), findsWidgets);
  });

  testWidgets('the selected segment reflects the current choice',
      (tester) async {
    usePhoneSurface(tester);
    final h = await UiHarness.create();
    await tester.pumpWidget(
      h.app(home: const SettingsPage(), language: AppLanguage.english),
    );
    await tester.pumpAndSettle();
    await showLanguageRow(tester);

    final button = tester.widget<SegmentedButton<AppLanguage>>(
      find.byKey(SettingsPageKeys.language),
    );
    expect(button.selected, {AppLanguage.english});
  });
}
