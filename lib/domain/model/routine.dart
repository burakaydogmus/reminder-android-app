import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/subtask.dart';

/// Günün bir saati (F3.7 rutin adımı): 0–23 saat, 0–59 dakika.
///
/// Saklanan ve JSON'daki biçim `HH:MM` metnidir ([storage]); rutin adımı
/// tarihten bağımsız olduğu için `DateTime` tutulmaz — tarih uygulama
/// anında verilir (`RoutineApplyPlan`).
class RoutineTime implements Comparable<RoutineTime> {
  const RoutineTime(this.hour, this.minute);

  final int hour;
  final int minute;

  /// Gün başından beri geçen dakika (sıralama ve karşılaştırma için).
  int get minutesOfDay => hour * 60 + minute;

  /// `HH:MM`; saklama ve JSON biçimi.
  String get storage =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// `HH:MM` metnini çözer; biçim bozuk veya aralık dışıysa `null`
  /// (satır/öğe atılmaz, adım saatsiz sayılır).
  static RoutineTime? tryParse(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return RoutineTime(hour, minute);
  }

  /// [date] gününde bu saate denk gelen yerel zaman (duvar saati; takvim
  /// alanlarıyla kurulur, `Duration` eklenmez).
  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(RoutineTime other) =>
      minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is RoutineTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'RoutineTime($storage)';
}

/// Bir rutinin adımı (F3.7): uygulandığında oluşacak hatırlatıcının şablonu.
///
/// Alanlar hatırlatıcının kendi sözlüğünden gelir ([RoutineTime] dışında yeni
/// bir tip yok): başlık, isteğe bağlı saat, kategori kimliği
/// ([ReminderCategoryIds] ya da bir kullanıcı kategorisi), öncelik
/// ([ReminderPriority] ölçeği) ve isteğe bağlı maddeler ([Subtask]).
///
/// Şablondaki maddeler **her zaman açıktır** ve `0..n-1` numaralıdır:
/// kurucu `SubtaskList.normalized(...).reset` uygular.
class RoutineItem {
  RoutineItem({
    required this.id,
    required this.title,
    this.time,
    this.categoryId = ReminderCategoryIds.other,
    int priority = ReminderPriority.none,
    List<Subtask> subtasks = const [],
    this.position = 0,
  })  : priority = ReminderPriority.normalize(priority),
        subtasks = SubtaskList.normalized(subtasks).reset;

  static const maxTitleLength = 80;

  final String id;
  final String title;

  /// Günün saati; `null` = saatsiz adım (uygulandığında zamansız hatırlatıcı,
  /// tıpkı editörde "Zamanla ve bildir" kapalıyken olduğu gibi).
  final RoutineTime? time;

  final String categoryId;

  /// [ReminderPriority] ölçeği: 0 yok … 3 yüksek.
  final int priority;

  /// Şablon maddeleri; hepsi açık, [Subtask.position] sırasında.
  final List<Subtask> subtasks;

  /// Rutin içindeki sıra (0 tabanlı); [RoutineItemList] sıralı tutar.
  final int position;

  bool get hasSubtasks => subtasks.isNotEmpty;

  bool get hasPriority => priority != ReminderPriority.none;

