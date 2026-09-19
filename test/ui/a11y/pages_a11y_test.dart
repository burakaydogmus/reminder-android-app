import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/lists/smart_list_page.dart';
import 'package:reminder/ui/lists/smart_lists.dart';
import 'package:reminder/ui/maps/location_picker_page.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui_harness.dart';
import 'a11y_audit.dart';
import 'a11y_sample_data.dart';

/// F4.5 audit: pushed pages (§3.6).
const _bothPlatforms = [TargetPlatform.android, TargetPlatform.iOS];

Future<UiHarness> _pumpPage(
  WidgetTester tester,
  A11yVariant variant,
  Widget page,
) async {
  final h = await UiHarness.create(
    reminders: auditReminders(),
    birthdays: auditBirthdays(),
    now: auditClock,
  );
  await tester.pumpWidget(
    h.app(
      theme: variant.theme,
      platform: variant.platform,
      home: NowScope(clock: auditClock, child: page),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'search_recent_v1': ['fatura', 'market'],
    });
    PackageInfo.setMockInitialValues(
      appName: 'Hatırlatıcı',
      packageName: 'com.burakaydogmus.reminder',
      version: '2.1.0',
      buildNumber: '8',
      buildSignature: '',
    );
  });

  for (final list in [SmartList.overdue, SmartList.scheduled]) {
    a11yAudit('Akıllı liste ${list.labelIn(AppL10n.turkish)}',
        (tester, variant) async {
      await _pumpPage(tester, variant, SmartListPage(list: list));
    });
  }

  a11yAudit('Akıllı liste empty state', (tester, variant) async {
    await _pumpPage(
      tester,
      variant,
      const SmartListPage(list: SmartList.located),
    );
    await tester.pumpAndSettle();
  });

  a11yAudit('Arama with recent searches', (tester, variant) async {
    await _pumpPage(tester, variant, const SearchPage());
  });

  a11yAudit(
    'Arama with results',
    (tester, variant) async {
      await _pumpPage(tester, variant, const SearchPage());
      await tester.enterText(find.byKey(SearchPageKeys.field), 'market');
      await tester.pumpAndSettle();
      expect(find.byType(SearchResultCard), findsWidgets);
    },
    platforms: _bothPlatforms,
  );

  a11yAudit(
    'Ayarlar',
    (tester, variant) async {
      await _pumpPage(tester, variant, const SettingsPage());
    },
    platforms: _bothPlatforms,
    surface: const Size(390, 3200),
  );

  a11yAudit('Doğum günleri', (tester, variant) async {
    await _pumpPage(tester, variant, const BirthdaysPage());
  });

  a11yAudit('Konum seçici', (tester, variant) async {
    // flutter_map's tile cache asks path_provider for a directory.
    final cache = Directory.systemTemp.createTempSync('a11y_tiles');
    addTearDown(() => cache.deleteSync(recursive: true));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cache.path,
    );
    final h = await UiHarness.create(now: auditClock);
    await tester.pumpWidget(
      h.app(
        theme: variant.theme,
        platform: variant.platform,
        home: LocationPickerPage(
          categoryId: ReminderCategoryIds.market,
          initialPoint: const LatLng(41.0082, 28.9784),
          initialLabel: 'Migros Kadıköy',
          linkOpener: (_) async => true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
