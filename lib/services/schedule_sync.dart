import 'dart:async';

import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/sync_interfaces.dart';

/// Zamanlanmış bildirimleri saklanan durumla eşitleyen servis.
///
/// Gerçek uygulama: `NotificationService`. Sözleşme: çağrıdan sonra bekleyen
/// hatırlatıcı **ve** doğum günü bildirimleri tam olarak verilen listelere
/// karşılık gelir; biri diğerini silemez.
abstract interface class NotificationSync {
  Future<void> syncSchedules({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  });
}

/// Tüm zamanlamaları (bildirimler, geofence'ler, ana ekran widget'ı) saklanan
/// durumla eşitleyen **tek giriş noktası** (F1.2).
///
/// `ReminderCubit` (ana isolate) ve widget arka plan callback'i (ayrı isolate)
/// aynı sırayı ve aynı kuralları kullansın diye buradan geçer. Yeni bir
/// zamanlama türü eklenirse buraya eklenir; çağıranlar tek tek servis
/// çağırmaz.
///
/// **Sıralama ve birleştirme (F1.7):** [syncAll] çağrıları hiçbir zaman iç içe
/// geçmez; aynı anda tek senkron çalışır. Biri çalışırken gelen çağrılar
/// kuyruğa alınır ve birleştirilir: her çağrı saklanan durumun **tam** bir
/// anlık görüntüsünü taşıdığı için yalnızca en son bekleyen istek çalıştırılır;
/// arada kalan istekler atlanır. Kuyruktaki tüm çağıranların `Future`'ı bu son
/// senkron bittiğinde (onun hatasıyla birlikte) tamamlanır. Böylece hızlı art
/// arda düzenlemeler iptal/kurulum adımlarını karıştıramaz.
///
/// Sınır: sıralama örnek başınadır. Widget arka plan callback'i ayrı bir
/// isolate'te kendi örneğini kurar; isolate'ler arası yarışlar bu sınıfın
/// kapsamı dışındadır (fark bazlı senkron bir sonraki çağrıda durumu yine
/// düzeltir).
class ScheduleSync {
  ScheduleSync({
    required NotificationSync notifications,
    required GeofenceSync geofence,
    required HomeWidgetSync homeWidget,
  })  : _notifications = notifications,
        _geofence = geofence,
        _homeWidget = homeWidget;

  final NotificationSync _notifications;
  final GeofenceSync _geofence;
  final HomeWidgetSync _homeWidget;

  bool _running = false;
  _SyncRequest? _queued;
  Completer<void>? _queuedDone;

  /// Sırasıyla bildirimleri, geofence'leri ve widget'ı günceller.
  ///
  /// Başka bir senkron çalışıyorsa bekler; bu arada daha yeni bir çağrı
  /// gelirse bu çağrının durumu yerine onunki kurulur (bkz. sınıf notu).
  Future<void> syncAll({
    required List<Reminder> reminders,
    required List<Birthday> birthdays,
    required AppSettings settings,
  }) {
    final request = _SyncRequest(reminders, birthdays, settings);
    if (_running) {
      _queued = request;
      return (_queuedDone ??= Completer<void>()).future;
    }
    return _run(request);
  }

  /// [request]'i çalıştırır, bitince (hata olsa da) kuyruktaki son isteği
  /// başlatır. `_running` ilk `await`'ten önce, eşzamanlı olarak ayarlanır.
  Future<void> _run(_SyncRequest request) async {
    _running = true;
    try {
      await _syncNow(request);
    } finally {
      _running = false;
      final next = _queued;
      final done = _queuedDone;
      _queued = null;
      _queuedDone = null;
      if (next != null && done != null) done.complete(_run(next));
    }
  }

  Future<void> _syncNow(_SyncRequest request) async {
    final enabled = request.settings.notificationsEnabled;
    await _notifications.syncSchedules(
      reminders: request.reminders,
      birthdays: request.birthdays,
      notificationsEnabled: enabled,
    );
    await _geofence.syncWithReminders(
      request.reminders,
      notificationsEnabled: enabled,
    );
    await _homeWidget.sync(request.reminders);
  }

  /// Zamanlamalara dokunmadan yalnızca widget'ı yeniler (veri değişmediğinde).
  Future<void> refreshHomeWidget(List<Reminder> reminders) =>
      _homeWidget.sync(reminders);
}

/// [ScheduleSync.syncAll] argümanlarının anlık görüntüsü.
class _SyncRequest {
  const _SyncRequest(this.reminders, this.birthdays, this.settings);

  final List<Reminder> reminders;
  final List<Birthday> birthdays;
  final AppSettings settings;
}
