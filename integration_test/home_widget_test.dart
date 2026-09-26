// E2E 5/7 — real `home_widget` storage.
//
// On the host `HomeWidgetPlatform` is replaced by a fake and `Platform.isAndroid`
// is false, so `syncRemindersToHomeWidget` never actually writes anything. Here
// the payload goes into the plugin's real Android `SharedPreferences` file — the
// same bytes `WidgetPayload.kt` reads when the launcher draws a widget — and is
// read back through the plugin.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/home/widget_payload.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';

import 'helpers/e2e.dart';

/// The pre-F5.1 key; the first sync must delete it.
const String kLegacyPayloadKey = 'reminders_active_json';

Future<Map<String, Object?>?> readPayload() async {
  final raw = await HomeWidget.getWidgetData<String>(kHomeWidgetPayloadKey);
  if (raw == null) return null;
  return jsonDecode(raw) as Map<String, Object?>;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a sync writes the v2 payload into home_widget storage',
      (tester) async {
    // Leave something under the legacy key so the deletion is observable.
    await HomeWidget.saveWidgetData<String>(kLegacyPayloadKey, '[]');

    await launchApp(tester);
    await reachToday(tester);
    final cubit = cubitOf(tester);

    final now = DateTime.now();
    final reminder = Reminder(
      id: 'e2e-widget',
      title: 'Çöpü çıkar',
      isDone: false,
      createdAt: now,
      remindAt: now.add(const Duration(hours: 1)),
    );
    await cubit.addReminder(reminder);

    // `ScheduleSync.syncAll` writes the payload after every change.
    await pumpUntilTrue(
      tester,
      () async {
        final payload = await readPayload();
        final items = payload?['items'] as List<Object?>?;
        return items != null &&
            items.any(
                (item) => (item as Map<String, Object?>)['id'] == reminder.id);
      },
      reason: 'for the reminder to appear in the "$kHomeWidgetPayloadKey" '
          'payload stored by home_widget',
    );

    final payload = (await readPayload())!;
    expect(payload['v'], WidgetPayload.version,
        reason: 'the native side only reads this version (F5.1)');
    expect(payload['lang'], 'tr',
        reason: 'the widget chrome follows the in-app language (F6.1)');
    expect(payload['notificationsEnabled'], isTrue);
    final items =
        (payload['items']! as List<Object?>).cast<Map<String, Object?>>();
    final item = items.singleWhere((i) => i['id'] == reminder.id);
    expect(item['title'], reminder.title);
    expect(item['dueAt'], isNotNull,
        reason: 'the native side recomputes sections from dueAt at draw time');

    expect(
      await HomeWidget.getWidgetData<String>(kLegacyPayloadKey),
      isNull,
      reason: 'the first sync deletes the pre-F5.1 key',
    );

    // Deleting the reminder is reflected in the stored payload, so a widget
    // that outlives the app never shows a removed item.
    await cubit.deleteReminder(reminder.id);
    await pumpUntilTrue(
      tester,
      () async {
        final items = (await readPayload())?['items'] as List<Object?>?;
        return items != null &&
            !items.any(
                (item) => (item as Map<String, Object?>)['id'] == reminder.id);
      },
      reason: 'for the deleted reminder to leave the widget payload',
    );
    expect(tester.takeException(), isNull);
  });
}
