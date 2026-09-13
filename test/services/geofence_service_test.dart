import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_logic.dart';
import 'package:reminder/services/geofence_platform.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/geofence_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';

/// Plugin'e dokunmayan, çağrıları kaydeden sahte platform.
class FakeGeofencePlatform implements GeofencePlatform {
  FakeGeofencePlatform({this.maxRegions = kAndroidMaxGeofences});

  @override
  final int maxRegions;

  final Map<String, GeofenceTarget> registered = {};
  final List<String> created = [];
  final List<String> removed = [];
  final Set<String> failCreateFor = {};
  int reCreateCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reCreateRegistered() async => reCreateCalls++;

  @override
  Future<Set<String>> registeredIds() async => registered.keys.toSet();

  @override
  Future<bool> create(GeofenceTarget target) async {
    created.add(target.id);
    if (failCreateFor.contains(target.id)) return false;
    registered[target.id] = target;
    return true;
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    registered.remove(id);
  }
}

Reminder _located(String id, {double lat = 41, bool isDone = false}) =>
    buildReminder(
      id: id,
      isDone: isDone,
      locationTriggerEnabled: true,
      locationLatitude: lat,
      locationLongitude: 29,
    );

void main() {
  late FakeGeofencePlatform platform;
  late GeofenceService service;
  final clock = DateTime(2026, 9, 13, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = FakeGeofencePlatform();
    service = GeofenceService.forTesting(
      platform: platform,
      clock: () => clock,
    );
  });

  test('initialize re-creates persisted registrations once', () async {
    await service.initialize();
    await service.initialize();

    expect(platform.reCreateCalls, 1);
  });

  test('registers eligible reminders and records registration time', () async {
    await service.syncWithReminders(
      [_located('a'), _located('b', isDone: true), buildReminder(id: 'c')],
      notificationsEnabled: true,
    );

    expect(platform.registered.keys, ['a']);
    final records = await GeofenceStateStore().loadRegistrations();
    expect(records.keys, ['a']);
    expect(records['a']!.registeredAt, clock);
  });

  test('a second sync with the same data does not touch the OS', () async {
    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);
    platform.created.clear();

    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);

    expect(platform.created, isEmpty);
    expect(platform.removed, isEmpty);
  });

  test('re-creates moved regions and removes deleted ones', () async {
    await service.syncWithReminders(
      [_located('a'), _located('b')],
      notificationsEnabled: true,
    );
    platform.created.clear();

    await service.syncWithReminders(
      [_located('a', lat: 42)],
      notificationsEnabled: true,
    );

    expect(platform.removed, unorderedEquals(['a', 'b']));
    expect(platform.created, ['a']);
    expect(platform.registered['a']!.latitude, 42);
    expect((await GeofenceStateStore().loadRegistrations()).keys, ['a']);
  });

  test('removes everything when notifications are disabled', () async {
    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);

    await service
        .syncWithReminders([_located('a')], notificationsEnabled: false);

    expect(platform.registered, isEmpty);
    expect(await GeofenceStateStore().loadRegistrations(), isEmpty);
  });

  test('does not record failed registrations so the next sync retries',
      () async {
    platform.failCreateFor.add('a');
    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);
    expect(await GeofenceStateStore().loadRegistrations(), isEmpty);

    platform.failCreateFor.clear();
    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);
    expect(platform.registered.keys, ['a']);
  });

  test('migrates ids registered by flutter_geofence_manager', () async {
    SharedPreferences.setMockInitialValues({
      'geofence_registered_ids_v1': ['old', 'a'],
    });

    await service
        .syncWithReminders([_located('a')], notificationsEnabled: true);

    expect(platform.removed, unorderedEquals(['old', 'a']));
    expect(platform.registered.keys, ['a']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('geofence_registered_ids_v1'), isNull);
  });

  test('respects the platform region limit', () async {
    platform = FakeGeofencePlatform(maxRegions: kIosMaxGeofences);
    service = GeofenceService.forTesting(platform: platform);

    await service.syncWithReminders(
      List.generate(
        25,
        (i) => buildReminder(
          id: 'r$i',
          createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          locationTriggerEnabled: true,
          locationLatitude: 41,
          locationLongitude: 29,
        ),
      ),
      notificationsEnabled: true,
    );

    expect(platform.registered, hasLength(kIosMaxGeofences));
  });

  test('real platform is unsupported on the test host', () async {
    await expectLater(
      NativeGeofencePlatform().initialize(),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
