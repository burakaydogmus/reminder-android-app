/// Rutinin (F3.7) bir güne uygulanması: saf plan + hatırlatıcı üretimi.
///
/// **Otomatik uygulama arka plan görevi değildir.** Rutinin tekrar kuralı
/// (`Routine.repeat`) uygulandığında oluşan hatırlatıcılara aktarılır; sonraki
/// günleri işletim sistemi kendi bildirim tekrarıyla getirir (F3.1 motoru).
/// WorkManager/BGTaskScheduler bilinçli olarak kullanılmadı: iOS arka plan
/// görevinin çalışacağını garanti etmez, yani bazı sabahlar rutin sessizce
/// oluşmazdı (bkz. CLAUDE.md → Rutinler).
library;

import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/domain/text_search.dart';

/// Bir adımın plandaki durumu.
enum RoutineItemState {
  /// Eşi yok: uygulanınca yeni hatırlatıcı oluşur.
  create,

  /// Bu rutinden oluşturulmuş bir hatırlatıcı zaten var (kimlik bağı).
  /// [RoutineApplyMode.replaceExisting] onu günceller.
  linked,

  /// Bağı olmayan ama aynı gün için aynı başlık/kategoriyle var olan bir
  /// hatırlatıcı bulundu (elle oluşturulmuş ya da F3.7 öncesi). Yalnızca
  /// atlanabilir; kimliği bu rutine ait olmadığı için güncellenmez.
  similar,
}

/// Plandaki bir adım ve varsa eşi.
class RoutineApplyEntry {
  const RoutineApplyEntry({
    required this.item,
    required this.state,
    this.existing,
  });

  final RoutineItem item;
  final RoutineItemState state;

  /// Bulunan eş hatırlatıcı ([state] `create` ise `null`).
  final Reminder? existing;

  bool get isDuplicate => state != RoutineItemState.create;

  /// Eş, bu rutinin kendi hatırlatıcısı mı (güncellenebilir).
  bool get isLinked => state == RoutineItemState.linked;
}

/// Uygulama kipi: eşler bulunduğunda ne yapılacağı.
enum RoutineApplyMode {
  /// Yalnızca eşi olmayan adımlar eklenir (varsayılan).
  onlyNew,

  /// Bu rutine bağlı eşler yeni tarihe/kurala ve adımın güncel alanlarına göre
  /// **güncellenir** (kimlik korunur, ikinci bir seri oluşmaz); bağsız eşler
  /// atlanır, eşi olmayan adımlar eklenir.
  replaceExisting,

  /// Eşler yok sayılır: her adım için yeni hatırlatıcı oluşturulur (kullanıcı
  /// "Yine de ekle" dediğinde).
  addAll,
}

/// Uygulama sonucu: oluşan ve güncellenen hatırlatıcılar.
class RoutineApplyOutcome {
  const RoutineApplyOutcome({
    this.created = const [],
    this.updated = const [],
    this.skipped = 0,
  });

  /// Yeni hatırlatıcılar (depoya eklenecek).
  final List<Reminder> created;

  /// Var olan hatırlatıcıların güncellenmiş kopyaları (aynı kimlikler).
  final List<Reminder> updated;

  /// Dokunulmayan (atlanan) adım sayısı.
  final int skipped;

  int get total => created.length + updated.length;

  bool get isEmpty => created.isEmpty && updated.isEmpty;
}

/// Bir rutinin bir güne uygulanma planı: her adım için "yeni mi, eşi var mı".
///
/// Saf ve zamandan bağımsız kurulur ([RoutineApplyPlan.from]); hatırlatıcılar
/// ancak [build] çağrılınca (saat + kimlik üreteci verilince) oluşur, böylece
/// arayüz planı her çizimde kimlik üretmeden gösterebilir.
class RoutineApplyPlan {
  const RoutineApplyPlan({
    required this.routine,
    required this.date,
    required this.entries,
  });

  final Routine routine;

  /// Hedef gün (yerel, gece yarısına indirilmiş).
  final DateTime date;

  final List<RoutineApplyEntry> entries;

  List<RoutineApplyEntry> get newEntries => [
        for (final e in entries)
          if (!e.isDuplicate) e
      ];

  List<RoutineApplyEntry> get duplicates => [
        for (final e in entries)
          if (e.isDuplicate) e
      ];

  /// Bu rutine bağlı (güncellenebilir) eşler.
  List<RoutineApplyEntry> get linked => [
        for (final e in entries)
          if (e.isLinked) e
      ];

