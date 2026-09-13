import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../ui_harness.dart';

void main() {
  for (final (themeName, theme) in korThemes) {
    group('SettingsPage ($themeName)', () {
      testWidgets('theme segments update the stored mode', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SegmentedButton<String>), findsOneWidget);
        await tester.tap(find.text('Koyu'));
        await tester.pumpAndSettle();
        expect(h.cubit.state.settings.themeMode, AppThemeModeIds.dark);
        verify(() => h.repository.saveSettings(any())).called(1);
      });

      testWidgets('notifications use Switch.adaptive', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Switch), findsOneWidget);
        await tester.tap(find.text('Hatırlatma bildirimleri'));
        await tester.pumpAndSettle();
        expect(h.cubit.state.settings.notificationsEnabled, isFalse);
      });

      testWidgets('reset asks for confirmation first', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        final reset = find.text('Tüm verileri sıfırla');
        await tester.scrollUntilVisible(
          reset,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(find.text('Onayla'), findsOneWidget);

        await tester.tap(find.text('İptal'));
        await tester.pumpAndSettle();
        verifyNever(() => h.repository.clearAll());
      });
    });
  }
}
