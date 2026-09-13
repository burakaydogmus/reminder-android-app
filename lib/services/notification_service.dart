import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/notification_ids.dart';
import 'package:reminder/services/notification_actions.dart';
import 'package:reminder/services/notification_fingerprint_store.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/schedule_sync.dart';

/// `flutter_local_notifications` üzerinden zamanlı hatırlatıcı ve yıllık doğum
/// günü bildirimlerini yönetir.
///
/// **Zamanlama politikası (F1.2, F1.7):** zamanlanmış bildirimleri toplu
/// olarak kuran tek genel metot [syncSchedules]'tır; hatırlatıcıları **ve**
/// doğum günlerini birlikte ele alır ve fark bazlı çalışır. Yalnızca
/// hatırlatıcıları kurup doğum günlerini silen bir yol yoktur. Uygulama
/// genelinde bu metot doğrudan değil, [ScheduleSync.syncAll] üzerinden
/// çağrılır.
///
/// **Aksiyonlar (F3.2):** hatırlatıcı ve konum bildirimleri Tamamla/Ertele
/// aksiyonları taşır (Android düğmeleri, iOS kategorisi); doğum günleri
/// taşımaz. Yanıtlar `notification_actions.dart` içinde işlenir.
class NotificationService implements NotificationSync {
  NotificationService._(this._plugin, this._fingerprints);

  static final NotificationService instance = NotificationService._(
    FlutterLocalNotificationsPlugin(),
    const NotificationFingerprintStore(),
  );

  /// Gerçek plugin yerine sahte bir plugin ile çalışan örnek (testler).
  @visibleForTesting
  factory NotificationService.forTesting(
    FlutterLocalNotificationsPlugin plugin, {
    NotificationFingerprintStore fingerprints =
        const NotificationFingerprintStore(),
  }) =>
      NotificationService._(plugin, fingerprints);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationFingerprintStore _fingerprints;

  bool _initialized = false;

