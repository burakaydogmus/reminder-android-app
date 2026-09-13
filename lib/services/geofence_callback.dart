import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:native_geofence/native_geofence.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_logic.dart';
import 'package:reminder/services/geofence_state_store.dart';
import 'package:reminder/services/notification_service.dart';

/// OS bir bölgeye girişi bildirdiğinde çağrılan arka plan giriş noktası.
///
/// Uygulama kapalıyken de çalışır: Android'de WorkManager, iOS'ta
/// CoreLocation uygulamayı arka planda başlatır ve `native_geofence` ayrı bir
/// (headless) Flutter engine'de bu fonksiyonu çağırır. Ana isolate'in hiçbir
/// durumu (cubit, singleton alanları) burada yoktur; veriler depodan okunur.
@pragma('vm:entry-point')
Future<void> geofenceEntryCallback(GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (params.event != GeofenceEvent.enter) return;

  // Ayrı engine: veritabanı bağlantısı bu çağrıya özeldir, sonunda kapatılır.
  final repository = ReminderRepository();
  try {
    await handleGeofenceEntry(
      params.geofences.map((g) => g.id),
      repository: repository,
      store: GeofenceStateStore(),
      showNotification: (r) async {
        await NotificationService.instance.initialize();
        await NotificationService.instance.showGeofenceEntry(r);
      },
      now: DateTime.now(),
    );
  } catch (e, st) {
    debugPrint('Geofence callback failed: $e\n$st');
  } finally {
    await repository.close();
  }
}

/// Giriş olayını işler: uygun hatırlatıcılar için bildirim gösterir ve
/// tekrar bildirimi önlemek için zamanı kaydeder.
@visibleForTesting
Future<void> handleGeofenceEntry(
  Iterable<String> geofenceIds, {
  required ReminderRepository repository,
  required GeofenceStateStore store,
  required Future<void> Function(Reminder reminder) showNotification,
  required DateTime now,
}) async {
  final settings = await repository.loadSettings();
  if (!settings.notificationsEnabled) return;

  final reminders = await repository.loadReminders();
  final registrations = await store.loadRegistrations();
  final lastNotified = await store.loadLastNotified();

  for (final id in geofenceIds.toSet()) {
    final reminder = reminderToNotifyOnEntry(
      geofenceId: id,
      reminders: reminders,
      notificationsEnabled: settings.notificationsEnabled,
      now: now,
      registeredAt: registrations[id]?.registeredAt,
      lastNotifiedAt: lastNotified[id],
    );
    if (reminder == null) continue;
    await showNotification(reminder);
    await store.setLastNotified(id, now);
  }
}
