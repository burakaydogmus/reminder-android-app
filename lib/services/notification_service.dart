import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/domain/notification_ids.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
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
///
/// **Dil (F6.1):** başlık, gövde, kanal adları ve aksiyon düğmeleri kayıtlı
/// "Dil" seçimine (yoksa sistem diline) göre Türkçe veya İngilizcedir;
/// [BackgroundLocalizations] ile her senkronda ve her konum bildiriminde
/// yeniden çözülür (arka plan isolate'leri dahil). Dil parmak izine girer:
/// dil değişince bekleyen bildirimler yeni dilde yeniden kurulur. iOS aksiyon
/// kategorisi [initialize] anındaki dille kaydedilir (bir sonraki açılışta
/// güncellenir).
///
/// **Tam zamanlı alarm yedeği (F6.2c):** Android 12+'da "Alarmlar ve
/// hatırlatıcılar" izni yoksa bildirimler `inexactAllowWhileIdle` ile kurulur
/// (birkaç dakika gecikebilir, ama gelir); izin varsa `exactAllowWhileIdle`.
/// Mod her senkronda bir kez belirlenir ve parmak izine girer; izin verilince
/// bir sonraki senkron (ör. uygulama ön plana dönünce) bildirimleri tam
/// zamanlı olarak yeniden kurar.
class NotificationService implements NotificationSync {
  NotificationService._(
    this._plugin,
    this._fingerprints,
    Future<bool> Function()? canScheduleExact,
    this._localizations,
  ) : _canScheduleExactOverride = canScheduleExact;

  static final NotificationService instance = NotificationService._(
    FlutterLocalNotificationsPlugin(),
    const NotificationFingerprintStore(),
    null,
    BackgroundLocalizations.load,
  );

  /// Gerçek plugin yerine sahte bir plugin ile çalışan örnek (testler).
  /// [canScheduleExact] tam zamanlı alarm iznini taklit eder (varsayılan:
  /// izin var); [localizations] bildirim dilini verir (varsayılan: Türkçe).
  @visibleForTesting
  factory NotificationService.forTesting(
    FlutterLocalNotificationsPlugin plugin, {
    NotificationFingerprintStore fingerprints =
        const NotificationFingerprintStore(),
    Future<bool> Function()? canScheduleExact,
    Future<AppLocalizations> Function()? localizations,
  }) =>
      NotificationService._(
        plugin,
        fingerprints,
        canScheduleExact ?? () async => true,
        localizations ?? () async => AppL10n.turkish,
      );

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationFingerprintStore _fingerprints;
  final Future<bool> Function()? _canScheduleExactOverride;

  /// Bildirim metinlerinin dili (F6.1): kayıtlı "Dil" + sistem dili.
  final Future<AppLocalizations> Function() _localizations;

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
      notificationCategories:
          darwinNotificationCategories(await _localizations()),
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
    final l10n = await _localizations();

    const channelId = 'reminders_geo_v1';

    final place = r.locationPlaceLabel?.trim();
    final body = reminderNotificationBody(
      r,
      l10n,
      context: (place != null && place.isNotEmpty) ? place : null,
      fallback: l10n.notifGeoFallback,
    );
    final bigText = reminderSubtaskBigText(r, body, l10n);
    final subtitle = reminderSubtaskSubtitle(r, l10n);