  /// Plugin'i başlatır, iOS aksiyon kategorilerini ve yanıt işleyicilerini
  /// kaydeder. Arka plan isolate'lerinde de aynı işleyiciler verilir ki
  /// kayıtlı arka plan giriş noktası hiçbir yoldan eksik kalmasın.
  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // No prompt on initialize (also runs at launch and in background
    // isolates); permissions are requested in context (F1.6,
    // PermissionService).
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: darwinNotificationCategories,
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackgroundHandler,
    );

    _initialized = true;
  }

  /// Uygulamayı bir bildirim başlattıysa ayrıntıları (soğuk açılış, F3.2).
  Future<NotificationAppLaunchDetails?> appLaunchDetails() async {
    if (!_initialized) await initialize();
    return _plugin.getNotificationAppLaunchDetails();
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _plugin.cancel(id: reminder.notificationId);
    await _plugin.cancel(id: reminder.geoNotificationId);
  }

  Future<void> cancelBirthday(Birthday birthday) async {
    for (final preset in BirthdayAdvanceOffset.presets) {
      await _plugin.cancel(id: birthday.notificationIdFor(preset.minutes));
    }
  }

  /// Konum (geofence) ile tetiklenen anlık bildirim.
  Future<void> showGeofenceEntry(Reminder r) async {
    if (!_initialized) await initialize();

    const channelId = 'reminders_geo_v1';
    const channelName = 'Konum hatırlatmaları';
    const channelDescription = 'Seçtiğiniz yere geldiğinizde';

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      actions: androidReminderActions,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: reminderNotificationCategoryId,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final place = r.locationPlaceLabel?.trim();
    final body = (r.note != null && r.note!.trim().isNotEmpty)
        ? r.note!.trim()
        : (place != null && place.isNotEmpty)
            ? place
            : 'Kayıtlı konuma girdiniz';

    await _plugin.show(
      id: r.geoNotificationId,
      title: r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body: body,
      notificationDetails: details,
      payload: ReminderPayload(r.id).encode(),
    );
  }

  /// Bu uygulamanın tüm bildirimlerini (hatırlatıcı, doğum günü, konum;
  /// gösterilen ve zamanlanmış) iptal eder ve parmak izlerini siler. Yalnızca
  /// "Tüm verileri sıfırla" gibi her şeyin silindiği durumlar içindir; senkron
  /// için [syncSchedules] kullanın.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _fingerprints.clear();
  }

  /// Zamanlanmış bildirimleri saklanan durumla **fark bazlı** eşitler (F1.7).
  ///
  /// Sözleşme (F1.2): çağrıdan sonra bekleyen hatırlatıcı ve doğum günü
  /// bildirimleri tam olarak verilen listelere karşılık gelir; ikisi her zaman
  /// birlikte hesaplandığı için biri diğerini silemez.
  ///
  /// 1. İstenen küme: bildirimler açıksa gelecekteki tamamlanmamış zamanlı
  ///    hatırlatıcılar ve tüm doğum günü offset'leri (id → spesifikasyon).
  /// 2. `pendingNotificationRequests()` içinde olup istenmeyen **her** id tek
  ///    tek `cancel` edilir — silinen kayıtlar ve F1.5 öncesi eski şemalı
  ///    id'ler de. Bilinmeyen bekleyen bir id'nin kalmasına yol açan bir yol
  ///    yoktur; tek istisna verilen hatırlatıcıların konum (`geo:`) id'leridir
  ///    (bunlar zamanlanmaz, gösterilir; senkron onlara hiç dokunmaz).
  /// 3. İstenen bir bildirim yalnızca bekleyenlerde yoksa veya parmak izi
  ///    ([NotificationFingerprintStore]) değiştiyse yeniden kurulur. Parmak
  ///    izi kaydı yok/bozuksa istenen tümü yeniden kurulur.
  ///
  /// Senkron yolunda `cancelAll` **kullanılmaz**: gösterilmiş (teslim edilmiş)
  /// bildirimler, ör. bir konum bildirimi, düzenleme sırasında çekmeceden
  /// kaybolmaz. Bildirimler kapalıysa bekleyenlerin hepsi tek tek iptal edilir
  /// ve parmak izleri silinir. Plugin başlatılmamışsa (ör. arka plan
  /// isolate'i) önce başlatılır.
  @override
  Future<void> syncSchedules({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  }) async {
    if (!_initialized) await initialize();

    final pendingIds = {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id,
    };
    // Konum bildirimleri yalnızca gösterilir; `cancel` onları çekmeceden de
    // kaldıracağı için senkron bu id'lere asla dokunmaz.
    final geoIds = {for (final r in reminders) r.geoNotificationId};

    final desired = <int, _ScheduleSpec>{};
    if (notificationsEnabled) {
      final now = tz.TZDateTime.now(tz.local);
      for (final r in reminders) {
        if (r.isDone) continue;
        final at = reminderFireTime(r, now);
        if (at == null) continue;
        final spec = _reminderSpec(r, tz.TZDateTime.from(at, tz.local));
        desired[spec.id] = spec;
      }

      // Yıllık tekrarlayan doğum günü hatırlatmaları: her aktif offset için
      // ayrı bildirim, `DateTimeComponents.dateAndTime` ile her yıl yeniden
      // tetiklenir.
      for (final b in birthdays) {
        for (final spec in _birthdaySpecs(b)) {
          desired[spec.id] = spec;
        }
      }
    }

    for (final id in pendingIds) {
      if (desired.containsKey(id) || geoIds.contains(id)) continue;
      await _plugin.cancel(id: id);
    }

    if (!notificationsEnabled) {
      await _fingerprints.clear();
      return;
    }

    final stored = await _fingerprints.load();
    final next = <int, String>{};
    for (final spec in desired.values) {
      final fingerprint = spec.fingerprint;
      next[spec.id] = fingerprint;
      final upToDate = stored != null &&
          pendingIds.contains(spec.id) &&
          stored[spec.id] == fingerprint;
      if (upToDate) continue;
      await _schedule(spec);
    }

    // Kurulumlardan **sonra** yazılır: yarıda kalan bir senkron eski parmak
    // izlerini bırakır ve bir sonraki senkron farkı yeniden kurar.
    if (stored == null || !mapEquals(stored, next)) {
      await _fingerprints.save(next);
    }
  }

  Future<void> _schedule(_ScheduleSpec spec) => _plugin.zonedSchedule(
        id: spec.id,
        title: spec.title,
        body: spec.body,
        scheduledDate: spec.scheduledDate,
        notificationDetails: spec.details,
        androidScheduleMode: _androidScheduleMode,
        matchDateTimeComponents: spec.matchDateTimeComponents,
        payload: spec.payload,
      );

  static const _androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

  /// Parmak izine giren kurulum biçimi sürümü (testler için görünür).
  @visibleForTesting
  static const scheduleFingerprintVersion = _ScheduleSpec._version;

  List<_ScheduleSpec> _birthdaySpecs(Birthday b) {
    const channelId = 'reminders_birthdays_v1';
    const channelName = 'Doğum günü hatırlatmaları';
    const channelDescription =
        'Yıllık olarak tekrarlayan doğum günü bildirimleri';

    // Doğum günleri aksiyon taşımaz; dokunmak Doğum günleri listesini açar.
    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final specs = <_ScheduleSpec>[];
    final next = b.nextOccurrence();
    for (final offset in b.advanceOffsetsMinutes) {
      final fireDateTime = next.subtract(Duration(minutes: offset));
      var scheduled = tz.TZDateTime.from(fireDateTime, tz.local);

      // Eğer hesaplanan ilk tetik geçmişte kalmışsa (örn. yarın doğum günü ama
      // "1 gün önce" saati geçti), bir sonraki yılın doğum gününden hesapla.
      // `Birthday.nextOccurrence` 29 Şubat → 28 Şubat kuralını uygular.
      final now = tz.TZDateTime.now(tz.local);
      if (!scheduled.isAfter(now)) {
        final following = b.nextOccurrence(from: next);
        scheduled = tz.TZDateTime.from(
          following.subtract(Duration(minutes: offset)),
          tz.local,
        );
      }

      specs.add(_ScheduleSpec(
        id: b.notificationIdFor(offset),
        channelId: channelId,
        title: birthdayNotificationTitle(b, offset),
        body: birthdayNotificationBody(offset),
        scheduledDate: scheduled,
        details: details,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: BirthdayPayload(b.id).encode(),
      ));
    }
    return specs;
  }

  /// Doğum günü bildirim başlığı.
  ///
  /// Bildirim `DateTimeComponents.dateAndTime` ile her yıl **aynı metinle**
  /// tekrarlar (uygulama açılmasa da doğum günleri kaçmasın diye). Bu yüzden
  /// başlık ve gövde yaşa/yıla bağlı bilgi içermez (F1.8); yaş uygulama içinde
  /// gösterilir.
  @visibleForTesting
  static String birthdayNotificationTitle(Birthday b, int offsetMinutes) {
    if (offsetMinutes == 0) return '🎂 ${b.name}';
    return '🎂 Yaklaşıyor: ${b.name}';
  }

  /// Doğum günü bildirim gövdesi; yalnızca offset'e bağlıdır (yaş içermez).
  @visibleForTesting
  static String birthdayNotificationBody(int offsetMinutes) {
    if (offsetMinutes <= 0) return 'Bugün doğum günü.';
    if (offsetMinutes < 60) return '$offsetMinutes dakika sonra doğum günü.';
    if (offsetMinutes < 1440) {
      return '${offsetMinutes ~/ 60} saat sonra doğum günü.';
    }
    final days = offsetMinutes ~/ 1440;
    if (days == 1) return 'Yarın doğum günü.';
    return '$days gün sonra doğum günü.';
  }

  /// Tamamlanmamış zamanlı hatırlatıcının bildirim anı; zamanlanmayacaksa
  /// `null`.
  ///
  /// **Tekrar (F3.1):** her hatırlatıcı için yalnızca **bir sonraki** tekrar
  /// kurulur; F1.7 fark senkronu her yüklemede/değişiklikte onu güncel tutar.
  /// `remindAt` gelecekteyse o; geçmişte kalmış (tamamlanmamış) tekrarlayan
  /// hatırlatıcıda kuralın [now]'dan sonraki ilk tekrarı, böylece bildirimler
  /// sürer. Tekrarsız geçmiş hatırlatıcı zamanlanmaz.
  @visibleForTesting
  static DateTime? reminderFireTime(Reminder r, DateTime now) {
    final at = r.remindAt;
    if (r.isDone || at == null) return null;
    if (at.isAfter(now)) return at;
    if (!r.isRecurring) return null;
    return r.recurrence.nextOccurrence(after: now, anchor: at);
  }

  /// Uygulama açılmasa da işletim sisteminin tekrarlayabileceği kurallar için
  /// `matchDateTimeComponents`; diğerlerinde `null` (yalnızca sonraki tekrar).
  ///
  /// - Her gün → [DateTimeComponents.time]
  /// - Her hafta tek gün → [DateTimeComponents.dayOfWeekAndTime]
  /// - Her ayın 1–28'i → [DateTimeComponents.dayOfMonthAndTime] (29–31 kısa
  ///   aylarda ay sonuna kırpılır; sistem o ayı atlardı)
  /// - Aralıklı (`interval > 1`), haftada birden çok gün, bitiş tarihli → `null`:
  ///   sistem tekrarı aralığı/bitişi bilmez; sonraki tekrar uygulama açıldığında
  ///   veya hatırlatıcı değiştiğinde kurulur.
  ///
  /// Bildirim her zaman kuralın bir sonraki gerçek tekrarına kurulduğu için
  /// (erken tamamlama dahil) sistem tekrarı yalnızca uygulama açılmadığında
  /// devreye girer.
  @visibleForTesting
  static DateTimeComponents? reminderRepeatComponents(RecurrenceRule rule) {
    if (rule.interval != 1 || rule.until != null) return null;
    return switch (rule.frequency) {
      RecurrenceFrequency.none => null,
      RecurrenceFrequency.daily => DateTimeComponents.time,
      RecurrenceFrequency.weekly =>
        rule.weekdays.length <= 1 ? DateTimeComponents.dayOfWeekAndTime : null,
      RecurrenceFrequency.monthly => (rule.dayOfMonth ?? 31) <= 28
          ? DateTimeComponents.dayOfMonthAndTime
          : null,
    };
  }

  _ScheduleSpec _reminderSpec(Reminder r, tz.TZDateTime scheduled) {
    const channelId = 'reminders_channel_v1';
    const channelName = 'Hatırlatmalar';
    const channelDescription = 'Zamanlanmış hatırlatıcı bildirimleri';

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      actions: androidReminderActions,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: reminderNotificationCategoryId,
    );

    const details = NotificationDetails(android: android, iOS: darwin);

    final body = (r.note != null && r.note!.trim().isNotEmpty)
        ? r.note!.trim()
        : 'Hatırlatma zamanı';

    return _ScheduleSpec(
      id: r.notificationId,
      channelId: channelId,
      title: r.title.trim().isEmpty ? 'Hatırlatıcı' : r.title.trim(),
      body: body,
      scheduledDate: scheduled,
      details: details,
      matchDateTimeComponents: reminderRepeatComponents(r.recurrence),
      payload: ReminderPayload(r.id).encode(),
      recurrence: jsonEncode(r.recurrence.toJson()),
    );
  }
}