  /// Başlığı kırpar ve [maxTitleLength] karakterde keser.
  static String normalizeTitle(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'[\t ]+'), ' ');
    return collapsed.length <= maxTitleLength
        ? collapsed
        : collapsed.substring(0, maxTitleLength).trimRight();
  }

  /// Nullable [time] açıkça temizlenebilir: `copyWith(time: () => null)`.
  RoutineItem copyWith({
    String? id,
    String? title,
    RoutineTime? Function()? time,
    String? categoryId,
    int? priority,
    List<Subtask>? subtasks,
    int? position,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time != null ? time() : this.time,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time?.storage,
        'categoryId': categoryId,
        'priority': priority,
        'subtasks': [for (final s in subtasks) s.toJson()],
        'position': position,
      };

  /// `id` veya `title` eksik/yanlış tipte ise [FormatException]. Bozuk `time`
  /// metni saatsiz adım olur, okunamayan maddeler atlanır.
  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || title is! String) {
      throw const FormatException('RoutineItem needs a string id and title');
    }
    return RoutineItem(
      id: id,
      title: title,
      time: RoutineTime.tryParse(json['time']),
      categoryId: json['categoryId'] as String? ?? ReminderCategoryIds.other,
      priority: json['priority'] is num
          ? (json['priority'] as num).toInt()
          : ReminderPriority.none,
      subtasks: Subtask.listFromJson(json['subtasks']),
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }

  /// JSON'daki `items` değeri; eksik → boş liste, okunamayan adımlar atlanır.
  static List<RoutineItem> listFromJson(Object? value) {
    if (value is! List) return const [];
    final items = <RoutineItem>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        items.add(RoutineItem.fromJson(Map<String, dynamic>.from(item)));
      } on FormatException {
        continue;
      }
    }
    return RoutineItemList.normalized(items);
  }

  @override
  bool operator ==(Object other) =>
      other is RoutineItem &&
      other.id == id &&
      other.title == title &&
      other.time == time &&
      other.categoryId == categoryId &&
      other.priority == priority &&
      other.position == position &&
      _sameSubtasks(other.subtasks, subtasks);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        time,
        categoryId,
        priority,
        position,
        Object.hashAll(subtasks),
      );

  @override
  String toString() => 'RoutineItem($id, "$title", '
      '${time?.storage ?? 'no time'}, $categoryId, #$position)';
}

/// Hazır hatırlatıcı paketi (F3.7): ad, isteğe bağlı renk/ikon ve sıralı
/// adımlar. Uygulandığında adımlarından gerçek hatırlatıcılar oluşur
/// (`RoutineApplyPlan`); rutinin kendisi hiçbir hatırlatıcıya bağlı değildir,
/// silinmesi oluşturulmuş hatırlatıcılara dokunmaz.
class Routine {
  Routine({
    required this.id,
    required this.name,
    this.colorKey,
    this.iconKey,
    List<RoutineItem> items = const [],
    this.repeat = RecurrenceRule.none,
    required this.createdAt,
    this.position = 0,
  }) : items = RoutineItemList.normalized(items);

  static const maxNameLength = 32;

  final String id;
  final String name;

  /// `KorColorKey.storageKey`; `null` = arayüzün varsayılanı
  /// (`RoutineVisuals`). Hex saklanmaz (kategorilerle aynı sözlük).
  final String? colorKey;

  /// [CategoryIconKeys] değerlerinden biri; `null` = varsayılan ikon.
  final String? iconKey;

  /// Adımlar, [RoutineItem.position] sırasında.
  final List<RoutineItem> items;

  /// Otomatik uygulama (F3.7): rutin uygulandığında **saatli** adımlarının
  /// hatırlatıcıları bu tekrar kuralını taşır, yani sonraki günleri işletim
  /// sisteminin bildirimleri getirir — arka plan görevi yoktur (bkz.
  /// `routine_apply.dart` ve CLAUDE.md). [RecurrenceRule.none] = yalnızca
  /// elle uygulama (tek seferlik hatırlatıcılar).
  ///
  /// Arayüz üç seçenek sunar: Yok / Her gün ([RecurrenceRule.daily]) / Seçili
  /// günler ([RecurrenceRule.weekly]); saklanan başka bir kural olduğu gibi
  /// korunur ve oluşturulan hatırlatıcıya aktarılır.
  final RecurrenceRule repeat;

  /// Rutin uygulandığında oluşan hatırlatıcılar tekrar eder mi.
  bool get repeats => !repeat.isNone;

  /// Oluşturulma zamanı (duvar saati; hatırlatıcı `createdAt` ile aynı
  /// biçimde saklanır).
  final DateTime createdAt;

  /// Listedeki sıra (0 tabanlı); depo ve cubit sıralı tutar.
  final int position;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.length;

