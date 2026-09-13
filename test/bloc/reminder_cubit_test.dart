import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

ReminderState _state({
  List<Reminder> reminders = const [],
  List<Birthday> birthdays = const [],
  AppSettings settings = const AppSettings(),
}) =>
    ReminderState(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
    );

Matcher _hasReminderIds(List<String> ids) => isA<ReminderState>()
    .having((s) => s.reminders.map((r) => r.id).toList(), 'reminder ids', ids);

void main() {
  late MockReminderRepository repository;
  late MockNotificationService notifications;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;

  setUpAll(registerModelFallbackValues);

  setUp(() {
    repository = MockReminderRepository();
    notifications = MockNotificationService();
    geofence = MockGeofenceSync();
    homeWidget = MockHomeWidgetSync();
    stubRepositoryWrites(repository);
    stubNotificationService(notifications);
    stubGeofenceSync(geofence);
    stubHomeWidgetSync(homeWidget);
  });

  ReminderCubit buildCubit() => ReminderCubit(
        repository,
        notifications,
        geofence: geofence,
        homeWidget: homeWidget,
      );

  /// Geofence ve home widget senkronunun tam bir kez, verilen hatırlatıcı
  /// id'leri (sırasıyla) ve bildirim bayrağıyla çağrıldığını doğrular.
  /// Geofence'e giden listeyi döndürür.
  List<Reminder> verifyServicesSynced(
    List<String> reminderIds, {
    required bool notificationsEnabled,
  }) {
    final geo = verify(
      () => geofence.syncWithReminders(
        captureAny(),
        notificationsEnabled: notificationsEnabled,
      ),
    ).captured.single as List<Reminder>;
    expect(geo.map((r) => r.id), reminderIds, reason: 'geofence sync');
    verifyNoMoreInteractions(geofence);

    final widget = verify(() => homeWidget.sync(captureAny())).captured.single
        as List<Reminder>;
    expect(widget.map((r) => r.id), reminderIds, reason: 'home widget sync');
    verifyNoMoreInteractions(homeWidget);
    return geo;
  }

  test('initial state is empty with default settings', () {
    final cubit = buildCubit();
    expect(cubit.state.reminders, isEmpty);
    expect(cubit.state.birthdays, isEmpty);
    expect(cubit.state.settings.notificationsEnabled, isTrue);
    cubit.close();
  });

  group('ReminderState', () {
    test('active/completed split by isDone', () {
      final s = _state(reminders: [
        buildReminder(id: 'a'),
        buildReminder(id: 'b', isDone: true),
        buildReminder(id: 'c'),
      ]);

      expect(s.active.map((r) => r.id), ['a', 'c']);
      expect(s.completed.map((r) => r.id), ['b']);
    });
  });

  group('load', () {
    final doneOld = buildReminder(
      id: 'done',
      isDone: true,
      remindAt: DateTime(2020, 1, 1),
    );
    final timedLate =
        buildReminder(id: 'timed-late', remindAt: DateTime(2026, 9, 1));
    final timedEarly =
        buildReminder(id: 'timed-early', remindAt: DateTime(2026, 1, 1));
    final untimedOld =
        buildReminder(id: 'untimed-old', createdAt: DateTime(2025, 1, 1));
    final untimedNew =
        buildReminder(id: 'untimed-new', createdAt: DateTime(2026, 1, 1));
    final birthday = buildBirthday();
    const settings = AppSettings(notificationsEnabled: false);
    const sortedIds = [
      'timed-early',
      'timed-late',
      'untimed-new',
      'untimed-old',
      'done',
    ];

    setUp(() {
      when(() => repository.loadReminders()).thenAnswer(
        (_) async => [doneOld, untimedOld, timedLate, untimedNew, timedEarly],
      );
      when(() => repository.loadBirthdays())
          .thenAnswer((_) async => [birthday]);
      when(() => repository.loadSettings()).thenAnswer((_) async => settings);
    });

    blocTest<ReminderCubit, ReminderState>(
      'emits sorted reminders: active before done, timed by date, '
      'untimed by createdAt desc',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ReminderState>()
            .having(
          (s) => s.reminders.map((r) => r.id).toList(),
          'reminder ids',
          sortedIds,
        )
            .having((s) => s.birthdays, 'birthdays', [birthday]).having(
          (s) => s.settings.notificationsEnabled,
          'notificationsEnabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(
          () => notifications.syncSchedules(
            reminders: any(named: 'reminders', that: hasLength(5)),
            birthdays: [birthday],
            notificationsEnabled: false,
          ),
        ).called(1);
        verifyServicesSynced(sortedIds, notificationsEnabled: false);
        verifyNever(() => repository.saveReminders(any()));
      },
    );
  });

  group('reminder mutations', () {
    final a = buildReminder(id: 'a', title: 'A');
    final b = buildReminder(id: 'b', title: 'B');

    void verifyPersistedAll() {
      verify(() => repository.saveReminders(any())).called(1);
      verify(() => repository.saveBirthdays(any())).called(1);
      verify(() => repository.saveSettings(any())).called(1);
      verify(
        () => notifications.syncSchedules(
          reminders: any(named: 'reminders'),
          birthdays: any(named: 'birthdays'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
    }

    blocTest<ReminderCubit, ReminderState>(
      'addReminder appends, saves and syncs services',
      build: buildCubit,
      seed: () => _state(reminders: [a]),
      act: (cubit) => cubit.addReminder(b),
      expect: () => [
        _hasReminderIds(['a', 'b'])
      ],
      verify: (_) {
        final saved = verify(() => repository.saveReminders(captureAny()))
            .captured
            .single as List<Reminder>;
        expect(saved.map((r) => r.id), ['a', 'b']);
        verify(() => repository.saveBirthdays(any())).called(1);
        verify(() => repository.saveSettings(any())).called(1);
        verifyServicesSynced(['a', 'b'], notificationsEnabled: true);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'updateReminder replaces the matching reminder in place',
      build: buildCubit,
      seed: () => _state(reminders: [a, b]),
      act: (cubit) => cubit.updateReminder(buildReminder(id: 'a', title: 'A2')),
      expect: () => [
        isA<ReminderState>().having(
          (s) => s.reminders.map((r) => r.title).toList(),
          'titles',
          ['A2', 'B'],
        ),
      ],
      verify: (_) {
        verifyPersistedAll();
        final synced =
            verifyServicesSynced(['a', 'b'], notificationsEnabled: true);
        expect(synced.first.title, 'A2');
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'deleteReminder removes, cancels its notification and saves',
      build: buildCubit,
      seed: () => _state(reminders: [a, b]),
      act: (cubit) => cubit.deleteReminder('a'),
      expect: () => [
        _hasReminderIds(['b'])
      ],
      verify: (_) {
        verify(() => notifications.cancelReminder(a)).called(1);
        verifyPersistedAll();
        verifyServicesSynced(['b'], notificationsEnabled: true);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'deleteReminder with unknown id does not cancel anything',
      build: buildCubit,
      seed: () => _state(reminders: [a]),
      act: (cubit) => cubit.deleteReminder('missing'),
      expect: () => [
        _hasReminderIds(['a'])
      ],
      verify: (_) {
        verifyNever(() => notifications.cancelReminder(any()));
        verify(() => repository.saveReminders(any())).called(1);
        verifyServicesSynced(['a'], notificationsEnabled: true);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'toggleDone flips isDone and keeps every other field',
      build: buildCubit,
      seed: () => _state(reminders: [
        buildReminder(
          id: 'full',
          title: 'Tam',
          note: 'not',
          createdAt: DateTime(2026, 2, 1),
          remindAt: DateTime(2026, 2, 2, 8),
          categoryId: 'other',
          customCategoryLabel: 'Hobi',
          locationTriggerEnabled: true,
          locationLatitude: 41,
          locationLongitude: 29,
          locationRadiusMeters: 250,
          locationPlaceLabel: 'Yer',
        ),
        b,
      ]),
      act: (cubit) => cubit.toggleDone('full'),
      expect: () => [
        isA<ReminderState>().having((s) => s.reminders, 'reminders', [
          isA<Reminder>()
              .having((r) => r.id, 'id', 'b')
              .having((r) => r.isDone, 'isDone', isFalse),
          isA<Reminder>()
              .having((r) => r.isDone, 'isDone', isTrue)
              .having((r) => r.title, 'title', 'Tam')
              .having((r) => r.note, 'note', 'not')
              .having((r) => r.createdAt, 'createdAt', DateTime(2026, 2, 1))
              .having((r) => r.remindAt, 'remindAt', DateTime(2026, 2, 2, 8))
              .having((r) => r.customCategoryLabel, 'label', 'Hobi')
              .having((r) => r.locationTriggerEnabled, 'geo', isTrue)
              .having((r) => r.locationLatitude, 'lat', 41)
              .having((r) => r.locationLongitude, 'lng', 29)
              .having((r) => r.locationRadiusMeters, 'radius', 250)
              .having((r) => r.locationPlaceLabel, 'place', 'Yer'),
        ]),
      ],
      verify: (_) {
        verifyPersistedAll();
        final synced =
            verifyServicesSynced(['b', 'full'], notificationsEnabled: true);
        expect(synced.last.isDone, isTrue);
      },
    );

    group('keeps compareReminders order (F1.8)', () {
      final early = buildReminder(id: 'early', remindAt: DateTime(2026, 3, 1));
      final late = buildReminder(id: 'late', remindAt: DateTime(2026, 9, 1));
      final untimed = buildReminder(id: 'untimed');
      final done = buildReminder(
        id: 'done',
        isDone: true,
        remindAt: DateTime(2026, 1, 1),
      );

      blocTest<ReminderCubit, ReminderState>(
        'addReminder inserts a timed reminder at its date position',
        build: buildCubit,
        seed: () => _state(reminders: [early, late, untimed, done]),
        act: (cubit) => cubit.addReminder(
          buildReminder(id: 'mid', remindAt: DateTime(2026, 6, 1)),
        ),
        expect: () => [
          _hasReminderIds(['early', 'mid', 'late', 'untimed', 'done']),
        ],
        verify: (_) {
          final saved = verify(() => repository.saveReminders(captureAny()))
              .captured
              .single as List<Reminder>;
          expect(
            saved.map((r) => r.id),
            ['early', 'mid', 'late', 'untimed', 'done'],
          );
          verifyServicesSynced(
            ['early', 'mid', 'late', 'untimed', 'done'],
            notificationsEnabled: true,
          );
        },
      );

      blocTest<ReminderCubit, ReminderState>(
        'addReminder puts a newer untimed reminder before older untimed ones',
        build: buildCubit,
        seed: () => _state(reminders: [early, untimed, done]),
        act: (cubit) => cubit.addReminder(
          buildReminder(id: 'newest', createdAt: DateTime(2026, 5, 1)),
        ),
        expect: () => [
          _hasReminderIds(['early', 'newest', 'untimed', 'done']),
        ],
      );

      blocTest<ReminderCubit, ReminderState>(
        'updateReminder moves a reminder whose date changed',
        build: buildCubit,
        seed: () => _state(reminders: [early, late, untimed]),
        act: (cubit) =>
            cubit.updateReminder(early.copyWith(remindAt: () => null)),
        expect: () => [
          _hasReminderIds(['late', 'untimed', 'early']),
        ],
      );

      blocTest<ReminderCubit, ReminderState>(
        'toggleDone moves a completed reminder after active ones and back',
        build: buildCubit,
        seed: () => _state(reminders: [early, late, untimed, done]),
        act: (cubit) async {
          await cubit.toggleDone('early');
          await cubit.toggleDone('done');
        },
        expect: () => [
          _hasReminderIds(['late', 'untimed', 'done', 'early']),
          _hasReminderIds(['done', 'late', 'untimed', 'early']),
        ],
      );

      blocTest<ReminderCubit, ReminderState>(
        'deleteReminder keeps the remaining order',
        build: buildCubit,
        seed: () => _state(reminders: [early, late, untimed, done]),
        act: (cubit) => cubit.deleteReminder('late'),
        expect: () => [
          _hasReminderIds(['early', 'untimed', 'done']),
        ],
      );
    });

    final birthday = buildBirthday();

    blocTest<ReminderCubit, ReminderState>(
      'toggleDone resyncs birthdays together with reminders (F1.2)',
      build: buildCubit,
      seed: () => _state(reminders: [a], birthdays: [birthday]),
      act: (cubit) => cubit.toggleDone('a'),
      verify: (_) {
        verify(
          () => notifications.syncSchedules(
            reminders: any(named: 'reminders'),
            birthdays: [birthday],
            notificationsEnabled: true,
          ),
        ).called(1);
        verifyNever(() => notifications.cancelAll());
      },
    );
  });

  group('birthday mutations', () {
    final x = buildBirthday(id: 'x', name: 'X');
    final y = buildBirthday(id: 'y', name: 'Y');

    blocTest<ReminderCubit, ReminderState>(
      'addBirthday appends and saves',
      build: buildCubit,
      seed: () => _state(birthdays: [x]),
      act: (cubit) => cubit.addBirthday(y),
      expect: () => [
        isA<ReminderState>().having((s) => s.birthdays, 'birthdays', [x, y]),
      ],
      verify: (_) {
        verify(() => repository.saveBirthdays([x, y])).called(1);
        verify(
          () => notifications.syncSchedules(
            reminders: [],
            birthdays: [x, y],
            notificationsEnabled: true,
          ),
        ).called(1);
        verifyServicesSynced([], notificationsEnabled: true);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'updateBirthday replaces the matching birthday',
      build: buildCubit,
      seed: () => _state(birthdays: [x, y]),
      act: (cubit) => cubit.updateBirthday(x.copyWith(name: 'X2')),
      expect: () => [
        isA<ReminderState>().having(
          (s) => s.birthdays.map((b) => b.name).toList(),
          'names',
          ['X2', 'Y'],
        ),
      ],
      verify: (_) {
        verify(() => repository.saveBirthdays(any())).called(1);
        verifyServicesSynced([], notificationsEnabled: true);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'deleteBirthday removes and cancels its notifications',
      build: buildCubit,
      seed: () => _state(birthdays: [x, y]),
      act: (cubit) => cubit.deleteBirthday('x'),
      expect: () => [
        isA<ReminderState>().having((s) => s.birthdays, 'birthdays', [y]),
      ],
      verify: (_) {
        verify(() => notifications.cancelBirthday(x)).called(1);
        verify(() => repository.saveBirthdays([y])).called(1);
        verifyServicesSynced([], notificationsEnabled: true);
      },
    );
  });

  group('settings', () {
    blocTest<ReminderCubit, ReminderState>(
      'setThemeMode emits new theme and only saves settings',
      build: buildCubit,
      act: (cubit) => cubit.setThemeMode(AppThemeModeIds.dark),
      expect: () => [
        isA<ReminderState>().having(
          (s) => s.settings.themeMode,
          'themeMode',
          AppThemeModeIds.dark,
        ),
      ],
      verify: (_) {
        final saved = verify(() => repository.saveSettings(captureAny()))
            .captured
            .single as AppSettings;
        expect(saved.themeMode, AppThemeModeIds.dark);
        verifyNever(() => repository.saveReminders(any()));
        verifyNever(() => repository.saveBirthdays(any()));
        verifyZeroInteractions(notifications);
        verifyZeroInteractions(geofence);
        verifyZeroInteractions(homeWidget);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'setThemeMode with the current value does nothing',
      build: buildCubit,
      act: (cubit) => cubit.setThemeMode(AppThemeModeIds.system),
      expect: () => <ReminderState>[],
      verify: (_) {
        verifyZeroInteractions(repository);
        verifyZeroInteractions(notifications);
        verifyZeroInteractions(geofence);
        verifyZeroInteractions(homeWidget);
      },
    );

    blocTest<ReminderCubit, ReminderState>(
      'setNotificationsEnabled emits, saves and resyncs with the new flag',
      build: buildCubit,
      seed: () => _state(reminders: [buildReminder()]),
      act: (cubit) => cubit.setNotificationsEnabled(false),
      expect: () => [
        isA<ReminderState>().having(
          (s) => s.settings.notificationsEnabled,
          'notificationsEnabled',
          isFalse,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveSettings(any())).called(1);
        verify(
          () => notifications.syncSchedules(
            reminders: any(named: 'reminders'),
            birthdays: any(named: 'birthdays'),
            notificationsEnabled: false,
          ),
        ).called(1);
        verifyServicesSynced(['r1'], notificationsEnabled: false);
      },
    );
  });

  group('clearAllData', () {
    blocTest<ReminderCubit, ReminderState>(
      'cancels notifications, clears geofences and storage, resets state '
      'and empties the home widget',
      build: buildCubit,
      seed: () => _state(
        reminders: [buildReminder()],
        birthdays: [buildBirthday()],
        settings: const AppSettings(
          notificationsEnabled: false,
          themeMode: AppThemeModeIds.dark,
        ),
      ),
      act: (cubit) => cubit.clearAllData(),
      expect: () => [
        isA<ReminderState>()
            .having((s) => s.reminders, 'reminders', isEmpty)
            .having((s) => s.birthdays, 'birthdays', isEmpty)
            .having(
              (s) => s.settings.themeMode,
              'themeMode',
              AppThemeModeIds.system,
            )
            .having(
              (s) => s.settings.notificationsEnabled,
              'notificationsEnabled',
              isTrue,
            ),
      ],
      verify: (_) {
        verifyInOrder([
          () => notifications.cancelAll(),
          () => geofence.syncWithReminders([], notificationsEnabled: false),
          () => repository.clearAll(),
          () => homeWidget.sync([]),
        ]);
        verifyNoMoreInteractions(geofence);
        verifyNoMoreInteractions(homeWidget);
        verifyNever(() => repository.saveReminders(any()));
        verifyNever(
          () => notifications.syncSchedules(
            reminders: any(named: 'reminders'),
            birthdays: any(named: 'birthdays'),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        );
      },
    );
  });
}
