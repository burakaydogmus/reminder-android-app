import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/services/sync_interfaces.dart';

/// Ana ekran widget'ına giden veri anahtarı (Android `HomeWidget` önbelleği).
const String kHomeWidgetRemindersJsonKey = 'reminders_active_json';

/// Android AppWidgetProvider tam sınıf adı (`updateWidget` için).
const String kReminderListWidgetQualifiedAndroidName =
    'com.burakaydogmus.reminder.ReminderListWidgetProvider';

/// Tamamlanmamış hatırlatıcıların özetini widget depolama alanına yazar ve görünümü yeniler.
Future<void> syncRemindersToHomeWidget(List<Reminder> reminders) async {
  if (!Platform.isAndroid) return;

  final active = reminders.where((r) => !r.isDone).toList();
  active.sort(compareReminders);
  final top = active.take(8).toList();
  final payload =
      top.map((r) => {'id': r.id, 'title': r.title}).toList(growable: false);
  await HomeWidget.saveWidgetData(
    kHomeWidgetRemindersJsonKey,
    jsonEncode(payload),
  );
  await HomeWidget.updateWidget(
    qualifiedAndroidName: kReminderListWidgetQualifiedAndroidName,
  );
}

/// [HomeWidgetSync]'in gerçek uygulaması; [syncRemindersToHomeWidget]'e
/// delege eder.
class PlatformHomeWidgetSync implements HomeWidgetSync {
  const PlatformHomeWidgetSync();

  @override
  Future<void> sync(List<Reminder> reminders) =>
      syncRemindersToHomeWidget(reminders);
}
