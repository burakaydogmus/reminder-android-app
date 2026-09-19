import 'dart:convert';

import 'package:reminder/domain/category_label_migration.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

/// Why a backup file was rejected as a whole. Nothing is applied in any of
/// these cases.
enum BackupErrorKind {
  /// Not valid JSON (or not a JSON object).
  notJson,

  /// Valid JSON, but `format` is not [BackupFormat.formatId].
  notBackup,

  /// `version` is newer than [BackupFormat.version] (written by a newer app).
  unsupportedVersion,

  /// Right format, broken structure (missing/invalid `version`,
  /// `reminders`, `birthdays` or `categories` not a list).
  invalid,
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.kind, {this.foundVersion, this.detail});

  final BackupErrorKind kind;

  /// The file's `version` for [BackupErrorKind.unsupportedVersion].
  final int? foundVersion;
  final String? detail;

  @override
  String toString() => 'BackupFormatException($kind'
      '${foundVersion != null ? ', version $foundVersion' : ''}'
      '${detail != null ? ': $detail' : ''})';
}

/// A parsed backup. Lists contain only the readable items; unreadable ones
/// are counted in [skippedReminders] / [skippedBirthdays].
class BackupDocument {
  const BackupDocument({
    required this.version,
    required this.reminders,
    required this.birthdays,
    this.categories = const [],
    this.settings,
    this.exportedAt,
    this.appVersion,
    this.skippedReminders = 0,
    this.skippedBirthdays = 0,
    this.skippedCategories = 0,
    this.settingsSkipped = false,
  });

  final int version;
  final List<Reminder> reminders;
  final List<Birthday> birthdays;

  /// Categories (F4.3) in the file's order, built-ins included when the file
  /// stored their order. Version 1 files have no categories: they are
  /// derived from the reminders' "Diğer + özel ad" labels
  /// ([CategoryLabelMigration], like the schema v5 migration) and those
  /// reminders already point to them.
  final List<ReminderCategory> categories;

  /// `null` when the file has no (readable) `settings` object.
  final AppSettings? settings;
  final DateTime? exportedAt;
  final String? appVersion;
  final int skippedReminders;
  final int skippedBirthdays;
  final int skippedCategories;

  /// `settings` was present but could not be read.
  final bool settingsSkipped;

  /// Unreadable records (items plus an unreadable settings object).
  int get skippedCount =>
      skippedReminders +
      skippedBirthdays +
      skippedCategories +
      (settingsSkipped ? 1 : 0);
}

/// Versioned JSON backup (F2.2; version 2 adds `categories`, F4.3):
///
/// ```json
/// {
///   "format": "hatirlatici-backup",
///   "version": 2,
///   "exportedAt": "2026-09-13T10:30:00.000Z",
///   "app": {"version": "2.1.0+8"},
///   "reminders": [Reminder.toJson(), ...],
///   "birthdays": [Birthday.toJson(), ...],
///   "categories": [ReminderCategory.toJson(), ...],
///   "settings": AppSettings.toJson()
/// }
/// ```
///
/// Version 2 (F4.3) bumped the version because a version 1 reader would drop
/// the categories and show user-category reminders as "Diğer". Version 1
/// files are still read: their "Diğer + özel ad" labels become categories.
///
/// Items are the models' own `toJson`/`fromJson`, so model fields added later
/// are exported and imported without touching this file (model times keep
/// their wall-clock ISO strings). Bump [version] only for changes an older
/// reader would misinterpret; additive model fields don't need a bump because
/// `fromJson` defaults missing fields.
///
/// Import is tolerant per item (F1.4 spirit): an item that is not an object,
/// fails `fromJson`, has an empty id or repeats an earlier id is skipped and
/// counted. Top-level problems throw [BackupFormatException].
abstract final class BackupFormat {
  static const formatId = 'hatirlatici-backup';

  /// Highest version this app reads and the version it writes.
  static const version = 2;

  static Map<String, dynamic> toJson({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    List<ReminderCategory> categories = const [],
    required AppSettings settings,
    required DateTime exportedAt,
    String? appVersion,
  }) {
    return {
      'format': formatId,
      'version': version,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'app': {'version': appVersion},
      'reminders': [for (final r in reminders) r.toJson()],
      'birthdays': [for (final b in birthdays) b.toJson()],
      'categories': [for (final c in categories) c.toJson()],
      'settings': settings.toJson(),
    };
  }

