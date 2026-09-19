import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/home/widget_change_signal.dart';
import 'package:reminder/services/notification_actions.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';
import '../helpers/mocks.dart';
import '../helpers/test_database.dart';

/// Gerçek depo (bellek içi Drift + mock SharedPreferences) + hatırlatıcı kayıt
/// sayacı.
class _CountingRepository extends ReminderRepository {
  _CountingRepository() : super(database: openTestDatabase());

  int reminderSaves = 0;

  @override
  Future<void> saveReminders(List<Reminder> reminders) {
    reminderSaves++;
    return super.saveReminders(reminders);
  }
}

NotificationResponse _action(String actionId, String? payload) =>
    NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: actionId,
      payload: payload,
    );

Set<int> _birthdayIds(Birthday b) =>
    {for (final o in b.advanceOffsetsMinutes) b.notificationIdFor(o)};

void main() {
  late _CountingRepository repository;
  late FakeNotificationsPlugin plugin;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;
  late ScheduleSync schedules;

  final realNow = DateTime.now();
  final tomorrow = realNow.add(const Duration(days: 1));
  final first = buildReminder(id: 'first', remindAt: tomorrow);
  final second = buildReminder(id: 'second', remindAt: tomorrow);
  final finished = buildReminder(id: 'finished', isDone: true);
  final untimed = buildReminder(id: 'untimed');
  final overdue = buildReminder(
    id: 'overdue',
    remindAt: realNow.subtract(const Duration(days: 2)),
  );
  final birthday = buildBirthday(id: 'bday');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerModelFallbackValues();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = _CountingRepository();
    await repository.saveReminders([first, second, finished, untimed, overdue]);
    await repository.saveBirthdays([birthday]);
    repository.reminderSaves = 0;

    plugin = FakeNotificationsPlugin();
    geofence = MockGeofenceSync();
    homeWidget = MockHomeWidgetSync();
    stubGeofenceSync(geofence);
    stubHomeWidgetSync(homeWidget);
    schedules = ScheduleSync(
      notifications: NotificationService.forTesting(plugin),
      geofence: geofence,
      homeWidget: homeWidget,
    );
  });

  /// Uygulamanın son açılışta kurduğu durum: tüm zamanlamalar mevcut.
  Future<void> syncLikeTheApp() async {
    await schedules.syncAll(
      reminders: await repository.loadReminders(),
      birthdays: await repository.loadBirthdays(),
      settings: await repository.loadSettings(),
    );
    clearInteractions(geofence);
    clearInteractions(homeWidget);
    plugin.resetCounters();
  }

  Future<bool> handle(
    String actionId, {
    String? payload = 'reminder:first',
    DateTime? now,
  }) =>
      handleNotificationAction(
        _action(actionId, payload),
        repository: repository,
        schedules: schedules,
        now: now ?? realNow,
      );

  Future<Reminder> stored(String id) async =>
      (await repository.loadReminders()).firstWhere((r) => r.id == id);

  group('snoozedRemindAt', () {
    final now = DateTime(2026, 9, 13, 14, 32, 45, 120);

    test('10 dk and 1 saat count from now, rounded to the minute', () {
      expect(
        snoozedRemindAt(NotificationActionIds.snooze10Minutes, now),
        DateTime(2026, 9, 13, 14, 42),
      );
      expect(
        snoozedRemindAt(NotificationActionIds.snooze1Hour, now),
        DateTime(2026, 9, 13, 15, 32),
      );
    });

    test('Yarın sabah is 09:00 on the next day', () {
      expect(
        snoozedRemindAt(NotificationActionIds.snoozeTomorrowMorning, now),
        DateTime(2026, 9, 14, 9),
      );
      // Just after midnight it is still the next calendar day.
      expect(
        snoozedRemindAt(
          NotificationActionIds.snoozeTomorrowMorning,
          DateTime(2026, 9, 14, 0, 5),
        ),
        DateTime(2026, 9, 15, 9),
      );
    });

    test('Yarın sabah crosses month and year ends', () {
      expect(
        snoozedRemindAt(
          NotificationActionIds.snoozeTomorrowMorning,
          DateTime(2026, 9, 30, 22, 15),
        ),
        DateTime(2026, 10, 1, 9),
      );
      expect(
        snoozedRemindAt(
          NotificationActionIds.snoozeTomorrowMorning,
          DateTime(2026, 12, 31, 23, 59),
        ),
        DateTime(2027, 1, 1, 9),
      );
      expect(
        snoozedRemindAt(
          NotificationActionIds.snooze1Hour,
          DateTime(2026, 10, 31, 23, 30),
        ),
        DateTime(2026, 11, 1, 0, 30),
      );
    });

    test('complete and unknown ids are not snoozes', () {
      expect(snoozedRemindAt(NotificationActionIds.complete, now), isNull);
      expect(snoozedRemindAt('other', now), isNull);
    });
  });

  group('handleNotificationAction', () {
    test('Tamamla completes the reminder and keeps birthdays scheduled',
        () async {
      await syncLikeTheApp();

      expect(await handle(NotificationActionIds.complete), isTrue);

      expect((await stored('first')).isDone, isTrue);
      expect(repository.reminderSaves, 1);
      expect(
        plugin.pending.keys.toSet(),
        {second.notificationId, ..._birthdayIds(birthday)},
      );
      final geo = verify(
        () => geofence.syncWithReminders(
          captureAny(),
          notificationsEnabled: true,
        ),
      ).captured.single as List<Reminder>;
      expect(geo.firstWhere((r) => r.id == 'first').isDone, isTrue);
      verify(() => anyHomeWidgetSync(homeWidget)).called(1);
    });

    test('Tamamla on a recurring reminder advances it (F3.1)', () async {
      final now = DateTime(2026, 9, 13, 12);
      final weekly = buildReminder(
        id: 'weekly',
        remindAt: DateTime(2026, 9, 12, 16),
        recurrence: RecurrenceRule.weekly([DateTime.saturday]),
      );
      await repository
          .saveReminders([first, second, finished, untimed, overdue, weekly]);
      repository.reminderSaves = 0;

      expect(
        await handle(
          NotificationActionIds.complete,
          payload: 'reminder:weekly',
          now: now,
        ),
        isTrue,
      );

      final r = await stored('weekly');
      expect(r.isDone, isFalse);
      expect(r.remindAt, completeReminder(weekly, now).remindAt);
      expect(r.remindAt, DateTime(2026, 9, 19, 16));
      expect(r.recurrence, weekly.recurrence);
      expect(repository.reminderSaves, 1);
    });

    for (final (actionId, expected) in [
      (NotificationActionIds.snooze10Minutes, DateTime(2026, 9, 30, 22, 25)),
      (NotificationActionIds.snooze1Hour, DateTime(2026, 9, 30, 23, 15)),
      (NotificationActionIds.snoozeTomorrowMorning, DateTime(2026, 10, 1, 9)),
    ]) {
      test('$actionId stores the snoozed time (fixed clock)', () async {
        final now = DateTime(2026, 9, 30, 22, 15, 30);

        expect(await handle(actionId, now: now), isTrue);

        final r = await stored('first');
        expect(r.remindAt, expected);
        expect(r.isDone, isFalse);
        expect(repository.reminderSaves, 1);
      });
    }

    test('a snooze reschedules the notification at the new time', () async {
      await syncLikeTheApp();

      await handle(NotificationActionIds.snooze1Hour);

      final expected =
          snoozedRemindAt(NotificationActionIds.snooze1Hour, realNow)!;
      expect(plugin.scheduledIds, [first.notificationId]);
      expect(
        plugin.pending[first.notificationId]!.scheduledDate,
        tz.TZDateTime.from(expected, tz.local),
      );
      expect(plugin.pending[first.notificationId]!.payload, 'reminder:first');
    });

    for (final r in [untimed, overdue]) {
      test('snoozing "${r.id}" gives it a future time', () async {
        await syncLikeTheApp();

        await handle(
          NotificationActionIds.snooze10Minutes,
          payload: ReminderPayload(r.id).encode(),
        );

        final expected =
            snoozedRemindAt(NotificationActionIds.snooze10Minutes, realNow)!;
        expect((await stored(r.id)).remindAt, expected);
        expect(plugin.pending.keys, contains(r.notificationId));
      });
    }

    test('a legacy geofence payload (raw id) is handled', () async {
      await handle(NotificationActionIds.complete, payload: 'first');

      expect((await stored('first')).isDone, isTrue);
    });

    for (final (label, actionId, payload) in [
      ('missing reminder', NotificationActionIds.complete, 'reminder:missing'),
      ('done reminder', NotificationActionIds.snooze1Hour, 'reminder:finished'),
      ('birthday payload', NotificationActionIds.complete, 'birthday:bday'),
      ('no payload', NotificationActionIds.complete, null),
      ('unknown action', 'reminder.delete', 'reminder:first'),
    ]) {
      test('$label is a no-op', () async {
        await syncLikeTheApp();
        final before = await repository.loadReminders();

        expect(await handle(actionId, payload: payload), isFalse);

        expect(repository.reminderSaves, 0);
        expect(plugin.writeCalls, 0);
        verifyZeroInteractions(geofence);
        verifyZeroInteractions(homeWidget);
        expect(
          (await repository.loadReminders()).map((r) => r.toJson()),
          before.map((r) => r.toJson()),
        );
      });
    }

    test('notifications disabled: saves the change, schedules nothing',
        () async {
      await repository
          .saveSettings(const AppSettings(notificationsEnabled: false));

      expect(await handle(NotificationActionIds.snooze10Minutes), isTrue);

      expect((await stored('first')).remindAt, isNot(first.remindAt));
      expect(plugin.pending, isEmpty);
      expect(plugin.scheduleCalls, 0);
      verify(
        () => geofence.syncWithReminders(any(), notificationsEnabled: false),
      ).called(1);
    });
  });

  group('app change signal (F1.3)', () {
    late ReceivePort port;
    late List<Object?> messages;
    late StreamSubscription<Object?> sub;

    setUp(() {
      port = ReceivePort();
      messages = [];
      sub = port.listen(messages.add);
      IsolateNameServer.removePortNameMapping(widgetChangePortName);
      IsolateNameServer.registerPortWithName(
        port.sendPort,
        widgetChangePortName,
      );
    });

    tearDown(() async {
      IsolateNameServer.removePortNameMapping(widgetChangePortName);
      await sub.cancel();
      port.close();
    });

    Future<void> drain() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test('a saved action notifies the running app', () async {
      await handle(NotificationActionIds.complete);
      await drain();
      expect(messages, hasLength(1));
    });

    test('a no-op sends no signal', () async {
      await handle(NotificationActionIds.complete, payload: 'reminder:nope');
      await drain();
      expect(messages, isEmpty);
    });
  });

  group('entry points', () {
    test('isReminderAction needs a known action and a reminder payload', () {
      expect(
        isReminderAction(_action(NotificationActionIds.complete, 'reminder:a')),
        isTrue,
      );
      expect(
        isReminderAction(_action(NotificationActionIds.complete, 'birthday:a')),
        isFalse,
      );
      expect(isReminderAction(_action('x', 'reminder:a')), isFalse);
    });

    test('background isolate builds the real services', () {
      expect(buildNotificationActionSchedules(), isA<ScheduleSync>());
    });

    test('background handler ignores non-actions without touching storage',
        () async {
      await notificationActionBackgroundHandler(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'reminder:first',
        ),
      );
      await notificationActionBackgroundHandler(
        _action(NotificationActionIds.complete, 'birthday:bday'),
      );

      expect((await stored('first')).isDone, isFalse);
    });

    test('foreground tap is routed, dismissal is ignored', () {
      final router = NotificationTapRouter.instance..take();

      onNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.notificationDismissed,
          payload: 'reminder:first',
        ),
      );
      expect(router.pending, isNull);

      onNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'reminder:first',
        ),
      );
      expect(router.take(), const ReminderPayload('first'));
    });
  });
}