  /// Adı kırpar, boşlukları teke indirir, [maxNameLength] karakterde keser.
  static String normalizeName(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.length <= maxNameLength
        ? collapsed
        : collapsed.substring(0, maxNameLength).trimRight();
  }

  /// Nullable alanlar açıkça temizlenebilir: `copyWith(colorKey: () => null)`.
  Routine copyWith({
    String? id,
    String? name,
    String? Function()? colorKey,
    String? Function()? iconKey,
    List<RoutineItem>? items,
    RecurrenceRule? repeat,
    DateTime? createdAt,
    int? position,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey != null ? colorKey() : this.colorKey,
      iconKey: iconKey != null ? iconKey() : this.iconKey,
      items: items ?? this.items,
      repeat: repeat ?? this.repeat,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorKey': colorKey,
        'iconKey': iconKey,
        'items': [for (final item in items) item.toJson()],
        'repeat': repeat.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'position': position,
      };

  /// `id` veya `name` eksik/yanlış tipte ise [FormatException]; `createdAt`
  /// eksik/çözülemezse [fallbackCreatedAt] (verilmezse epoch) kullanılır,
  /// okunamayan adımlar atlanır.
  factory Routine.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackCreatedAt,
  }) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Routine needs a string id and name');
    }
    final createdAt = json['createdAt'];
    return Routine(
      id: id,
      name: name,
      colorKey: json['colorKey'] as String?,
      iconKey: json['iconKey'] as String?,
      items: RoutineItem.listFromJson(json['items']),
      repeat: RecurrenceRule.fromJson(json['repeat']),
      createdAt: (createdAt is String ? DateTime.tryParse(createdAt) : null) ??
          fallbackCreatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Routine &&
      other.id == id &&
      other.name == name &&
      other.colorKey == colorKey &&
      other.iconKey == iconKey &&
      other.repeat == repeat &&
      other.createdAt == createdAt &&
      other.position == position &&
      _sameItems(other.items, items);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        colorKey,
        iconKey,
        repeat,
        createdAt,
        position,
        Object.hashAll(items),
      );

  @override
  String toString() =>
      'Routine($id, "$name", ${items.length} items, #$position)';
}

bool _sameSubtasks(List<Subtask> a, List<Subtask> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameItems(List<RoutineItem> a, List<RoutineItem> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Adım listesi yardımcıları ([SubtaskList] ile aynı sözleşme): hepsi
/// değiştirilemez bir liste döndürür ve [RoutineItem.position] değerlerini
/// liste sırasına eşitler.
extension RoutineItemList on List<RoutineItem> {
  /// [position] sırasına dizilmiş (eşitlikte ilk sıra korunur) ve `0..n-1`
  /// olarak numaralanmış kopya.
  static List<RoutineItem> normalized(Iterable<RoutineItem> items) {
    final indexed = items.toList();
    final order = List<int>.generate(indexed.length, (i) => i)
      ..sort((a, b) {
        final byPosition = indexed[a].position.compareTo(indexed[b].position);
        return byPosition != 0 ? byPosition : a.compareTo(b);
      });
    return List.unmodifiable([
      for (var i = 0; i < order.length; i++)
        indexed[order[i]].copyWith(position: i),
    ]);
  }

  /// [items] verilen sırayla, `0..n-1` olarak numaralanmış kopya.
  static List<RoutineItem> inOrder(Iterable<RoutineItem> items) =>
      List.unmodifiable([
        for (final (i, item) in items.indexed)
          item.position == i ? item : item.copyWith(position: i),
      ]);

  List<RoutineItem> _renumbered(List<RoutineItem> items) =>
      RoutineItemList.inOrder(items);

  /// Sonuna (veya [index] konumuna) yeni adım ekler.
  List<RoutineItem> added(RoutineItem item, {int? index}) {
    final items = [...this];
    items.insert((index ?? items.length).clamp(0, items.length), item);
    return _renumbered(items);
  }

  /// Aynı kimlikli adımı değiştirir; kimlik yoksa sona ekler.
  List<RoutineItem> replaced(RoutineItem item) =>
      any((i) => i.id == item.id) ? updated(item) : added(item);

  /// Aynı kimlikli adımı yerinde değiştirir (kimlik yoksa değişiklik yok).
  List<RoutineItem> updated(RoutineItem item) => _renumbered([
        for (final i in this) i.id == item.id ? item : i,
      ]);

  /// [id] adımını kaldırır.
  List<RoutineItem> removed(String id) => _renumbered([
        for (final i in this)
          if (i.id != id) i,
      ]);

  /// [oldIndex] adımını [newIndex] konumuna taşır ([newIndex] taşınan adım
  /// çıkarıldıktan **sonraki** listedeki hedef; `onReorderItem` ile aynı).
  List<RoutineItem> reordered(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= length) return _renumbered([...this]);
    final items = [...this];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex.clamp(0, items.length), moved);
    return _renumbered(items);
  }

  /// [id] adımını [delta] kadar (−1 yukarı, +1 aşağı) taşır.
  List<RoutineItem> moved(String id, int delta) {
    final index = indexWhere((i) => i.id == id);
    if (index < 0) return _renumbered([...this]);
    return reordered(index, index + delta);
  }
}

