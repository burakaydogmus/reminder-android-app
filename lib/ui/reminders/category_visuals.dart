import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

/// The fixed icon set of categories (F4.3): 18 Material Symbols Rounded
/// icons keyed by [CategoryIconKeys]. Categories store the key, never an
/// `IconData`, so icons stay tree-shakeable and stable across versions.
abstract final class CategoryIcons {
  static const Map<String, IconData> byKey = {
    CategoryIconKeys.label: Icons.label_rounded,
    CategoryIconKeys.basket: Icons.shopping_basket_rounded,
    CategoryIconKeys.home: Icons.home_rounded,
    CategoryIconKeys.work: Icons.work_rounded,
    CategoryIconKeys.heart: Icons.favorite_rounded,
    CategoryIconKeys.sun: Icons.wb_sunny_rounded,
    CategoryIconKeys.fitness: Icons.fitness_center_rounded,
    CategoryIconKeys.school: Icons.school_rounded,
    CategoryIconKeys.pets: Icons.pets_rounded,
    CategoryIconKeys.car: Icons.directions_car_rounded,
    CategoryIconKeys.flight: Icons.flight_rounded,
    CategoryIconKeys.restaurant: Icons.restaurant_rounded,
    CategoryIconKeys.payments: Icons.payments_rounded,
    CategoryIconKeys.medication: Icons.medication_rounded,
    CategoryIconKeys.child: Icons.child_care_rounded,
    CategoryIconKeys.flower: Icons.local_florist_rounded,
    CategoryIconKeys.build: Icons.build_rounded,
    CategoryIconKeys.book: Icons.menu_book_rounded,
  };

  /// Turkish names for screen readers ("Spor, seçili").
  static const Map<String, String> spokenNames = {
    CategoryIconKeys.label: 'Etiket',
    CategoryIconKeys.basket: 'Sepet',
    CategoryIconKeys.home: 'Ev',
    CategoryIconKeys.work: 'Çanta',
    CategoryIconKeys.heart: 'Kalp',
    CategoryIconKeys.sun: 'Güneş',
    CategoryIconKeys.fitness: 'Spor',
    CategoryIconKeys.school: 'Okul',
    CategoryIconKeys.pets: 'Evcil hayvan',
    CategoryIconKeys.car: 'Araba',
    CategoryIconKeys.flight: 'Uçak',
    CategoryIconKeys.restaurant: 'Yemek',
    CategoryIconKeys.payments: 'Para',
    CategoryIconKeys.medication: 'İlaç',
    CategoryIconKeys.child: 'Çocuk',
    CategoryIconKeys.flower: 'Çiçek',
    CategoryIconKeys.build: 'Tamir',
    CategoryIconKeys.book: 'Kitap',
  };

  /// Unknown keys fall back to the label icon.
  static IconData of(String key) => byKey[key] ?? Icons.label_rounded;
}

/// Turkish names of the 12 category colours for screen readers
/// ("Lacivert, seçili", §3.3.6).
abstract final class CategoryColorNames {
  static const Map<KorColorKey, String> _names = {
    KorColorKey.market: 'Yeşil',
    KorColorKey.ev: 'Turkuaz',
    KorColorKey.is_: 'Mavi',
    KorColorKey.saglik: 'Pembe',
    KorColorKey.gunluk: 'Hardal',
    KorColorKey.diger: 'Mor',
    KorColorKey.dogumGunu: 'Eflatun',
    KorColorKey.kor: 'Kor',
    KorColorKey.lacivert: 'Lacivert',
    KorColorKey.zeytin: 'Zeytin',
    KorColorKey.kiremit: 'Kiremit',
    KorColorKey.arduvaz: 'Arduvaz',
  };

  static String of(KorColorKey key) => _names[key]!;
}

/// The single mapping from category ids to Kor colour keys, icons and
/// labels (F4.3: built-in and user categories).
///
/// UI-only, so it lives here instead of `domain/model`. Colours are resolved
/// through `KorColors` for the current brightness; never store a hex.
///
/// Built-in ids resolve without touching the cubit (their visuals are
/// fixed). Other ids read `ReminderState.categories` with `context.select`,
/// so call these helpers only from a `build` method; without a
/// [ReminderCubit] above (isolated widgets, tests) only built-ins exist and
/// unknown ids show as "Diğer".
abstract final class CategoryVisuals {
  /// The current category catalog (built-ins when there is no cubit).
  static CategoryCatalog catalogOf(BuildContext context) =>
      context.select<ReminderCubit?, CategoryCatalog>(
        (cubit) => cubit?.state.categories ?? CategoryCatalog.builtIns,
      );

  /// [catalogOf] without subscribing: for callbacks and code outside
  /// `build` (e.g. text styles computed while parsing).
  static CategoryCatalog readCatalog(BuildContext context) =>
      context.read<ReminderCubit?>()?.state.categories ??
      CategoryCatalog.builtIns;

  /// [colorsOf] without subscribing (see [readCatalog]).
  static CategoryColors readColorsOf(BuildContext context, String id) =>
      context.korColors.category(colorKeyOf(readCatalog(context).resolve(id)));

  /// The category of [id]; unknown/deleted ids resolve to "Diğer".
  static ReminderCategory categoryOf(BuildContext context, String id) =>
      ReminderCategoryIds.isBuiltIn(id)
          ? ReminderCategory.builtIn(id)
          : catalogOf(context).resolve(id);

  /// Display name of [id] ("Market", "Spor salonu", unknown → "Diğer").
  static String labelOf(BuildContext context, String id) =>
      categoryOf(context, id).name;

  static IconData iconFor(BuildContext context, String id) =>
      iconOf(categoryOf(context, id));

  /// Resolved fg/container/onFg/onContainer colours of [id] in the current
  /// theme. Text on `container` uses `onContainer`, icons `fg`.
  static CategoryColors colorsOf(BuildContext context, String id) =>
      context.korColors.category(colorKeyOf(categoryOf(context, id)));

  static IconData iconOf(ReminderCategory category) =>
      CategoryIcons.of(category.iconKey);

  /// Stored colour key of [category]; unknown keys → "Diğer".
  static KorColorKey colorKeyOf(ReminderCategory category) =>
      KorColorKey.tryParse(category.colorKey) ?? KorColorKey.diger;

  /// Colour key for a category id without a [BuildContext] (pure
  /// groupings); unknown ids fall back to "Diğer".
  static KorColorKey colorKeyFor(String id, [CategoryCatalog? catalog]) =>
      colorKeyOf((catalog ?? CategoryCatalog.builtIns).resolve(id));

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
    final category = CategoryVisuals.categoryOf(context, categoryId);
    return CategoryBadge(category: category, size: size);
  }
}

/// [CategoryIconBadge] for a category object (e.g. the editor's live
/// preview, before the category is saved).
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 40});

  final ReminderCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors =
        context.korColors.category(CategoryVisuals.colorKeyOf(category));
    return IconBadge(
      icon: CategoryVisuals.iconOf(category),
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
