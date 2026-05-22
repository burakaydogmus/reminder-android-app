import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';

@pragma('vm:entry-point')
Future<void> reminderHomeWidgetCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid) return;

  if (uri == null) return;
  if (uri.scheme != 'reminderwidget' || uri.host != 'toggle') return;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return;

  await initializeDateFormatting('tr_TR');
  tzdata.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  final repo = ReminderRepository();
  final list = await repo.loadReminders();
  var changed = false;
  final updated = list.map((r) {
    if (r.id != id) return r;
    if (r.isDone) return r;
    changed = true;
    return Reminder(
      id: r.id,
      title: r.title,
      note: r.note,
      isDone: true,
      createdAt: r.createdAt,
      remindAt: r.remindAt,
      categoryId: r.categoryId,
      customCategoryLabel: r.customCategoryLabel,
      locationTriggerEnabled: r.locationTriggerEnabled,
      locationLatitude: r.locationLatitude,
      locationLongitude: r.locationLongitude,
      locationRadiusMeters: r.locationRadiusMeters,
      locationPlaceLabel: r.locationPlaceLabel,
    );
  }).toList();

  if (!changed) {
    await syncRemindersToHomeWidget(list);
    return;
  }

  await repo.saveReminders(updated);

  await NotificationService.instance.initialize();
  final settings = await repo.loadSettings();
  await NotificationService.instance.syncFromReminders(
    updated,
    notificationsEnabled: settings.notificationsEnabled,
  );

  await GeofenceService.instance.initialize();
  await GeofenceService.instance.syncWithReminders(
    updated,
    notificationsEnabled: settings.notificationsEnabled,
  );

  await syncRemindersToHomeWidget(updated);
}
