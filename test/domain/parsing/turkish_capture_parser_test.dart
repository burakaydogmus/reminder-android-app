import 'package:flutter_test/flutter_test.dart';

import 'cases/capture_case.dart';
import 'cases/date_cases.dart';
import 'cases/recurrence_cases.dart';
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
  };

  for (final entry in tables.entries) {
    group(entry.key, () => runCases(entry.value));
  }
}
