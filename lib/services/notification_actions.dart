import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/home/widget_change_signal.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';
import 'package:reminder/util/local_timezone.dart';

/// Hatırlatıcı bildirim aksiyonlarının id'leri (F3.2). Platforma kalıcı
/// olarak yazılır (Android bildirimi, iOS kategorisi); değiştirmeyin.
abstract final class NotificationActionIds {
  static const complete = 'reminder.complete';
  static const snooze10Minutes = 'reminder.snooze_10m';
  static const snooze1Hour = 'reminder.snooze_1h';
  static const snoozeTomorrowMorning = 'reminder.snooze_tomorrow';
}

/// Hatırlatıcı bildirimlerinin iOS kategori id'si.
const String reminderNotificationCategoryId = 'reminder_actions';

/// Android hatırlatıcı bildirimi düğmeleri (§3.3.12): Tamamla · 10 dk · 1 saat.
///
/// Arayüzü açmazlar; aksiyon arka plan isolate'inde işlenir ve bildirim
/// kapatılır.
const List<AndroidNotificationAction> androidReminderActions = [
  AndroidNotificationAction(
    NotificationActionIds.complete,
    'Tamamla',
    showsUserInterface: false,
    cancelNotification: true,
  ),
  AndroidNotificationAction(
    NotificationActionIds.snooze10Minutes,
    '10 dk',
    showsUserInterface: false,
    cancelNotification: true,
  ),
  AndroidNotificationAction(
    NotificationActionIds.snooze1Hour,
    '1 saat',
    showsUserInterface: false,
    cancelNotification: true,
  ),
];

/// iOS bildirim kategorileri (uzun bas, §3.3.12): Tamamla · 10 dk ertele ·
/// 1 saat ertele · Yarın sabah. `foreground` seçeneği yok: aksiyonlar arka
/// plan isolate'inde çalışır.
List<DarwinNotificationCategory> get darwinNotificationCategories => [
      DarwinNotificationCategory(
        reminderNotificationCategoryId,
        actions: [
          DarwinNotificationAction.plain(
            NotificationActionIds.complete,
            'Tamamla',
          ),
          DarwinNotificationAction.plain(
            NotificationActionIds.snooze10Minutes,
            '10 dk ertele',
          ),
          DarwinNotificationAction.plain(
            NotificationActionIds.snooze1Hour,
            '1 saat ertele',
          ),
          DarwinNotificationAction.plain(
            NotificationActionIds.snoozeTomorrowMorning,
            'Yarın sabah',
          ),
        ],
      ),
    ];

/// Aksiyon düğmesine basıldığında (uygulama kapalı veya arka planda) çalışan
/// giriş noktası.
///
/// Plugin'in ayrı Flutter engine'inde çalışır: cubit ve ana isolate'in
/// singleton durumu yoktur. Widget callback'i gibi yalnızca ortamı hazırlar,
/// gerçek servisleri kurar ve işi [handleNotificationAction]'a verir.
@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (!isReminderAction(response)) return;

  // Ayrı engine: veritabanı bağlantısı bu çağrıya özeldir, sonunda kapatılır.
  final repository = ReminderRepository();
  try {
    // Aksiyon engine'i süreç boyunca yaşar ve sonraki aksiyonlarda yeniden
    // kullanılır; SharedPreferences önbelleği (eski depo yedeği) bayat
    // olabilir.
    await (await SharedPreferences.getInstance()).reload();
    await initializeDateFormatting('tr_TR');
    await configureLocalTimezone();
    await handleNotificationAction(
      response,
      repository: repository,
      schedules: buildNotificationActionSchedules(),
      now: DateTime.now(),
    );
  } catch (e, st) {
    debugPrint('Notification action failed: $e\n$st');
  } finally {
    await repository.close();
  }
}

/// Uygulama çalışırken gelen bildirim yanıtları (ana isolate).
///
/// Dokunma → [NotificationTapRouter] ilgili ekranı açar. Aksiyon normalde
/// arka plan giriş noktasına gider; platform yine de buraya iletirse aynı
/// işleyiciyle ele alınır.
void onNotificationResponse(NotificationResponse response) {
  switch (response.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      NotificationTapRouter.instance.openResponse(response);
    case NotificationResponseType.selectedNotificationAction:
      unawaited(_handleActionInForeground(response));
    default:
      break;
  }
}

ScheduleSync? _foregroundSchedules;

