import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:native_geofence/native_geofence.dart';

import 'package:reminder/services/geofence_callback.dart';
import 'package:reminder/services/geofence_logic.dart';

/// Geofence plugin'ine ince sarmalayıcı; testlerde sahtesi kullanılır.
abstract interface class GeofencePlatform {
  /// Platformun aynı anda izleyebildiği en fazla bölge sayısı.
  int get maxRegions;

  /// Android/iOS dışında [UnsupportedError] fırlatır.
  Future<void> initialize();

  /// Kaydedilmiş bölgeleri OS'e yeniden bildirir (Android: zorla durdurma
  /// veya OEM kaynaklı silinmelere karşı). iOS'ta etkisizdir.
  Future<void> reCreateRegistered();

  Future<Set<String>> registeredIds();

  /// Başarılıysa `true`; izin eksikliği vb. durumda `false`.
  Future<bool> create(GeofenceTarget target);

  Future<void> remove(String id);
}

/// `native_geofence` tabanlı gerçek uygulama.
class NativeGeofencePlatform implements GeofencePlatform {
  bool get _supported => Platform.isAndroid || Platform.isIOS;

  @override
  int get maxRegions =>
      Platform.isIOS ? kIosMaxGeofences : kAndroidMaxGeofences;

  NativeGeofenceManager get _manager {
    if (!_supported) {
      throw UnsupportedError('Geofencing is only supported on Android and iOS');
    }
    return NativeGeofenceManager.instance;
  }

  @override
  Future<void> initialize() async => _manager.initialize();

  @override
  Future<void> reCreateRegistered() async {
    if (!Platform.isAndroid) return;
    try {
      await _manager.reCreateAfterReboot();
    } on NativeGeofenceException catch (e) {
      debugPrint('Geofence re-create failed: ${e.code} ${e.message}');
    }
  }

  @override
  Future<Set<String>> registeredIds() async =>
      (await _manager.getRegisteredGeofenceIds()).toSet();

  @override
  Future<bool> create(GeofenceTarget target) async {
    try {
      await _manager.createGeofence(
        Geofence(
          id: target.id,
          location: Location(
            latitude: target.latitude,
            longitude: target.longitude,
          ),
          radiusMeters: target.radiusMeters,
          triggers: const {GeofenceEvent.enter},
          // Zaten bölgenin içindeyken kayıt bildirim üretmesin.
          iosSettings: const IosGeofenceSettings(initialTrigger: false),
          androidSettings: const AndroidGeofenceSettings(initialTriggers: {}),
        ),
        geofenceEntryCallback,
      );
      return true;
    } on NativeGeofenceException catch (e) {
      debugPrint(
          'Geofence ${target.id} not registered: ${e.code} ${e.message}');
      return false;
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _manager.removeGeofenceById(id);
    } on NativeGeofenceException catch (e) {
      // Android bilinmeyen kimlik için geofenceNotFound döndürebilir.
      debugPrint('Geofence $id not removed: ${e.code} ${e.message}');
    }
  }
}
