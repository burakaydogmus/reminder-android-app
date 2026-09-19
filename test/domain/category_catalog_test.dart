import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../helpers/factories.dart';

void main() {
  group('ReminderCategory', () {
    test('JSON round trip keeps every field', () {
      final c = buildCategory(position: 7);
      expect(ReminderCategory.fromJson(c.toJson()), c);
    });

    test('fromJson defaults missing colour, icon and position', () {
      final c = ReminderCategory.fromJson({'id': 'x', 'name': 'Hobi'});
      expect(c.colorKey, CategoryColorKeys.diger);
      expect(c.iconKey, CategoryIconKeys.label);
      expect(c.position, 0);
    });

    test('fromJson throws without id or name', () {
      expect(() => ReminderCategory.fromJson({'name': 'x'}), throwsA(anything));
      expect(() => ReminderCategory.fromJson({'id': 'x'}), throwsA(anything));
    });

    test('built-ins are marked, user categories are not', () {
      expect(
          ReminderCategory.builtIn(ReminderCategoryIds.work).isBuiltIn, isTrue);
      expect(buildCategory().isBuiltIn, isFalse);
    });

    test('normalizeName trims, collapses spaces and caps at 24', () {
      expect(ReminderCategory.normalizeName('  Spor   salonu '), 'Spor salonu');
      expect(ReminderCategory.normalizeName('a' * 30).length,
          ReminderCategory.maxNameLength);
    });

    test('18 distinct icon keys', () {
      expect(CategoryIconKeys.all.toSet().length, 18);
    });
  });

  group('CategoryCatalog', () {
    test('empty store gives the six built-ins in default order', () {
      final catalog = CategoryCatalog(const []);
      expect(catalog.ordered.map((c) => c.id), ReminderCategoryIds.orderedIds);
      expect(catalog.ordered.map((c) => c.position), [0, 1, 2, 3, 4, 5]);
      expect(catalog.labelOf(ReminderCategoryIds.home), 'Ev İşleri');
    });

    test('user categories without stored built-ins go after them', () {
      final catalog = CategoryCatalog([buildCategory(position: 0)]);
      expect(catalog.ordered.last.id, 'c1');
      expect(catalog.ordered.last.position, 6);
      expect(catalog.userCategories.map((c) => c.id), ['c1']);
    });

    test('stored order wins; built-in name/colour/icon stay fixed', () {
      final catalog = CategoryCatalog([
        buildCategory(position: 0),
        const ReminderCategory(
          id: ReminderCategoryIds.work,
          name: 'Ofis',
          colorKey: 'kor',
          iconKey: 'book',
          position: 1,
        ),
      ]);
      expect(catalog.ordered.take(2).map((c) => c.id),
          ['c1', ReminderCategoryIds.work]);
      final work = catalog.byId(ReminderCategoryIds.work)!;
      expect(work.name, 'İş');
      expect(work.colorKey, CategoryColorKeys.is_);
      // Missing built-ins are appended.
      expect(catalog.ordered.length, 7);
      expect(catalog.contains(ReminderCategoryIds.market), isTrue);
    });

    test('unknown ids resolve to Diğer', () {
      final catalog = CategoryCatalog(const []);
      expect(catalog.resolve('gone').id, ReminderCategoryIds.other);
      expect(catalog.labelOf('gone'), 'Diğer');
    });

    test('duplicate ids keep the first', () {
      final catalog = CategoryCatalog([
        buildCategory(name: 'A', position: 0),
        buildCategory(name: 'B', position: 1),
      ]);
      expect(catalog.userCategories.single.name, 'A');
    });

    test('byFoldedName ignores case, Turkish diacritics and spaces', () {
      final catalog = CategoryCatalog([buildCategory(name: 'Spor Salonu')]);
      expect(catalog.byFoldedName(' SPOR  salonu')?.id, 'c1');
      expect(catalog.byFoldedName('saglik')?.id, ReminderCategoryIds.health);
      expect(catalog.byFoldedName('Spor salonu', exceptId: 'c1'), isNull);
    });

    test('value equality', () {
      expect(CategoryCatalog([buildCategory()]),
          CategoryCatalog([buildCategory()]));
      expect(CategoryCatalog([buildCategory()]) == CategoryCatalog.builtIns,
          isFalse);
    });
  });

  test('CategoryNames.fold', () {
    expect(CategoryNames.fold(' İŞ  Yeri '), 'is yeri');
    expect(CategoryNames.fold('Günlük'), CategoryNames.fold('GUNLUK'));
  });
}
