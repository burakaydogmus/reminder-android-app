import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/ios_widget_completions.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/services/schedule_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';
import '../helpers/test_database.dart';
import 'fake_home_widget_platform.dart';

final _now = DateTime(2026, 9, 13, 14, 32);

/// Bellek içi Drift deposu + kayıt sayacı.
class _CountingRepository extends ReminderRepository {
  _CountingRepository() : super(database: openTestDatabase());

  int reminderSaves = 0;

  @override
  Future<void> saveReminders(List<Reminder> reminders) {
    reminderSaves++;
    return super.saveReminders(reminders);
  }
}

String _queue(List<(String, DateTime)> entries) => jsonEncode([
      for (final (id, at) in entries)
        {'id': id, 'at': at.millisecondsSinceEpoch},
    ]);

void main() {
  group('parseWidgetCompletions', () {
    test('empty and unreadable payloads give an empty list', () {
      expect(parseWidgetCompletions(null), isEmpty);
      expect(parseWidgetCompletions(''), isEmpty);
      expect(parseWidgetCompletions('not json'), isEmpty);
      expect(parseWidgetCompletions('{"id": "a"}'), isEmpty,
          reason: 'the queue is a list');
      expect(parseWidgetCompletions('[]'), isEmpty);
    });

    test('skips items without a usable id or time', () {
      final parsed = parseWidgetCompletions(jsonEncode([
        'a',
        {'at': 1},
        {'id': '', 'at': 1},
        {'id': 'ok', 'at': 'yesterday'},
        {'id': 'good', 'at': 1789999200000},
      ]));

      expect(parsed, [
        WidgetCompletion('good', DateTime.fromMillisecondsSinceEpoch(1789999200000)),
      ]);
    });

    test('orders by completion time, keeping the queue order on ties', () {
      final parsed = parseWidgetCompletions(_queue([
        ('late', _now.add(const Duration(minutes: 5))),
        ('first', _now),
        ('same-a', _now.add(const Duration(minutes: 1))),
        ('same-b', _now.add(const Duration(minutes: 1))),
      ]));

      expect([for (final c in parsed) c.reminderId],
          ['first', 'same-a', 'same-b', 'late']);
    });
  });

  group('applyPendingWidgetCompletions', () {
    late _CountingRepository repository;
    late MockNotificationSync notifications;
    late MockGeofenceSync geofence;
    late MockHomeWidgetSync homeWidget;
    late ScheduleSync schedules;

    final open = buildReminder(
      id: 'open',
      remindAt: DateTime(2026, 9, 13, 16),
    );
    final done = buildReminder(id: 'done', isDone: true);
    final repeating = buildReminder(
      id: 'repeating',
      remindAt: DateTime(2026, 9, 13, 16),
      recurrence: RecurrenceRule.daily(),
    );

    setUpAll(registerModelFallbackValues);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = _CountingRepository();
      await repository.saveReminders([open, done, repeating]);
      repository.reminderSaves = 0;

      notifications = MockNotificationSync();
      geofence = MockGeofenceSync();
      homeWidget = MockHomeWidgetSync();
      when(
        () => notifications.syncSchedules(
          reminders: any(named: 'reminders'),
          birthdays: any(named: 'birthdays'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((_) async {});
      stubGeofenceSync(geofence);
      stubHomeWidgetSync(homeWidget);
      schedules = ScheduleSync(
        notifications: notifications,
        geofence: geofence,
        homeWidget: homeWidget,
      );
    });

    tearDown(() => repository.close());

    Future<int> apply(FakeHomeWidgetPlatform platform) =>
        applyPendingWidgetCompletions(
          repository: repository,
          schedules: schedules,
          now: () => _now,
          platform: platform,
        );

    test('does nothing off iOS, even with a queue', () async {
      final platform = FakeHomeWidgetPlatform(
        isAndroid: true,
        stored: {kWidgetCompletionsKey: _queue([('open', _now)])},
      );

      expect(await apply(platform), 0);
      expect(platform.calls, isEmpty);
      expect(repository.reminderSaves, 0);
      verifyNever(() => anyHomeWidgetSync(homeWidget));
    });

    test('an empty queue reads but never writes or syncs', () async {
      final platform = FakeHomeWidgetPlatform(isIOS: true);

      expect(await apply(platform), 0);
      expect(platform.calls, [
        'setAppGroupId:$kHomeWidgetAppGroupId',
        'read:$kWidgetCompletionsKey',
      ]);
      expect(repository.reminderSaves, 0);
      verifyNever(() => anyHomeWidgetSync(homeWidget));
    });

    test('completes the reminder, clears the queue and syncs everything',
        () async {
      final at = _now.subtract(const Duration(minutes: 3));
      final platform = FakeHomeWidgetPlatform(
        isIOS: true,
        stored: {kWidgetCompletionsKey: _queue([('open', at)])},
      );

      expect(await apply(platform), 1);

      final stored = await repository.loadReminders();
      expect(stored.firstWhere((r) => r.id == 'open').isDone, isTrue);
      expect(repository.reminderSaves, 1);
      // The queue is cleared *before* the sync, so the widget does not hide the
      // row twice.
      expect(platform.saved[kWidgetCompletionsKey], isNull);
      expect(
        platform.calls.indexOf('save:$kWidgetCompletionsKey') <
            platform.calls.length,
        isTrue,
      );
      verify(
        () => notifications.syncSchedules(
          reminders: any(named: 'reminders'),
          birthdays: any(named: 'birthdays'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
      verify(() => anyHomeWidgetSync(homeWidget)).called(1);
    });

    test('a recurring reminder advances instead of being marked done', () async {
      final platform = FakeHomeWidgetPlatform(
        isIOS: true,
        stored: {kWidgetCompletionsKey: _queue([('repeating', _now)])},
      );

      expect(await apply(platform), 1);

      final stored =
          (await repository.loadReminders()).firstWhere((r) => r.id == 'repeating');
      expect(stored.isDone, isFalse);
      expect(stored.remindAt, DateTime(2026, 9, 14, 16));
    });

    test('unknown, deleted and already done ids only refresh the widget',
        () async {
      final platform = FakeHomeWidgetPlatform(
        isIOS: true,
        stored: {
          kWidgetCompletionsKey: _queue([('done', _now), ('ghost', _now)]),
        },
      );

      expect(await apply(platform), 0);
      expect(repository.reminderSaves, 0,
          reason: 'nothing changed, so nothing is written');
      expect(platform.saved[kWidgetCompletionsKey], isNull,
          reason: 'unprocessable ids must not pile up in the queue');
      verifyNever(
        () => notifications.syncSchedules(
          reminders: any(named: 'reminders'),
          birthdays: any(named: 'birthdays'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
      verify(() => anyHomeWidgetSync(homeWidget)).called(1);
    });

    test('a timestamp in the future is clamped to now', () async {
      final platform = FakeHomeWidgetPlatform(
        isIOS: true,
        stored: {
          kWidgetCompletionsKey:
              _queue([('repeating', _now.add(const Duration(days: 30)))]),
        },
      );

      expect(await apply(platform), 1);

      final stored =
          (await repository.loadReminders()).firstWhere((r) => r.id == 'repeating');
      // Clamped: the next occurrence is tomorrow, not a month away.
      expect(stored.remindAt, DateTime(2026, 9, 14, 16));
    });

    test('applies several completions in queue order', () async {
      final platform = FakeHomeWidgetPlatform(
        isIOS: true,
        stored: {
          kWidgetCompletionsKey: _queue([
            ('open', _now.subtract(const Duration(minutes: 2))),
            ('repeating', _now.subtract(const Duration(minutes: 1))),
          ]),
        },
      );

      expect(await apply(platform), 2);

      final stored = await repository.loadReminders();
      expect(stored.firstWhere((r) => r.id == 'open').isDone, isTrue);
      expect(stored.firstWhere((r) => r.id == 'repeating').isDone, isFalse);
      expect(repository.reminderSaves, 1, reason: 'one transaction');
    });
  });
}
