import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/geofence_logic.dart';

import '../helpers/factories.dart';

void main() {
  final now = DateTime(2026, 9, 13, 12);

  group('buildGeofenceTargets', () {
    test('keeps only active reminders with location trigger and coordinates',
        () {
      final targets = buildGeofenceTargets(
        [
          buildReminder(
            id: 'ok',
            locationTriggerEnabled: true,
            locationLatitude: 41,
            locationLongitude: 29,
          ),
          buildReminder(
            id: 'done',
            isDone: true,
            locationTriggerEnabled: true,
            locationLatitude: 41,
            locationLongitude: 29,
          ),
          buildReminder(
            id: 'disabled',
            locationLatitude: 41,
            locationLongitude: 29,
          ),
          buildReminder(
            id: 'no-lat',
            locationTriggerEnabled: true,
            locationLongitude: 29,
          ),
          buildReminder(
            id: 'no-lng',
            locationTriggerEnabled: true,
            locationLatitude: 41,
          ),
        ],
        notificationsEnabled: true,
        maxRegions: kAndroidMaxGeofences,
      );

      expect(targets.map((t) => t.id), ['ok']);
      expect(targets.single.latitude, 41);
      expect(targets.single.longitude, 29);
    });

    test('returns nothing when notifications are disabled', () {
      final targets = buildGeofenceTargets(
        [
          buildReminder(
            locationTriggerEnabled: true,
            locationLatitude: 41,
            locationLongitude: 29,
          ),
        ],
        notificationsEnabled: false,
        maxRegions: kAndroidMaxGeofences,
      );

      expect(targets, isEmpty);
    });

    test('clamps radius to 100–500 m', () {
      GeofenceTarget targetFor(double radius) => buildGeofenceTargets(
            [
              buildReminder(
                locationTriggerEnabled: true,
                locationLatitude: 41,
                locationLongitude: 29,
                locationRadiusMeters: radius,
              ),
            ],
            notificationsEnabled: true,
            maxRegions: kAndroidMaxGeofences,
          ).single;

      expect(targetFor(20).radiusMeters, 100);
      expect(targetFor(250).radiusMeters, 250);
      expect(targetFor(2000).radiusMeters, 500);
    });

    test('above the platform limit keeps the most recently created reminders',
        () {
      final reminders = List.generate(
        25,
        (i) => buildReminder(
          id: 'r$i',
          createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          locationTriggerEnabled: true,
          locationLatitude: 41,
          locationLongitude: 29,
        ),
      );

      final ios = buildGeofenceTargets(
        reminders,
        notificationsEnabled: true,
        maxRegions: kIosMaxGeofences,
      );
      final android = buildGeofenceTargets(
        reminders,
        notificationsEnabled: true,
        maxRegions: kAndroidMaxGeofences,
      );

      expect(ios, hasLength(20));
      expect(ios.first.id, 'r24');
      expect(ios.map((t) => t.id), isNot(contains('r4')));
      expect(ios.map((t) => t.id), contains('r5'));
      expect(android, hasLength(25));
    });
  });

  group('planGeofenceSync', () {
    const a = GeofenceTarget(
      id: 'a',
      latitude: 41,
      longitude: 29,
      radiusMeters: 150,
    );
    const b = GeofenceTarget(
      id: 'b',
      latitude: 40,
      longitude: 28,
      radiusMeters: 200,
    );

    test('creates new regions', () {
      final plan = planGeofenceSync(
        desired: [a, b],
        platformIds: {},
        recordedSignatures: {},
      );

      expect(plan.toRemove, isEmpty);
      expect(plan.toCreate, [a, b]);
    });

    test('leaves unchanged regions alone', () {
      final plan = planGeofenceSync(
        desired: [a],
        platformIds: {'a'},
        recordedSignatures: {'a': a.signature},
      );

      expect(plan.isEmpty, isTrue);
    });

    test('re-creates regions whose location or radius changed', () {
      const moved = GeofenceTarget(
        id: 'a',
        latitude: 41.001,
        longitude: 29,
        radiusMeters: 150,
      );
      final plan = planGeofenceSync(
        desired: [moved],
        platformIds: {'a'},
        recordedSignatures: {'a': a.signature},
      );

      expect(plan.toRemove, ['a']);
      expect(plan.toCreate, [moved]);
    });

    test('removes regions that are no longer wanted', () {
      final plan = planGeofenceSync(
        desired: [a],
        platformIds: {'a', 'stale'},
        recordedSignatures: {'a': a.signature, 'stale': b.signature},
      );

      expect(plan.toRemove, ['stale']);
      expect(plan.toCreate, isEmpty);
    });

    test('re-creates regions registered by someone else (legacy package)', () {
      final plan = planGeofenceSync(
        desired: [a],
        platformIds: {'a'},
        recordedSignatures: {},
      );

      expect(plan.toRemove, ['a']);
      expect(plan.toCreate, [a]);
    });

    test('re-creates recorded regions the OS dropped', () {
      final plan = planGeofenceSync(
        desired: [a],
        platformIds: {},
        recordedSignatures: {'a': a.signature},
      );

      expect(plan.toRemove, isEmpty);
      expect(plan.toCreate, [a]);
    });
  });

  group('reminderToNotifyOnEntry', () {
    final located = buildReminder(
      id: 'geo',
      locationTriggerEnabled: true,
      locationLatitude: 41,
      locationLongitude: 29,
    );

    test('returns the matching active location reminder', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'geo',
          reminders: [buildReminder(id: 'other'), located],
          notificationsEnabled: true,
          now: now,
        ),
        same(located),
      );
    });

    test('ignores done reminders', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'done',
          reminders: [
            buildReminder(
              id: 'done',
              isDone: true,
              locationTriggerEnabled: true,
              locationLatitude: 41,
              locationLongitude: 29,
            ),
          ],
          notificationsEnabled: true,
          now: now,
        ),
        isNull,
      );
    });

    test('ignores reminders with location trigger disabled', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'off',
          reminders: [
            buildReminder(
              id: 'off',
              locationLatitude: 41,
              locationLongitude: 29,
            ),
          ],
          notificationsEnabled: true,
          now: now,
        ),
        isNull,
      );
    });

    test('ignores reminders without coordinates', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'nocoords',
          reminders: [
            buildReminder(id: 'nocoords', locationTriggerEnabled: true),
          ],
          notificationsEnabled: true,
          now: now,
        ),
        isNull,
      );
    });

    test('returns null when notifications are disabled', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'geo',
          reminders: [located],
          notificationsEnabled: false,
          now: now,
        ),
        isNull,
      );
    });

    test('returns null for an unknown (deleted) reminder id', () {
      expect(
        reminderToNotifyOnEntry(
          geofenceId: 'deleted',
          reminders: [located],
          notificationsEnabled: true,
          now: now,
        ),
        isNull,
      );
    });

    test('suppresses the initial trigger right after registration', () {
      Reminder? at(Duration sinceRegistration) => reminderToNotifyOnEntry(
            geofenceId: 'geo',
            reminders: [located],
            notificationsEnabled: true,
            now: now,
            registeredAt: now.subtract(sinceRegistration),
          );

      expect(at(const Duration(seconds: 5)), isNull);
      expect(at(kGeofenceInitialTriggerGrace), same(located));
      expect(at(const Duration(hours: 1)), same(located));
    });

    test('does not re-notify within the cooldown', () {
      Reminder? at(Duration sinceLast) => reminderToNotifyOnEntry(
            geofenceId: 'geo',
            reminders: [located],
            notificationsEnabled: true,
            now: now,
            lastNotifiedAt: now.subtract(sinceLast),
          );

      expect(at(Duration.zero), isNull);
      expect(at(const Duration(minutes: 9, seconds: 59)), isNull);
      expect(at(kGeofenceNotificationCooldown), same(located));
    });
  });
}
