import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/data/backup/backup_io.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/settings/backup_preview_sheet.dart';
import 'package:reminder/ui/settings/reset_data_dialog.dart';
import 'package:reminder/ui/settings/settings_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Records share calls and returns a scripted picked file.
class FakeBackupIo implements BackupIo {
  String? pickedContents;
  Object? pickError;
  BackupShareOutcome shareOutcome = BackupShareOutcome.shared;
  final shared = <({String fileName, String contents})>[];
  int pickCalls = 0;

  @override
  Future<String?> appVersion() async => '9.9.9+1';

  @override
  Future<BackupShareOutcome> shareBackupFile({
    required String fileName,
    required String contents,
    Rect? origin,
  }) async {
    shared.add((fileName: fileName, contents: contents));
    return shareOutcome;
  }

  @override
  Future<String?> pickBackupFile() async {
    pickCalls++;
    if (pickError case final error?) throw error;
    return pickedContents;
  }
}

String _backupJson({
  List<Reminder> reminders = const [],
  List<Birthday> birthdays = const [],
  List<Object?> extraReminderItems = const [],
  int version = 1,
}) {
  final map = BackupFormat.toJson(
    reminders: reminders,
    birthdays: birthdays,
    settings: const AppSettings(themeMode: AppThemeModeIds.dark),
    exportedAt: DateTime.utc(2026, 9, 1, 8),
  );
  map['version'] = version;
  map['reminders'] = <Object?>[
    ...map['reminders'] as List,
    ...extraReminderItems,
  ];
  return jsonEncode(map);
}

