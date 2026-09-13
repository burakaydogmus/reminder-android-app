import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

/// Test verisi üretmek için kısa fabrikalar. Yalnızca testin önemsediği
/// alanları geçin; geri kalanı makul varsayılanlarla doldurulur.
Reminder buildReminder({
  String id = 'r1',
  String title = 'Ekmek al',
  String? note,
  bool isDone = false,
  DateTime? createdAt,
  DateTime? remindAt,
  String categoryId = ReminderCategoryIds.other,
  String? customCategoryLabel,
  bool locationTriggerEnabled = false,
  double? locationLatitude,
  double? locationLongitude,
  double locationRadiusMeters = 150,
  String? locationPlaceLabel,
}) {
  return Reminder(
    id: id,
    title: title,
    note: note,
    isDone: isDone,
    createdAt: createdAt ?? DateTime(2026, 1, 1, 12),
    remindAt: remindAt,
    categoryId: categoryId,
    customCategoryLabel: customCategoryLabel,
    locationTriggerEnabled: locationTriggerEnabled,
    locationLatitude: locationLatitude,
    locationLongitude: locationLongitude,
    locationRadiusMeters: locationRadiusMeters,
    locationPlaceLabel: locationPlaceLabel,
  );
}

Birthday buildBirthday({
  String id = 'b1',
  String name = 'Ayşe',
  String? note,
  DateTime? date,
  int notifyHour = 9,
  int notifyMinute = 0,
  List<int> advanceOffsetsMinutes = const <int>[0, 1440],
  DateTime? createdAt,
}) {
  return Birthday(
    id: id,
    name: name,
    note: note,
    date: date ?? DateTime(1990, 5, 10),
    notifyHour: notifyHour,
    notifyMinute: notifyMinute,
    advanceOffsetsMinutes: advanceOffsetsMinutes,
    createdAt: createdAt ?? DateTime(2026, 1, 1, 12),
  );
}