  bool get hasDuplicates => duplicates.isNotEmpty;

  bool get hasLinked => linked.isNotEmpty;

  bool get hasNew => newEntries.isNotEmpty;

  bool get isEmpty => entries.isEmpty;

  /// Planı kurar: [existing] içindeki (durumdaki, silinmemiş) hatırlatıcılara
  /// bakarak her adımın durumunu belirler.
  ///
  /// **Eşleşme kuralı** (tek yerde, belgelenmiş):
  /// 1. **Bağ:** aynı `routineId` + `routineItemId` taşıyan bir hatırlatıcı.
  ///    Rutin tekrar ediyorsa (`Routine.repeats`) tarih **aranmaz** — seri
  ///    zaten var, ikincisi oluşturulmaz. Tekrar etmiyorsa eşleşme yalnızca
  ///    **aynı gün** için sayılır (dünkü uygulama bugünü engellemez).
  /// 2. **Benzer:** bağ yoksa, aynı katlanmış başlık (`TextSearch.fold`) ve
  ///    aynı kategoriyle o güne ait bir hatırlatıcı — elle oluşturulmuş ya da
  ///    F3.7 öncesi kayıtlar için. Atlanabilir, güncellenmez.
  ///
  /// "O güne ait" demek: saatli adımda `remindAt` o gün; saatsiz adımda
  /// `remindAt == null` ve `createdAt` o gün (zamansız hatırlatıcının tarihi
  /// yoktur, bkz. [reminderFor]). Tamamlanmış hatırlatıcılar da eş sayılır,
  /// yoksa rutini tamamlayıp yeniden uygulamak kopya üretirdi. Her hatırlatıcı
  /// en fazla bir adıma eş olur.
  static RoutineApplyPlan from({
    required Routine routine,
    required DateTime date,
    required List<Reminder> existing,
  }) {
    final day = _dateOnly(date);
    final used = <String>{};
    final entries = <RoutineApplyEntry>[];
    for (final item in routine.items) {
      Reminder? linked;
      for (final r in existing) {
        if (used.contains(r.id)) continue;
        if (r.routineId != routine.id || r.routineItemId != item.id) continue;
        if (!routine.repeats && !_onDay(r, item, day)) continue;
        linked = r;
        break;
      }
      if (linked != null) {
        used.add(linked.id);
        entries.add(RoutineApplyEntry(
          item: item,
          state: RoutineItemState.linked,
          existing: linked,
        ));
        continue;
      }
      Reminder? similar;
      final folded = TextSearch.fold(item.title.trim());
      for (final r in existing) {
        if (used.contains(r.id)) continue;
        if (r.categoryId != item.categoryId) continue;
        if (TextSearch.fold(r.title.trim()) != folded) continue;
        if (!_onDay(r, item, day)) continue;
        similar = r;
        break;
      }
      if (similar != null) {
        used.add(similar.id);
        entries.add(RoutineApplyEntry(
          item: item,
          state: RoutineItemState.similar,
          existing: similar,
        ));
        continue;
      }
      entries.add(
        RoutineApplyEntry(item: item, state: RoutineItemState.create),
      );
    }
    return RoutineApplyPlan(routine: routine, date: day, entries: entries);
  }

  /// Planı hatırlatıcılara çevirir.
  ///
  /// [mode] eşlerin ne olacağını belirler; [now] yeni hatırlatıcıların
  /// `createdAt` değeri, [newId] / [newSubtaskId] kimlik üreteçleridir.
  RoutineApplyOutcome build({
    required DateTime now,
    required String Function() newId,
    required String Function() newSubtaskId,
    RoutineApplyMode mode = RoutineApplyMode.onlyNew,
  }) {
    final created = <Reminder>[];
    final updated = <Reminder>[];
    var skipped = 0;
    for (final entry in entries) {
      switch (entry.state) {
        case RoutineItemState.create:
          created.add(reminderFor(
            entry.item,
            now: now,
            id: newId(),
            newSubtaskId: newSubtaskId,
          ));
        case RoutineItemState.linked:
          if (mode == RoutineApplyMode.addAll) {
            created.add(reminderFor(
              entry.item,
              now: now,
              id: newId(),
              newSubtaskId: newSubtaskId,
            ));
          } else if (mode == RoutineApplyMode.replaceExisting) {
            updated.add(_updated(entry.existing!, entry.item));
          } else {
            skipped++;
          }
        case RoutineItemState.similar:
          if (mode == RoutineApplyMode.addAll) {
            created.add(reminderFor(
              entry.item,
              now: now,
              id: newId(),
              newSubtaskId: newSubtaskId,
            ));
          } else {
            skipped++;
          }
      }
    }
    return RoutineApplyOutcome(
      created: List.unmodifiable(created),
      updated: List.unmodifiable(updated),
      skipped: skipped,
    );
  }