/// Rutin listesi yardımcıları (sıra = [Routine.position]).
extension RoutineList on List<Routine> {
  /// [position] sırasına dizilmiş ve `0..n-1` numaralanmış kopya; tekrarlanan
  /// kimlikte ilki kazanır.
  static List<Routine> normalized(Iterable<Routine> routines) {
    final seen = <String>{};
    final unique = [
      for (final r in routines)
        if (seen.add(r.id)) r,
    ];
    final order = List<int>.generate(unique.length, (i) => i)
      ..sort((a, b) {
        final byPosition = unique[a].position.compareTo(unique[b].position);
        return byPosition != 0 ? byPosition : a.compareTo(b);
      });
    return List.unmodifiable([
      for (var i = 0; i < order.length; i++)
        unique[order[i]].copyWith(position: i),
    ]);
  }

  /// [routines] verilen sırayla, `0..n-1` numaralanmış kopya.
  static List<Routine> inOrder(Iterable<Routine> routines) =>
      List.unmodifiable([
        for (final (i, r) in routines.indexed)
          r.position == i ? r : r.copyWith(position: i),
      ]);

  Routine? byId(String id) {
    for (final r in this) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Aynı katlanmış ada sahip rutin (büyük/küçük harf ve Türkçe aksan
  /// duyarsız); [exceptId] atlanır.
  Routine? byFoldedName(String name, {String? exceptId}) {
    final folded = RoutineNames.fold(name);
    if (folded.isEmpty) return null;
    for (final r in this) {
      if (r.id == exceptId) continue;
      if (RoutineNames.fold(r.name) == folded) return r;
    }
    return null;
  }

  /// Aynı kimlikli rutini yerinde değiştirir, yoksa sona ekler.
  List<Routine> saved(Routine routine) {
    if (byId(routine.id) == null) {
      return RoutineList.inOrder([...this, routine]);
    }
    return RoutineList.inOrder([
      for (final r in this) r.id == routine.id ? routine : r,
    ]);
  }

  List<Routine> removed(String id) => RoutineList.inOrder([
        for (final r in this)
          if (r.id != id) r,
      ]);

  /// [oldIndex] rutinini [newIndex] konumuna taşır (`onReorderItem` ile aynı
  /// anlam).
  List<Routine> reordered(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= length) return RoutineList.inOrder(this);
    final items = [...this];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex.clamp(0, items.length), moved);
    return RoutineList.inOrder(items);
  }
}

/// Rutin adlarının karşılaştırması: `CategoryNames.fold` ile aynı kural
/// (büyük/küçük harf ve Türkçe aksan duyarsız).
abstract final class RoutineNames {
  static String fold(String name) => CategoryNames.fold(name);
}
