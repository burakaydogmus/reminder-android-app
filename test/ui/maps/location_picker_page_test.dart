import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:reminder/config/app_links.dart';
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

  for (final (themeName, theme) in korThemes) {
    group('OSM attribution ($themeName)', () {
      Future<List<Uri>> pumpPicker(
        WidgetTester tester, {
        bool launchResult = true,
      }) async {
        final opened = <Uri>[];
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            theme: theme,
            home: LocationPickerPage(
              categoryId: ReminderCategoryIds.other,
              initialPoint: const LatLng(41.0082, 28.9784),
              linkOpener: (uri) async {
                opened.add(uri);
                return launchResult;
              },
            ),
          ),
        );
        await tester.pump();
        return opened;
      }

      testWidgets(
          'shows "© OpenStreetMap contributors" and links to the '
          'copyright page', (tester) async {
        final opened = await pumpPicker(tester);

        final attribution = find.byType(SimpleAttributionWidget);
        expect(attribution, findsOneWidget);
        expect(
          find.descendant(of: attribution, matching: find.textContaining('©')),
          findsOneWidget,
        );
        final source = find.text('OpenStreetMap contributors');
        expect(source, findsOneWidget);
        expect(
          tester.widget<SimpleAttributionWidget>(attribution).onTap,
          isNotNull,
        );

        await tester.tap(source);
        await tester.pump();
        expect(opened, [AppLinks.osmCopyright]);
        expect(
          AppLinks.osmCopyright.toString(),
          'https://www.openstreetmap.org/copyright',
        );
      });

      testWidgets('attribution stays clear of "Konumuma git"', (tester) async {
        await pumpPicker(tester);

        final attribution = tester.getRect(
          find.text('OpenStreetMap contributors'),
        );
        final myLocation = tester.getRect(find.byTooltip('Konumuma git'));
        expect(attribution.overlaps(myLocation), isFalse);
      });

      testWidgets('a failed launch shows a snackbar', (tester) async {
        await pumpPicker(tester, launchResult: false);

        await tester.tap(find.text('OpenStreetMap contributors'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Bağlantı açılamadı.'), findsOneWidget);
      });
    });
  }
}
