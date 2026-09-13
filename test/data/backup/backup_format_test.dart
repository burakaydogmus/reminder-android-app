import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/backup/backup_format.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../../helpers/factories.dart';

Matcher _throwsKind(BackupErrorKind kind) => throwsA(
      isA<BackupFormatException>().having((e) => e.kind, 'kind', kind),
    );

Map<String, dynamic> _header({Object? version = 1}) => {
      'format': BackupFormat.formatId,
      'version': version,
    };

void main() {
  final exportedAt = DateTime.utc(2026, 9, 13, 10, 30);

  final reminders = [
    buildReminder(
      id: 'r1',
      title: 'Ekmek al',
      note: 'Tam buğday',
      remindAt: DateTime(2026, 9, 14, 18, 30),
      categoryId: ReminderCategoryIds.market,
    ),
    buildReminder(
      id: 'r2',
      title: 'Eczane',
      isDone: true,
      locationTriggerEnabled: true,
      locationLatitude: 41.0,
      locationLongitude: 29.0,
      locationRadiusMeters: 200,
      locationPlaceLabel: 'Moda',
    ),
    buildReminder(
      id: 'r3',
      categoryId: ReminderCategoryIds.other,
      customCategoryLabel: 'Hobi',
    ),
  ];
  final birthdays = [
    buildBirthday(id: 'b1', name: 'Ayşe', note: 'Kitap'),
    buildBirthday(
      id: 'b2',
      name: 'Can',
      date: DateTime(2000, 2, 29),
      notifyHour: 8,
      notifyMinute: 15,
      advanceOffsetsMinutes: const [0, 60, 10080],
    ),
  ];
  const settings = AppSettings(
    notificationsEnabled: false,
    themeMode: AppThemeModeIds.dark,
  );

  String encode() => BackupFormat.encode(
        reminders: reminders,
        birthdays: birthdays,
        settings: settings,
        exportedAt: exportedAt,
        appVersion: '2.1.0+8',
      );

  group('encode', () {
    test('writes the versioned header and model JSON', () {
      final json = jsonDecode(encode()) as Map<String, dynamic>;
      expect(json['format'], 'hatirlatici-backup');
      expect(json['version'], 1);
      expect(json['exportedAt'], '2026-09-13T10:30:00.000Z');
      expect(json['app'], {'version': '2.1.0+8'});
      expect(json['reminders'], [for (final r in reminders) r.toJson()]);
      expect(json['birthdays'], [for (final b in birthdays) b.toJson()]);
      expect(json['settings'], settings.toJson());
    });

    test('file name uses the local date', () {
      expect(
        BackupFormat.fileNameFor(DateTime(2026, 3, 7, 23, 59)),
        'hatirlatici-yedek-2026-03-07.json',
      );
    });
  });

  group('decode', () {
    test('round trip equals the original lists and settings', () {
      final backup = BackupFormat.decode(encode());
      expect(backup.version, 1);
      expect(
        [for (final r in backup.reminders) r.toJson()],
        [for (final r in reminders) r.toJson()],
      );
      expect(
        [for (final b in backup.birthdays) b.toJson()],
        [for (final b in birthdays) b.toJson()],
      );
      expect(backup.settings?.toJson(), settings.toJson());
      expect(backup.exportedAt, exportedAt);
      expect(backup.appVersion, '2.1.0+8');
      expect(backup.skippedCount, 0);
    });

    test('wall-clock times stay wall-clock', () {
      final backup = BackupFormat.decode(encode());
      final remindAt = backup.reminders.first.remindAt!;
      expect(remindAt.isUtc, isFalse);
      expect((remindAt.hour, remindAt.minute), (18, 30));
    });

    test('skips unreadable items and counts them', () {
      final raw = jsonEncode({
        ..._header(),
        'reminders': [
          reminders[0].toJson(),
          'not an object',
          {'id': 'x', 'title': 'no createdAt'},
          {...reminders[1].toJson(), 'createdAt': 'yesterday'},
          {...reminders[2].toJson(), 'id': ''},
          {...reminders[0].toJson(), 'title': 'duplicate id'},
          // Unknown (future) fields are ignored, the item is kept.
          {...reminders[2].toJson(), 'recurrence': 'weekly'},
        ],
        'birthdays': [
          birthdays[0].toJson(),
          {
            ...birthdays[1].toJson(),
            'advanceOffsetsMinutes': ['x']
          },
          42,
        ],
        'settings': {'notificationsEnabled': 'yes'},
      });

      final backup = BackupFormat.decode(raw);
      expect(backup.reminders.map((r) => r.id), ['r1', 'r3']);
      expect(backup.reminders.first.title, 'Ekmek al');
      expect(backup.skippedReminders, 5);
      expect(backup.birthdays.map((b) => b.id), ['b1']);
      expect(backup.skippedBirthdays, 2);
      expect(backup.settings, isNull);
      expect(backup.settingsSkipped, isTrue);
      expect(backup.skippedCount, 8);
    });

    test('missing lists and settings are empty, not errors', () {
      final backup = BackupFormat.decode(jsonEncode(_header()));
      expect(backup.reminders, isEmpty);
      expect(backup.birthdays, isEmpty);
      expect(backup.settings, isNull);
      expect(backup.settingsSkipped, isFalse);
      expect(backup.exportedAt, isNull);
      expect(backup.appVersion, isNull);
    });

    test('rejects text that is not a JSON object', () {
      expect(() => BackupFormat.decode('{oops'),
          _throwsKind(BackupErrorKind.notJson));
      expect(() => BackupFormat.decode('[]'),
          _throwsKind(BackupErrorKind.notJson));
      expect(
          () => BackupFormat.decode(''), _throwsKind(BackupErrorKind.notJson));
    });

    test('rejects an unknown format', () {
      expect(
        () =>
            BackupFormat.decode(jsonEncode({'format': 'other', 'version': 1})),
        _throwsKind(BackupErrorKind.notBackup),
      );
      expect(
        () => BackupFormat.decode(jsonEncode({'version': 1, 'reminders': []})),
        _throwsKind(BackupErrorKind.notBackup),
      );
    });

    test('rejects a newer version with the found version', () {
      expect(
        () => BackupFormat.decode(jsonEncode({
          ..._header(version: 2),
          'reminders': [reminders[0].toJson()],
        })),
        throwsA(
          isA<BackupFormatException>()
              .having((e) => e.kind, 'kind', BackupErrorKind.unsupportedVersion)
              .having((e) => e.foundVersion, 'foundVersion', 2),
        ),
      );
    });

    test('rejects a missing or malformed version', () {
      for (final version in [null, '1', 0, -1, 1.5]) {
        expect(
          () => BackupFormat.decode(jsonEncode(_header(version: version))),
          _throwsKind(BackupErrorKind.invalid),
          reason: 'version $version',
        );
      }
    });

    test('rejects lists of the wrong type as a whole', () {
      expect(
        () => BackupFormat.decode(jsonEncode({..._header(), 'reminders': {}})),
        _throwsKind(BackupErrorKind.invalid),
      );
      expect(
        () => BackupFormat.decode(
          jsonEncode({..._header(), 'birthdays': 'none'}),
        ),
        _throwsKind(BackupErrorKind.invalid),
      );
    });
  });
}
