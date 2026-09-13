import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/home/widget_change_signal.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:reminder/util/local_timezone.dart';

/// Ana ekran widget etkileşimlerinin arka plan giriş noktası.
///
/// Ayrı bir isolate'te çalışır: cubit ve ana isolate'in singleton durumu
/// yoktur. Bu yüzden yalnızca ortamı hazırlar ve gerçek servisleri kurup
/// [handleReminderHomeWidgetToggle]'a verir; iş mantığı oradadır.
@pragma('vm:entry-point')
Future<void> reminderHomeWidgetCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid) return;

  final id = reminderIdFromWidgetUri(uri);
  if (id == null) return;

  await initializeDateFormatting('tr_TR');
  await configureLocalTimezone();

  await handleReminderHomeWidgetToggle(
    id,
    repository: ReminderRepository(),
    schedules: ScheduleSync(
      notifications: NotificationService.instance,
      geofence: GeofenceService.instance,
      homeWidget: const PlatformHomeWidgetSync(),
    ),
  );
}

/// `reminderwidget://toggle?id=<id>` adresinden hatırlatıcı id'sini çıkarır;
/// başka bir adres için `null`.
@visibleForTesting
String? reminderIdFromWidgetUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'reminderwidget' || uri.host != 'toggle') return null;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return null;
  return id;
}

/// Widget'tan gelen "tamamla" isteğini işler.
///
/// Hatırlatıcı bulunamazsa veya zaten tamamlanmışsa hiçbir şey kaydedilmez ve
/// zamanlamalara dokunulmaz; yalnızca widget depodaki listeyle yenilenir.
/// Aksi halde hatırlatıcı tamamlanır, kaydedilir ve doğum günleri ile ayarlar
/// depodan okunarak **tüm** zamanlamalar [ScheduleSync.syncAll] ile
/// eşitlenir (F1.2: doğum günü bildirimleri silinmez).
@visibleForTesting
Future<void> handleReminderHomeWidgetToggle(
  String reminderId, {
  required ReminderRepository repository,
  required ScheduleSync schedules,
}) async {
  final reminders = await repository.loadReminders();
  var changed = false;
  final updated = reminders.map((r) {
    if (r.id != reminderId || r.isDone) return r;
    changed = true;
    return r.copyWith(isDone: true);
  }).toList();

  if (!changed) {
    await schedules.refreshHomeWidget(reminders);
    return;
  }

  await repository.saveReminders(updated);

  final birthdays = await repository.loadBirthdays();
  final settings = await repository.loadSettings();
  await schedules.syncAll(
    reminders: updated,
    birthdays: birthdays,
    settings: settings,
  );
  notifyAppOfWidgetChange(); // F1.3: açık uygulama depodan yeniden yüklesin.
}
