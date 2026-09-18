import 'dart:convert' show LineSplitter;

/// Hatırlatıcının bir maddesi (F3.3, alt görev / checklist).
///
/// Saf Dart değer tipi. [position] listedeki sırayı tutar; [SubtaskList]
/// yardımcıları her değişiklikten sonra sırayı `0..n-1` olarak yeniden
/// numaralar, yani `Reminder.subtasks` her zaman [position] sırasındadır.
class Subtask {
  const Subtask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.position = 0,
  });

  final String id;
  final String title;
  final bool isDone;
  final int position;

  Subtask copyWith({String? id, String? title, bool? isDone, int? position}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'position': position,
      };

  /// `id` veya `title` eksik/yanlış tipte ise [FormatException].
  factory Subtask.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || title is! String) {
      throw const FormatException('Subtask needs a string id and title');
    }
    return Subtask(
      id: id,
      title: title,
      isDone: json['isDone'] as bool? ?? false,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }

  /// JSON'daki `subtasks` değeri; eksik (eski kayıt/yedek) → boş liste.
  /// Okunamayan maddeler atlanır, geri kalanlar [position] sırasına dizilip
  /// yeniden numaralanır.
  static List<Subtask> listFromJson(Object? value) {
    if (value is! List) return const [];
    final items = <Subtask>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        items.add(Subtask.fromJson(Map<String, dynamic>.from(item)));
      } on FormatException {
        continue;
      }
    }
    return SubtaskList.normalized(items);
  }

  @override
  bool operator ==(Object other) =>
      other is Subtask &&
      other.id == id &&
      other.title == title &&
      other.isDone == isDone &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, title, isDone, position);

  @override
  String toString() =>
      'Subtask($id, "$title", ${isDone ? 'done' : 'open'}, #$position)';
}

/// Madde listesi yardımcıları. Hepsi yeni (değiştirilemez) liste döndürür ve
/// [Subtask.position] değerlerini liste sırasına eşitler.
extension SubtaskList on List<Subtask> {
  /// [position] sırasına dizilmiş (eşitlikte ilk sıra korunur) ve `0..n-1`
  /// olarak numaralanmış kopya.
  static List<Subtask> normalized(Iterable<Subtask> items) {
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
  static List<Subtask> inOrder(Iterable<Subtask> items) => List.unmodifiable([
        for (final (i, s) in items.indexed)
          s.position == i ? s : s.copyWith(position: i),
      ]);

  int get doneCount => where((s) => s.isDone).length;

  int get openCount => length - doneCount;

  /// Tamamlanan oranı (0–1); madde yoksa 0.
  double get progress => isEmpty ? 0 : doneCount / length;

  /// Madde varsa ve hepsi tamamlandıysa `true`.
  bool get allDone => isNotEmpty && every((s) => s.isDone);

  List<Subtask> get open => where((s) => !s.isDone).toList(growable: false);

  List<Subtask> get done => where((s) => s.isDone).toList(growable: false);

  List<Subtask> _renumbered(List<Subtask> items) => List.unmodifiable([
        for (var i = 0; i < items.length; i++)
          items[i].position == i ? items[i] : items[i].copyWith(position: i),
      ]);

  /// [id] maddesinin durumunu tersine çevirir ([done] verilirse ona ayarlar).
  List<Subtask> toggled(String id, {bool? done}) => _renumbered([
        for (final s in this)
          s.id == id ? s.copyWith(isDone: done ?? !s.isDone) : s,
      ]);

  /// [id] maddesinin başlığını değiştirir.
  List<Subtask> renamed(String id, String title) => _renumbered([
        for (final s in this) s.id == id ? s.copyWith(title: title) : s,
      ]);

  /// Sonuna (veya [index] konumuna) yeni madde ekler.
  List<Subtask> added(Subtask subtask, {int? index}) {
    final items = [...this];
    items.insert((index ?? items.length).clamp(0, items.length), subtask);
    return _renumbered(items);
  }

  /// [subtasks] maddelerini sırayla sona (veya [index] konumuna) ekler.
  List<Subtask> addedAll(Iterable<Subtask> subtasks, {int? index}) {
    final items = [...this];
    items.insertAll((index ?? items.length).clamp(0, items.length), subtasks);
    return _renumbered(items);
  }

  /// [id] maddesini kaldırır.
  List<Subtask> removed(String id) => _renumbered([
        for (final s in this)
          if (s.id != id) s
      ]);

  /// [oldIndex] konumundaki maddeyi [newIndex] konumuna taşır. [newIndex],
  /// taşınan madde çıkarıldıktan **sonraki** listedeki hedef konumdur
  /// (`ReorderableListView.onReorderItem` ile aynı). Geçersiz konumlar
  /// kırpılır.
  List<Subtask> reordered(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= length) return _renumbered([...this]);
    final items = [...this];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex.clamp(0, items.length), moved);
    return _renumbered(items);
  }

  /// [id] maddesini [delta] kadar (−1 yukarı, +1 aşağı) taşır.
  List<Subtask> moved(String id, int delta) {
    final index = indexWhere((s) => s.id == id);
    if (index < 0) return _renumbered([...this]);
    return reordered(index, index + delta);
  }

  /// Tüm maddeleri tamamlanmamış yapar (tekrarlayan hatırlatıcı bir sonraki
  /// tekrara ilerlerken, bkz. `completeReminder`).
  List<Subtask> get reset => _renumbered([
        for (final s in this) s.isDone ? s.copyWith(isDone: false) : s,
      ]);
}

