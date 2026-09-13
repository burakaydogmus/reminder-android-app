import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_callback.dart';
import 'package:reminder/services/geofence_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

void main() {
  late MockReminderRepository repository;
  late GeofenceStateStore store;
  late List<String> shown;
  final now = DateTime(2026, 9, 13, 12);

  final located = buildReminder(
    id: 'geo',
    locationTriggerEnabled: true,
    locationLatitude: 41,
    locationLongitude: 29,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockReminderRepository();
    store = GeofenceStateStore();
    shown = [];
    when(() => repository.loadReminders()).thenAnswer((_) async => [located]);
    when(() => repository.loadSettings())
        .thenAnswer((_) async => const AppSettings());
  });

  Future<void> enter(List<String> ids, DateTime at) => handleGeofenceEntry(
        ids,
        repository: repository,
        store: store,
        showNotification: (Reminder r) async => shown.add(r.id),
        now: at,
      );

  test('shows a notification and records the time', () async {
    await enter(['geo', 'unknown'], now);

    expect(shown, ['geo']);
    expect((await store.loadLastNotified())['geo'], now);
  });

  test('duplicate enter within the cooldown is ignored', () async {
    await enter(['geo'], now);
    await enter(['geo'], now.add(const Duration(minutes: 1)));
    await enter(['geo'], now.add(const Duration(minutes: 11)));

    expect(shown, ['geo', 'geo']);
  });

  test('does nothing when notifications are disabled', () async {
    when(() => repository.loadSettings()).thenAnswer(
        (_) async => const AppSettings(notificationsEnabled: false));

    await enter(['geo'], now);

    expect(shown, isEmpty);
    verifyNever(() => repository.loadReminders());
  });

  test('ignores the initial trigger right after registration', () async {
    await store.saveRegistrations({
      'geo': GeofenceRegistration(
        signature: 'x',
        registeredAt: now.subtract(const Duration(seconds: 3)),
      ),
    });

    await enter(['geo'], now);

    expect(shown, isEmpty);
  });
}
