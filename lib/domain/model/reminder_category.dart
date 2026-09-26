import 'package:reminder/domain/text_search.dart';

/// Yerleşik kategori kimlikleri (kararlı, kalıcı). Kullanıcı kategorileri
/// (F4.3) başka kimlikler alır; bkz. [ReminderCategory].
///
/// F4.3 öncesinde [ReminderCategoryIds.other] için özel etiket hatırlatıcıda
/// `customCategoryLabel` alanında tutuluyordu; şema v5 geçişi bu etiketleri
/// kullanıcı kategorilerine dönüştürür (`CategoryLabelMigration`).
abstract class ReminderCategoryIds {
  static const market = 'market';
  static const home = 'home';
  static const work = 'work';
  static const health = 'health';
  static const errands = 'errands';
  static const other = 'other';

  static const List<String> orderedIds = [
    market,
    home,
    work,
    health,
    errands,
    other,
  ];

  static bool isBuiltIn(String id) => orderedIds.contains(id);

  static String defaultLabel(String id) {
    switch (id) {
      case market:
        return 'Market';
      case home:
        return 'Ev İşleri';
      case work:
        return 'İş';
      case health:
        return 'Sağlık';
      case errands:
        return 'Günlük';
      case other:
        return 'Diğer';
      default:
        return 'Diğer';
    }
  }

  /// F4.3 öncesi etiket kuralı: [customCategoryLabel] yalnızca `other` için
  /// anlamlıdır. Arayüz artık `CategoryCatalog.labelOf` kullanır.
  static String displayLabel(String categoryId, String? customCategoryLabel) {
    if (categoryId == other &&
        customCategoryLabel != null &&
        customCategoryLabel.trim().isNotEmpty) {
      return customCategoryLabel.trim();
    }
    return defaultLabel(categoryId);
  }
}

/// Kategori renk anahtarları (`KorColorKey.storageKey` ile aynı metinler).
/// Domain arayüz katmanını içe aktarmadığı için burada metin olarak durur;
/// arayüz `KorColorKey.tryParse` ile çözer (bilinmeyen → `diger`).
abstract final class CategoryColorKeys {
  static const market = 'market';
  static const ev = 'ev';
  static const is_ = 'is';
  static const saglik = 'saglik';
  static const gunluk = 'gunluk';
  static const diger = 'diger';
}

/// Kategori ikon anahtarları (F4.3). Sabit bir kümedir; arayüz her anahtarı
/// `CategoryIcons` ile bir ikona eşler (dinamik `IconData` saklanmaz).
abstract final class CategoryIconKeys {
  static const label = 'label';
  static const basket = 'basket';
  static const home = 'home';
  static const work = 'work';
  static const heart = 'heart';
  static const sun = 'sun';
  static const fitness = 'fitness';
  static const school = 'school';
  static const pets = 'pets';
  static const car = 'car';
  static const flight = 'flight';
  static const restaurant = 'restaurant';
  static const payments = 'payments';
  static const medication = 'medication';
  static const child = 'child';
  static const flower = 'flower';
  static const build = 'build';
  static const book = 'book';

  /// Editördeki sırayla 18 anahtar.
  static const List<String> all = [
    label,
    basket,
    home,
    work,
    heart,
    sun,
    fitness,
    school,
    pets,
    car,
    flight,
    restaurant,
    payments,
    medication,
    child,
    flower,
    build,
    book,
  ];
}

/// Hatırlatıcı kategorisi (F4.3).
///
/// Yerleşik kategoriler ([ReminderCategoryIds]) kararlı kimliklerini korur,
/// silinemez ve yeniden adlandırılamaz, yalnızca sıralanabilir. Kullanıcı
/// kategorileri tamamen düzenlenebilir. Renk hex değil anahtar olarak
/// saklanır ([colorKey], `KorColorKey.storageKey`), ikon da sabit bir anahtar
/// kümesinden ([CategoryIconKeys]).
class ReminderCategory {
  const ReminderCategory({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.iconKey,
    this.position = 0,
  });

  /// Kullanıcı kategorisi adının azami uzunluğu.
  static const maxNameLength = 24;

  final String id;
  final String name;

  /// `KorColorKey.storageKey` (örn. `lacivert`).
  final String colorKey;

  /// [CategoryIconKeys] değerlerinden biri.
  final String iconKey;

  /// Listedeki sıra (0 tabanlı); [CategoryCatalog] sıralı tutar.
  final int position;

  bool get isBuiltIn => ReminderCategoryIds.isBuiltIn(id);

  /// Yerleşik kategorinin tanımı ([ReminderCategoryIds.orderedIds] sırası).
  static ReminderCategory builtIn(String id) {
    final (color, icon) = switch (id) {
      ReminderCategoryIds.market => (
          CategoryColorKeys.market,
          CategoryIconKeys.basket
        ),
      ReminderCategoryIds.home => (CategoryColorKeys.ev, CategoryIconKeys.home),
      ReminderCategoryIds.work => (
          CategoryColorKeys.is_,
          CategoryIconKeys.work
        ),
      ReminderCategoryIds.health => (
          CategoryColorKeys.saglik,
          CategoryIconKeys.heart
        ),
      ReminderCategoryIds.errands => (
          CategoryColorKeys.gunluk,
          CategoryIconKeys.sun
        ),
      _ => (CategoryColorKeys.diger, CategoryIconKeys.label),
    };
    final index = ReminderCategoryIds.orderedIds.indexOf(id);
    return ReminderCategory(
      id: ReminderCategoryIds.isBuiltIn(id) ? id : ReminderCategoryIds.other,
      name: ReminderCategoryIds.defaultLabel(id),
      colorKey: color,
      iconKey: icon,
      position: index < 0 ? ReminderCategoryIds.orderedIds.length - 1 : index,
    );
  }

