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
  });
}
