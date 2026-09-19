import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';

import 'a11y_audit.dart';
import 'a11y_sample_data.dart';

/// F4.5 audit: the three shell tabs (§3.6) on Android and iOS chrome.
const _bothPlatforms = [TargetPlatform.android, TargetPlatform.iOS];

/// Tall enough for the whole page at 200 %, so no text sits under the
/// floating nav (the pages end with padding above it).
const _shellSurface = Size(390, 2800);

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label).last);
  await tester.pumpAndSettle();
}

void main() {
  a11yAudit(
    'Bugün with overdue, recurring, subtasks and pinned reminders',
    (tester, variant) async {
      await pumpAuditShell(tester, variant);
      expect(find.text('Elektrik faturasını öde'), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: _shellSurface,
  );

  a11yAudit('Bugün empty state', (tester, variant) async {
    await pumpAuditShell(tester, variant, reminders: const []);
  }, surface: _shellSurface);

  a11yAudit(
    'Takvim week view with agenda',
    (tester, variant) async {
      await pumpAuditShell(tester, variant);
      await _selectTab(tester, 'Takvim');
      expect(find.byType(CalendarPage), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: _shellSurface,
  );

  a11yAudit('Takvim month grid', (tester, variant) async {
    await pumpAuditShell(tester, variant);
    await _selectTab(tester, 'Takvim');
    await tester.tap(find.byKey(CalendarPageKeys.toggleMonth));
    await tester.pumpAndSettle();
  }, surface: _shellSurface);

  a11yAudit(
    'Listeler with smart lists and categories',
    (tester, variant) async {
      await pumpAuditShell(tester, variant);
      await _selectTab(tester, 'Listeler');
      expect(find.text('Kategorilerim'), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: _shellSurface,
  );
}
