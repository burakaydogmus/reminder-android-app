import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/notification_actions.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';

/// F6.1: notification texts, channels and actions in both languages.
void main() {
  final tr = AppL10n.turkish;
  final en = AppL10n.english;

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final tomorrow = DateTime.now().add(const Duration(days: 1));

  group('texts', () {
    test('birthday titles and bodies', () {
      final b = buildBirthday(name: 'Ayşe');
      expect(
          NotificationService.birthdayNotificationTitle(b, 0, tr), '🎂 Ayşe');
      expect(
        NotificationService.birthdayNotificationTitle(b, 1440, tr),
        '🎂 Yaklaşıyor: Ayşe',
      );
      expect(
        NotificationService.birthdayNotificationTitle(b, 1440, en),
        '🎂 Coming up: Ayşe',
      );
      expect(
        [
          for (final m in [0, 30, 60, 180, 1440, 4320, 10080])
            NotificationService.birthdayNotificationBody(m, en),
        ],
        [
          'Birthday today.',
          'Birthday in 30 minutes.',
          'Birthday in 1 hour.',
          'Birthday in 3 hours.',
          'Birthday tomorrow.',
          'Birthday in 3 days.',
          'Birthday in 7 days.',
        ],
      );
      expect(
        NotificationService.birthdayNotificationBody(180, tr),
        '3 saat sonra doğum günü.',
      );
    });

    test('reminder bodies with subtasks', () {
      final r = buildReminder(
        subtasks: buildSubtasks(
          ['Süt', 'Ekmek', 'Yumurta', 'Peynir', 'Zeytin', 'Çay', 'Şeker'],
          done: {0},
        ),
      );
      expect(
          NotificationService.reminderNotificationBody(r, en), '6 items left');
      expect(
        NotificationService.reminderNotificationBody(r, en, context: 'Home'),
        'Home · 6 items left',
      );
      expect(
        NotificationService.reminderNotificationBody(buildReminder(), en),
        'Time for your reminder',
      );
      expect(
        NotificationService.reminderNotificationBody(buildReminder(), tr),
        'Hatırlatma zamanı',
      );
      final big = NotificationService.reminderSubtaskBigText(r, 'x', en)!;
      expect(big.split('\n').last, '… and 1 more item');
      expect(
        NotificationService.reminderSubtaskBigText(r, 'x', tr)!
            .split('\n')
            .last,
        '… ve 1 madde daha',
      );
    });

    test('action buttons', () {
      expect(
        [for (final a in androidReminderActions(en)) a.title],
        ['Complete', '10 min', '1 hour'],
      );
      expect(
        [for (final a in androidReminderActions(tr)) a.title],
        ['Tamamla', '10 dk', '1 saat'],
      );
      expect(
        [for (final a in androidReminderActions(en)) a.id],
        [for (final a in androidReminderActions(tr)) a.id],
        reason: 'action ids are persisted; only titles change',
      );
      final category = darwinNotificationCategories(en).single;
      expect(
        [for (final a in category.actions) a.title],
        ['Complete', 'Snooze 10 min', 'Snooze 1 hour', 'Tomorrow morning'],
      );
    });
  });

  group('syncSchedules', () {
    test('schedules in the resolved language with localized channels',
        () async {
      final plugin = FakeNotificationsPlugin();
      final service = NotificationService.forTesting(
        plugin,
        localizations: () async => en,
      );
      final untitled = buildReminder(id: 'r', title: ' ', remindAt: tomorrow);
      final birthday = buildBirthday(id: 'b', name: 'Deniz');

      await service.syncSchedules(
        reminders: [untitled],
        birthdays: [birthday],
        notificationsEnabled: true,
      );

      final reminder = plugin.pending[untitled.notificationId]!;
      expect(reminder.title, 'Reminder');
      expect(reminder.body, 'Time for your reminder');
      final android = reminder.details!.android!;
      expect(android.channelName, 'Reminders');
      expect(
        [for (final a in android.actions!) a.title],
        ['Complete', '10 min', '1 hour'],
      );
      final birthdayNotification = plugin.pending[birthday.notificationIdFor(
        birthday.advanceOffsetsMinutes.first,
      )]!;
      expect(birthdayNotification.title, contains('Deniz'));
      expect(
        (birthdayNotification.details!.android!).channelName,
        'Birthday reminders',
      );
    });

    test('changing the language reschedules every notification once', () async {
      final plugin = FakeNotificationsPlugin();
      var l10n = tr;
      final service = NotificationService.forTesting(
        plugin,
        localizations: () async => l10n,
      );
      final r = buildReminder(id: 'r', title: 'Süt al', remindAt: tomorrow);
      Future<void> sync() => service.syncSchedules(
            reminders: [r],
            birthdays: const [],
            notificationsEnabled: true,
          );

      await sync();
      plugin.resetCounters();
      await sync();
      expect(plugin.writeCalls, 0, reason: 'same language: nothing to do');

      l10n = en;
      await sync();
      expect(plugin.scheduledIds, [r.notificationId]);
      expect(
        (plugin.pending[r.notificationId]!.details!.android!).channelName,
        'Reminders',
      );

      plugin.resetCounters();
      await sync();
      expect(plugin.writeCalls, 0);
    });

    test('geofence entries use the language too', () async {
      final plugin = FakeNotificationsPlugin();
      final service = NotificationService.forTesting(
        plugin,
        localizations: () async => en,
      );
      final geo = buildReminder(
        id: 'geo',
        title: '',
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
      );

      await service.showGeofenceEntry(geo);

      expect(plugin.shownTexts[geo.geoNotificationId],
          ('Reminder', 'You arrived at a saved place'));
      expect(
        (plugin.shownDetails[geo.geoNotificationId]!.android!).channelName,
        'Location reminders',
      );
    });
  });
}
