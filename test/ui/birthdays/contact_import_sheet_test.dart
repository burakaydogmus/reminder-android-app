import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/contact_birthday_import.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/services/contacts_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/birthdays/contact_import_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/permissions/permission_sheet.dart';

import '../../helpers/factories.dart';
import '../../services/fake_contacts_platform.dart';
import '../ui_harness.dart';

// Sunday 13 Sep 2026.
final _now = DateTime(2026, 9, 13, 14, 32);

Future<(UiHarness, FakeContactsPlatform)> _pump(
  WidgetTester tester, {
  List<ContactBirthday> contacts = const [],
  List<Birthday> birthdays = const [],
  ContactsReadException? failure,
  PermissionSnapshot? permissions,
  AppLanguage language = AppLanguage.turkish,
}) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);

  final platform = FakeContactsPlatform(contactBirthdays: contacts)
    ..failure = failure;
  final h = await UiHarness.create(birthdays: birthdays, now: () => _now);
  if (permissions != null) h.permissions.snapshot = permissions;
  await tester.pumpWidget(
    h.app(
      language: language,
      home: NowScope(
        clock: () => _now,
        child: BirthdaysPage(contactsPlatform: platform),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (h, platform);
}

/// Opens Doğum günleri › "Rehberden aktar".
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(BirthdaysPageKeys.import));
  await tester.pumpAndSettle();
}

const _grantedExceptContacts = PermissionSnapshot(
  notifications: NotificationPermissionState.granted,
  exactAlarms: ExactAlarmState.granted,
  location: LocationPermissionState.always,
  contacts: ContactsPermissionState.notRequested,
);

const _contactsDenied = PermissionSnapshot(
  notifications: NotificationPermissionState.granted,
  exactAlarms: ExactAlarmState.granted,
  location: LocationPermissionState.always,
  contacts: ContactsPermissionState.denied,
);

