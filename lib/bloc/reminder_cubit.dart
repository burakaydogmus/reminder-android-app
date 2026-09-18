import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:reminder/services/sync_interfaces.dart';

class ReminderState {
  final List<Reminder> reminders;
  final List<Birthday> birthdays;
  final AppSettings settings;

  /// Tarihe bağlı getter'ların (ör. [upcomingBirthdays]) kullandığı saat.
  /// Testlerde sabit bir zaman verilebilir; varsayılan `DateTime.now`.
  final DateTime Function() clock;

  const ReminderState({
    required this.reminders,
    required this.birthdays,
    required this.settings,
    this.clock = DateTime.now,
  });

  List<Reminder> get active =>
      reminders.where((r) => !r.isDone).toList(growable: false);

  List<Reminder> get completed =>
      reminders.where((r) => r.isDone).toList(growable: false);

  /// Bir sonraki doğum gününe göre artan sıralı liste (eşitlikte isim).
  List<Birthday> get upcomingBirthdays {
    final now = clock();
    final entries = [
      for (final b in birthdays)
        (birthday: b, next: b.nextOccurrence(from: now)),
    ];
    entries.sort((a, b) {
      final byDate = a.next.compareTo(b.next);
      if (byDate != 0) return byDate;
      return a.birthday.name.compareTo(b.birthday.name);
    });
    return List.unmodifiable(entries.map((e) => e.birthday));
  }

  ReminderState copyWith({
    List<Reminder>? reminders,
    List<Birthday>? birthdays,
    AppSettings? settings,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      birthdays: birthdays ?? this.birthdays,
      settings: settings ?? this.settings,
      clock: clock,
    );
  }
}

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit(
    this._repository,
    this._notifications, {
    required GeofenceSync geofence,
    required HomeWidgetSync homeWidget,
    DateTime Function() now = DateTime.now,
  })  : _geofence = geofence,
        _homeWidget = homeWidget,
        _now = now,
        _schedules = ScheduleSync(
          notifications: _notifications,
          geofence: geofence,
          homeWidget: homeWidget,
        ),
        super(ReminderState(
          reminders: const [],
          birthdays: const [],
          settings: const AppSettings(),
          clock: now,
        ));

  /// Saat kaynağı (testlerde sabitlenir); yayınlanan her duruma aktarılır.
  final DateTime Function() _now;

  final ReminderRepository _repository;
  final NotificationService _notifications;
  final GeofenceSync _geofence;
  final HomeWidgetSync _homeWidget;

  /// Tüm zamanlamaların tek giriş noktası; widget callback'i de aynısını
  /// kullanır.
  final ScheduleSync _schedules;

  /// Durumdaki hatırlatıcı listesi her zaman [compareReminders] sırasındadır;
  /// listeyi değiştiren her yol bu yardımcıdan geçer.
  static List<Reminder> _sorted(Iterable<Reminder> reminders) =>
      List<Reminder>.of(reminders)..sort(compareReminders);

  Future<void> load() async {
    final reminders = _sorted(await _repository.loadReminders());
    final birthdays = await _repository.loadBirthdays();
    final settings = await _repository.loadSettings();
    emit(ReminderState(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
      clock: _now,
    ));
    await _schedules.syncAll(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
    );
  }

  Future<void> _persistAndSync() async {
    final s = state;
    await _repository.saveReminders(s.reminders);
    await _repository.saveBirthdays(s.birthdays);
    await _repository.saveSettings(s.settings);
    await _schedules.syncAll(
      reminders: s.reminders,
      birthdays: s.birthdays,
      settings: s.settings,
    );
  }

  Future<void> addReminder(Reminder reminder) async {
    final next = _sorted([...state.reminders, reminder]);
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
  }

  Future<void> updateReminder(Reminder updated) async {
    final next =
        _sorted(state.reminders.map((r) => r.id == updated.id ? updated : r));
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
  }

  Future<void> deleteReminder(String id) async {
    Reminder? removed;
    for (final r in state.reminders) {
      if (r.id == id) {
        removed = r;
        break;
      }
    }
    final next = _sorted(state.reminders.where((r) => r.id != id));
    emit(state.copyWith(reminders: next));
    if (removed != null) {
      await _notifications.cancelReminder(removed);
    }
    await _persistAndSync();
  }

  /// Tamamlanmışsa geri alır, değilse [completeReminder] kuralıyla tamamlar:
  /// tekrarlayan hatırlatıcı bitmez, bir sonraki tekrara ilerler (F3.1).
  ///
  /// Güncellenen hatırlatıcıyı döndürür (UI "Sonraki: …" geri bildirimi
  /// için); id bulunamazsa `null`.
  Future<Reminder?> toggleDone(String id) async {
    Reminder? updated;
    final next = _sorted(state.reminders.map((r) {
      if (r.id != id) return r;
      return updated =
          r.isDone ? r.copyWith(isDone: false) : completeReminder(r, _now());
    }));
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
    return updated;
  }

  Future<void> addBirthday(Birthday birthday) async {
    final next = [...state.birthdays, birthday];
    emit(state.copyWith(birthdays: next));
    await _persistAndSync();
  }

  Future<void> updateBirthday(Birthday updated) async {
    final next = state.birthdays
        .map((b) => b.id == updated.id ? updated : b)
        .toList(growable: false);
    emit(state.copyWith(birthdays: next));
    await _persistAndSync();
  }

  Future<void> deleteBirthday(String id) async {
    Birthday? removed;
    for (final b in state.birthdays) {
      if (b.id == id) {
        removed = b;
        break;
      }
    }
    final next = state.birthdays.where((b) => b.id != id).toList();
    emit(state.copyWith(birthdays: next));
    if (removed != null) {
      await _notifications.cancelBirthday(removed);
    }
    await _persistAndSync();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    emit(state.copyWith(
      settings: state.settings.copyWith(notificationsEnabled: enabled),
    ));
    await _persistAndSync();
  }

  Future<void> setThemeMode(String themeMode) async {
    if (state.settings.themeMode == themeMode) return;
    emit(state.copyWith(
      settings: state.settings.copyWith(themeMode: themeMode),
    ));
    await _repository.saveSettings(state.settings);
  }

  Future<void> clearAllData() async {
    await _notifications.cancelAll();
    await _geofence.syncWithReminders(
      [],
      notificationsEnabled: false,
    );
    await _repository.clearAll();
    emit(ReminderState(
      reminders: const [],
      birthdays: const [],
      settings: const AppSettings(),
      clock: _now,
    ));
    await _homeWidget.sync(const []);
  }
}
