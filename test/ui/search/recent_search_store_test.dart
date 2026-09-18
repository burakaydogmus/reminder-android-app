import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/search/recent_search_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = RecentSearchStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empty by default', () async {
    expect(await store.load(), isEmpty);
  });

  test('newest first, trimmed, blank ignored', () async {
    await store.add('market');
    await store.add('  doktor   randevusu ');
    await store.add('   ');
    expect(await store.load(), ['doktor randevusu', 'market']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(RecentSearchStore.key), [
      'doktor randevusu',
      'market',
    ]);
  });

  test('duplicates collapse Turkish-insensitively to the newest', () async {
    await store.add('İstanbul');
    await store.add('market');
    await store.add('istanbul');
    expect(await store.load(), ['istanbul', 'market']);
  });

  test('keeps at most 8', () async {
    for (var i = 0; i < 10; i++) {
      await store.add('arama $i');
    }
    final list = await store.load();
    expect(list, hasLength(RecentSearchStore.maxEntries));
    expect(list.first, 'arama 9');
    expect(list.last, 'arama 2');
  });

  test('clear removes the key', () async {
    await store.add('market');
    await store.clear();
    expect(await store.load(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(RecentSearchStore.key), isFalse);
  });
}
