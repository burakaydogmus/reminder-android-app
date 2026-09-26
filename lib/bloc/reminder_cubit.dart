import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/domain/routine_apply.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:reminder/services/sync_interfaces.dart';

class ReminderState {
  final List<Reminder> reminders;
  final List<Birthday> birthdays;
  final AppSettings settings;

  /// Kategoriler (F4.3), görüntüleme sırasıyla. Yalnızca kategoriler
  /// değişince yeni bir nesne olur, böylece `context.select` ile okuyan
  /// arayüz diğer değişikliklerde yeniden çizilmez. Verilmezse yalnızca
  /// yerleşikler ([CategoryCatalog.builtIns]).
  CategoryCatalog get categories => _categories ?? CategoryCatalog.builtIns;
  final CategoryCatalog? _categories;

  /// Rutinler (F3.7), görüntüleme sırasıyla. Kategoriler gibi yalnızca
  /// rutinler değişince yeni bir liste nesnesi olur.
  List<Routine> get routines => _routines ?? const [];
  final List<Routine>? _routines;

  /// Tarihe bağlı getter'ların (ör. [upcomingBirthdays]) kullandığı saat.
  /// Testlerde sabit bir zaman verilebilir; varsayılan `DateTime.now`.
  final DateTime Function() clock;

  const ReminderState({
    required this.reminders,
    required this.birthdays,
    required this.settings,
    CategoryCatalog? categories,
    List<Routine>? routines,
    this.clock = DateTime.now,
  })  : _categories = categories,
        _routines = routines;

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
    CategoryCatalog? categories,
    List<Routine>? routines,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      birthdays: birthdays ?? this.birthdays,
      settings: settings ?? this.settings,
      categories: categories ?? this.categories,
      routines: routines ?? this.routines,
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
    String Function()? newId,
  })  : _geofence = geofence,
        _homeWidget = homeWidget,
        _now = now,
        _newId = newId ?? const Uuid().v4,
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

  /// Cubit'in kendi oluşturduğu kayıtların kimlik üreteci (rutin uygulama,
  /// F3.7); testlerde sabitlenir.
  final String Function() _newId;

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
    final loaded = CategoryCatalog(await _repository.loadCategories());
    final loadedRoutines = RoutineList.normalized(
      await _repository.loadRoutines(),
    );
    emit(ReminderState(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
      // Aynı içerik → aynı nesne (select ile okuyanlar yeniden çizilmez).
      categories: loaded == state.categories ? state.categories : loaded,
      routines: _sameRoutines(loadedRoutines, state.routines)
          ? state.routines
          : loadedRoutines,
      clock: _now,
    ));
    await _schedules.syncAll(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
      categories: state.categories,
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
      categories: s.categories,
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

  /// Birden çok doğum günü ekler (rehberden aktarma, F7.3): liste **tek**
  /// [ReminderRepository.saveBirthdays] transaction'ıyla yazılır ve sonda
  /// **bir kez** [ScheduleSync.syncAll] çalışır.
  ///
  /// [addBirthday]'i N kez çağırmak N kalıcılaştırma + N fark tabanlı zamanlama
  /// eşitlemesi demekti; 200 kişilik bir aktarma bunu görünür biçimde
  /// yavaşlatıyordu. Tekli API aynen korunur.
  ///
  /// Yalnızca doğum günleri değiştiği için hatırlatıcılar ve ayarlar yeniden
  /// yazılmaz. Yazma başarısız olursa transaction geri alınır: yarım yazılmış
  /// bir durum kalmaz.
  Future<void> addBirthdays(Iterable<Birthday> birthdays) async {
    final added = birthdays.toList(growable: false);
    if (added.isEmpty) return;
    final next = [...state.birthdays, ...added];
    emit(state.copyWith(birthdays: next));
    final s = state;
    await _repository.saveBirthdays(s.birthdays);
    await _schedules.syncAll(
      reminders: s.reminders,
      birthdays: s.birthdays,
      settings: s.settings,
      categories: s.categories,
    );
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

  /// Kullanıcı kategorisi ekler (yeni kimlik, listenin sonuna) veya aynı
  /// kimlikli kategoriyi günceller (sırası korunur). Yerleşik kategoriler
  /// düzenlenemez; onlar için hiçbir şey yapmaz.
  Future<void> saveCategory(ReminderCategory category) async {
    if (category.isBuiltIn) return;
    final current = state.categories.ordered;
    final exists = state.categories.contains(category.id);
    final next = exists
        ? [
            for (final c in current)
              c.id == category.id ? category.copyWith(position: c.position) : c
          ]
        : [...current, category.copyWith(position: current.length)];
    await _saveCategories(next);
  }

  /// Kategorileri [orderedIds] sırasına dizer (yerleşikler dahil). Listede
  /// olmayan kategoriler mevcut sıralarıyla sona eklenir, bilinmeyen
  /// kimlikler yok sayılır.
  Future<void> reorderCategories(List<String> orderedIds) async {
    final byId = {for (final c in state.categories.ordered) c.id: c};
    final next = <ReminderCategory>[
      for (final id in orderedIds)
        if (byId.remove(id) case final c?) c,
      ...state.categories.ordered.where((c) => byId.containsKey(c.id)),
    ];
    await _saveCategories([
      for (var i = 0; i < next.length; i++) next[i].copyWith(position: i),
    ]);
  }

  /// [from] konumundaki kategoriyi [to] konumuna taşır (0 tabanlı, taşıma
  /// sonrası dizin).
  Future<void> moveCategory(int from, int to) async {
    final ids = [for (final c in state.categories.ordered) c.id];
    if (from < 0 || from >= ids.length) return;
    final id = ids.removeAt(from);
    ids.insert(to.clamp(0, ids.length), id);
    await reorderCategories(ids);
  }

  /// Kullanıcı kategorisini siler (depoda yumuşak silme); hatırlatıcıları
  /// "Diğer"e taşınır. Taşınan hatırlatıcı sayısını döndürür. Yerleşik veya
  /// bilinmeyen kimlik → 0, değişiklik yok.
  Future<int> deleteCategory(String id) async {
    if (ReminderCategoryIds.isBuiltIn(id) || !state.categories.contains(id)) {
      return 0;
    }
    var moved = 0;
    final reminders = _sorted(state.reminders.map((r) {
      if (r.categoryId != id) return r;
      moved++;
      return r.copyWith(categoryId: ReminderCategoryIds.other);
    }));
    final categories = CategoryCatalog(
      state.categories.ordered.where((c) => c.id != id),
    );
    emit(state.copyWith(reminders: reminders, categories: categories));
    await _repository.saveCategories(categories.ordered);
    if (moved > 0) {
      await _persistAndSync();
    } else {
      await _refreshHomeWidget();
    }
    return moved;
  }

  Future<void> _saveCategories(List<ReminderCategory> categories) async {
    final next = CategoryCatalog(categories);
    if (next == state.categories) return;
    emit(state.copyWith(categories: next));
    await _repository.saveCategories(next.ordered);
    await _refreshHomeWidget();
  }

  /// Kategori rengi değişince widget'taki noktalar da güncellensin; bildirim
  /// ve geofence'e dokunulmaz.
  Future<void> _refreshHomeWidget() => _schedules.refreshHomeWidget(
        reminders: state.reminders,
        birthdays: state.birthdays,
        settings: state.settings,
        categories: state.categories,
      );

  /// Rutini (F3.7) ekler (yeni kimlik → listenin sonuna) veya aynı kimlikli
  /// rutini yerinde günceller. Oluşturulmuş hatırlatıcılara dokunulmaz: rutini
  /// düzenlemek geçmiş uygulamaları **geri dönük değiştirmez**.
  Future<void> saveRoutine(Routine routine) async {
    await _saveRoutines(state.routines.saved(routine));
  }

  /// Rutini siler (depoda yumuşak silme). Bu rutinden oluşmuş hatırlatıcılar
  /// **olduğu gibi kalır** (bağ gevşektir, bkz. `Reminder.routineId`).
  Future<void> deleteRoutine(String id) async {
    if (state.routines.byId(id) == null) return;
    await _saveRoutines(state.routines.removed(id));
  }

  /// Rutinleri [orderedIds] sırasına dizer; listede olmayanlar mevcut
  /// sıralarıyla sona eklenir, bilinmeyen kimlikler yok sayılır.
  Future<void> reorderRoutines(List<String> orderedIds) async {
    final byId = {for (final r in state.routines) r.id: r};
    final next = <Routine>[
      for (final id in orderedIds)
        if (byId.remove(id) case final r?) r,
      ...state.routines.where((r) => byId.containsKey(r.id)),
    ];
    await _saveRoutines(RoutineList.inOrder(next));
  }

  /// [from] konumundaki rutini [to] konumuna taşır (0 tabanlı, taşıma sonrası
  /// dizin — `ReorderableListView.onReorderItem` ile aynı).
  Future<void> moveRoutine(int from, int to) async {
    await _saveRoutines(state.routines.reordered(from, to));
  }

  Future<void> _saveRoutines(List<Routine> routines) async {
    final next = RoutineList.inOrder(routines);
    if (_sameRoutines(next, state.routines)) return;
    emit(state.copyWith(routines: next));
    await _repository.saveRoutines(next);
  }

  /// [routine] rutininin [date] gününe uygulanma planı (saf; durumdaki
  /// hatırlatıcılara bakar). Arayüz aynı planı önizleme için kullanır.
  RoutineApplyPlan planRoutine(Routine routine, {required DateTime date}) =>
      RoutineApplyPlan.from(
        routine: routine,
        date: date,
        existing: state.reminders,
      );

  /// Rutini uygular: adımlarından **gerçek hatırlatıcılar** oluşturur (ve
  /// [RoutineApplyMode.replaceExisting] ile bu rutine bağlı olanları
  /// günceller), sonra olağan yoldan kaydeder ve `ScheduleSync.syncAll`
  /// çalıştırır — bildirimler, widget'lar ve takvim kendiliğinden güncellenir.
  ///
  /// Plan uygulama anında yeniden kurulur, yani arayüzün gösterdiği
  /// önizlemeden sonra durum değişse bile kopya üretilmez. Rutin tekrar
  /// ediyorsa (`Routine.repeats`) saatli adımların hatırlatıcıları o tekrar
  /// kuralını taşır; sonraki günleri işletim sistemi getirir (arka plan görevi
  /// yok).
  Future<RoutineApplyOutcome> applyRoutine(
    Routine routine, {
    required DateTime date,
    RoutineApplyMode mode = RoutineApplyMode.onlyNew,
  }) async {
    final plan = planRoutine(routine, date: date);
    final outcome = plan.build(
      now: _now(),
      newId: _newId,
      newSubtaskId: _newId,
      mode: mode,
    );
    if (outcome.isEmpty) return outcome;
    final updatedById = {for (final r in outcome.updated) r.id: r};
    final next = _sorted([
      for (final r in state.reminders) updatedById[r.id] ?? r,
      ...outcome.created,
    ]);
    emit(state.copyWith(reminders: next));
    await _persistAndSync();
    return outcome;
  }

  static bool _sameRoutines(List<Routine> a, List<Routine> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
      categories: CategoryCatalog.builtIns,
      routines: const [],
      clock: _now,
    ));
    await _homeWidget.sync(
      const [],
      birthdays: const [],
      notificationsEnabled: const AppSettings().notificationsEnabled,
    );
  }
}
