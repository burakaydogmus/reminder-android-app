import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/permissions/permission_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

Widget _opener({Birthday? existing}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showBirthdayEditorSheet(context, existing: existing),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  for (final (themeName, theme) in korThemes) {
    testWidgets(
        'new birthday: name focused, empty name inline error '
        '($themeName)', (tester) async {
      final h = await UiHarness.create();
      await tester.pumpWidget(h.app(home: _opener(), theme: theme));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final name = find.byKey(BirthdayEditorKeys.name);
      final editable = tester.widget<EditableText>(
        find.descendant(of: name, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.ensureVisible(find.byKey(BirthdayEditorKeys.save));
      await tester.tap(find.byKey(BirthdayEditorKeys.save));
      await tester.pumpAndSettle();
      expect(find.text('İsim boş olamaz.'), findsOneWidget);
      expect(h.cubit.state.birthdays, isEmpty);
    });
  }

  testWidgets('editing an existing birthday saves the new name', (
    tester,
  ) async {
    final existing = buildBirthday(name: 'Ayşe', date: DateTime(1990, 5, 10));
    final h = await UiHarness.create(birthdays: [existing]);
    await tester.pumpWidget(h.app(home: _opener(existing: existing)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('10 Mayıs 1990'), findsOneWidget);
    await tester.enterText(find.byKey(BirthdayEditorKeys.name), 'Ayşe Yılmaz');
    await tester.ensureVisible(find.byKey(BirthdayEditorKeys.save));
    await tester.tap(find.byKey(BirthdayEditorKeys.save));
    await tester.pumpAndSettle();

    expect(h.cubit.state.birthdays.single.name, 'Ayşe Yılmaz');
  });

  testWidgets('saving a birthday asks for notifications the first time', (
    tester,
  ) async {
    final existing = buildBirthday();
    final h = await UiHarness.create(birthdays: [existing]);
    h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
      notifications: NotificationPermissionState.notRequested,
    );
    await tester.pumpWidget(h.app(home: _opener(existing: existing)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(BirthdayEditorKeys.save));
    await tester.tap(find.byKey(BirthdayEditorKeys.save));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionSheet), findsOneWidget);

    await tester.tap(find.byKey(PermissionSheetKeys.dismiss));
    await tester.pumpAndSettle();
    expect(h.permissions.calls, isEmpty);
    expect(find.byKey(BirthdayEditorKeys.save), findsNothing);
  });
}
