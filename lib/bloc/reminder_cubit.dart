import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';

class ReminderState {
  final List<Reminder> reminders;
  final List<Birthday> birthdays;
  final AppSettings settings;

  const ReminderState({
    required this.reminders,
    required this.birthdays,
    required this.settings,
  });

  List<Reminder> get active =>
      reminders.where((r) => !r.isDone).toList(growable: false);

  List<Reminder> get completed =>
      reminders.where((r) => r.isDone).toList(growable: false);

  /// Bir sonraki doğum gününe göre artan sıralı liste.
  List<Birthday> get upcomingBirthdays {
    final list = [...birthdays];
    list.sort((a, b) => a.daysUntilNext().compareTo(b.daysUntilNext()));
    return List.unmodifiable(list);
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
    );
  }
}

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit(
    this._repository,
    this._notifications,
  ) : super(const ReminderState(
          reminders: [],
          birthdays: [],
          settings: AppSettings(),
        ));

  final ReminderRepository _repository;
  final NotificationService _notifications;

  Future<void> load() async {
    final reminders = await _repository.loadReminders();
    final birthdays = await _repository.loadBirthdays();
    final settings = await _repository.loadSettings();
    reminders.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final ta = a.remindAt;
      final tb = b.remindAt;
      if (ta != null && tb != null) return ta.compareTo(tb);
      if (ta != null) return -1;
      if (tb != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    emit(ReminderState(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
    ));
    await _notifications.syncFromReminders(
      reminders,
      notificationsEnabled: settings.notificationsEnabled,
    );
    await _notifications.scheduleBirthdays(
      birthdays,
      notificationsEnabled: settings.notificationsEnabled,
    );
    await GeofenceService.instance.syncWithReminders(
      reminders,
      notificationsEnabled: settings.notificationsEnabled,
    );
    await syncRemindersToHomeWidget(reminders);
  }

  Future<void> _persistAndSync() async {
    final s = state;
    await _repository.saveReminders(s.reminders);
    await _repository.saveBirthdays(s.birthdays);
    await _repository.saveSettings(s.settings);
    await _notifications.syncFromReminders(
      s.reminders,
      notificationsEnabled: s.settings.notificationsEnabled,
    );
    await _notifications.scheduleBirthdays(
      s.birthdays,
      notificationsEnabled: s.settings.notificationsEnabled,
    );
    await GeofenceService.instance.syncWithReminders(
      s.reminders,
      notificationsEnabled: s.settings.notificationsEnabled,
    );
    await syncRemindersToHomeWidget(s.reminders);
  }

  Future<void> addReminder(Reminder reminder) async {
    final next = [...state.reminders, reminder];
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
  }

  Future<void> updateReminder(Reminder updated) async {
    final next = state.reminders
        .map((r) => r.id == updated.id ? updated : r)
        .toList(growable: false);
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
    final next = state.reminders.where((r) => r.id != id).toList();
    emit(state.copyWith(reminders: next));
    if (removed != null) {
      await _notifications.cancelReminder(removed);
    }
    await _persistAndSync();
  }

  Future<void> toggleDone(String id) async {
    final next = state.reminders.map((r) {
      if (r.id != id) return r;
      return Reminder(
        id: r.id,
        title: r.title,
        note: r.note,
        isDone: !r.isDone,
        createdAt: r.createdAt,
        remindAt: r.remindAt,
        categoryId: r.categoryId,
        customCategoryLabel: r.customCategoryLabel,
        locationTriggerEnabled: r.locationTriggerEnabled,
        locationLatitude: r.locationLatitude,
        locationLongitude: r.locationLongitude,
        locationRadiusMeters: r.locationRadiusMeters,
        locationPlaceLabel: r.locationPlaceLabel,
      );
    }).toList();
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
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
    await GeofenceService.instance.syncWithReminders(
      [],
      notificationsEnabled: false,
    );
    await _repository.clearAll();
    emit(const ReminderState(
      reminders: [],
      birthdays: [],
      settings: AppSettings(),
    ));
    await syncRemindersToHomeWidget(const []);
  }
}
