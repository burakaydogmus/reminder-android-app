import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F6.1: the ARB files stay in sync and no user-visible Turkish text is left
/// in the UI code.
void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  final tr = load('app_tr.arb');
  final en = load('app_en.arb');

  Set<String> messageKeys(Map<String, dynamic> arb) => {
        for (final k in arb.keys)
          if (!k.startsWith('@')) k
      };

  /// `{name}` arguments at the top level or inside plural/select cases
  /// (not case bodies such as `=1{day}` / `other{days}`).
  Set<String> placeholders(String message) => {
        for (final m
            in RegExp(r'(?<![=\w])\{(\w+)(?=[,}])').allMatches(message))
          m.group(1)!,
      };

  test('every Turkish key exists in English and vice versa', () {
    final trKeys = messageKeys(tr);
    final enKeys = messageKeys(en);
    expect(trKeys.difference(enKeys), isEmpty, reason: 'missing in app_en');
    expect(enKeys.difference(trKeys), isEmpty, reason: 'missing in app_tr');
    expect(trKeys.length, greaterThan(400));
  });

  test('no empty values', () {
    for (final arb in [tr, en]) {
      for (final key in messageKeys(arb)) {
        final value = arb[key];
        expect(value, isA<String>(), reason: key);
        expect((value as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('English uses only placeholders declared in the template', () {
    for (final key in messageKeys(en)) {
      final declared = <String>{
        ...?((tr['@$key'] as Map<String, dynamic>?)?['placeholders']
                as Map<String, dynamic>?)
            ?.keys,
      };
      final used = placeholders(en[key] as String)
        ..removeWhere((p) => p == 'count' && declared.contains('count'));
      expect(
        used.difference(declared),
        isEmpty,
        reason: '$key uses undeclared placeholders',
      );
    }
  });

  test('the template declares the placeholders it uses', () {
    for (final key in messageKeys(tr)) {
      final declared = <String>{
        ...?((tr['@$key'] as Map<String, dynamic>?)?['placeholders']
                as Map<String, dynamic>?)
            ?.keys,
      };
      expect(
        placeholders(tr[key] as String).difference(declared),
        isEmpty,
        reason: key,
      );
    }
  });

  group('no hardcoded user-visible strings (CLAUDE.md › Localization)', () {
    // Literals with Turkish letters that are not UI copy: grammar tables
    // (possessive/dative suffixes), casing helpers and the licence notice.
    const allowed = {
      'lib/ui/common/kor_format.dart',
      'lib/ui/common/recurrence_text.dart',
      'lib/ui/reminders/snooze_options.dart',
      'lib/ui/capture/capture_text.dart',
    };
    const turkish = '[çğıöşüÇĞİÖŞÜ]';
    final literal = RegExp(
      "'[^'\\n]*$turkish[^'\\n]*'" '|"[^"\\n]*$turkish[^"\\n]*"',
    );

    test('lib/ui and lib/services have no Turkish string literals', () {
      final offenders = <String>[];
      for (final dir in ['lib/ui', 'lib/services', 'lib/home']) {
        for (final file in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          final path = file.path.replaceAll(r'\', '/');
          if (allowed.contains(path)) continue;
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trimLeft();
            if (line.startsWith('//') || line.startsWith('import ')) continue;
            final code = lines[i].split(' // ').first;
            if (literal.hasMatch(code)) offenders.add('$path:${i + 1}: $line');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}
