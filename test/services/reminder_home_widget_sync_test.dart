import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/home/widget_payload.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/ios_widget_completions.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';

import '../helpers/factories.dart';
import '../helpers/l10n_setup.dart';
import 'fake_home_widget_platform.dart';

final _now = DateTime(2026, 9, 13, 14, 32);

void main() {
  setUpAll(initTestDateFormatting);

  final reminder = buildReminder(
    id: 'a',
    title: 'Ali\'yi kurstan al',
    remindAt: DateTime(2026, 9, 13, 16),
  );

  Future<void> sync(FakeHomeWidgetPlatform platform) =>
      syncRemindersToHomeWidget(
        [reminder],
        birthdays: const [],
        notificationsEnabled: true,
        now: () => _now,
        l10n: AppL10n.turkish,
        platform: platform,
      );

  group('platform branching', () {
    test('Android writes the payload and refreshes the four providers',
        () async {
      final platform = FakeHomeWidgetPlatform(isAndroid: true);

      await sync(platform);

      expect(platform.appGroupIds, isEmpty,
          reason: 'Android ignores the App Group; the call stays iOS-only');
      expect(platform.saved.keys,
          [kHomeWidgetPayloadKey, 'reminders_active_json']);
      expect(platform.saved['reminders_active_json'], isNull);
      expect(platform.androidUpdates, [
        for (final widget in ReminderHomeWidget.values) widget.qualifiedName,
      ]);
      expect(platform.iosUpdates, isEmpty);
    });

    test('iOS sets the App Group, then writes and reloads every kind',
        () async {
      final platform = FakeHomeWidgetPlatform(isIOS: true);

      await sync(platform);

      expect(platform.appGroupIds, [kHomeWidgetAppGroupId]);
      expect(platform.calls.first, 'setAppGroupId:$kHomeWidgetAppGroupId',
          reason: 'saving before the group id would land in the app sandbox');
      expect(platform.saved.keys,
          [kHomeWidgetPayloadKey, 'reminders_active_json']);
      expect(platform.saved['reminders_active_json'], isNull);
      expect(platform.iosUpdates, kIosWidgetKinds);
      expect(platform.androidUpdates, isEmpty);
    });

    test('other platforms do nothing at all', () async {
      final platform = FakeHomeWidgetPlatform();

      await sync(platform);

      expect(platform.calls, isEmpty);
    });
  });

  group('payload', () {
    test('is the same JSON on both platforms', () async {
      final android = FakeHomeWidgetPlatform(isAndroid: true);
      final ios = FakeHomeWidgetPlatform(isIOS: true);

      await sync(android);
      await sync(ios);

      expect(
        ios.saved[kHomeWidgetPayloadKey],
        android.saved[kHomeWidgetPayloadKey],
      );
      final decoded =
          jsonDecode(ios.saved[kHomeWidgetPayloadKey]!) as Map<String, Object?>;
      expect(decoded['v'], WidgetPayload.version);
      expect(decoded['lang'], 'tr');
    });

    test('carries the English labels when the app language is English',
        () async {
      final platform = FakeHomeWidgetPlatform(isIOS: true);

      await syncRemindersToHomeWidget(
        [reminder],
        birthdays: const [],
        notificationsEnabled: true,
        now: () => _now,
        l10n: AppL10n.english,
        platform: platform,
      );

      final decoded = jsonDecode(platform.saved[kHomeWidgetPayloadKey]!)
          as Map<String, Object?>;
      expect(decoded['lang'], 'en');
    });
  });

  group('PlatformHomeWidgetSync', () {
    test('passes its platform through', () async {
      final platform = FakeHomeWidgetPlatform(isIOS: true);

      await PlatformHomeWidgetSync(platform: platform).sync(
        [reminder],
        birthdays: const [],
        notificationsEnabled: true,
      );

      expect(platform.iosUpdates, kIosWidgetKinds);
    });
  });

  // No Swift tests run in CI, so the shared identifiers are checked against the
  // native sources here: a rename on one side fails the Dart suite.
  group('native contract', () {
    String read(String path) => File(path).readAsStringSync();

    test('the widget kinds match ReminderWidgetBundle.swift', () {
      final swift = read('ios/ReminderWidget/ReminderWidgetBundle.swift');
      for (final kind in kIosWidgetKinds) {
        expect(
          swift,
          contains('static let kind = "$kind"'),
          reason: '$kind is reloaded from Dart but not declared in Swift',
        );
      }
      expect(
        RegExp('static let kind = ').allMatches(swift).length,
        kIosWidgetKinds.length,
        reason: 'a new Swift widget also needs an entry in kIosWidgetKinds',
      );
    });

    test('the App Group id matches Swift and both entitlements', () {
      expect(
        read('ios/ReminderWidget/ReminderWidgetStore.swift'),
        contains('static let appGroupId = "$kHomeWidgetAppGroupId"'),
      );
      for (final path in [
        'ios/Runner/Runner.entitlements',
        'ios/ReminderWidget/ReminderWidgetExtension.entitlements',
      ]) {
        expect(read(path), contains('<string>$kHomeWidgetAppGroupId</string>'),
            reason: '$path must grant the App Group');
      }
    });

    test('the shared keys match ReminderWidgetStore.swift', () {
      final swift = read('ios/ReminderWidget/ReminderWidgetStore.swift');
      expect(
          swift, contains('static let payloadKey = "$kHomeWidgetPayloadKey"'));
      expect(
        swift,
        contains('static let completionsKey = "$kWidgetCompletionsKey"'),
      );
    });

    test('the URL scheme is declared in the Runner Info.plist', () {
      expect(
        read('ios/Runner/Info.plist'),
        contains('<string>reminderwidget</string>'),
        reason: 'widget taps reach the app through CFBundleURLTypes',
      );
    });
  });
}
