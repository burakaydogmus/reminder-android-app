import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/notification_fingerprint_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = NotificationFingerprintStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips fingerprints', () async {
    await store.save({1: 'a', 2147483647: 'b'});

    expect(await store.load(), {1: 'a', 2147483647: 'b'});
  });

  test('returns null when nothing is stored', () async {
    expect(await store.load(), isNull);
  });

  test('an empty map is not the same as a missing store', () async {
    await store.save(const {});

    expect(await store.load(), isEmpty);
  });

  for (final raw in ['{not json', '[1, 2]', '{"x": "a"}', '{"1": 2}', '""']) {
    test('returns null for corrupt content: $raw', () async {
      SharedPreferences.setMockInitialValues({
        NotificationFingerprintStore.storageKey: raw,
      });

      expect(await store.load(), isNull);
    });
  }

  test('clear removes the stored map', () async {
    await store.save({1: 'a'});
    await store.clear();

    expect(await store.load(), isNull);
  });
}
