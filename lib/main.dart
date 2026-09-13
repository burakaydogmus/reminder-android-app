import 'dart:io' show Platform;

import 'package:material_ui/material_ui.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:reminder/app.dart';
import 'package:reminder/home/reminder_home_widget_callback.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/util/local_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await HomeWidget.setAppGroupId('group.com.burakaydogmus.reminder');
    await HomeWidget.registerInteractivityCallback(reminderHomeWidgetCallback);
  }
  await initializeDateFormatting('tr_TR');
  await configureLocalTimezone();
  await NotificationService.instance.initialize();
  // No permission prompts at launch (F1.6): notification, exact alarm and
  // location permissions are asked in context via PermissionFlows.
  await GeofenceService.instance.initialize();
  GeofenceService.instance.startListening(NotificationService.instance);
  runApp(
    PermissionScope(
      service: PlatformPermissionService.platform(),
      child: const App(),
    ),
  );
}
