import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

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
    expect(CategoryVisuals.iconFor('nope'), Icons.label_rounded);
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
}