/// Serbest metni madde başlıklarına böler (F3.3; yapıştırma, "Maddelere böl").
///
/// Ayraçlar: satır sonu, virgül (iki rakam arasındaki ondalık virgül hariç),
/// noktalı virgül ve (büyük/küçük harf
/// duyarsız) ayrı bir kelime olarak " ve ". Başlıklar kırpılır; baştaki
/// madde işaretleri (`-`, `*`, `•`, `1.`, `2)`, `[ ]`, `[x]`) atılır; boş
/// parçalar düşer. Bölünecek bir şey yoksa kırpılmış metnin kendisi (boşsa
/// boş liste) döner.
List<String> splitSubtaskText(String text) {
  final parts = text.split(_subtaskSeparators);
  return [
    for (final part in parts)
      if (_cleanSubtaskTitle(part) case final title when title.isNotEmpty)
        title,
  ];
}

/// Yalnızca satır sonlarından böler (çok satırlı yapıştırma, Enter); satır
/// içindeki virgül ve "ve" korunur ("Peynir, beyaz" tek madde kalır). Madde
/// işaretleri ve boş satırlar [splitSubtaskText]'teki gibi atılır.
List<String> splitSubtaskLines(String text) => [
      for (final line in const LineSplitter().convert(text))
        if (_cleanSubtaskTitle(line) case final title when title.isNotEmpty)
          title,
    ];

/// Metin birden fazla maddeye bölünüyorsa `true` ("Maddelere böl?" önerisi
/// ve çok parçalı yapıştırma için).
bool looksLikeSubtaskList(String text) => splitSubtaskText(text).length > 1;

final _subtaskSeparators = RegExp(
  // Virgül iki rakam arasındaysa ondalık ayraçtır ("1,5 kg"), bölünmez.
  r'\r\n|[\n\r;]|(?<!\d),|,(?!\d)|\s+ve\s+',
  caseSensitive: false,
  unicode: true,
);

final _bulletPrefix = RegExp(
  r'^(?:[-*•·▪◦–—]+|\d{1,3}[.)](?=\s|$)|\[[ xX✓]?\])\s*',
  unicode: true,
);

String _cleanSubtaskTitle(String part) {
  var title = part.trim();
  while (true) {
    final stripped = title.replaceFirst(_bulletPrefix, '').trim();
    if (stripped == title) return title;
    title = stripped;
  }
}