void main() {
  final clock = DateTime(2026, 9, 13, 10);

  late UiHarness h;
  late FakeBackupIo io;

  /// Makes the mocked repository behave like storage, so `cubit.load()`
  /// after an import shows what was written.
  void backRepositoryWithMemory(List<Reminder> reminders) {
    var storedReminders = [...reminders];
    var storedBirthdays = <Birthday>[];
    var storedSettings = const AppSettings();
    when(() => h.repository.saveReminders(any())).thenAnswer((i) async {
      storedReminders = [...i.positionalArguments.first as List<Reminder>];
    });
    when(() => h.repository.saveBirthdays(any())).thenAnswer((i) async {
      storedBirthdays = [...i.positionalArguments.first as List<Birthday>];
    });
    when(() => h.repository.saveSettings(any())).thenAnswer((i) async {
      storedSettings = i.positionalArguments.first as AppSettings;
    });
    when(() => h.repository.loadReminders())
        .thenAnswer((_) async => [...storedReminders]);
    when(() => h.repository.loadBirthdays())
        .thenAnswer((_) async => [...storedBirthdays]);
    when(() => h.repository.loadSettings())
        .thenAnswer((_) async => storedSettings);
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(h.app(
      home: SettingsPage(
        backupIo: io,
        backupService: BackupService(h.repository, clock: () => clock),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapScrolled(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() async {
    io = FakeBackupIo();
  });

  testWidgets('shows the backup card with both actions', (tester) async {
    h = await UiHarness.create();
    await pumpPage(tester);

    final export = find.byKey(SettingsPageKeys.backupExport);
    await tester.scrollUntilVisible(
      export,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Yedekle ve geri yükle'), findsOneWidget);
    expect(
      find.descendant(of: export, matching: find.text('Yedekle')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(SettingsPageKeys.backupImport),
        matching: find.text('Geri yükle'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Yedekle shares a dated JSON file with the stored data',
      (tester) async {
    h = await UiHarness.create(
      reminders: [buildReminder(id: 'r1'), buildReminder(id: 'r2')],
      birthdays: [buildBirthday(id: 'b1')],
    );
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupExport));

    expect(io.shared, hasLength(1));
    expect(io.shared.single.fileName, 'hatirlatici-yedek-2026-09-13.json');
    final backup = BackupFormat.decode(io.shared.single.contents);
    expect(backup.reminders.map((r) => r.id), ['r1', 'r2']);
    expect(backup.birthdays.map((b) => b.id), ['b1']);
    expect(backup.appVersion, '9.9.9+1');
    expect(find.text('Yedek dosyası paylaşıldı.'), findsOneWidget);
  });

  testWidgets('preview shows counts; cancelling changes nothing',
      (tester) async {
    h = await UiHarness.create();
    io.pickedContents = _backupJson(
      reminders: [buildReminder(id: 'n1'), buildReminder(id: 'n2')],
      birthdays: [buildBirthday(id: 'b9')],
      extraReminderItems: ['broken'],
    );
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));

    expect(
      find.text('2 hatırlatıcı, 1 doğum günü bulundu; 1 kayıt okunamadı.'),
      findsOneWidget,
    );
    expect(find.text('Birleştir'), findsOneWidget);
    expect(find.text('Değiştir'), findsOneWidget);

    await tester.tap(find.byKey(BackupPreviewKeys.cancel));
    await tester.pumpAndSettle();
    verifyNever(() => h.repository.saveReminders(any()));
    verifyNever(() => h.repository.saveBirthdays(any()));
  });

  testWidgets('Birleştir upserts, keeps local items and reloads the cubit',
      (tester) async {
    h = await UiHarness.create(
      reminders: [buildReminder(id: 'r1', title: 'Yerel')],
    );
    backRepositoryWithMemory([buildReminder(id: 'r1', title: 'Yerel')]);
    io.pickedContents = _backupJson(
      reminders: [buildReminder(id: 'n1', title: 'Yedekten')],
      birthdays: [buildBirthday(id: 'b1')],
    );
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));
    await tester.tap(find.byKey(BackupPreviewKeys.confirm));
    await tester.pumpAndSettle();

    expect(
      h.cubit.state.reminders.map((r) => r.id).toSet(),
      {'r1', 'n1'},
    );
    expect(h.cubit.state.birthdays.map((b) => b.id), ['b1']);
    // Merge leaves settings alone.
    verifyNever(() => h.repository.saveSettings(any()));
    expect(find.text('Geri yüklendi: 1 hatırlatıcı, 1 doğum günü.'),
        findsOneWidget);
  });

  testWidgets('Değiştir asks for confirmation, then replaces everything',
      (tester) async {
    h = await UiHarness.create(
      reminders: [buildReminder(id: 'r1')],
    );
    backRepositoryWithMemory([buildReminder(id: 'r1')]);
    io.pickedContents = _backupJson(
      reminders: [buildReminder(id: 'n1'), buildReminder(id: 'n2')],
    );
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));
    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BackupPreviewKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.text('Verileri değiştir'), findsOneWidget);
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(h.cubit.state.reminders.map((r) => r.id).toSet(), {'n1', 'n2'});
    expect(h.cubit.state.settings.themeMode, AppThemeModeIds.dark);
    expect(find.text('Geri yüklendi: 2 hatırlatıcı, 0 doğum günü.'),
        findsOneWidget);
  });

  testWidgets('cancelling the replace confirmation applies nothing',
      (tester) async {
    h = await UiHarness.create();
    io.pickedContents = _backupJson(reminders: [buildReminder(id: 'n1')]);
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));
    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BackupPreviewKeys.confirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    verifyNever(() => h.repository.saveReminders(any()));
  });

  testWidgets('a file that is not a backup is rejected without a preview',
      (tester) async {
    h = await UiHarness.create();
    io.pickedContents = jsonEncode({'format': 'other', 'version': 1});
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));

    expect(find.byType(BackupPreviewSheet), findsNothing);
    expect(find.text('Bu dosya bir Hatırlatıcı yedeği değil.'), findsOneWidget);
    verifyNever(() => h.repository.saveReminders(any()));
  });

  testWidgets('a newer backup version asks to update the app', (tester) async {
    h = await UiHarness.create();
    io.pickedContents = _backupJson(version: BackupFormat.version + 1);
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));

    expect(find.byType(BackupPreviewSheet), findsNothing);
    expect(find.textContaining('sürüm ${BackupFormat.version + 1}'),
        findsOneWidget);
  });

  testWidgets('cancelled picker does nothing', (tester) async {
    h = await UiHarness.create();
    await pumpPage(tester);

    await tapScrolled(tester, find.byKey(SettingsPageKeys.backupImport));

    expect(io.pickCalls, 1);
    expect(find.byType(BackupPreviewSheet), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('reset → Önce yedekle exports, then the dialog returns',
      (tester) async {
    h = await UiHarness.create(reminders: [buildReminder(id: 'r1')]);
    io.shareOutcome = BackupShareOutcome.dismissed;
    await pumpPage(tester);

    await tapScrolled(tester, find.text('Tüm verileri sıfırla'));
    expect(find.byType(ResetDataDialog), findsOneWidget);

    await tester.tap(find.byKey(ResetDataDialogKeys.backupFirst));
    await tester.pumpAndSettle();

    expect(io.shared, hasLength(1));
    verifyNever(() => h.repository.clearAll());
    expect(find.byType(ResetDataDialog), findsOneWidget);

    await tester.tap(find.byKey(ResetDataDialogKeys.confirm));
    await tester.pumpAndSettle();
    verify(() => h.repository.clearAll()).called(1);
    expect(find.byType(ResetDataDialog), findsNothing);
  });

  testWidgets('reset → Önce yedekle stops when the backup fails',
      (tester) async {
    h = await UiHarness.create();
    when(() => h.repository.loadReminders()).thenThrow(StateError('db'));
    await pumpPage(tester);

    await tapScrolled(tester, find.text('Tüm verileri sıfırla'));
    await tester.tap(find.byKey(ResetDataDialogKeys.backupFirst));
    await tester.pumpAndSettle();

    expect(find.byType(ResetDataDialog), findsNothing);
    expect(find.text('Yedek oluşturulamadı. Tekrar dene.'), findsOneWidget);
    verifyNever(() => h.repository.clearAll());
  });
}