  /// Ad düzenlemesi: baştaki/sondaki boşluklar atılır, iç boşluklar teke
  /// indirilir, [maxNameLength] karakterde kesilir.
  static String normalizeName(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.length <= maxNameLength
        ? collapsed
        : collapsed.substring(0, maxNameLength).trimRight();
  }

  ReminderCategory copyWith({
    String? id,
    String? name,
    String? colorKey,
    String? iconKey,
    int? position,
  }) {
    return ReminderCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      iconKey: iconKey ?? this.iconKey,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorKey': colorKey,
        'iconKey': iconKey,
        'position': position,
      };

  /// Eksik renk/ikon → `diger` / `label`; `id` veya `name` eksikse hata
  /// fırlatır (yedek içe aktarma öğeyi atlar).
  factory ReminderCategory.fromJson(Map<String, dynamic> json) {
    return ReminderCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorKey: json['colorKey'] as String? ?? CategoryColorKeys.diger,
      iconKey: json['iconKey'] as String? ?? CategoryIconKeys.label,
      position: json['position'] is num ? (json['position'] as num).toInt() : 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderCategory &&
      other.id == id &&
      other.name == name &&
      other.colorKey == colorKey &&
      other.iconKey == iconKey &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, name, colorKey, iconKey, position);

  @override
  String toString() => 'ReminderCategory($id, $name, $colorKey, $iconKey, '
      '$position)';
}

/// Sıralı, değişmez kategori listesi ve kimlikle arama (F4.3).
///
/// Her zaman altı yerleşik kategoriyi içerir; yerleşiklerin adı, rengi ve
/// ikonu sabittir (saklanan değer yok sayılır), yalnızca sıraları saklanır.
/// Bilinmeyen (silinmiş) bir kimlik "Diğer" olarak çözülür.
class CategoryCatalog {
  CategoryCatalog._(this.ordered) : _byId = {for (final c in ordered) c.id: c};

  /// Saklanan listeden katalog: yerleşikler eklenir/sabitlenir, tekrarlanan
  /// kimliklerde ilki kazanır, [ReminderCategory.position] 0..n-1 yapılır.
  ///
  /// Hiç yerleşik satır yoksa (yeni kurulum, v5 geçişi) yerleşikler başa,
  /// varsa eksik yerleşikler sona eklenir.
  factory CategoryCatalog(Iterable<ReminderCategory> stored) {
    final sorted = [...stored]
      ..sort((a, b) => a.position.compareTo(b.position));
    final seen = <String>{};
    final result = <ReminderCategory>[];
    final hasBuiltIn = sorted.any((c) => c.isBuiltIn);
    if (!hasBuiltIn) {
      for (final id in ReminderCategoryIds.orderedIds) {
        seen.add(id);
        result.add(ReminderCategory.builtIn(id));
      }
    }
    for (final c in sorted) {
      if (c.id.isEmpty || !seen.add(c.id)) continue;
      result.add(c.isBuiltIn ? ReminderCategory.builtIn(c.id) : c);
    }
    for (final id in ReminderCategoryIds.orderedIds) {
      if (seen.add(id)) result.add(ReminderCategory.builtIn(id));
    }
    return CategoryCatalog._(List.unmodifiable([
      for (var i = 0; i < result.length; i++) result[i].copyWith(position: i),
    ]));
  }

  /// Yalnızca yerleşik kategoriler (varsayılan sıra).
  static final CategoryCatalog builtIns = CategoryCatalog(const []);

  /// Tüm kategoriler, görüntüleme sırasıyla.
  final List<ReminderCategory> ordered;
  final Map<String, ReminderCategory> _byId;

  List<ReminderCategory> get userCategories => [
        for (final c in ordered)
          if (!c.isBuiltIn) c
      ];

  bool contains(String id) => _byId.containsKey(id);

  /// [id] kategorisi; yoksa `null`.
  ReminderCategory? byId(String id) => _byId[id];

  /// [id] kategorisi; bilinmeyen/silinmiş kimlik → "Diğer".
  ReminderCategory resolve(String id) =>
      _byId[id] ?? _byId[ReminderCategoryIds.other]!;

  String labelOf(String id) => resolve(id).name;

  /// Katlanmış adı (büyük/küçük harf ve Türkçe aksan duyarsız) [name] ile
  /// aynı kategori; [exceptId] hariç.
  ReminderCategory? byFoldedName(String name, {String? exceptId}) {
    final key = CategoryNames.fold(name);
    if (key.isEmpty) return null;
    for (final c in ordered) {
      if (c.id != exceptId && CategoryNames.fold(c.name) == key) return c;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryCatalog &&
      other.ordered.length == ordered.length &&
      Iterable.generate(ordered.length)
          .every((i) => other.ordered[i] == ordered[i]);

  @override
  int get hashCode => Object.hashAll(ordered);
}

/// Kategori adı karşılaştırma yardımcıları.
abstract final class CategoryNames {
  /// Türkçe katlanmış anahtar ([TextSearch.foldName]: büyük/küçük harf ve
  /// aksan duyarsız, İ/I/ı → i, ş → s, ğ → g, ç → c, ö → o, ü → u), boşluklar
  /// teke inmiş ve kırpılmış. `Spor Salonu`, `spor  salonu` ve `SPOR SALONU`
  /// aynı anahtarı verir.
  static String fold(String name) => TextSearch.foldName(name);
}
