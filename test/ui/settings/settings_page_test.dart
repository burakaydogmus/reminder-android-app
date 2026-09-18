import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/settings/permissions_group.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../ui_harness.dart';

Finder _inRow(Key row, String text) => find.descendant(
      of: find.byKey(row),
      matching: find.text(text),
    );

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
        await tester.ensureVisible(find.text('Koyu'));
        await tester.pumpAndSettle();
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

        // Also Titreşim geri bildirimi (F4.7); both Switch.adaptive.
        expect(find.byType(Switch), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Hatırlatma bildirimleri'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Hatırlatma bildirimleri'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hatırlatma bildirimleri'));
        await tester.pumpAndSettle();
        expect(h.cubit.state.settings.notificationsEnabled, isFalse);
      });

      testWidgets('Titreşim geri bildirimi toggles the haptics setting',
          (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        final row = find.byKey(SettingsPageKeys.haptics);
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(_inRow(SettingsPageKeys.haptics, 'Titreşim geri bildirimi'),
            findsOneWidget);
        Switch toggle() => tester.widget<Switch>(
              find.descendant(of: row, matching: find.byType(Switch)),
            );
        expect(toggle().value, isTrue);

        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(toggle().value, isFalse);
        expect(await h.haptics.isEnabled(), isFalse);

        await tester
            .tap(find.descendant(of: row, matching: find.byType(Switch)));
        await tester.pumpAndSettle();
        expect(toggle().value, isTrue);
        expect(await h.haptics.isEnabled(), isTrue);
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
        await tester.ensureVisible(reset);
        await tester.pumpAndSettle();
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(find.text('Onayla'), findsOneWidget);

        await tester.tap(find.text('İptal'));
        await tester.pumpAndSettle();
        verifyNever(() => h.repository.clearAll());
      });

      testWidgets('İzinler shows all granted without actions', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(find.text('İzinler'), findsOneWidget);
        expect(
          _inRow(PermissionsGroupKeys.notifications, 'Açık'),
          findsOneWidget,
        );
        expect(
          _inRow(PermissionsGroupKeys.location, 'Her zaman'),
          findsOneWidget,
        );
        expect(
          _inRow(PermissionsGroupKeys.exactAlarms, 'Açık'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(PermissionsGroup),
            matching: find.byType(TextButton),
          ),
          findsNothing,
        );
      });

      testWidgets('İzinler shows problems with fix actions', (tester) async {
        final h = await UiHarness.create();
        h.permissions.snapshot = const PermissionSnapshot(
          notifications: NotificationPermissionState.denied,
          exactAlarms: ExactAlarmState.denied,
          location: LocationPermissionState.whileInUse,
        );
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(
          _inRow(
            PermissionsGroupKeys.location,
            'Yalnızca kullanırken — arka plan hatırlatmaları çalışmaz',
          ),
          findsOneWidget,
        );
        expect(
          _inRow(
            PermissionsGroupKeys.notifications,
            'Kapalı — hatırlatmalar zamanında gelmez',
          ),
          findsOneWidget,
        );
        expect(
          _inRow(PermissionsGroupKeys.exactAlarms, 'Ayarları aç'),
          findsOneWidget,
        );

        await tester
            .tap(_inRow(PermissionsGroupKeys.notifications, 'Ayarları aç'));
        await tester.pumpAndSettle();
        expect(h.permissions.calls, contains('openNotificationSettings'));
        expect(h.permissions.calls, isNot(contains('requestNotifications')));

        await tester.tap(_inRow(PermissionsGroupKeys.location, 'Düzelt'));
        await tester.pumpAndSettle();
        expect(h.permissions.calls, contains('requestLocationAlways'));
        // The fake grants "always": the status updates in place.
        expect(
          _inRow(PermissionsGroupKeys.location, 'Her zaman'),
          findsOneWidget,
        );

        await tester
            .tap(_inRow(PermissionsGroupKeys.exactAlarms, 'Ayarları aç'));
        await tester.pumpAndSettle();
        expect(h.permissions.calls, contains('openExactAlarmSettings'));
      });

      testWidgets('not yet requested offers "İzin ver"', (tester) async {
        final h = await UiHarness.create();
        h.permissions.snapshot = const PermissionSnapshot(
          notifications: NotificationPermissionState.notRequested,
          exactAlarms: ExactAlarmState.notRequired,
          location: LocationPermissionState.denied,
        );
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(PermissionsGroupKeys.exactAlarms), findsNothing);
        expect(
          _inRow(PermissionsGroupKeys.location, 'Ayarları aç'),
          findsOneWidget,
        );
        await tester
            .tap(_inRow(PermissionsGroupKeys.notifications, 'İzin ver'));
        await tester.pumpAndSettle();
        expect(h.permissions.calls, ['requestNotifications']);
        expect(
          _inRow(PermissionsGroupKeys.notifications, 'Açık'),
          findsOneWidget,
        );
      });

      testWidgets('status is re-checked when the app resumes', (tester) async {
        final h = await UiHarness.create();
        h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
          location: LocationPermissionState.whileInUse,
        );
        await tester.pumpWidget(
          h.app(home: const SettingsPage(), theme: theme),
        );
        await tester.pumpAndSettle();
        expect(_inRow(PermissionsGroupKeys.location, 'Düzelt'), findsOneWidget);

        // User granted "Her zaman" in system settings and came back.
        h.permissions.snapshot = PermissionSnapshot.allGranted;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(
          _inRow(PermissionsGroupKeys.location, 'Her zaman'),
          findsOneWidget,
        );
      });
    });
  }
}
