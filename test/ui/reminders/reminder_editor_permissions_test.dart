import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

Widget _opener({DateTime? initialRemindAt}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showReminderEditorSheet(
              context,
              initialRemindAt: initialRemindAt,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

Finder get _locationSwitch => find.descendant(
      of: find.bySemanticsLabel('Konuma gelince hatırlat'),
      matching: find.byType(Switch),
    );

void main() {
  group('Reminder editor permission flows', () {
    testWidgets('turning on "Nerede" runs the two-step location flow',
        (tester) async {
      final h = await UiHarness.create();
      h.permissions
        ..snapshot = PermissionSnapshot.allGranted.copyWith(
          location: LocationPermissionState.notRequested,
        )
        ..alwaysRequestResult = LocationPermissionState.whileInUse;
      await tester.pumpWidget(h.app(home: _opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(_locationSwitch);
      await tester.tap(_locationSwitch);
      await tester.pumpAndSettle();

      // Step 1: explanation before the system prompt.
      expect(find.text('Adım 1/2'), findsOneWidget);
      expect(h.permissions.calls, isEmpty);
      await tester.tap(find.byKey(PermissionSheetKeys.confirm));
      await tester.pumpAndSettle();
      expect(h.permissions.calls, ['requestLocationWhenInUse']);

      // Step 2: "Her zaman" explanation.
      expect(find.text('Adım 2/2'), findsOneWidget);
      expect(find.text('Her zaman izin ver'), findsOneWidget);
      await tester.tap(find.byKey(PermissionSheetKeys.dismiss));
      await tester.pumpAndSettle();
      expect(h.permissions.calls, ['requestLocationWhenInUse']);

      // Inline warning: background reminders may not fire.
      expect(find.textContaining('yalnızca kullanırken'), findsOneWidget);
      expect(find.text('Düzelt'), findsOneWidget);

      // Turning it off and on again does not repeat the sheets.
      await tester.tap(_locationSwitch);
      await tester.pumpAndSettle();
      await tester.tap(_locationSwitch);
      await tester.pumpAndSettle();
      expect(find.byType(PermissionSheet), findsNothing);
    });

    testWidgets('"Şimdi değil" in step 1 asks nothing', (tester) async {
      final h = await UiHarness.create();
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        location: LocationPermissionState.notRequested,
      );
      await tester.pumpWidget(h.app(home: _opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(_locationSwitch);
      await tester.tap(_locationSwitch);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PermissionSheetKeys.dismiss));
      await tester.pumpAndSettle();

      expect(h.permissions.calls, isEmpty);
      expect(find.byType(PermissionSheet), findsNothing);
      expect(find.textContaining('Konum izni yok'), findsOneWidget);
    });

    testWidgets('granted "always" shows no sheet and no warning',
        (tester) async {
      final h = await UiHarness.create();
      await tester.pumpWidget(h.app(home: _opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(_locationSwitch);
      await tester.tap(_locationSwitch);
      await tester.pumpAndSettle();
      expect(find.byType(PermissionSheet), findsNothing);
      expect(find.text('Düzelt'), findsNothing);
    });

    testWidgets('first timed save shows the notification sheet once',
        (tester) async {
      final h = await UiHarness.create();
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        notifications: NotificationPermissionState.notRequested,
      );
      final at = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(h.app(home: _opener(initialRemindAt: at)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Fatura');
      await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
      await tester.tap(find.byKey(ReminderEditorKeys.save));
      await tester.pumpAndSettle();

      expect(find.text('Hatırlatmaları zamanında al'), findsOneWidget);
      expect(h.cubit.state.reminders, isEmpty);
      await tester.tap(find.byKey(PermissionSheetKeys.confirm));
      await tester.pumpAndSettle();

      expect(h.permissions.calls, ['requestNotifications']);
      expect(h.cubit.state.reminders.single.title, 'Fatura');
      expect(find.byKey(ReminderEditorKeys.title), findsNothing);
    });

    testWidgets('untimed save never asks for notifications', (tester) async {
      final h = await UiHarness.create();
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        notifications: NotificationPermissionState.notRequested,
      );
      await tester.pumpWidget(h.app(home: _opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Not');
      await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
      await tester.tap(find.byKey(ReminderEditorKeys.save));
      await tester.pumpAndSettle();

      expect(find.byType(PermissionSheet), findsNothing);
      expect(h.cubit.state.reminders, hasLength(1));
    });

    testWidgets('denied notifications are not re-asked on save',
        (tester) async {
      final h = await UiHarness.create(
        reminders: [buildReminder(id: 'x', title: 'Eski')],
      );
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        notifications: NotificationPermissionState.denied,
      );
      final at = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(h.app(home: _opener(initialRemindAt: at)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Yeni');
      await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
      await tester.tap(find.byKey(ReminderEditorKeys.save));
      await tester.pumpAndSettle();

      expect(find.byType(PermissionSheet), findsNothing);
      expect(h.permissions.calls, isEmpty);
      expect(h.cubit.state.reminders, hasLength(2));
    });

    testWidgets('exact alarms off: sheet with "Ayarları aç"', (tester) async {
      final h = await UiHarness.create();
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        exactAlarms: ExactAlarmState.denied,
      );
      final at = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(h.app(home: _opener(initialRemindAt: at)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Alarm');
      await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
      await tester.tap(find.byKey(ReminderEditorKeys.save));
      await tester.pumpAndSettle();

      expect(find.text('Tam zamanında hatırlatma'), findsOneWidget);
      await tester.tap(find.text('Ayarları aç'));
      await tester.pumpAndSettle();
      expect(h.permissions.calls, ['openExactAlarmSettings']);
      expect(h.cubit.state.reminders, hasLength(1));
    });
  });
}