  static String encode({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    List<ReminderCategory> categories = const [],
    required AppSettings settings,
    required DateTime exportedAt,
    String? appVersion,
  }) {
    return const JsonEncoder.withIndent('  ').convert(toJson(
      reminders: reminders,
      birthdays: birthdays,
      categories: categories,
      settings: settings,
      exportedAt: exportedAt,
      appVersion: appVersion,
    ));
  }

  /// `hatirlatici-yedek-YYYY-MM-DD.json` for the local date of [date].
  static String fileNameFor(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'hatirlatici-yedek-${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}.json';
  }

  static BackupDocument decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw BackupFormatException(BackupErrorKind.notJson, detail: e.message);
    }
    if (decoded is! Map) {
      throw const BackupFormatException(BackupErrorKind.notJson);
    }
    if (decoded['format'] != formatId) {
      throw const BackupFormatException(BackupErrorKind.notBackup);
    }

    final rawVersion = decoded['version'];
    if (rawVersion is! num ||
        rawVersion != rawVersion.truncate() ||
        rawVersion < 1) {
      throw const BackupFormatException(
        BackupErrorKind.invalid,
        detail: 'version',
      );
    }
    final fileVersion = rawVersion.toInt();
    if (fileVersion > version) {
      throw BackupFormatException(
        BackupErrorKind.unsupportedVersion,
        foundVersion: fileVersion,
      );
    }

    final reminders = _decodeList(
      decoded['reminders'],
      'reminders',
      Reminder.fromJson,
      (r) => r.id,
    );
    final birthdays = _decodeList(
      decoded['birthdays'],
      'birthdays',
      Birthday.fromJson,
      (b) => b.id,
    );

    final storedCategories = _decodeList(
      decoded['categories'],
      'categories',
      ReminderCategory.fromJson,
      (c) => c.id,
    );
    var reminderItems = reminders.items;
    var categories = storedCategories.items;
    if (fileVersion < 2) {
      // F4.3: same rule as the schema v5 migration.
      final labelled = CategoryLabelMigration.apply(
        reminderItems,
        existing: CategoryCatalog.builtIns,
      );
      reminderItems = labelled.reminders;
      categories = labelled.created;
    }

    AppSettings? settings;
    var settingsSkipped = false;
    final rawSettings = decoded['settings'];
    if (rawSettings is Map) {
      try {
        settings = AppSettings.fromJson(Map<String, dynamic>.from(rawSettings));
      } catch (_) {
        settingsSkipped = true;
      }
    } else if (rawSettings != null) {
      settingsSkipped = true;
    }

    final app = decoded['app'];
    final appVersion = app is Map ? app['version'] : null;
    final exportedAt = decoded['exportedAt'];

    return BackupDocument(
      version: fileVersion,
      reminders: reminderItems,
      birthdays: birthdays.items,
      categories: categories,
      settings: settings,
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      appVersion: appVersion is String ? appVersion : null,
      skippedReminders: reminders.skipped,
      skippedBirthdays: birthdays.skipped,
      skippedCategories: storedCategories.skipped,
      settingsSkipped: settingsSkipped,
    );
  }

  static ({List<T> items, int skipped}) _decodeList<T>(
    Object? raw,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
    String Function(T item) idOf,
  ) {
    if (raw == null) return (items: <T>[], skipped: 0);
    if (raw is! List) {
      throw BackupFormatException(BackupErrorKind.invalid, detail: key);
    }
    final items = <T>[];
    final ids = <String>{};
    var skipped = 0;
    for (final entry in raw) {
      try {
        final item = fromJson(Map<String, dynamic>.from(entry as Map));
        final id = idOf(item);
        if (id.isEmpty || !ids.add(id)) {
          skipped++;
          continue;
        }
        items.add(item);
      } catch (_) {
        // fromJson throws TypeError/FormatException for broken items.
        skipped++;
      }
    }
    return (items: items, skipped: skipped);
  }
}
