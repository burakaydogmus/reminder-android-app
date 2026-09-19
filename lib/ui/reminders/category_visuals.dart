import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
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

  /// Names for screen readers ("Spor, seçili").
  static String spokenName(String key, AppLocalizations l10n) => switch (key) {
        CategoryIconKeys.basket => l10n.categoryIconBasket,
        CategoryIconKeys.home => l10n.categoryIconHome,
        CategoryIconKeys.work => l10n.categoryIconWork,
        CategoryIconKeys.heart => l10n.categoryIconHeart,
        CategoryIconKeys.sun => l10n.categoryIconSun,
        CategoryIconKeys.fitness => l10n.categoryIconFitness,
        CategoryIconKeys.school => l10n.categoryIconSchool,
        CategoryIconKeys.pets => l10n.categoryIconPets,
        CategoryIconKeys.car => l10n.categoryIconCar,
        CategoryIconKeys.flight => l10n.categoryIconFlight,
        CategoryIconKeys.restaurant => l10n.categoryIconRestaurant,
        CategoryIconKeys.payments => l10n.categoryIconPayments,
        CategoryIconKeys.medication => l10n.categoryIconMedication,
        CategoryIconKeys.child => l10n.categoryIconChild,
        CategoryIconKeys.flower => l10n.categoryIconFlower,
        CategoryIconKeys.build => l10n.categoryIconBuild,
        CategoryIconKeys.book => l10n.categoryIconBook,
        _ => l10n.categoryIconLabel,
      };

  /// Unknown keys fall back to the label icon.
  static IconData of(String key) => byKey[key] ?? Icons.label_rounded;
}

/// Names of the 12 category colours for screen readers ("Lacivert,
/// seçili", §3.3.6).
abstract final class CategoryColorNames {
  static String of(KorColorKey key, AppLocalizations l10n) => switch (key) {
        KorColorKey.market => l10n.colorMarket,
        KorColorKey.ev => l10n.colorEv,
        KorColorKey.is_ => l10n.colorIs,
        KorColorKey.saglik => l10n.colorSaglik,
        KorColorKey.gunluk => l10n.colorGunluk,
        KorColorKey.diger => l10n.colorDiger,
        KorColorKey.dogumGunu => l10n.colorDogumGunu,
        KorColorKey.kor => l10n.colorKor,
        KorColorKey.lacivert => l10n.colorLacivert,
        KorColorKey.zeytin => l10n.colorZeytin,
        KorColorKey.kiremit => l10n.colorKiremit,
        KorColorKey.arduvaz => l10n.colorArduvaz,
      };
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

  /// Display name of [id] ("Market", "Spor salonu", unknown → "Diğer") in
  /// the app language: built-ins are translated, user categories keep the
  /// name the user typed.
  static String labelOf(BuildContext context, String id) =>
      nameOf(categoryOf(context, id), context.l10n);

  /// Display name of [category] (see [labelOf]); also for pure code.
  static String nameOf(ReminderCategory category, AppLocalizations l10n) =>
      category.isBuiltIn ? builtInName(category.id, l10n) : category.name;

  /// Localized name of a built-in category id (unknown → "Diğer").
  static String builtInName(String id, AppLocalizations l10n) => switch (id) {
        ReminderCategoryIds.market => l10n.categoryMarket,
        ReminderCategoryIds.home => l10n.categoryHome,
        ReminderCategoryIds.work => l10n.categoryWork,
        ReminderCategoryIds.health => l10n.categoryHealth,
        ReminderCategoryIds.errands => l10n.categoryErrands,
        _ => l10n.categoryOther,
      };

  /// [labelOf] for pure code: [id] resolved in [catalog].
  static String labelIn(
    CategoryCatalog catalog,
    String id,
    AppLocalizations l10n,
  ) =>
      nameOf(catalog.resolve(id), l10n);

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
