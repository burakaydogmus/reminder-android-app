import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/services/notification_service.dart';
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

  test('cancelAll removes reminder and birthday notifications', () async {
    await service.syncSchedules(
      reminders: [future],
      birthdays: [birthday],
      notificationsEnabled: true,
    );

    await service.cancelAll();

    expect(plugin.pending, isEmpty);
  });
}