void main() {
  final ayse = buildContactBirthday(name: 'Ayşe Yılmaz', month: 9, day: 14);
  final bora =
      buildContactBirthday(name: 'Bora Demir', month: 6, day: 2, year: 1985);
  final ilkay = buildContactBirthday(name: 'ILKAY ÖZ', month: 3, day: 4);

  testWidgets(
      'granted: lists contacts with a birthday and imports the picked '
      'ones', (tester) async {
    final (h, platform) = await _pump(tester, contacts: [ayse, bora]);
    await _openSheet(tester);

    expect(platform.reads, 1);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.text('Bora Demir'), findsOneWidget);
    // Nothing is preselected, so an accidental open imports nothing.
    expect(
      tester
          .widget<FilledButton>(find.byKey(ContactImportKeys.importButton))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Ayşe Yılmaz'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();

    expect(h.cubit.state.birthdays.length, 1);
    final saved = h.cubit.state.birthdays.single;
    expect(saved.name, 'Ayşe Yılmaz');
    expect(saved.month, 9);
    expect(saved.day, 14);
    expect(saved.year, isNull, reason: 'the contact has no year');
    expect(saved.notifyHour, 9);
    expect(saved.advanceOffsetsMinutes, const [0, 1440]);
  });

  testWidgets('a year-known contact keeps its year and shows the date',
      (tester) async {
    final (h, _) = await _pump(tester, contacts: [bora]);
    await _openSheet(tester);
    expect(find.textContaining('2 Haziran 1985'), findsOneWidget);

    await tester.tap(find.text('Bora Demir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();

    expect(h.cubit.state.birthdays.single.year, 1985);
  });

  testWidgets('a year-less contact says so on the row', (tester) async {
    await _pump(tester, contacts: [ayse]);
    await _openSheet(tester);
    expect(find.textContaining('yıl bilinmiyor'), findsOneWidget);
    expect(find.textContaining('14 Eylül'), findsOneWidget);
  });

  testWidgets(
      'a duplicate is shown as "zaten ekli", unselected and disabled '
      '(Turkish İ/ı folding)', (tester) async {
    final (h, _) = await _pump(
      tester,
      contacts: [ilkay, ayse],
      birthdays: [
        buildBirthday(id: 'b1', name: 'İlkay Öz', date: DateTime(1988, 3, 4)),
      ],
    );
    await _openSheet(tester);

    expect(find.text('ILKAY ÖZ'), findsOneWidget);
    expect(find.textContaining('zaten ekli'), findsOneWidget);

    final duplicateRow = find.ancestor(
      of: find.text('ILKAY ÖZ'),
      matching: find.byType(CheckboxListTile),
    );
    expect(tester.widget<CheckboxListTile>(duplicateRow).onChanged, isNull);

    // "Tümünü seç" must not pick it up either.
    await tester.tap(find.byKey(ContactImportKeys.selectAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();

    expect(
      [for (final b in h.cubit.state.birthdays) b.name],
      ['İlkay Öz', 'Ayşe Yılmaz'],
      reason: 'no second record for the already stored birthday',
    );
  });

  testWidgets('select all / clear selection drives the import button',
      (tester) async {
    await _pump(tester, contacts: [ayse, bora]);
    await _openSheet(tester);

    await tester.tap(find.byKey(ContactImportKeys.selectAll));
    await tester.pumpAndSettle();
    expect(find.text('2 kişiyi aktar'), findsOneWidget);
    expect(find.text('Seçimi temizle'), findsOneWidget);

    await tester.tap(find.byKey(ContactImportKeys.selectAll));
    await tester.pumpAndSettle();
    expect(find.text('Tümünü seç (2)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(ContactImportKeys.importButton))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
      'the result summary lists imported and skipped names, then a '
      'snackbar', (tester) async {
    await _pump(
      tester,
      contacts: [ilkay, ayse, bora],
      birthdays: [
        buildBirthday(id: 'b1', name: 'İlkay Öz', date: DateTime(1988, 3, 4)),
      ],
    );
    await _openSheet(tester);
    await tester.tap(find.byKey(ContactImportKeys.selectAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();

    expect(find.text('Aktarma özeti'), findsOneWidget);
    expect(find.text('Aktarılan: 2'), findsOneWidget);
    expect(find.text('Ayşe Yılmaz · Bora Demir'), findsOneWidget);
    expect(find.text('Zaten ekliydi: 1'), findsOneWidget);
    expect(find.text('ILKAY ÖZ'), findsOneWidget);

    await tester.tap(find.byKey(ContactImportKeys.done));
    await tester.pumpAndSettle();
    expect(
      find.text('2 doğum günü aktarıldı, 1 tanesi zaten ekliydi'),
      findsOneWidget,
    );
  });

  testWidgets('contacts without a birthday never reach the list',
      (tester) async {
    // The seam filters them, so an empty read is the "no birthdays" case.
    final (_, platform) = await _pump(tester, contacts: const []);
    await _openSheet(tester);
    expect(platform.reads, 1);
    expect(find.textContaining('Rehberde doğum günü yok'), findsOneWidget);
    expect(find.byKey(ContactImportKeys.importButton), findsNothing);
  });

  testWidgets('permission refused: explains and offers the Settings deep link',
      (tester) async {
    final (h, platform) = await _pump(
      tester,
      contacts: [ayse],
      permissions: _grantedExceptContacts,
    );
    h.permissions.contactsRequestResult = ContactsPermissionState.denied;
    await _openSheet(tester);

    // The pre-permission sheet comes first.
    expect(find.text('Doğum günlerini rehberden alalım'), findsOneWidget);
    await tester.tap(find.byKey(PermissionSheetKeys.confirm));
    await tester.pumpAndSettle();

    expect(h.permissions.calls, contains('requestContacts'));
    expect(platform.reads, 0, reason: 'nothing is read without permission');
    expect(find.textContaining('Rehber izni verilmedi'), findsOneWidget);
    expect(find.byKey(ContactImportKeys.openSettings), findsOneWidget);
  });

  testWidgets('already denied: no system prompt, straight to the explanation',
      (tester) async {
    final (h, platform) = await _pump(
      tester,
      contacts: [ayse],
      permissions: _contactsDenied,
    );
    await _openSheet(tester);

    expect(find.text('Doğum günlerini rehberden alalım'), findsNothing);
    expect(find.byKey(ContactImportKeys.openSettings), findsOneWidget);
    expect(platform.reads, 0);

    // Coming back from system settings with the permission granted reads.
    h.permissions.appSettingsResult = ContactsPermissionState.granted;
    await tester.tap(find.byKey(ContactImportKeys.openSettings));
    await tester.pumpAndSettle();
    expect(h.permissions.calls, contains('openAppSettings'));
    expect(platform.reads, 1);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
  });

  testWidgets(
      'permission revoked between the check and the read degrades to '
      'the explanation', (tester) async {
    await _pump(
      tester,
      contacts: [ayse],
      failure: const ContactsReadException(ContactsFailure.permissionDenied),
    );
    await _openSheet(tester);
    expect(find.byKey(ContactImportKeys.openSettings), findsOneWidget);
    expect(find.textContaining('Rehber izni verilmedi'), findsOneWidget);
  });

  testWidgets(
      'a non-permission read failure says the address book cannot be '
      'read', (tester) async {
    await _pump(
      tester,
      contacts: [ayse],
      failure: const ContactsReadException(ContactsFailure.unavailable),
    );
    await _openSheet(tester);
    expect(find.textContaining('Rehber şu an okunamıyor'), findsOneWidget);
    expect(find.byKey(ContactImportKeys.openSettings), findsNothing);
  });

  testWidgets('English: the sheet, the empty state and the snackbar translate',
      (tester) async {
    await _pump(
      tester,
      contacts: [ayse],
      language: AppLanguage.english,
    );
    await _openSheet(tester);
    expect(find.text('Import from contacts'), findsOneWidget);
    expect(find.text('1 contact has a birthday'), findsOneWidget);
    expect(find.textContaining('year unknown'), findsOneWidget);

    await tester.tap(find.text('Ayşe Yılmaz'));
    await tester.pumpAndSettle();
    expect(find.text('Import 1 contact'), findsOneWidget);
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();
    expect(find.text('Imported: 1'), findsOneWidget);
    await tester.tap(find.byKey(ContactImportKeys.done));
    await tester.pumpAndSettle();
    expect(find.text('1 birthday imported'), findsOneWidget);
  });

  test('the sheet result carries the counts', () {
    const result = ContactImportResult(imported: ['a'], skipped: ['b', 'c']);
    expect(result.importedCount, 1);
    expect(result.skippedCount, 2);
    expect(result.isEmpty, isFalse);
    expect(const ContactImportResult.empty().isEmpty, isTrue);
  });
}