  /// [item] adımından bu plandaki gün için yeni bir hatırlatıcı.
  ///
  /// - **Saat:** adımın saati varsa o gün o saat; **yoksa `remindAt` null**
  ///   kalır — editörde "Zamanla ve bildir" kapalı bir hatırlatıcıyla birebir
  ///   aynı (yeni bir varsayılan saat uydurulmaz). Zamansız hatırlatıcının
  ///   tarihi yoktur, yani seçilen gün yalnızca saatli adımları etkiler.
  /// - **Tekrar:** rutinin kuralı yalnızca **saatli** adımlara geçer (kuralın
  ///   saati hatırlatıcının kendi saatinden gelir; saatsiz hatırlatıcı zaten
  ///   bildirim kurmaz, bkz. `Reminder.isRecurring`). Haftalık kuralda gün
  ///   listesi hedef günü içermiyorsa ilk tekrar, editörün yaptığı gibi
  ///   (`firstOnOrAfter`) ilk seçili güne taşınır.
  /// - **Kategori / öncelik / maddeler:** adımdan; maddeler yeni kimliklerle
  ///   ve açık olarak kopyalanır.
  /// - **Bağ:** `routineId` + `routineItemId` bu rutini işaret eder.
  Reminder reminderFor(
    RoutineItem item, {
    required DateTime now,
    required String id,
    required String Function() newSubtaskId,
  }) {
    final time = item.time;
    var remindAt = time?.onDate(date);
    var recurrence = RecurrenceRule.none;
    if (remindAt != null && routine.repeats) {
      recurrence = routine.repeat;
      final first = recurrence.firstOnOrAfter(from: remindAt, anchor: remindAt);
      if (first != null) remindAt = first;
    }
    return Reminder(
      id: id,
      title: item.title,
      isDone: false,
      createdAt: now,
      remindAt: remindAt,
      categoryId: item.categoryId,
      priority: item.priority,
      recurrence: recurrence,
      subtasks: SubtaskList.inOrder([
        for (final s in item.subtasks)
          Subtask(id: newSubtaskId(), title: s.title),
      ]),
      routineId: routine.id,
      routineItemId: item.id,
    );
  }