/// Zamanlanacak tek bir bildirimin tam tanımı (F1.7 fark hesabı).
class _ScheduleSpec {
  const _ScheduleSpec({
    required this.id,
    required this.channelId,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.details,
    this.matchDateTimeComponents,
    this.payload,
    this.recurrence,
  });

  /// Kurulum biçimi (kanal ayarları, zamanlama modu, aksiyonlar/kategori vb.)
  /// değişirse artırın; tüm bildirimler bir kez yeniden kurulur.
  ///
  /// - v2 (F3.2): hatırlatıcılara Tamamla/Ertele aksiyonları ve iOS kategorisi
  ///   eklendi; eski bildirimler aksiyonlarla yeniden kurulur.
  /// - v3 (F3.1): tekrar kuralı parmak izine girdi, tekrarlayan hatırlatıcılar
  ///   `matchDateTimeComponents` ile kurulur.
  static const _version = 3;

  final int id;
  final String channelId;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails details;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;

  /// Hatırlatıcının tekrar kuralı (JSON); doğum günlerinde `null`. Kural
  /// değişince (aynı sonraki tarih olsa bile) bildirim yeniden kurulur.
  final String? recurrence;

  /// Bildirimin kurulduğu haliyle eşleşen kısa özet. Zaman hem an hem de
  /// saat dilimi olarak girer (`dateAndTime` tekrarı yerel saate bağlıdır).
  String get fingerprint {
    final canonical = jsonEncode([
      'v$_version',
      channelId,
      NotificationService._androidScheduleMode.name,
      title,
      body,
      scheduledDate.millisecondsSinceEpoch,
      scheduledDate.location.name,
      matchDateTimeComponents?.name ?? '-',
      payload ?? '-',
      recurrence ?? '-',
    ]);
    final hash = NotificationIds.fnv1a32(canonical).toRadixString(16);
    return '$hash:${canonical.length}';
  }
}
