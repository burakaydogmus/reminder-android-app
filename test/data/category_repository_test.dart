import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/data/db/app_database.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/test_database.dart';

/// Categories (F4.3, schema v5) in the repository.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DateTime now;
  late ReminderRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    now = DateTime.utc(2026, 9, 1, 12);
    repository = ReminderRepository(database: db, clock: () => now);
  });

  tearDown(() => db.close());

  List<ReminderCategory> withBuiltIns(List<ReminderCategory> user) =>
      CategoryCatalog(user).ordered;

  test('empty database has no stored categories', () async {
    expect(await repository.loadCategories(), isEmpty);
  });

  test('round trip keeps order, colour and icon', () async {
    final list = withBuiltIns([
      buildCategory(id: 'gym', name: 'Spor'),
      buildCategory(
          id: 'book', name: 'Kitap', colorKey: 'kor', iconKey: 'book'),
    ]);
    await repository.saveCategories(list);
    final loaded = await repository.loadCategories();
    expect(loaded, list);
    expect(CategoryCatalog(loaded).ordered, list);
  });

  test('reorder rewrites positions; unchanged rows keep updated_at', () async {
    final list = withBuiltIns([buildCategory(id: 'gym')]);
    await repository.saveCategories(list);
    final first = now.microsecondsSinceEpoch;

    now = now.add(const Duration(minutes: 1));
    final reordered = [list.last, ...list.take(list.length - 1)];
    await repository.saveCategories(
      [
        for (var i = 0; i < reordered.length; i++)
          reordered[i].copyWith(position: i)
      ],
    );
    final loaded = await repository.loadCategories();
    expect(loaded.first.id, 'gym');
    expect(loaded.map((c) => c.position), List.generate(7, (i) => i));

    // Saving the same list again touches nothing.
    now = now.add(const Duration(minutes: 1));
    final before = {
      for (final r in await db.select(db.categories).get()) r.id: r.updatedAt,
    };
    await repository.saveCategories(loaded);
    final after = {
      for (final r in await db.select(db.categories).get()) r.id: r.updatedAt,
    };
    expect(after, before);
    expect(before.values.every((t) => t > first), isTrue);
  });

  test('a category missing from the list is soft-deleted', () async {
    final list = withBuiltIns([buildCategory(id: 'gym')]);
    await repository.saveCategories(list);
    now = now.add(const Duration(minutes: 1));
    await repository.saveCategories(withBuiltIns(const []));

    expect((await repository.loadCategories()).map((c) => c.id),
        isNot(contains('gym')));
    final row = await (db.select(db.categories)
          ..where((t) => t.id.equals('gym')))
        .getSingle();
    expect(row.deletedAt, now.microsecondsSinceEpoch);

    // Re-saving restores it.
    await repository.saveCategories(list);
    expect(
        (await repository.loadCategories()).map((c) => c.id), contains('gym'));
  });

  test('clearAll removes categories', () async {
    await repository.saveCategories(withBuiltIns([buildCategory()]));
    await repository.clearAll();
    expect(await db.select(db.categories).get(), isEmpty);
  });

  test('legacy "Diğer + özel ad" reminders become categories on import',
      () async {
    SharedPreferences.setMockInitialValues({
      'reminders_v1': jsonEncode([
        buildReminder(id: 'a', customCategoryLabel: 'Spor').toJson(),
        buildReminder(id: 'b', customCategoryLabel: 'SPOR').toJson(),
        buildReminder(id: 'c').toJson(),
      ]),
    });
    final reminders = await repository.loadReminders();
    final categories = await repository.loadCategories();
    expect(categories.single.name, 'Spor');
    expect(categories.single.colorKey, CategoryColorKeys.diger);
    expect(reminders.map((r) => r.categoryId),
        [categories.single.id, categories.single.id, 'other']);
    // The old label is kept for rollback.
    expect(reminders.first.customCategoryLabel, 'Spor');
  });
}
