import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/maps/location_picker_page.dart';

import '../ui_harness.dart';

void main() {
  for (final state in [
    LocationPermissionState.notRequested,
    LocationPermissionState.denied,
  ]) {
    testWidgets('opening the picker does not request location ($state)',
        (tester) async {
      final h = await UiHarness.create();
      h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
        location: state,
      );
      await tester.pumpWidget(
        h.app(
          home: const LocationPickerPage(
            categoryId: ReminderCategoryIds.other,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The map is still usable for manual selection.
      expect(find.text('Bu konumu kaydet'), findsOneWidget);
      expect(h.permissions.calls, isEmpty);
    });
  }
}
