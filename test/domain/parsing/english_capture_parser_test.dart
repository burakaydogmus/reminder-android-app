import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/parsing/capture_parser.dart';

import 'cases/capture_case.dart';
import 'cases/en/en_date_cases.dart';
import 'cases/en/en_edge_cases.dart';
import 'cases/en/en_recurrence_cases.dart';
import 'cases/en/en_split_cases.dart';
import 'cases/en/en_tag_cases.dart';
import 'cases/en/en_time_cases.dart';

/// Table-driven English examples (F4.6c), grouped by rule. Every sentence
/// uses the same fixed clock as the Turkish table, `kNow`
/// (Sunday 13 September 2026, 14:32).
void main() {
  final tables = <String, List<CaptureCase>>{
    'dates': enDateCases,
    'times': enTimeCases,
    'recurrence': enRecurrenceCases,
    'tags': enTagCases,
    'split': enSplitCases,
    'edge': enEdgeCases,
  };

  for (final entry in tables.entries) {
    group(
        entry.key, () => runCases(entry.value, locale: CaptureLocale.english));
  }

  // Same bar as the Turkish table (design §5.5 risk 6).
  test('example table has at least 200 distinct sentences', () {
    final inputs = [for (final t in tables.values) ...t.map((c) => c.input)];
    expect(inputs.toSet().length, greaterThanOrEqualTo(200));
  });
}