    final android = AndroidNotificationDetails(
      channelId,
      l10n.notifChannelLocation,
      channelDescription: l10n.notifChannelLocationDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      actions: androidReminderActions(l10n),
      styleInformation:
          bigText == null ? null : BigTextStyleInformation(bigText),
    );

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: reminderNotificationCategoryId,
      subtitle: subtitle,
    );

    final details = NotificationDetails(android: android, iOS: darwin);

    await _plugin.show(
      id: r.geoNotificationId,
      title: r.title.trim().isEmpty ? l10n.notifTitleFallback : r.title.trim(),
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
      final l10n = await _localizations();
      for (final r in reminders) {
        if (r.isDone) continue;
        final at = reminderFireTime(r, now);
        if (at == null) continue;
        final spec = _reminderSpec(r, tz.TZDateTime.from(at, tz.local), l10n);
        desired[spec.id] = spec;
      }

      // Yıllık tekrarlayan doğum günü hatırlatmaları: her aktif offset için
      // ayrı bildirim, `DateTimeComponents.dateAndTime` ile her yıl yeniden
      // tetiklenir.
      for (final b in birthdays) {
        for (final spec in _birthdaySpecs(b, l10n)) {
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
    // Mod senkron başına bir kez belirlenir (F6.2c).
    var mode = desired.isEmpty
        ? exactScheduleMode
        : scheduleModeFor(canScheduleExact: await _canScheduleExact());
    final next = <int, String>{};
    for (final spec in desired.values) {
      final fingerprint = spec.fingerprint(mode);
      final upToDate = stored != null &&
          pendingIds.contains(spec.id) &&
          stored[spec.id] == fingerprint;
      if (upToDate) {
        next[spec.id] = fingerprint;
        continue;
      }
      try {
        await _schedule(spec, mode);
      } on PlatformException catch (e) {
        // Tam zamanlı kurulum reddedildi (ör. izin kontrolden sonra geri
        // alındı: `exact_alarms_not_permitted`). Senkron durmaz: bu ve kalan
        // bildirimler inexact kurulur; izin dönünce parmak izi farkı onları
        // yeniden tam zamanlı kurar.
        if (mode == inexactScheduleMode) rethrow;
        debugPrint('Exact alarm scheduling failed (${e.code}); '
            'falling back to inexact.');
        mode = inexactScheduleMode;
        await _schedule(spec, mode);
      }
      next[spec.id] = spec.fingerprint(mode);
    }

    // Kurulumlardan **sonra** yazılır: yarıda kalan bir senkron eski parmak
    // izlerini bırakır ve bir sonraki senkron farkı yeniden kurar.
    if (stored == null || !mapEquals(stored, next)) {
      await _fingerprints.save(next);
    }
  }

  Future<void> _schedule(_ScheduleSpec spec, AndroidScheduleMode mode) =>
      _plugin.zonedSchedule(
        id: spec.id,
        title: spec.title,
        body: spec.body,
        scheduledDate: spec.scheduledDate,
        notificationDetails: spec.details,
        androidScheduleMode: mode,
        matchDateTimeComponents: spec.matchDateTimeComponents,
        payload: spec.payload,
      );

  /// Tam zamanlı alarm izni varken kullanılan mod.
  static const exactScheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

  /// İzin yokken kullanılan mod (`setAndAllowWhileIdle`): Doze'da da çalışır,
  /// izin gerektirmez; sistem birkaç dakika geciktirebilir.
  static const inexactScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

  /// Senkronda kullanılacak Android zamanlama modu (F6.2c).
  @visibleForTesting
  static AndroidScheduleMode scheduleModeFor(
          {required bool canScheduleExact}) =>
      canScheduleExact ? exactScheduleMode : inexactScheduleMode;

  /// Android 12+'da `canScheduleExactNotifications()`; Android dışında (iOS)
  /// ve eski Android'de `true`. Kontrol hata verirse tam zamanlı denenir;
  /// kurulum reddedilirse senkron inexact'a düşer.
  Future<bool> _canScheduleExact() async {
    final override = _canScheduleExactOverride;
    if (override != null) return override();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? true;
    } on PlatformException catch (e) {
      debugPrint('canScheduleExactNotifications failed: ${e.code}');
      return true;
    }
  }

  /// Parmak izine giren kurulum biçimi sürümü (testler için görünür).
  @visibleForTesting
  static const scheduleFingerprintVersion = _ScheduleSpec._version;

  List<_ScheduleSpec> _birthdaySpecs(Birthday b, AppLocalizations l10n) {
    const channelId = 'reminders_birthdays_v1';

    // Doğum günleri aksiyon taşımaz; dokunmak Doğum günleri listesini açar.
    final android = AndroidNotificationDetails(
      channelId,
      l10n.notifChannelBirthdays,
      channelDescription: l10n.notifChannelBirthdaysDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: android, iOS: darwin);

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
        locale: l10n.localeName,
        title: birthdayNotificationTitle(b, offset, l10n),
        body: birthdayNotificationBody(offset, l10n),
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
  static String birthdayNotificationTitle(
    Birthday b,
    int offsetMinutes,
    AppLocalizations l10n,
  ) {
    if (offsetMinutes == 0) return l10n.notifBirthdayTitle(b.name);
    return l10n.notifBirthdayTitleSoon(b.name);
  }

  /// Doğum günü bildirim gövdesi; yalnızca offset'e bağlıdır (yaş içermez).
  @visibleForTesting
  static String birthdayNotificationBody(
    int offsetMinutes,
    AppLocalizations l10n,
  ) {
    if (offsetMinutes <= 0) return l10n.notifBirthdayToday;
    if (offsetMinutes < 60) return l10n.notifBirthdayInMinutes(offsetMinutes);
    if (offsetMinutes < 1440) {
      return l10n.notifBirthdayInHours(offsetMinutes ~/ 60);
    }
    final days = offsetMinutes ~/ 1440;
    if (days == 1) return l10n.notifBirthdayTomorrow;
    return l10n.notifBirthdayInDays(days);
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

  /// Android BigText görünümünde listelenen en fazla açık madde sayısı.
  static const maxListedSubtasks = 5;

  /// Hatırlatıcı bildirim gövdesi (F3.3): not, yoksa [context] (ör. konum
  /// adı), o da yoksa [fallback]. Açık madde varsa "N madde kaldı" eklenir
  /// ("Migros Kadıköy · 4 madde kaldı"); o durumda genel [fallback] metni
  /// yerine yalnızca "4 madde kaldı" yazılır.
  @visibleForTesting
  static String reminderNotificationBody(
    Reminder r,
    AppLocalizations l10n, {
    String? context,
    String? fallback,
  }) {
    final note = r.note?.trim();
    final lead = (note != null && note.isNotEmpty) ? note : context;
    final open = r.subtasks.openCount;
    if (open == 0) return lead ?? fallback ?? l10n.notifBodyFallback;
    final remaining = l10n.notifSubtasksLeft(open);
    return lead == null
        ? remaining
        : l10n.notifBodyWithSubtasks(lead, remaining);
  }

  /// Android genişletilmiş metni (BigTextStyle): [body] ve altında ilk
  /// [maxListedSubtasks] açık madde ("• Süt"), fazlası "… ve N madde daha".
  /// Açık madde yoksa `null` (düz bildirim).
  @visibleForTesting
  static String? reminderSubtaskBigText(
    Reminder r,
    String body,
    AppLocalizations l10n,
  ) {
    final open = r.subtasks.open;
    if (open.isEmpty) return null;
    final lines = [
      body,
      for (final s in open.take(maxListedSubtasks)) '• ${s.title.trim()}',
      if (open.length > maxListedSubtasks)
        l10n.notifSubtasksMore(open.length - maxListedSubtasks),
    ];
    return lines.join('\n');
  }

  /// iOS bildiriminin alt başlığı: ilk [maxListedSubtasks] açık madde tek
  /// satırda, "Süt · Ekmek · … ve 2 madde daha". Açık madde yoksa `null`.
  ///
  /// **Neden alt başlık, gövdeye eklemek değil (F6.4):** gövde platformlar
  /// arasında ortaktır (`zonedSchedule` tek `body` alır), bu yüzden maddeleri
  /// gövdeye eklemek Android'in daraltılmış tek satırlık metnini de bozardı —
  /// orada maddeler zaten `BigTextStyleInformation` ile gösteriliyor
  /// ([reminderSubtaskBigText]). `DarwinNotificationDetails.subtitle`
  /// yalnızca iOS'a giden, Android'in yok saydığı tek alandır; başlığın
  /// altında, gövdenin üstünde çıkar. Tek satır olduğu için maddeler madde
  /// imi yerine " · " ile ayrılır.
  @visibleForTesting
  static String? reminderSubtaskSubtitle(Reminder r, AppLocalizations l10n) {
    final open = r.subtasks.open;
    if (open.isEmpty) return null;
    return [
      for (final s in open.take(maxListedSubtasks)) s.title.trim(),
      if (open.length > maxListedSubtasks)
        l10n.notifSubtasksMore(open.length - maxListedSubtasks),
    ].join(' · ');
  }

  _ScheduleSpec _reminderSpec(
    Reminder r,
    tz.TZDateTime scheduled,
    AppLocalizations l10n,
  ) {
    const channelId = 'reminders_channel_v1';

    final body = reminderNotificationBody(r, l10n);
    final bigText = reminderSubtaskBigText(r, body, l10n);
    final subtitle = reminderSubtaskSubtitle(r, l10n);

    final android = AndroidNotificationDetails(
      channelId,
      l10n.notifChannelReminders,
      channelDescription: l10n.notifChannelRemindersDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      actions: androidReminderActions(l10n),
      styleInformation:
          bigText == null ? null : BigTextStyleInformation(bigText),
    );

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: reminderNotificationCategoryId,
      subtitle: subtitle,
    );

    final details = NotificationDetails(android: android, iOS: darwin);

    return _ScheduleSpec(
      id: r.notificationId,
      channelId: channelId,
      locale: l10n.localeName,
      title: r.title.trim().isEmpty ? l10n.notifTitleFallback : r.title.trim(),
      body: body,
      scheduledDate: scheduled,
      details: details,
      matchDateTimeComponents: reminderRepeatComponents(r.recurrence),
      payload: ReminderPayload(r.id).encode(),
      recurrence: jsonEncode(r.recurrence.toJson()),
      subtasks: bigText,
      subtaskSubtitle: subtitle,
    );
  }
}

/// Zamanlanacak tek bir bildirimin tam tanımı (F1.7 fark hesabı).
class _ScheduleSpec {
  const _ScheduleSpec({
    required this.id,
    required this.channelId,
    required this.locale,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.details,
    this.matchDateTimeComponents,
    this.payload,
    this.recurrence,
    this.subtasks,
    this.subtaskSubtitle,
  });

  /// Kurulum biçimi (kanal ayarları, zamanlama modu, aksiyonlar/kategori vb.)
  /// değişirse artırın; tüm bildirimler bir kez yeniden kurulur.
  ///
  /// - v2 (F3.2): hatırlatıcılara Tamamla/Ertele aksiyonları ve iOS kategorisi
  ///   eklendi; eski bildirimler aksiyonlarla yeniden kurulur.
  /// - v3 (F3.1): tekrar kuralı parmak izine girdi, tekrarlayan hatırlatıcılar
  ///   `matchDateTimeComponents` ile kurulur.
  /// - v4 (F3.3): gövdede "N madde kaldı", Android BigText açık maddeleri
  ///   listeler; madde metni parmak izine girdi.
  /// - v5 (F6.2c): Android zamanlama modu izne göre seçilir (exact /
  ///   inexact) ve senkronda belirlenen mod parmak izine girer.
  /// - v6 (F6.1): metinler, kanal adları ve aksiyonlar uygulama dilinde;
  ///   dil parmak izine girdi (dil değişince hepsi yeniden kurulur).
  /// - v7 (F6.4): iOS bildirimi açık maddeleri `subtitle` ile gösterir;
  ///   alt başlık parmak izine girdi, kurulu bildirimler bir kez yeniden
  ///   kurulur.
  static const _version = 7;

  final int id;
  final String channelId;

  /// Metinlerin dili (`tr` / `en`); kanal adları ve aksiyon düğmeleri de
  /// ona göre olduğu için parmak izine girer.
  final String locale;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails details;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;

  /// Hatırlatıcının tekrar kuralı (JSON); doğum günlerinde `null`. Kural
  /// değişince (aynı sonraki tarih olsa bile) bildirim yeniden kurulur.
  final String? recurrence;

  /// Android BigText metni (açık maddeler, F3.3); madde yoksa `null`. Madde
  /// eklenir, işaretlenir veya yeniden adlandırılırsa bildirim yeniden kurulur.
  final String? subtasks;

  /// iOS alt başlığı (açık maddeler tek satırda, F6.4); madde yoksa `null`.
  /// Android metninden ayrı tutulur ki biri değişince parmak izi de değişsin.
  final String? subtaskSubtitle;

  /// Bildirimin [mode] ile kurulduğu haliyle eşleşen kısa özet. Zaman hem an
  /// hem de saat dilimi olarak girer (`dateAndTime` tekrarı yerel saate
  /// bağlıdır). Mod değişince (izin verildi / geri alındı) bildirim yeniden
  /// kurulur.
  String fingerprint(AndroidScheduleMode mode) {
    final canonical = jsonEncode([
      'v$_version',
      channelId,
      locale,
      mode.name,
      title,
      body,
      scheduledDate.millisecondsSinceEpoch,
      scheduledDate.location.name,
      matchDateTimeComponents?.name ?? '-',
      payload ?? '-',
      recurrence ?? '-',
      subtasks ?? '-',
      subtaskSubtitle ?? '-',
    ]);
    final hash = NotificationIds.fnv1a32(canonical).toRadixString(16);
    return '$hash:${canonical.length}';
  }
}
