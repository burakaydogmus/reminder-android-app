import 'dart:convert';

/// Kararlı (deterministik) bildirim kimlikleri (F1.5).
///
/// `flutter_local_notifications` bildirimleri `int` kimlikle zamanlar ve iptal
/// eder. Kimlik daha önce Dart `String.hashCode` ile türetiliyordu; bu değer
/// Dart sürümleri, çalıştırmalar ve isolate'ler arasında aynı kalmak zorunda
/// değildir, dolayısıyla SDK güncellemesinden sonra ya da ana isolate ile arka
/// plan isolate'leri (widget callback, geofence callback) arasında farklı
/// kimlik üretilip `cancel` bildirimi ıskalayabilirdi.
///
/// **Algoritma:** isim alanlı bir anahtarın UTF-8 baytları üzerinde 32-bit
/// FNV-1a (offset basis `0x811C9DC5`, prime `0x01000193`), sonuç
/// `0x7FFFFFFF` ile maskelenir (Android `int` kimlikleri pozitif 31 bit);
/// `0` sonucu `1`'e eşlenir. Böylece kimlikler her zaman `1..0x7FFFFFFF`
/// aralığındadır.
///
/// **İsim alanları** (farklı bildirim türleri aynı UUID için aynı kimliği
/// üretmez):
/// - `reminder:<id>` — zamanlı hatırlatıcı ([reminderNotificationId])
/// - `geo:<id>` — konum bildirimi ([geoNotificationId])
/// - `birthday:<id>:<offsetMinutes>` — doğum günü önbildirimi
///   ([birthdayNotificationId])
///
/// Bu fonksiyonların çıktısı **kalıcı bir sözleşmedir**: zamanlanmış
/// bildirimler cihazda bu kimliklerle durur. Algoritma veya anahtar biçimi
/// değişirse `test/domain/notification_ids_test.dart` içindeki sabit
/// beklenen değerler kırılır; böyle bir değişiklik eski kimlikli
/// bildirimlerin temizlenmesini (ör. `NotificationService.syncSchedules`
/// başındaki `cancelAll`) gerektirir.
abstract final class NotificationIds {
  static const int _fnvOffsetBasis = 0x811C9DC5;
  static const int _fnvPrime = 0x01000193;
  static const int _mask31 = 0x7FFFFFFF;

  /// [input]'un UTF-8 baytları üzerinde 32-bit FNV-1a (işaretsiz,
  /// `0..0xFFFFFFFF`).
  static int fnv1a32(String input) {
    var hash = _fnvOffsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      // 32 bit × 25 bit çarpım 64-bit VM int'ine sığar; sonra 32 bite indir.
      hash = (hash * _fnvPrime) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// [key] için `1..0x7FFFFFFF` aralığında kararlı kimlik.
  static int fromKey(String key) {
    final id = fnv1a32(key) & _mask31;
    return id == 0 ? 1 : id;
  }

  /// Zamanlı hatırlatıcı bildirimi: `reminder:<id>`.
  static int reminderNotificationId(String reminderId) =>
      fromKey('reminder:$reminderId');

  /// Konum (geofence) bildirimi: `geo:<id>`.
  static int geoNotificationId(String reminderId) => fromKey('geo:$reminderId');

  /// Doğum günü önbildirimi: `birthday:<id>:<offsetMinutes>`.
  static int birthdayNotificationId(String birthdayId, int offsetMinutes) =>
      fromKey('birthday:$birthdayId:$offsetMinutes');
}
