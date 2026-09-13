import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın kaydettiği bir bölgenin kalıcı kaydı.
class GeofenceRegistration {
  const GeofenceRegistration({
    required this.signature,
    required this.registeredAt,
  });

  final String signature;
  final DateTime registeredAt;

  Map<String, dynamic> toJson() => {
        'sig': signature,
        'at': registeredAt.millisecondsSinceEpoch,
      };

  static GeofenceRegistration? fromJson(Object? json) {
    if (json is! Map) return null;
    final sig = json['sig'];
    final at = json['at'];
    if (sig is! String || at is! int) return null;
    return GeofenceRegistration(
      signature: sig,
      registeredAt: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}

/// Geofence kayıtları ve son bildirim zamanları (SharedPreferences).
///
/// Ana isolate ve arka plan callback isolate'i aynı anahtarları okur/yazar.
/// Her isolate'in kendi SharedPreferences önbelleği olduğu için okumadan önce
/// `reload()` çağrılır.
class GeofenceStateStore {
  static const _keyRegistrations = 'geofence_registrations_v2';
  static const _keyLastNotified = 'geofence_last_notified_v1';

  /// `flutter_geofence_manager` döneminden kalan kimlik listesi.
  static const _keyLegacyIds = 'geofence_registered_ids_v1';

  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<Map<String, GeofenceRegistration>> loadRegistrations() async {
    final prefs = await _prefs();
    final result = <String, GeofenceRegistration>{};
    for (final entry in _decodeMap(prefs.getString(_keyRegistrations))) {
      final reg = GeofenceRegistration.fromJson(entry.value);
      if (reg != null) result[entry.key] = reg;
    }
    return result;
  }

  Future<void> saveRegistrations(Map<String, GeofenceRegistration> regs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyRegistrations,
      jsonEncode(regs.map((id, r) => MapEntry(id, r.toJson()))),
    );
  }

  Future<Map<String, DateTime>> loadLastNotified() async {
    final prefs = await _prefs();
    return {
      for (final entry in _decodeMap(prefs.getString(_keyLastNotified)))
        if (entry.value is int)
          entry.key: DateTime.fromMillisecondsSinceEpoch(entry.value as int),
    };
  }

  Future<void> setLastNotified(String id, DateTime at) async {
    final current = await loadLastNotified();
    current[id] = at;
    await _saveLastNotified(current);
  }

  /// Artık izlenmeyen hatırlatıcıların bildirim zamanlarını siler.
  Future<void> retainLastNotified(Set<String> ids) async {
    final current = await loadLastNotified();
    final before = current.length;
    current.removeWhere((id, _) => !ids.contains(id));
    if (current.length != before) await _saveLastNotified(current);
  }

  /// Eski paketin kimlik listesini döndürür ve siler (tek seferlik geçiş).
  Future<List<String>> takeLegacyRegisteredIds() async {
    final prefs = await _prefs();
    final ids = prefs.getStringList(_keyLegacyIds);
    if (ids == null) return const [];
    await prefs.remove(_keyLegacyIds);
    return ids;
  }

  Future<void> _saveLastNotified(Map<String, DateTime> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastNotified,
      jsonEncode(map.map((id, at) => MapEntry(id, at.millisecondsSinceEpoch))),
    );
  }

  static Iterable<MapEntry<String, Object?>> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      return decoded.entries.map((e) => MapEntry(e.key.toString(), e.value));
    } catch (_) {
      return const [];
    }
  }
}
