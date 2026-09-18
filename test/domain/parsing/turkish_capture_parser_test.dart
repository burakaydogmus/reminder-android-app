import 'package:flutter_test/flutter_test.dart';

import 'cases/capture_case.dart';
import 'cases/date_cases.dart';
import 'cases/edge_cases.dart';
import 'cases/recurrence_cases.dart';
import 'cases/split_cases.dart';
import 'cases/tag_cases.dart';
import 'cases/time_cases.dart';

/// Table-driven examples, grouped by rule. Every sentence uses the fixed
/// clock `kNow` (Pazar 13 Eylül 2026 14:32).
void main() {
  final tables = <String, List<CaptureCase>>{
    'dates': dateCases,
    'times': timeCases,
    'recurrence': recurrenceCases,
    'tags': tagCases,
    'split': splitCases,
    'edge': edgeCases,
  };

  for (final entry in tables.entries) {
    group(entry.key, () => runCases(entry.value));
  }

  // Design §5.5 risk 6: a table of 200+ Turkish example sentences.
  test('example table has at least 200 distinct sentences', () {
    final inputs = [for (final t in tables.values) ...t.map((c) => c.input)];
    expect(inputs.toSet().length, greaterThanOrEqualTo(200));
  });
}
