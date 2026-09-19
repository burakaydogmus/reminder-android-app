import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/category_label_migration.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../helpers/factories.dart';

void main() {
  final builtIns = CategoryCatalog.builtIns;

  test('each distinct label becomes one user category (diger, label)', () {
    final plan = CategoryLabelMigration.plan([
      ('a', 'Spor'),
      ('b', 'Kitap kulübü'),
      ('c', ' spor '),
      ('d', 'SPOR'),
    ], existing: builtIns);

    expect(plan.created.map((c) => c.name), ['Spor', 'Kitap kulübü']);
    expect(plan.created.every((c) => c.colorKey == CategoryColorKeys.diger),
        isTrue);
    expect(
        plan.created.every((c) => c.iconKey == CategoryIconKeys.label), isTrue);
    expect(plan.created.map((c) => c.position), [6, 7]);
    final spor = plan.created.first.id;
    expect(plan.assignments, {
      'a': spor,
      'b': plan.created.last.id,
      'c': spor,
      'd': spor,
    });
  });

  test('Turkish folding merges İ/ı and diacritics', () {
    final plan = CategoryLabelMigration.plan([
      ('a', 'Işık'),
      ('b', 'ISIK'),
      ('c', 'işık'),
    ], existing: builtIns);
    expect(plan.created, hasLength(1));
    expect(plan.assignments.values.toSet(), {plan.created.single.id});
  });

  test('empty labels and "Diğer" stay in Diğer; built-in names map', () {
    final plan = CategoryLabelMigration.plan([
      ('a', null),
      ('b', '   '),
      ('c', 'diger'),
      ('d', 'MARKET'),
    ], existing: builtIns);
    expect(plan.created, isEmpty);
    expect(plan.assignments, {'d': ReminderCategoryIds.market});
  });

  test('labels matching an existing user category reuse it', () {
    final existing = CategoryCatalog([buildCategory(id: 'u1', name: 'Spor')]);
    final plan =
        CategoryLabelMigration.plan([('a', 'spor')], existing: existing);
    expect(plan.created, isEmpty);
    expect(plan.assignments, {'a': 'u1'});
  });

  test('ids are stable per folded name', () {
    expect(CategoryLabelMigration.idFor('Spor'),
        CategoryLabelMigration.idFor(' SPOR'));
    expect(CategoryLabelMigration.idFor('Spor'),
        isNot(CategoryLabelMigration.idFor('Yoga')));
    expect(CategoryLabelMigration.idFor('Spor'), startsWith('label-'));
  });

  test('apply repoints only labelled "other" reminders, keeps the label', () {
    final result = CategoryLabelMigration.apply([
      buildReminder(id: 'a', customCategoryLabel: 'Spor', priority: 3),
      buildReminder(id: 'b'),
      buildReminder(
        id: 'c',
        categoryId: ReminderCategoryIds.work,
        customCategoryLabel: 'Spor',
      ),
    ], existing: builtIns);
    final spor = result.created.single;
    expect(result.reminders.map((r) => r.categoryId),
        [spor.id, ReminderCategoryIds.other, ReminderCategoryIds.work]);
    expect(result.reminders.first.customCategoryLabel, 'Spor');
    expect(result.reminders.first.priority, 3);
  });

  test('apply without labels returns the same list', () {
    final reminders = [buildReminder()];
    final result = CategoryLabelMigration.apply(reminders, existing: builtIns);
    expect(identical(result.reminders, reminders), isTrue);
    expect(result.created, isEmpty);
  });
}
