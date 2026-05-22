import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/app.dart';
import 'package:reminder/home/reminder_home_widget_callback.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await HomeWidget.setAppGroupId('group.com.fabirt.reminder');
    await HomeWidget.registerInteractivityCallback(reminderHomeWidgetCallback);
  }
  await initializeDateFormatting('tr_TR');
  tzdata.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissionsIfNeeded();
  await GeofenceService.instance.initialize();
  GeofenceService.instance.startListening(NotificationService.instance);
  runApp(const App());
}
