import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Zamanlanmış bildirimlerin parmak izleri: bildirim id'si → spesifikasyon
/// (başlık, gövde, zaman, tekrar, kanal, payload) özeti (F1.7).
///
/// `pendingNotificationRequests()` zamanlanan tarihi döndürmediği için
/// `NotificationService.syncSchedules` bir bildirimin değişip değişmediğini
/// buradan anlar. Ana isolate ve arka plan isolate'leri (widget callback) aynı
/// anahtarı kullanır; her isolate'in kendi SharedPreferences önbelleği olduğu
/// için okumadan önce `reload()` çağrılır.
class NotificationFingerprintStore {
  const NotificationFingerprintStore();

  /// SharedPreferences anahtarı (başka hiçbir yerde kullanılmaz).
  static const storageKey = 'notification_schedule_fingerprints_v1';

  /// Kayıtlı parmak izleri; kayıt yoksa veya bozuksa `null`.
  ///
  /// `null` "hangi bildirimin güncel olduğu bilinmiyor" demektir; çağıran
  /// istenen tüm bildirimleri yeniden kurmalıdır.
  Future<Map<int, String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final result = <int, String>{};
      for (final entry in decoded.entries) {
        final id = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (id == null || value is! String) return null;
        result[id] = value;
      }
      return result;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(Map<int, String> fingerprints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(fingerprints.map((id, fp) => MapEntry('$id', fp))),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
