import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';

/// Kategori kimliklerine ikon ve renk eşler. UI katmanına özgü olduğu için
/// `domain/model` altındaki [ReminderCategoryIds] yerine burada tutulur.
abstract class CategoryVisuals {
  static IconData iconFor(String id) {
    switch (id) {
      case ReminderCategoryIds.market:
        return Icons.shopping_cart_rounded;
      case ReminderCategoryIds.home:
        return Icons.home_rounded;
      case ReminderCategoryIds.work:
        return Icons.work_outline_rounded;
      case ReminderCategoryIds.health:
        return Icons.favorite_rounded;
      case ReminderCategoryIds.errands:
        return Icons.wb_sunny_rounded;
      case ReminderCategoryIds.other:
      default:
        return Icons.label_rounded;
    }
  }

  static Color colorFor(String id) {
    switch (id) {
      case ReminderCategoryIds.market:
        return const Color(0xFF43A047);
      case ReminderCategoryIds.home:
        return const Color(0xFFE53935);
      case ReminderCategoryIds.work:
        return const Color(0xFF1E88E5);
      case ReminderCategoryIds.health:
        return const Color(0xFFEC407A);
      case ReminderCategoryIds.errands:
        return const Color(0xFFFB8C00);
      case ReminderCategoryIds.other:
      default:
        return const Color(0xFF8762FF);
    }
  }
}

/// Yuvarlak, renkli kategori ikonu rozeti. Liste ve seçim ekranlarında
/// kullanılır. [size] dış kapsayıcının kenar uzunluğudur.
class CategoryIconBadge extends StatelessWidget {
  final String categoryId;
  final double size;
  final bool muted;
  final bool showCheck;

  const CategoryIconBadge({
    super.key,
    required this.categoryId,
    this.size = 44,
    this.muted = false,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = CategoryVisuals.colorFor(categoryId);
    final icon = CategoryVisuals.iconFor(categoryId);
    final bg = base.withValues(alpha: muted ? 0.10 : 0.16);
    final fg = muted ? base.withValues(alpha: 0.55) : base;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              showCheck ? Icons.check_rounded : icon,
              size: size * 0.55,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
