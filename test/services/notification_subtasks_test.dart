import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';

/// Subtasks in reminder notifications (F3.3): "N madde kaldı" body, Android
/// BigText with open items, subtasks in the F1.7 fingerprint.
void main() {
  late FakeNotificationsPlugin plugin;
  late NotificationService service;

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plugin = FakeNotificationsPlugin();
    service = NotificationService.forTesting(plugin);
  });

  String? bigTextOf(NotificationDetails? details) {
    final style = details?.android?.styleInformation;
    return style is BigTextStyleInformation ? style.bigText : null;
  }

  group('reminderNotificationBody', () {
    test('no subtasks: note or fallback as before', () {
      expect(
        NotificationService.reminderNotificationBody(buildReminder()),
        'Hatırlatma zamanı',
      );
      expect(
        NotificationService.reminderNotificationBody(
          buildReminder(note: '  Kart puanı  '),
        ),
        'Kart puanı',
      );
    });

    test('open subtasks: "N madde kaldı", after the note', () {
      final subtasks = buildSubtasks(['A', 'B', 'C'], done: {0});
      expect(
        NotificationService.reminderNotificationBody(
          buildReminder(subtasks: subtasks),
        ),
        '2 madde kaldı',
      );
      expect(
        NotificationService.reminderNotificationBody(
          buildReminder(note: 'Kart puanı', subtasks: subtasks),
        ),
        'Kart puanı · 2 madde kaldı',
      );
    });

    test('all subtasks done: plain body', () {
      expect(
        NotificationService.reminderNotificationBody(
          buildReminder(subtasks: buildSubtasks(['A'], done: {0})),
        ),
        'Hatırlatma zamanı',
      );
    });
  });

  group('reminderSubtaskBigText', () {
    test('null without open subtasks', () {
      expect(
        NotificationService.reminderSubtaskBigText(buildReminder(), 'x'),
        isNull,
      );
      expect(
        NotificationService.reminderSubtaskBigText(
          buildReminder(subtasks: buildSubtasks(['A'], done: {0})),
          'x',
        ),
        isNull,
      );
    });

    test('lists up to 5 open items, then "… ve N madde daha"', () {
      final r = buildReminder(
        subtasks: buildSubtasks(
          ['Süt', 'Ekmek', 'Çay', 'Un', 'Tuz', 'Şeker', 'Yağ', 'Pirinç'],
          done: {1},
        ),
      );
      expect(
        NotificationService.reminderSubtaskBigText(r, '7 madde kaldı'),
        '7 madde kaldı\n• Süt\n• Çay\n• Un\n• Tuz\n• Şeker\n'
        '… ve 2 madde daha',
      );
    });
  });

  group('scheduling', () {
    final at = DateTime.now().add(const Duration(days: 2));

    Future<void> sync(List<Subtask> subtasks) => service.syncSchedules(
          reminders: [
            buildReminder(id: 'm', remindAt: at, subtasks: subtasks),
          ],
          birthdays: const [],
          notificationsEnabled: true,
        );

    test('scheduled notification carries the body and BigText', () async {
      await sync(buildSubtasks(['Süt', 'Ekmek'], done: {1}));
      final n = plugin.pending.values.single;
      expect(n.body, '1 madde kaldı');
      expect(bigTextOf(n.details), '1 madde kaldı\n• Süt');
      // Actions (F3.2) are kept next to the style.
      expect(n.details!.android!.actions, isNotEmpty);
    });

    test('without subtasks there is no BigText style', () async {
      await sync(const []);
      expect(plugin.pending.values.single.details!.android!.styleInformation,
          isNull);
    });

    test(
        'toggling, renaming or adding a subtask reschedules; same list does '
        'not', () async {
      final subtasks = buildSubtasks(['Süt', 'Ekmek']);
      await sync(subtasks);
      plugin.resetCounters();

      await sync(subtasks);
      expect(plugin.scheduleCalls, 0, reason: 'unchanged');

      await sync(subtasks.toggled('s1'));
      expect(plugin.scheduleCalls, 1, reason: 'toggled');
      expect(plugin.pending.values.single.body, '1 madde kaldı');

      // Same count, different open item title: only the BigText differs.
      await sync(subtasks.toggled('s1').renamed('s2', 'Tam buğday ekmek'));
      expect(plugin.scheduleCalls, 2, reason: 'renamed');
      expect(
        bigTextOf(plugin.pending.values.single.details),
        '1 madde kaldı\n• Tam buğday ekmek',
      );
    });

    test('fingerprint version is at least 4 (F3.3)', () {
      expect(
        NotificationService.scheduleFingerprintVersion,
        greaterThanOrEqualTo(4),
      );
    });
  });

  test('geofence notification also shows open subtasks', () async {
    final geo = buildReminder(
      id: 'geo',
      locationTriggerEnabled: true,
      locationLatitude: 41,
      locationLongitude: 29,
      locationPlaceLabel: 'Migros Kadıköy',
      subtasks: buildSubtasks(['Süt', 'Ekmek']),
    );
    await service.showGeofenceEntry(geo);
    expect(
      bigTextOf(plugin.shownDetails[geo.geoNotificationId]),
      'Migros Kadıköy · 2 madde kaldı\n• Süt\n• Ekmek',
    );
  });
}
