/// Sabit kategori kimlikleri. [ReminderCategoryIds.other] için özel etiket
/// hatırlatıcıda `customCategoryLabel` alanında tutulur.
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

  /// [customCategoryLabel] yalnızca `other` için anlamlıdır.
  static String displayLabel(String categoryId, String? customCategoryLabel) {
    if (categoryId == other &&
        customCategoryLabel != null &&
        customCategoryLabel.trim().isNotEmpty) {
      return customCategoryLabel.trim();
    }
    return defaultLabel(categoryId);
  }
}
