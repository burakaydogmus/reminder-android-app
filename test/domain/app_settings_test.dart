import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('JSON round-trip preserves values', () {
      const settings = AppSettings(
        notificationsEnabled: false,
        themeMode: AppThemeModeIds.dark,
      );

      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored.notificationsEnabled, isFalse);
      expect(restored.themeMode, AppThemeModeIds.dark);
    });

    test('fromJson falls back to defaults for missing fields', () {
      final restored = AppSettings.fromJson(const {});

      expect(restored.notificationsEnabled, isTrue);
      expect(restored.themeMode, AppThemeModeIds.system);
    });
  });

  group('AppThemeModeIds.normalize', () {
    test('keeps known ids', () {
      for (final id in AppThemeModeIds.values) {
        expect(AppThemeModeIds.normalize(id), id);
      }
    });

    test('maps null and unknown values to system', () {
      expect(AppThemeModeIds.normalize(null), AppThemeModeIds.system);
      expect(AppThemeModeIds.normalize('sepia'), AppThemeModeIds.system);
    });
  });
}
