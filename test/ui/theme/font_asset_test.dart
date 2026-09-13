import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/theme/tokens/kor_typography.dart';

const _fontAsset = 'fonts/GoogleSansFlex/GoogleSansFlex-Latin.ttf';

/// Reads the variation axis tags from a TrueType font's `fvar` table.
List<String> _fvarAxes(ByteData data) {
  String tag(int offset) =>
      String.fromCharCodes(List.generate(4, (i) => data.getUint8(offset + i)));

  final numTables = data.getUint16(4);
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    if (tag(record) != 'fvar') continue;
    final table = data.getUint32(record + 8);
    final axesOffset = data.getUint16(table + 4);
    final axisCount = data.getUint16(table + 8);
    final axisSize = data.getUint16(table + 10);
    return [
      for (var a = 0; a < axisCount; a++)
        tag(table + axesOffset + a * axisSize),
    ];
  }
  return const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pubspec registers the GoogleSansFlex family', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${KorTypography.fontFamily}'));
    expect(pubspec, contains('asset: $_fontAsset'));
    expect(File(_fontAsset).existsSync(), isTrue);
    expect(File('fonts/GoogleSansFlex/OFL.txt').existsSync(), isTrue);
  });

  test('font asset loads and keeps only wght, opsz and ROND axes', () async {
    final data = await rootBundle.load(_fontAsset);
    // TrueType sfnt version 0x00010000.
    expect(data.getUint32(0), 0x00010000);
    expect(_fvarAxes(data).toSet(), {'wght', 'opsz', 'ROND'});

    final loader = FontLoader(KorTypography.fontFamily)
      ..addFont(Future.value(data));
    await loader.load();
  });
}
