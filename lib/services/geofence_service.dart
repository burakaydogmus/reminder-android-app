import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_logic.dart';
import 'package:reminder/services/geofence_platform.dart';
import 'package:reminder/services/geofence_state_store.dart';
import 'package:reminder/services/notification_service.dart';

/// OS geofence kayıtlarını hatırlatıcılarla senkronlar.
///
/// Giriş bildirimleri ana isolate'te değil, `geofenceEntryCallback` arka plan
/// callback'inde gösterilir; böylece uygulama kapalıyken de çalışır.
class GeofenceService {
  GeofenceService._(this._platform, this._store, this._clock);

  static final GeofenceService instance = GeofenceService._(
    NativeGeofencePlatform(),
    GeofenceStateStore(),
    DateTime.now,
  );

  @visibleForTesting
  factory GeofenceService.forTesting({
    required GeofencePlatform platform,
    GeofenceStateStore? store,
    DateTime Function()? clock,
  }) =>
      GeofenceService._(
        platform,
        store ?? GeofenceStateStore(),
        clock ?? DateTime.now,
      );

  final GeofencePlatform _platform;
  final GeofenceStateStore _store;
  final DateTime Function() _clock;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _platform.initialize();
    await _platform.reCreateRegistered();
    _initialized = true;
  }

  /// Uyumluluk için korunur; artık bir şey yapmaz.
  ///
  /// Giriş olayları arka plan callback'i (`geofenceEntryCallback`) tarafından
  /// işlenir, ana isolate'te dinleyici gerekmez.
  void startListening(NotificationService notifications) {}

  /// Hatırlatıcı listesine göre geofence'leri günceller (yalnızca fark).
  Future<void> syncWithReminders(
    List<Reminder> reminders, {
    required bool notificationsEnabled,
  }) async {
    if (!_initialized) await initialize();

    final desired = buildGeofenceTargets(
      reminders,
      notificationsEnabled: notificationsEnabled,
      maxRegions: _platform.maxRegions,
    );
    final records = await _store.loadRegistrations();
    final legacyIds = await _store.takeLegacyRegisteredIds();
    final platformIds = {...await _platform.registeredIds(), ...legacyIds};

    final plan = planGeofenceSync(
      desired: desired,
      platformIds: platformIds,
      recordedSignatures: records.map((id, r) => MapEntry(id, r.signature)),
    );

    for (final id in plan.toRemove) {
      await _platform.remove(id);
      records.remove(id);
    }

    final desiredIds = {for (final t in desired) t.id};
    records.removeWhere((id, _) => !desiredIds.contains(id));

    for (final target in plan.toCreate) {
      // Kayıt zamanı, oluşturmadan ÖNCE yazılır: iOS'un kayıt sonrası
      // gönderebileceği ilk durum olayı callback'te bununla ayıklanır.
      records[target.id] = GeofenceRegistration(
        signature: target.signature,
        registeredAt: _clock(),
      );
      await _store.saveRegistrations(records);
      if (!await _platform.create(target)) {
        records.remove(target.id);
      }
    }

    await _store.saveRegistrations(records);
    await _store.retainLastNotified(desiredIds);
  }
}
