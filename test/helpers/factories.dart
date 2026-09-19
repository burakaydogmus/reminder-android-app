import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/subtask.dart';

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
  RecurrenceRule recurrence = RecurrenceRule.none,
  List<Subtask> subtasks = const [],
  int priority = 0,
  bool pinned = false,
}) {
  return Reminder(
    recurrence: recurrence,
    subtasks: subtasks,
    priority: priority,
    pinned: pinned,
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

/// [titles] sırasıyla maddeler (`s1`, `s2`, … kimlikleri); [done] içindeki
/// sıra numaraları (0 tabanlı) tamamlanmış.
List<Subtask> buildSubtasks(List<String> titles, {Set<int> done = const {}}) {
  return [
    for (var i = 0; i < titles.length; i++)
      Subtask(
        id: 's${i + 1}',
        title: titles[i],
        isDone: done.contains(i),
        position: i,
      ),
  ];
}

/// Kullanıcı kategorisi (F4.3); varsayılan renk `lacivert`, ikon `fitness`.
ReminderCategory buildCategory({
  String id = 'c1',
  String name = 'Spor',
  String colorKey = 'lacivert',
  String iconKey = CategoryIconKeys.fitness,
  int position = 6,
}) {
  return ReminderCategory(
    id: id,
    name: name,
    colorKey: colorKey,
    iconKey: iconKey,
    position: position,
  );
}