  /// Var olan (bu rutine bağlı) hatırlatıcıyı adımın güncel alanlarına ve bu
  /// plandaki güne taşır; kimliği, notu, konumu, sabitlemesi ve **maddelerinin
  /// durumu** korunur (kullanıcının işaretledikleri kaybolmaz). Seri yeni güne
  /// taşındığı için hatırlatıcı yeniden açılır (`isDone: false`).
  Reminder _updated(Reminder existing, RoutineItem item) {
    final time = item.time;
    var remindAt = time?.onDate(date);
    var recurrence = RecurrenceRule.none;
    if (remindAt != null && routine.repeats) {
      recurrence = routine.repeat;
      final first = recurrence.firstOnOrAfter(from: remindAt, anchor: remindAt);
      if (first != null) remindAt = first;
    }
    return reminderWithRoutineItem(
      existing,
      item,
      remindAt: remindAt,
      recurrence: recurrence,
      isDone: false,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// [r] hatırlatıcısı [item] adımı için [day] gününe ait mi (bkz. [from]).
  static bool _onDay(Reminder r, RoutineItem item, DateTime day) {
    if (item.time != null) {
      final at = r.remindAt;
      return at != null && _sameDay(at, day);
    }
    return r.remindAt == null && _sameDay(r.createdAt, day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Adımın alanlarını var olan bir hatırlatıcıya yazar — rutinin "sahip olduğu"
/// alanların **tek** listesi: başlık, kategori, öncelik ve çağıranın verdiği
/// `remindAt` / `recurrence` / `isDone`.
///
/// Kullanıcının alanlarına dokunulmaz: kimlik, not, konum, sabitleme,
/// **maddelerin durumu** (ilerleme) ve rutin bağı olduğu gibi kalır.
///
/// Son üç alan bilinçli olarak çağırandan gelir, çünkü iki kullanımı farklıdır:
/// [RoutineApplyMode.replaceExisting] seriyi **yeni bir güne** taşır, rutinin
/// tekrar kuralını yazar ve hatırlatıcıyı yeniden açar; [routineReminderRefresh]
/// ("Hatırlatıcıları güncelle") günü, tekrarı ve tamamlanma durumunu olduğu gibi
/// bırakır. Alan listesi tek yerde durur, iki yola da buradan gider.
Reminder reminderWithRoutineItem(
  Reminder existing,
  RoutineItem item, {
  required DateTime? remindAt,
  required RecurrenceRule recurrence,
  required bool isDone,
}) {
  return existing.copyWith(
    title: item.title,
    remindAt: () => remindAt,
    categoryId: item.categoryId,
    priority: item.priority,
    recurrence: recurrence,
    isDone: isDone,
  );
}

/// "Bu rutinin hatırlatıcılarını güncelle" planı ([routineReminderRefresh]).
class RoutineReminderRefresh {
  const RoutineReminderRefresh({required this.linked, required this.changed});

  /// Bu rutinden oluşmuş hatırlatıcı sayısı — adımı silinmiş olanlar dahil, yani
  /// "bu rutinin hatırlatıcısı var mı" sorusunun yanıtı.
  final int linked;

  /// Gerçekten değişecek hatırlatıcıların güncellenmiş hali; zaten adımla aynı
  /// olanlar listede yer almaz, böylece "kaç hatırlatıcı değişecek" sorusu
  /// [count] ile doğru yanıtlanır.
  final List<Reminder> changed;

  bool get hasLinked => linked > 0;

  int get count => changed.length;

  bool get isEmpty => changed.isEmpty;
}

/// Rutinden oluşmuş hatırlatıcıları adımların **güncel** alanlarına göre yenileme
/// planı (F3.7 devamı, "Hatırlatıcıları güncelle").
///
/// Bağ `reminders.routine_id` + `routine_item_id`, [RoutineApplyPlan] ile aynı.
/// **Günden bağımsızdır:** uygulama sayfasındaki
/// [RoutineApplyMode.replaceExisting] seriyi seçilen yeni güne taşır; bu ise
/// günü olduğu gibi bırakıp yalnızca başlık, saat, kategori ve önceliği taşır.
///
/// Dokunulmayanlar: **tamamlanma durumu**, not, sabitleme, konum, maddelerin
/// ilerlemesi ve tekrar kuralı. Adımı silinmiş bir hatırlatıcı olduğu gibi kalır
/// (bağ gevşektir, bkz. `Reminder.routineId`) — [RoutineReminderRefresh.linked]
/// onu da sayar ama [RoutineReminderRefresh.changed] içine almaz.
///
/// Saat: adımın saati varsa hatırlatıcının **kendi günü** korunarak o saate
/// çekilir (zamansız bir hatırlatıcı için oluşturulma günü, `RoutineApplyPlan`'ın
/// zamansız eş kuralıyla aynı gün); adımın saati kalktıysa hatırlatıcı zamansız
/// olur.
RoutineReminderRefresh routineReminderRefresh({
  required Routine routine,
  required Iterable<Reminder> existing,
}) {
  final items = {for (final i in routine.items) i.id: i};
  var linked = 0;
  final changed = <Reminder>[];
  for (final r in existing) {
    if (r.routineId != routine.id) continue;
    linked++;
    final item = items[r.routineItemId];
    if (item == null) continue;
    final remindAt = _refreshedRemindAt(r, item);
    // `Reminder` değer eşitliği taşımadığı için değişen alanlar tek tek
    // karşılaştırılır; değişmeyen hatırlatıcı hem sayımdan hem yazmadan düşer.
    if (r.title == item.title &&
        r.categoryId == item.categoryId &&
        r.priority == item.priority &&
        r.remindAt == remindAt) {
      continue;
    }
    changed.add(
      reminderWithRoutineItem(
        r,
        item,
        remindAt: remindAt,
        recurrence: r.recurrence,
        isDone: r.isDone,
      ),
    );
  }
  return RoutineReminderRefresh(
    linked: linked,
    changed: List.unmodifiable(changed),
  );
}

DateTime? _refreshedRemindAt(Reminder existing, RoutineItem item) {
  final time = item.time;
  if (time == null) return null;
  return time.onDate(existing.remindAt ?? existing.createdAt);
}
