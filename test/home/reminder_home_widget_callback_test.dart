import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/home/reminder_home_widget_callback.dart';
import 'package:reminder/home/widget_change_signal.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/factories.dart';
import '../helpers/fake_notifications_plugin.dart';
import '../helpers/mocks.dart';

/// Gerçek depo (mock SharedPreferences) + hatırlatıcı kayıt sayacı.
class _CountingRepository extends ReminderRepository {
  int reminderSaves = 0;

  @override
  Future<void> saveReminders(List<Reminder> reminders) {
    reminderSaves++;
    return super.saveReminders(reminders);
  }
}

Set<int> _birthdayIds(Birthday b) =>
    {for (final o in b.advanceOffsetsMinutes) b.notificationIdFor(o)};

void main() {
  late _CountingRepository repository;
  late FakeNotificationsPlugin plugin;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;
  late ScheduleSync schedules;

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final first = buildReminder(id: 'first', remindAt: tomorrow);
  final second = buildReminder(id: 'second', remindAt: tomorrow);
  final finished = buildReminder(id: 'finished', isDone: true);
  final birthday = buildBirthday(id: 'bday');

  setUpAll(() {
    registerModelFallbackValues();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = _CountingRepository();
    await repository.saveReminders([first, second, finished]);
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
    plugin
      ..cancelAllCalls = 0
      ..scheduleCalls = 0
      ..cancelCalls = 0;
  }

  Future<void> toggle(String id) => handleReminderHomeWidgetToggle(
        id,
        repository: repository,
        schedules: schedules,
      );

  List<String> widgetIds() =>
      (verify(() => homeWidget.sync(captureAny())).captured.single
              as List<Reminder>)
          .map((r) => r.id)
          .toList();

  group('reminderIdFromWidgetUri', () {
    test('reads the id of a toggle uri', () {
      expect(
        reminderIdFromWidgetUri(Uri.parse('reminderwidget://toggle?id=abc')),
        'abc',
      );
    });

    test('ignores other or incomplete uris', () {
      for (final uri in [
        null,
        Uri.parse('reminderwidget://toggle'),
        Uri.parse('reminderwidget://toggle?id='),
        Uri.parse('reminderwidget://open?id=abc'),
        Uri.parse('other://toggle?id=abc'),
      ]) {
        expect(reminderIdFromWidgetUri(uri), isNull, reason: '$uri');
      }
    });
  });

  group('handleReminderHomeWidgetToggle', () {
    test('completing a reminder keeps birthday notifications scheduled',
        () async {
      await syncLikeTheApp();
      expect(
        plugin.pending.keys.toSet(),
        containsAll(_birthdayIds(birthday)),
      );

      await toggle('first');

      final stored = await repository.loadReminders();
      expect(stored.firstWhere((r) => r.id == 'first').isDone, isTrue);
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
      expect(widgetIds(), ['first', 'second', 'finished']);
    });

    for (final id in ['missing', 'finished']) {
      test('"$id" changes nothing but refreshes the widget', () async {
        await syncLikeTheApp();
        final before = plugin.pending.keys.toSet();

        await toggle(id);

        expect(repository.reminderSaves, 0);
        expect(plugin.writeCalls, 0);
        expect(plugin.pending.keys.toSet(), before);
        verifyZeroInteractions(geofence);
        expect(widgetIds(), ['first', 'second', 'finished']);
      });
    }

    test('schedules nothing when notifications are disabled', () async {
      await repository
          .saveSettings(const AppSettings(notificationsEnabled: false));

      await toggle('first');

      final stored = await repository.loadReminders();
      expect(stored.firstWhere((r) => r.id == 'first').isDone, isTrue);
      expect(plugin.pending, isEmpty);
      expect(plugin.scheduleCalls, 0);
      verify(
        () => geofence.syncWithReminders(any(), notificationsEnabled: false),
      ).called(1);
      expect(widgetIds(), ['first', 'second', 'finished']);
    });
  });
  group('widget change signal (F1.3)', () {
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

    Future<void> drain() => Future<void>.delayed(
          const Duration(milliseconds: 50),
        );

    test('a saved change notifies the running app', () async {
      await toggle('first');
      await drain();
      expect(messages, hasLength(1));
    });

    test('no change sends no signal', () async {
      await toggle('finished');
      await drain();
      expect(messages, isEmpty);
    });

    test('without a running app the signal is dropped', () async {
      IsolateNameServer.removePortNameMapping(widgetChangePortName);
      await toggle('first');
      await drain();
      expect(messages, isEmpty);
      expect(
        (await repository.loadReminders())
            .firstWhere((r) => r.id == 'first')
            .isDone,
        isTrue,
      );
    });
  });
}
