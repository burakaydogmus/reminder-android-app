import 'package:reminder/domain/model/reminder.dart';

/// Geofence yarıçapı sınırları (metre).
const double kGeofenceMinRadiusMeters = 100;
const double kGeofenceMaxRadiusMeters = 500;

/// iOS uygulama başına en fazla 20 bölgeyi izler.
const int kIosMaxGeofences = 20;

/// Android uygulama başına en fazla 100 geofence kaydına izin verir.
const int kAndroidMaxGeofences = 100;

/// Aynı hatırlatıcı için art arda gelen giriş olayları (platformun çift
/// tetiklemesi, sınırda gidip gelme) bu süre içinde yeniden bildirim üretmez.
const Duration kGeofenceNotificationCooldown = Duration(minutes: 10);

/// Bölge kaydedildikten hemen sonra gelen giriş olayı "zaten içerideydim"
/// anlamına gelir (iOS kayıt sonrası durumu bildirebiliyor); bildirim üretmez.
const Duration kGeofenceInitialTriggerGrace = Duration(seconds: 30);

/// OS'e kaydedilecek tek bir dairesel bölge.
class GeofenceTarget {
  const GeofenceTarget({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// Konum/yarıçap değişikliğini algılamak için kalıcı olarak saklanan imza.
  String get signature => '${latitude.toStringAsFixed(6)},'
      '${longitude.toStringAsFixed(6)},'
      '${radiusMeters.toStringAsFixed(1)}';

  @override
  bool operator ==(Object other) =>
      other is GeofenceTarget && other.id == id && other.signature == signature;

  @override
  int get hashCode => Object.hash(id, signature);

  @override
  String toString() => 'GeofenceTarget($id, $signature)';
}

/// Hatırlatıcının konum tetiklemesine uygun olup olmadığı.
bool isGeofenceEligible(Reminder r) =>
    !r.isDone &&
    r.locationTriggerEnabled &&
    r.locationLatitude != null &&
    r.locationLongitude != null;

/// Kaydedilmesi gereken bölgeler.
///
/// Bildirimler kapalıysa hiçbir bölge kaydedilmez. Uygun hatırlatıcı sayısı
/// platform sınırını ([maxRegions]) aşarsa **en son oluşturulan** hatırlatıcılar
/// seçilir (iOS'ta 20, Android'de 100).
List<GeofenceTarget> buildGeofenceTargets(
  List<Reminder> reminders, {
  required bool notificationsEnabled,
  required int maxRegions,
}) {
  if (!notificationsEnabled || maxRegions <= 0) return const [];

  final eligible = reminders.where(isGeofenceEligible).toList()
    ..sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

  return eligible
      .take(maxRegions)
      .map(
        (r) => GeofenceTarget(
          id: r.id,
          latitude: r.locationLatitude!,
          longitude: r.locationLongitude!,
          radiusMeters: r.locationRadiusMeters.clamp(
            kGeofenceMinRadiusMeters,
            kGeofenceMaxRadiusMeters,
          ),
        ),
      )
      .toList(growable: false);
}

/// [planGeofenceSync] sonucu.
class GeofenceSyncPlan {
  const GeofenceSyncPlan({required this.toRemove, required this.toCreate});

  final List<String> toRemove;
  final List<GeofenceTarget> toCreate;

  bool get isEmpty => toRemove.isEmpty && toCreate.isEmpty;
}

/// Mevcut kayıtlarla istenen bölgeleri karşılaştırır; yalnızca farkı üretir.
///
/// - [platformIds]: OS/plugin tarafında kayıtlı kimlikler (eski paketten
///   kalanlar dahil).
/// - [recordedSignatures]: bu uygulamanın kaydettiği bölgelerin imzaları.
///
/// Değişmeyen bölgeler yeniden kaydedilmez (yeniden kayıt iOS'ta ilk durum
/// olayını tetikleyebilir). Kaydı olmayan ya da imzası değişen bölge önce
/// silinir, sonra yeniden oluşturulur.
GeofenceSyncPlan planGeofenceSync({
  required List<GeofenceTarget> desired,
  required Set<String> platformIds,
  required Map<String, String> recordedSignatures,
}) {
  final desiredById = {for (final t in desired) t.id: t};

  bool upToDate(String id) =>
      platformIds.contains(id) &&
      recordedSignatures[id] == desiredById[id]?.signature;

  final toRemove = platformIds
      .where((id) => !desiredById.containsKey(id) || !upToDate(id))
      .toList()
    ..sort();
  final toCreate =
      desired.where((t) => !upToDate(t.id)).toList(growable: false);

  return GeofenceSyncPlan(toRemove: toRemove, toCreate: toCreate);
}

/// Bir bölgeye giriş olayında bildirim gösterilecek hatırlatıcı; yoksa `null`.
///
/// Uygulama açıkken geçerli olan kurallarla aynıdır: bildirimler açık,
/// hatırlatıcı mevcut, tamamlanmamış, konum tetiklemesi açık ve koordinatlı.
/// Ek olarak kayıt sonrası ilk tetikleme ([grace]) ve tekrar bildirim
/// ([cooldown]) engellenir.
Reminder? reminderToNotifyOnEntry({
  required String geofenceId,
  required List<Reminder> reminders,
  required bool notificationsEnabled,
  required DateTime now,
  DateTime? registeredAt,
  DateTime? lastNotifiedAt,
  Duration cooldown = kGeofenceNotificationCooldown,
  Duration grace = kGeofenceInitialTriggerGrace,
}) {
  if (!notificationsEnabled) return null;

  Reminder? match;
  for (final r in reminders) {
    if (r.id == geofenceId) {
      match = r;
      break;
    }
  }
  if (match == null || !isGeofenceEligible(match)) return null;

  if (registeredAt != null && now.isBefore(registeredAt.add(grace))) {
    return null;
  }
  if (lastNotifiedAt != null && now.isBefore(lastNotifiedAt.add(cooldown))) {
    return null;
  }
  return match;
}
