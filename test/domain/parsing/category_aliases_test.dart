import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/category_aliases.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';

import '../../helpers/factories.dart';

void main() {
  final now = DateTime(2026, 9, 13, 14, 32);
  final catalog = CategoryCatalog([
    buildCategory(id: 'gym', name: 'Spor Salonu', position: 0),
    buildCategory(id: 'book', name: 'Kitap Kulübü', position: 1),
    // Same folded name as a built-in alias: the earlier category wins.
    buildCategory(id: 'shop', name: 'Alışveriş', position: 2),
  ]);

  test('built-ins keep default aliases, user categories get folded names', () {
    final aliases = CategoryAliases.of(catalog);
    expect(aliases[ReminderCategoryIds.market], ['market', 'alışveriş']);
    expect(aliases[ReminderCategoryIds.home], contains('ev işleri'));
    expect(aliases['gym'], ['spor salonu']);
    expect(aliases['book'], ['kitap kulubu']);
    expect(aliases.containsKey('shop'), isFalse);
    expect(aliases.keys.toList(), [
      ...ReminderCategoryIds.orderedIds,
      'gym',
      'book',
    ]);
  });

  test('the parser matches user categories from the config', () {
    final config = CategoryAliases.configFor(catalog);
    String? idOf(String input) =>
        CaptureParser.parse(input, now: now, config: config).categoryId;

    expect(idOf('Koşu #sporsalonu'), 'gym');
    expect(idOf('Koşu #SPOR_SALONU'), 'gym');
    expect(idOf('Toplantı #kitap-kulubu'), 'book');
    expect(idOf('Süt #market'), ReminderCategoryIds.market);
    expect(idOf('Süt #alisveris'), ReminderCategoryIds.market);
    expect(idOf('Not #yoga'), isNull);
  });

  test('configFor keeps the base hours and list categories', () {
    const base = CaptureParserConfig(morningHour: 7, listCategoryIds: {'gym'});
    final config = CategoryAliases.configFor(catalog, base: base);
    expect(config.morningHour, 7);
    expect(config.listCategoryIds, {'gym'});
  });

  test('built-ins only equals the default aliases plus names', () {
    final aliases = CategoryAliases.of(CategoryCatalog.builtIns);
    for (final entry in CaptureParserConfig.defaultCategoryAliases.entries) {
      expect(aliases[entry.key], containsAll(entry.value));
    }
  });
}
