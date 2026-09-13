import 'dart:convert';

import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

/// Domain modelleri ↔ Drift satırları. Senkron alanları (`position`,
/// `updated_at`, `deleted_at`) yalnızca burada ve depoda bilinir.

/// Anlık zamanlar UTC epoch mikrosaniye olarak saklanır.
int toEpochMicros(DateTime value) => value.microsecondsSinceEpoch;

/// Saklanan anı yerel `DateTime` olarak döndürür.
DateTime fromEpochMicros(int value) =>
    DateTime.fromMicrosecondsSinceEpoch(value);

ReminderRow reminderToRow(
  Reminder r, {
  required int position,
  required int updatedAt,
  int? deletedAt,
}) {
  return ReminderRow(
    id: r.id,
    title: r.title,
    note: r.note,
    isDone: r.isDone,
    createdAt: toEpochMicros(r.createdAt),
    remindAt: r.remindAt == null ? null : toEpochMicros(r.remindAt!),
    categoryId: r.categoryId,
    customCategoryLabel: r.customCategoryLabel,
    locationTriggerEnabled: r.locationTriggerEnabled,
    locationLatitude: r.locationLatitude,
    locationLongitude: r.locationLongitude,
    locationRadiusMeters: r.locationRadiusMeters,
    locationPlaceLabel: r.locationPlaceLabel,
    position: position,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

Reminder reminderFromRow(ReminderRow row) {
  return Reminder(
    id: row.id,
    title: row.title,
    note: row.note,
    isDone: row.isDone,
    createdAt: fromEpochMicros(row.createdAt),
    remindAt: row.remindAt == null ? null : fromEpochMicros(row.remindAt!),
    categoryId: row.categoryId,
    customCategoryLabel: row.customCategoryLabel,
    locationTriggerEnabled: row.locationTriggerEnabled,
    locationLatitude: row.locationLatitude,
    locationLongitude: row.locationLongitude,
    locationRadiusMeters: row.locationRadiusMeters,
    locationPlaceLabel: row.locationPlaceLabel,
  );
}

BirthdayRow birthdayToRow(
  Birthday b, {
  required int position,
  required int updatedAt,
  int? deletedAt,
}) {
  return BirthdayRow(
    id: b.id,
    name: b.name,
    note: b.note,
    date: b.date.toIso8601String(),
    notifyHour: b.notifyHour,
    notifyMinute: b.notifyMinute,
    advanceOffsetsMinutes: jsonEncode(b.advanceOffsetsMinutes),
    createdAt: toEpochMicros(b.createdAt),
    position: position,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

/// Bozuk satırda (`date` / önbildirim JSON'u çözülemiyor) hata fırlatır;
/// depo satırı atlar.
Birthday birthdayFromRow(BirthdayRow row) {
  final offsets = (jsonDecode(row.advanceOffsetsMinutes) as List)
      .map((e) => (e as num).toInt())
      .toList(growable: false);
  return Birthday(
    id: row.id,
    name: row.name,
    note: row.note,
    date: DateTime.parse(row.date),
    notifyHour: row.notifyHour,
    notifyMinute: row.notifyMinute,
    advanceOffsetsMinutes: offsets,
    createdAt: fromEpochMicros(row.createdAt),
  );
}

SettingsRow settingsToRow(AppSettings s, {required int updatedAt}) {
  return SettingsRow(
    id: AppDatabase.settingsRowId,
    notificationsEnabled: s.notificationsEnabled,
    themeMode: s.themeMode,
    updatedAt: updatedAt,
  );
}

AppSettings settingsFromRow(SettingsRow row) {
  return AppSettings(
    notificationsEnabled: row.notificationsEnabled,
    themeMode: AppThemeModeIds.normalize(row.themeMode),
  );
}
