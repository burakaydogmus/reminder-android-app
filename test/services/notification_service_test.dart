import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_fingerprint_store.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';

Set<int> _birthdayIds(Birthday b) =>
    {for (final o in b.advanceOffsetsMinutes) b.notificationIdFor(o)};

void main() {
  late FakeNotificationsPlugin plugin;
  late NotificationService service;

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final future = buildReminder(id: 'future', remindAt: tomorrow);
  final past = buildReminder(
    id: 'past',
    remindAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
  final done = buildReminder(id: 'done', isDone: true, remindAt: tomorrow);
  final untimed = buildReminder(id: 'untimed');
  final birthday = buildBirthday(id: 'b1');

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plugin = FakeNotificationsPlugin();
    service = NotificationService.forTesting(plugin);
  });

  group('syncSchedules', () {
    test('schedules future active reminders and every birthday offset',
        () async {
      await service.syncSchedules(
        reminders: [future, past, done, untimed],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      expect(
        plugin.pending.keys.toSet(),
        {future.notificationId, ..._birthdayIds(birthday)},
      );
      for (final id in _birthdayIds(birthday)) {
        expect(plugin.pending[id]!.payload, 'birthday:b1');
        expect(
          plugin.pending[id]!.matchDateTimeComponents,
          DateTimeComponents.dateAndTime,
        );
      }
    });

    test('a reminder change keeps birthday notifications scheduled (F1.2)',
        () async {
      await service.syncSchedules(
        reminders: [future],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      await service.syncSchedules(
        reminders: [future.copyWith(isDone: true)],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      expect(plugin.pending.keys.toSet(), _birthdayIds(birthday));
    });

    test('drops notifications of removed reminders and birthdays', () async {
      final other = buildBirthday(id: 'b2', advanceOffsetsMinutes: [0]);
      await service.syncSchedules(
        reminders: [future],
        birthdays: [birthday, other],
        notificationsEnabled: true,
      );

      await service.syncSchedules(
        reminders: const [],
        birthdays: [other],
        notificationsEnabled: true,
      );

      expect(plugin.pending.keys.toSet(), _birthdayIds(other));
    });

    test('schedules nothing and clears existing ones when disabled', () async {
      await service.syncSchedules(
        reminders: [future],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      await service.syncSchedules(
        reminders: [future],
        birthdays: [birthday],
        notificationsEnabled: false,
      );

      expect(plugin.pending, isEmpty);
    });

    // F1.5 geçişi: eski `String.hashCode` kimlikleriyle zamanlanmış
    // bildirimler yeni kimliklerle hesaplanamaz. Her senkron (her uygulama
    // açılışında `ScheduleSync.syncAll`) bekleyenlerde olup istenmeyen her
    // id'yi tek tek iptal ettiği için bunlar da temizlenir (F1.7: cancelAll
    // olmadan).
    test('cancels unknown old-scheme pending ids without cancelAll', () async {
      final legacy = FakePendingNotification(
        id: 424242,
        title: 'old-scheme',
        scheduledDate: tz.TZDateTime.now(tz.local).add(
          const Duration(days: 3),
        ),
      );
      plugin.pending[legacy.id] = legacy;

      await service.syncSchedules(
        reminders: [future],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      expect(plugin.cancelAllCalls, 0);
      expect(plugin.cancelledIds, [legacy.id]);
      expect(plugin.pending.containsKey(legacy.id), isFalse);
      expect(
        plugin.pending.keys.toSet(),
        {future.notificationId, ..._birthdayIds(birthday)},
      );
    });

    test('initializes the plugin lazily, once', () async {
      for (var i = 0; i < 2; i++) {
        await service.syncSchedules(
          reminders: const [],
          birthdays: const [],
          notificationsEnabled: true,
        );
      }

      expect(plugin.initializeCalls, 1);
    });
  });

  group('birthday notification text (F1.8)', () {
    final zeynep = buildBirthday(
      id: 'z',
      name: 'Zeynep Aydın',
      date: DateTime(1990, 5, 10),
      advanceOffsetsMinutes: BirthdayAdvanceOffset.presets
          .map((p) => p.minutes)
          .toList(growable: false),
    );

    test('title names the person, with "Yaklaşıyor" before the day', () {
      expect(
        NotificationService.birthdayNotificationTitle(zeynep, 0),
        '🎂 Zeynep Aydın',
      );
      expect(
        NotificationService.birthdayNotificationTitle(zeynep, 1440),
        '🎂 Yaklaşıyor: Zeynep Aydın',
      );
    });

    test('body depends only on the offset', () {
      const expected = {
        0: 'Bugün doğum günü.',
        30: '30 dakika sonra doğum günü.',
        60: '1 saat sonra doğum günü.',
        180: '3 saat sonra doğum günü.',
        1440: 'Yarın doğum günü.',
        4320: '3 gün sonra doğum günü.',
        10080: '7 gün sonra doğum günü.',
      };
      expected.forEach((offset, body) {
        expect(
          NotificationService.birthdayNotificationBody(offset),
          body,
          reason: 'offset $offset',
        );
      });
    });

    test('scheduled yearly notifications contain no age', () async {
      await service.syncSchedules(
        reminders: const [],
        birthdays: [zeynep],
        notificationsEnabled: true,
      );

      expect(plugin.pending, hasLength(BirthdayAdvanceOffset.presets.length));
      final age = zeynep.upcomingAge!;
      for (final offset in zeynep.advanceOffsetsMinutes) {
        final n = plugin.pending[zeynep.notificationIdFor(offset)]!;
        expect(
          n.title,
          NotificationService.birthdayNotificationTitle(zeynep, offset),
        );
        expect(n.body, NotificationService.birthdayNotificationBody(offset));
        expect(
          n.matchDateTimeComponents,
          DateTimeComponents.dateAndTime,
        );
        for (final text in [n.title!, n.body!]) {
          expect(text, isNot(contains('yaş')), reason: 'offset $offset');
          expect(text, isNot(contains('$age')), reason: 'offset $offset');
          expect(text, isNot(contains('${age - 1}')), reason: '$offset');
          expect(text, isNot(contains('${age + 1}')), reason: '$offset');
        }
      }
    });
  });

  test('cancelAll removes reminder and birthday notifications', () async {
    await service.syncSchedules(
      reminders: [future],
      birthdays: [birthday],
      notificationsEnabled: true,
    );

    await service.cancelAll();

    expect(plugin.pending, isEmpty);
    expect(await const NotificationFingerprintStore().load(), isNull);
  });

  group('diff-based sync (F1.7)', () {
    final other = buildReminder(id: 'other', remindAt: tomorrow);
    final friend = buildBirthday(id: 'b2', advanceOffsetsMinutes: [0]);
    final allBirthdayIds = {..._birthdayIds(birthday), ..._birthdayIds(friend)};

    Future<void> sync(
      List<Reminder> reminders, {
      List<Birthday>? birthdays,
      bool enabled = true,
    }) =>
        service.syncSchedules(
          reminders: reminders,
          birthdays: birthdays ?? [birthday, friend],
          notificationsEnabled: enabled,
        );

    /// İlk senkron: her şey kurulu, sayaçlar sıfır.
    Future<void> baseline() async {
      await sync([future, other]);
      plugin.resetCounters();
    }

    test('an unchanged state writes nothing', () async {
      await baseline();

      await sync([future, other]);

      expect(plugin.writeCalls, 0);
    });

    test('editing one reminder reschedules only that id', () async {
      await baseline();

      await sync([future.copyWith(title: 'Süt al'), other]);

      expect(plugin.scheduledIds, [future.notificationId]);
      expect(plugin.cancelledIds, isEmpty);
      expect(plugin.cancelAllCalls, 0);
      expect(plugin.pending[future.notificationId]!.title, 'Süt al');
    });

    test('completing or deleting one reminder cancels only that id', () async {
      await baseline();

      await sync([future.copyWith(isDone: true), other]);
      expect(plugin.cancelledIds, [future.notificationId]);

      await sync([future.copyWith(isDone: true)]);
      expect(
          plugin.cancelledIds, [future.notificationId, other.notificationId]);
      expect(plugin.scheduleCalls, 0);
      expect(plugin.cancelAllCalls, 0);
      expect(plugin.pending.keys.toSet(), allBirthdayIds);
    });

    test('a time edit reschedules at the new time', () async {
      await baseline();
      final later = tomorrow.add(const Duration(hours: 2));

      await sync([future.copyWith(remindAt: () => later), other]);

      expect(plugin.scheduledIds, [future.notificationId]);
      expect(
        plugin.pending[future.notificationId]!.scheduledDate,
        tz.TZDateTime.from(later, tz.local),
      );
    });

    test('birthdays are untouched when only reminders change', () async {
      await baseline();

      await sync([future.copyWith(title: 'Yeni'), buildReminder(id: 'new')]);
      await sync([
        future.copyWith(title: 'Yeni'),
        buildReminder(id: 'timed', remindAt: tomorrow),
      ]);

      final touched = {...plugin.scheduledIds, ...plugin.cancelledIds};
      expect(touched.intersection(allBirthdayIds), isEmpty);
      expect(plugin.pending.keys.toSet(), containsAll(allBirthdayIds));
    });

    test('a birthday change touches only that birthday', () async {
      await baseline();

      await sync(
        [future, other],
        birthdays: [birthday, friend.copyWith(name: 'Mehmet')],
      );

      expect(plugin.scheduledIds, [friend.notificationIdFor(0)]);
      expect(plugin.cancelledIds, isEmpty);
    });

    test('a shown geofence notification survives syncs', () async {
      final geo = buildReminder(
        id: 'geo',
        remindAt: tomorrow,
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
      );
      await sync([geo, other]);
      await service.showGeofenceEntry(geo);
      expect(plugin.shown, {geo.geoNotificationId});

      await sync([geo.copyWith(title: 'Değişti'), other]);
      await sync([geo.copyWith(isDone: true)]);
      await sync(const [], enabled: false);

      expect(plugin.shown, {geo.geoNotificationId});
      expect(plugin.cancelAllCalls, 0);
      expect(plugin.cancelledIds, isNot(contains(geo.geoNotificationId)));
    });

    test('never cancels a geo id even if it shows up as pending', () async {
      final geo = buildReminder(id: 'geo', remindAt: tomorrow);
      plugin.pending[geo.geoNotificationId] = FakePendingNotification(
        id: geo.geoNotificationId,
        title: 'geo',
        scheduledDate: tz.TZDateTime.now(tz.local),
      );

      await sync([geo]);

      expect(plugin.cancelledIds, isNot(contains(geo.geoNotificationId)));
    });

    test('a pending entry missing from the plugin is rescheduled', () async {
      await baseline();
      plugin.pending.remove(other.notificationId);

      await sync([future, other]);

      expect(plugin.scheduledIds, [other.notificationId]);
    });

    for (final (label, raw) in [
      ('corrupt', '{not json'),
      ('missing', null),
    ]) {
      test('$label fingerprint store: reschedules all desired, no cancelAll',
          () async {
        await baseline();
        final prefs = await SharedPreferences.getInstance();
        if (raw == null) {
          await prefs.remove(NotificationFingerprintStore.storageKey);
        } else {
          await prefs.setString(NotificationFingerprintStore.storageKey, raw);
        }

        await sync([future, other]);

        expect(
          plugin.scheduledIds.toSet(),
          {future.notificationId, other.notificationId, ...allBirthdayIds},
        );
        expect(plugin.cancelledIds, isEmpty);
        expect(plugin.cancelAllCalls, 0);
        expect(await const NotificationFingerprintStore().load(), isNotNull);

        plugin.resetCounters();
        await sync([future, other]);
        expect(plugin.writeCalls, 0, reason: 'store repaired');
      });
    }

    test('disabled: cancels pending one by one and clears fingerprints',
        () async {
      await baseline();

      await sync([future, other], enabled: false);

      expect(plugin.pending, isEmpty);
      expect(plugin.cancelAllCalls, 0);
      expect(plugin.scheduleCalls, 0);
      expect(
        plugin.cancelledIds.toSet(),
        {future.notificationId, other.notificationId, ...allBirthdayIds},
      );
      expect(await const NotificationFingerprintStore().load(), isNull);

      plugin.resetCounters();
      await sync([future, other]);
      expect(plugin.pending.keys.toSet(), {
        future.notificationId,
        other.notificationId,
        ...allBirthdayIds,
      });
    });
  });
}
