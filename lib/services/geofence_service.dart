import 'dart:async';

import 'package:flutter_geofence_manager/flutter_geofence_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/sync_interfaces.dart';

/// OS geofence kayıtlarını hatırlatıcılarla senkronlar; girişte bildirim gösterir.
class GeofenceService implements GeofenceSync {
  GeofenceService._();
  static final GeofenceService instance = GeofenceService._();

  static const _prefsRegisteredIds = 'geofence_registered_ids_v1';

  final FlutterGeofenceManager _manager = FlutterGeofenceManager.instance;
  final ReminderRepository _repository = ReminderRepository();
  StreamSubscription<GeoFenceEvent>? _subscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _manager.initialize();
    _initialized = true;
  }

  void startListening(NotificationService notifications) {
    _subscription ??= _manager.onEvent().listen((event) async {
      if (event.transitionType != TransitionType.enter) return;

      final settings = await _repository.loadSettings();
      if (!settings.notificationsEnabled) return;

      final reminders = await _repository.loadReminders();
      Reminder? match;
      for (final r in reminders) {
        if (r.id == event.id) {
          match = r;
          break;
        }
      }
      if (match == null ||
          match.isDone ||
          !match.locationTriggerEnabled ||
          match.locationLatitude == null ||
          match.locationLongitude == null) {
        return;
      }

      await notifications.showGeofenceEntry(match);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Hatırlatıcı listesine göre geofence’leri günceller.
  @override
  Future<void> syncWithReminders(
    List<Reminder> reminders, {
    required bool notificationsEnabled,
  }) async {
    if (!_initialized) await initialize();

    final desired = reminders
        .where(
          (r) =>
              !r.isDone &&
              r.locationTriggerEnabled &&
              r.locationLatitude != null &&
              r.locationLongitude != null,
        )
        .map(
          (r) => GeoFenceRegion(
            id: r.id,
            latitude: r.locationLatitude!,
            longitude: r.locationLongitude!,
            radius: r.locationRadiusMeters.clamp(100.0, 500.0),
          ),
        )
        .toList();

    final prefs = await SharedPreferences.getInstance();
    final oldIds = prefs.getStringList(_prefsRegisteredIds) ?? [];

    for (final id in oldIds) {
      await _manager.removeGeoFence(id);
    }

    if (!notificationsEnabled || desired.isEmpty) {
      await prefs.setStringList(_prefsRegisteredIds, []);
      return;
    }

    final ok = await _manager.registerGeoFences(desired);
    if (ok) {
      await prefs.setStringList(
        _prefsRegisteredIds,
        desired.map((e) => e.id).toList(),
      );
    }
  }
}
