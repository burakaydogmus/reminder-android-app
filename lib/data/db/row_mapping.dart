import 'dart:convert';

import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/subtask.dart';

/// Domain modelleri ↔ Drift satırları. Senkron alanları (`position`,
/// `updated_at`, `deleted_at`) yalnızca burada ve depoda bilinir.

/// Depo defter alanları (`updated_at`, `deleted_at`): UTC epoch mikrosaniye.
int toEpochMicros(DateTime value) => value.microsecondsSinceEpoch;

/// Kullanıcı/model zamanları: JSON dönemiyle birebir aynı metin. Yerel değer
/// saat dilimi eki olmadan (duvar saati), UTC değer `Z` ile yazılır.
String toStoredDateTime(DateTime value) => value.toIso8601String();

/// [toStoredDateTime]'ın tersi; eski `fromJson` ile aynı `DateTime.parse`.
DateTime fromStoredDateTime(String value) => DateTime.parse(value);

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
    createdAt: toStoredDateTime(r.createdAt),
    remindAt: r.remindAt == null ? null : toStoredDateTime(r.remindAt!),
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
    recurrence: recurrenceToStored(r.recurrence),
    priority: ReminderPriority.normalize(r.priority),
    pinned: r.pinned,
  );
}

/// Tekrar kuralı: `RecurrenceRule.toJson()` JSON metni, tekrar yoksa `NULL`.
String? recurrenceToStored(RecurrenceRule rule) {
  final json = rule.toJson();
  return json == null ? null : jsonEncode(json);
}

/// [recurrenceToStored]'ın tersi; `NULL` veya bozuk metin → tekrar yok (satır
/// atlanmaz, hatırlatıcı tekrarsız yüklenir).
RecurrenceRule recurrenceFromStored(String? value) {
  if (value == null) return RecurrenceRule.none;
  try {
    return RecurrenceRule.fromJson(jsonDecode(value));
  } on FormatException {
    return RecurrenceRule.none;
  }
}

/// Hatırlatıcı satırı ve (sıralı, silinmemiş) madde satırları → model.
/// Maddeler `ReminderRepository` tarafından ayrı sorguyla yüklenir.
Reminder reminderFromRow(
  ReminderRow row, {
  List<SubtaskRow> subtasks = const [],
}) {
  return Reminder(
    id: row.id,
    title: row.title,
    note: row.note,
    isDone: row.isDone,
    createdAt: fromStoredDateTime(row.createdAt),
    remindAt: row.remindAt == null ? null : fromStoredDateTime(row.remindAt!),
    categoryId: row.categoryId,
    customCategoryLabel: row.customCategoryLabel,
    locationTriggerEnabled: row.locationTriggerEnabled,
    locationLatitude: row.locationLatitude,
    locationLongitude: row.locationLongitude,
    locationRadiusMeters: row.locationRadiusMeters,
    locationPlaceLabel: row.locationPlaceLabel,
    recurrence: recurrenceFromStored(row.recurrence),
    subtasks: SubtaskList.normalized(subtasks.map(subtaskFromRow)),
    priority: ReminderPriority.normalize(row.priority),
    pinned: row.pinned,
  );
}

/// Madde satırı (v3, F3.3); `position` modeldeki sırayla aynıdır.
SubtaskRow subtaskToRow(
  Subtask s, {
  required String reminderId,
  required int position,
  required int updatedAt,
  int? deletedAt,
}) {
  return SubtaskRow(
    reminderId: reminderId,
    id: s.id,
    title: s.title,
    isDone: s.isDone,
    position: position,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

Subtask subtaskFromRow(SubtaskRow row) {
  return Subtask(
    id: row.id,
    title: row.title,
    isDone: row.isDone,
    position: row.position,
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
    date: toStoredDateTime(b.date),
    notifyHour: b.notifyHour,
    notifyMinute: b.notifyMinute,
    advanceOffsetsMinutes: jsonEncode(b.advanceOffsetsMinutes),
    createdAt: toStoredDateTime(b.createdAt),
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
    date: fromStoredDateTime(row.date),
    notifyHour: row.notifyHour,
    notifyMinute: row.notifyMinute,
    advanceOffsetsMinutes: offsets,
    createdAt: fromStoredDateTime(row.createdAt),
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