Future<void> _handleActionInForeground(NotificationResponse response) async {
  if (!isReminderAction(response)) return;
  // Paylaşılan, referans sayımlı bağlantı: kapatmak uygulamanın deposunu
  // etkilemez.
  final repository = ReminderRepository();
  try {
    await handleNotificationAction(
      response,
      repository: repository,
      schedules: _foregroundSchedules ??= buildNotificationActionSchedules(),
      now: DateTime.now(),
    );
  } catch (e, st) {
    debugPrint('Notification action failed: $e\n$st');
  } finally {
    await repository.close();
  }
}

/// Aksiyon işleyicisinin gerçek servisleri (arka plan isolate'i dahil).
@visibleForTesting
ScheduleSync buildNotificationActionSchedules() => ScheduleSync(
      notifications: NotificationService.instance,
      geofence: GeofenceService.instance,
      homeWidget: const PlatformHomeWidgetSync(),
    );

/// [response] bilinen bir hatırlatıcı aksiyonu ve hatırlatıcı payload'ı
/// taşıyorsa `true`.
bool isReminderAction(NotificationResponse response) =>
    _isKnownAction(response.actionId) &&
    NotificationPayload.parse(response.payload) is ReminderPayload;

bool _isKnownAction(String? id) => switch (id) {
      NotificationActionIds.complete ||
      NotificationActionIds.snooze10Minutes ||
      NotificationActionIds.snooze1Hour ||
      NotificationActionIds.snoozeTomorrowMorning =>
        true,
      _ => false,
    };

/// Erteleme aksiyonunun yeni zamanı; erteleme değilse `null`.
///
/// Kurallar uygulama içi Ertele sheet'iyle ortaktır ([SnoozeOptions.from],
/// F3.5): göreli seçenekler saniyeyi atar, "Yarın sabah" ertesi gün 09:00.
@visibleForTesting
DateTime? snoozedRemindAt(String actionId, DateTime now) {
  final kind = switch (actionId) {
    NotificationActionIds.snooze10Minutes => SnoozeKind.tenMinutes,
    NotificationActionIds.snooze1Hour => SnoozeKind.oneHour,
    NotificationActionIds.snoozeTomorrowMorning => SnoozeKind.tomorrowMorning,
    _ => null,
  };
  if (kind == null) return null;
  return SnoozeOptions.from(now).firstWhere((o) => o.kind == kind).at;
}

/// Bir bildirim aksiyonunu uygular.
///
/// - Tamamla → [completeReminder] (tekrarsızda `isDone: true`, tekrarlayanda
///   bir sonraki tekrar); ertele → `remindAt` yeni zamana ayarlanır
///   (hatırlatıcı zamansız veya gecikmiş olsa da).
/// - Kaydeder, doğum günleri ve ayarları depodan okuyarak **tüm**
///   zamanlamaları [ScheduleSync.syncAll] ile eşitler (F1.2) ve açık
///   uygulamaya [notifyAppOfWidgetChange] ile haber verir (F1.3).
/// - Bilinmeyen aksiyon, hatırlatıcı olmayan payload, bulunamayan veya
///   tamamlanmış hatırlatıcı → hiçbir şey yazılmaz.
///
/// Değişiklik kaydedildiyse `true` döner.
Future<bool> handleNotificationAction(
  NotificationResponse response, {
  required ReminderRepository repository,
  required ScheduleSync schedules,
  required DateTime now,
}) async {
  final actionId = response.actionId;
  final payload = NotificationPayload.parse(response.payload);
  if (actionId == null || !_isKnownAction(actionId)) return false;
  if (payload is! ReminderPayload) return false;

  final reminders = await repository.loadReminders();
  var changed = false;
  final updated = <Reminder>[
    for (final r in reminders)
      if (r.id != payload.reminderId || r.isDone)
        r
      else
        () {
          changed = true;
          final snoozed = snoozedRemindAt(actionId, now);
          // Tamamla: uygulama içiyle aynı kural; tekrarlayan hatırlatıcı
          // bir sonraki tekrara ilerler (F3.1).
          return snoozed == null
              ? completeReminder(r, now)
              : r.copyWith(remindAt: () => snoozed);
        }(),
  ];
  if (!changed) return false;

  await repository.saveReminders(updated);
  final birthdays = await repository.loadBirthdays();
  final settings = await repository.loadSettings();
  await schedules.syncAll(
    reminders: updated,
    birthdays: birthdays,
    settings: settings,
  );
  notifyAppOfWidgetChange(); // F1.3: açık uygulama depodan yeniden yüklesin.
  return true;
}
