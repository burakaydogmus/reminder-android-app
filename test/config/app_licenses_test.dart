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

  Future<List<LicenseEntry>> entriesFor(String package) async {
    final entries = await LicenseRegistry.licenses.toList();
    return [
      for (final e in entries)
        if (e.packages.contains(package)) e,
    ];
  }

  Future<List<LicenseEntry>> fontEntries() =>
      entriesFor(googleSansFlexLicensePackage);

  String textOf(LicenseEntry entry) =>
      entry.paragraphs.map((p) => p.text).join('\n');

  test('registers the Google Sans Flex OFL from the bundled asset', () async {
    registerAppLicenses();

    final entries = await fontEntries();
    expect(entries, hasLength(1));
    final text = textOf(entries.single);
    expect(text, contains('Google Sans Flex Authors'));
    expect(text, contains('SIL Open Font License, Version 1.1'));
  });

  test('registers the vendored liquid_glass_renderer notice (MIT)', () async {
    registerAppLicenses();

    final entries = await entriesFor(liquidGlassRendererLicensePackage);
    expect(entries, hasLength(1));
    final text = textOf(entries.single);
    expect(text, contains('Copyright 2025 Tim Lehmann for whynotmake.it'));
    expect(text, contains('MIT License'));
    expect(text, contains('packages/liquid_glass_renderer'));
  });

  test('registers the adapted motor notice (MIT)', () async {
    registerAppLicenses();

    final entries = await entriesFor(motorLicensePackage);
    expect(entries, hasLength(1));
    final text = textOf(entries.single);
    expect(text, contains('Copyright (c) 2024 Tim Lehmann for whynotmake.it'));
    expect(text, contains('packages/motor'));
  });

  test('registering twice adds each licence once', () async {
    registerAppLicenses();
    registerAppLicenses();

    expect(await fontEntries(), hasLength(1));
    expect(await entriesFor(liquidGlassRendererLicensePackage), hasLength(1));
    expect(await entriesFor(motorLicensePackage), hasLength(1));
  });

  test('nothing is registered before init', () async {
    expect(await fontEntries(), isEmpty);
    expect(await entriesFor(liquidGlassRendererLicensePackage), isEmpty);
    expect(await entriesFor(motorLicensePackage), isEmpty);
  });
}
