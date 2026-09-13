import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

/// The single mapping from built-in category ids to Kor colour keys and icons.
///
/// UI-only, so it lives here instead of `domain/model`. Colours are resolved
/// through `KorColors` for the current brightness; never store a hex.
abstract final class CategoryVisuals {
  static const Map<String, KorColorKey> _colorKeys = {
    ReminderCategoryIds.market: KorColorKey.market,
    ReminderCategoryIds.home: KorColorKey.ev,
    ReminderCategoryIds.work: KorColorKey.is_,
    ReminderCategoryIds.health: KorColorKey.saglik,
    ReminderCategoryIds.errands: KorColorKey.gunluk,
    ReminderCategoryIds.other: KorColorKey.diger,
  };

  static const Map<String, IconData> _icons = {
    ReminderCategoryIds.market: Icons.shopping_basket_rounded,
    ReminderCategoryIds.home: Icons.home_rounded,
    ReminderCategoryIds.work: Icons.work_rounded,
    ReminderCategoryIds.health: Icons.favorite_rounded,
    ReminderCategoryIds.errands: Icons.wb_sunny_rounded,
    ReminderCategoryIds.other: Icons.label_rounded,
  };

  /// Colour key for a category id; unknown ids fall back to "Diğer".
  static KorColorKey colorKeyFor(String id) =>
      _colorKeys[id] ?? KorColorKey.diger;

  static IconData iconFor(String id) => _icons[id] ?? Icons.label_rounded;

  /// Resolved fg/container/onFg colours of [id] in the current theme.
  static CategoryColors colorsOf(BuildContext context, String id) =>
      context.korColors.category(colorKeyFor(id));

  /// Birthday accent (not a reminder category).
  static const KorColorKey birthdayColorKey = KorColorKey.dogumGunu;
  static const IconData birthdayIcon = Icons.cake_rounded;

  static CategoryColors birthdayColorsOf(BuildContext context) =>
      context.korColors.category(birthdayColorKey);
}

/// Round tonal category icon badge (decorative; not a tap target).
class CategoryIconBadge extends StatelessWidget {
  final String categoryId;
  final double size;

  const CategoryIconBadge({
    super.key,
    required this.categoryId,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CategoryVisuals.colorsOf(context, categoryId);
    return IconBadge(
      icon: CategoryVisuals.iconFor(categoryId),
      foreground: colors.fg,
      background: colors.container,
      size: size,
    );
  }
}

/// Circle with a centred icon; used for category and list badges.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.55, color: foreground),
      ),
    );
  }
}
