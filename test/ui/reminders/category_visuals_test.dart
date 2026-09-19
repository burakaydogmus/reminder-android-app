import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

void main() {
  test('every built-in category id maps to its Kor colour key', () {
    const expected = {
      ReminderCategoryIds.market: KorColorKey.market,
      ReminderCategoryIds.home: KorColorKey.ev,
      ReminderCategoryIds.work: KorColorKey.is_,
      ReminderCategoryIds.health: KorColorKey.saglik,
      ReminderCategoryIds.errands: KorColorKey.gunluk,
      ReminderCategoryIds.other: KorColorKey.diger,
    };
    expect(ReminderCategoryIds.orderedIds.toSet(), expected.keys.toSet());
    for (final entry in expected.entries) {
      expect(CategoryVisuals.colorKeyFor(entry.key), entry.value);
    }
  });

  test('unknown ids fall back to Diğer', () {
    expect(CategoryVisuals.colorKeyFor('nope'), KorColorKey.diger);
    expect(CategoryIcons.of('nope'), Icons.label_rounded);
  });

  test('birthday accent uses the dogumGunu key', () {
    expect(CategoryVisuals.birthdayColorKey, KorColorKey.dogumGunu);
  });

  for (final (name, theme, colors) in [
    ('light', KorTheme.light(), KorColors.light),
    ('dark', KorTheme.dark(), KorColors.dark),
  ]) {
    testWidgets('colorsOf resolves through the $name theme', (tester) async {
      late CategoryColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              resolved = CategoryVisuals.colorsOf(
                context,
                ReminderCategoryIds.home,
              );
              return const CategoryIconBadge(
                categoryId: ReminderCategoryIds.home,
              );
            },
          ),
        ),
      );
      expect(resolved, colors.category(KorColorKey.ev));
    });
  }

  test('18 icons and 12 spoken colour names (F4.3)', () {
    expect(CategoryIcons.byKey.keys, CategoryIconKeys.all);
    expect({
      for (final k in CategoryIconKeys.all)
        CategoryIcons.spokenName(k, AppL10n.turkish)
    }, hasLength(CategoryIconKeys.all.length));
    expect(
        KorColorKey.values
            .map((k) => CategoryColorNames.of(k, AppL10n.turkish))
            .toSet(),
        hasLength(12));
    expect(CategoryColorNames.of(KorColorKey.lacivert, AppL10n.turkish),
        'Lacivert');
  });

  test('colorKeyFor resolves user categories through a catalog', () {
    final catalog = CategoryCatalog([buildCategory(id: 'gym')]);
    expect(CategoryVisuals.colorKeyFor('gym', catalog), KorColorKey.lacivert);
    expect(CategoryVisuals.colorKeyFor('gym'), KorColorKey.diger);
    expect(
      CategoryVisuals.colorKeyOf(buildCategory(colorKey: 'bogus')),
      KorColorKey.diger,
    );
  });

  testWidgets('user categories resolve from the cubit, unknown → Diğer',
      (tester) async {
    final h = await UiHarness.create(categories: [
      buildCategory(id: 'gym', name: 'Spor salonu', colorKey: 'kor'),
    ]);
    late String label;
    late String unknown;
    late IconData icon;
    late CategoryColors resolved;
    await tester.pumpWidget(h.app(
      home: Builder(builder: (context) {
        label = CategoryVisuals.labelOf(context, 'gym');
        unknown = CategoryVisuals.labelOf(context, 'deleted');
        icon = CategoryVisuals.iconFor(context, 'gym');
        resolved = CategoryVisuals.colorsOf(context, 'gym');
        return const SizedBox.shrink();
      }),
    ));
    expect(label, 'Spor salonu');
    expect(unknown, 'Diğer');
    expect(icon, Icons.fitness_center_rounded);
    expect(resolved, KorColors.light.category(KorColorKey.kor));

    // A rename rebuilds dependents.
    await h.cubit.saveCategory(buildCategory(id: 'gym', name: 'Yoga'));
    await tester.pump();
    expect(label, 'Yoga');
  });

  testWidgets('without a cubit only built-ins exist', (tester) async {
    late String label;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        label = CategoryVisuals.labelOf(context, 'gym');
        return const SizedBox.shrink();
      }),
    ));
    expect(label, 'Diğer');
  });
}
