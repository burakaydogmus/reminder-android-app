import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/config/app_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LicenseRegistry.reset();
    resetAppLicensesForTesting();
  });

  tearDown(() {
    LicenseRegistry.reset();
    resetAppLicensesForTesting();
  });

  Future<List<LicenseEntry>> fontEntries() async {
    final entries = await LicenseRegistry.licenses.toList();
    return [
      for (final e in entries)
        if (e.packages.contains(googleSansFlexLicensePackage)) e,
    ];
  }

  test('registers the Google Sans Flex OFL from the bundled asset', () async {
    registerAppLicenses();

    final entries = await fontEntries();
    expect(entries, hasLength(1));
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Google Sans Flex Authors'));
    expect(text, contains('SIL Open Font License, Version 1.1'));
  });

  test('registering twice adds the licence once', () async {
    registerAppLicenses();
    registerAppLicenses();

    expect(await fontEntries(), hasLength(1));
  });

  test('nothing is registered before init', () async {
    expect(await fontEntries(), isEmpty);
  });
}
