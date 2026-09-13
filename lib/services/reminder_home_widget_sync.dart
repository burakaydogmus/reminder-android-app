import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'package:reminder/domain/model/reminder.dart';

/// Ana ekran widget'ına giden veri anahtarı (Android `HomeWidget` önbelleği).
const String kHomeWidgetRemindersJsonKey = 'reminders_active_json';

/// Android AppWidgetProvider tam sınıf adı (`updateWidget` için).
const String kReminderListWidgetQualifiedAndroidName =
    'com.fabirt.reminder.ReminderListWidgetProvider';

/// Tamamlanmamış hatırlatıcıların özetini widget depolama alanına yazar ve görünümü yeniler.
Future<void> syncRemindersToHomeWidget(List<Reminder> reminders) async {
  if (!Platform.isAndroid) return;

  final active = reminders.where((r) => !r.isDone).toList();
  active.sort((a, b) {
    final ta = a.remindAt;
    final tb = b.remindAt;
    if (ta != null && tb != null) return ta.compareTo(tb);
    if (ta != null) return -1;
    if (tb != null) return 1;
    return b.createdAt.compareTo(a.createdAt);
  });
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
