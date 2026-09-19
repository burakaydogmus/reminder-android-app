import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

/// Category management in [ReminderCubit] (F4.3).
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
    when(() => repository.loadBirthdays()).thenAnswer((_) async => []);
    when(() => repository.loadSettings())
        .thenAnswer((_) async => const AppSettings());
  });

  Future<ReminderCubit> loaded({
    List<Reminder> reminders = const [],
    List<ReminderCategory> categories = const [],
  }) async {
    when(() => repository.loadReminders())
        .thenAnswer((_) async => [...reminders]);
    when(() => repository.loadCategories())
        .thenAnswer((_) async => [...categories]);
    final cubit = ReminderCubit(
      repository,
      notifications,
      geofence: geofence,
      homeWidget: homeWidget,
    );
    await cubit.load();
    return cubit;
  }

  List<String> ids(ReminderCubit c) =>
      [for (final x in c.state.categories.ordered) x.id];

  List<ReminderCategory> lastSaved() =>
      verify(() => repository.saveCategories(captureAny())).captured.last
          as List<ReminderCategory>;

  test('initial state and load without stored categories: built-ins', () async {
    final cubit = await loaded();
    expect(ids(cubit), ReminderCategoryIds.orderedIds);
    expect(identical(cubit.state.categories, CategoryCatalog.builtIns), isTrue);
  });

  test('load keeps the same catalog object when nothing changed', () async {
    final cubit = await loaded(categories: [buildCategory(id: 'gym')]);
    final before = cubit.state.categories;
    await cubit.load();
    expect(identical(cubit.state.categories, before), isTrue);
    await cubit.addReminder(buildReminder());
    expect(identical(cubit.state.categories, before), isTrue);
  });

  test('saveCategory appends a new category and persists the list', () async {
    final cubit = await loaded();
    await cubit.saveCategory(buildCategory(id: 'gym', position: 0));
    expect(ids(cubit).last, 'gym');
    expect(cubit.state.categories.byId('gym')!.position, 6);
    expect(lastSaved().map((c) => c.id), ids(cubit));
  });

  test('saveCategory updates in place and ignores built-ins', () async {
    final cubit = await loaded(categories: [
      buildCategory(id: 'gym', position: 0),
      ReminderCategory.builtIn(ReminderCategoryIds.market)
          .copyWith(position: 1),
    ]);
    await cubit.saveCategory(buildCategory(id: 'gym', name: 'Yoga'));
    expect(cubit.state.categories.ordered.first.name, 'Yoga');
    expect(cubit.state.categories.ordered.first.position, 0);

    clearInteractions(repository);
    await cubit.saveCategory(ReminderCategory.builtIn(ReminderCategoryIds.work)
        .copyWith(name: 'Ofis'));
    expect(cubit.state.categories.labelOf(ReminderCategoryIds.work), 'İş');
    verifyNever(() => repository.saveCategories(any()));
  });

  test('reorderCategories and moveCategory', () async {
    final cubit = await loaded(categories: [buildCategory(id: 'gym')]);
    await cubit.reorderCategories(['gym', ReminderCategoryIds.other]);
    expect(ids(cubit).take(2), ['gym', ReminderCategoryIds.other]);
    expect(ids(cubit).length, 7);
    expect(lastSaved().map((c) => c.position), List.generate(7, (i) => i));

    await cubit.moveCategory(0, 6);
    expect(ids(cubit).last, 'gym');
    expect(ids(cubit).first, ReminderCategoryIds.other);
  });

  test('deleteCategory moves its reminders to Diğer and syncs', () async {
    final cubit = await loaded(
      reminders: [
        buildReminder(id: 'a', categoryId: 'gym'),
        buildReminder(id: 'b', categoryId: 'gym', isDone: true),
        buildReminder(id: 'c', categoryId: ReminderCategoryIds.work),
      ],
      categories: [buildCategory(id: 'gym')],
    );
    clearInteractions(repository);

    final moved = await cubit.deleteCategory('gym');

    expect(moved, 2);
    expect(cubit.state.categories.contains('gym'), isFalse);
    expect({
      for (final r in cubit.state.reminders) r.id: r.categoryId
    }, {
      'a': ReminderCategoryIds.other,
      'b': ReminderCategoryIds.other,
      'c': ReminderCategoryIds.work,
    });
    expect(lastSaved().map((c) => c.id), isNot(contains('gym')));
    final saved = verify(() => repository.saveReminders(captureAny()))
        .captured
        .single as List<Reminder>;
    expect(saved.where((r) => r.categoryId == 'gym'), isEmpty);
  });

  test('deleteCategory refuses built-ins and unknown ids', () async {
    final cubit = await loaded(
      reminders: [buildReminder(categoryId: ReminderCategoryIds.work)],
    );
    clearInteractions(repository);
    expect(await cubit.deleteCategory(ReminderCategoryIds.work), 0);
    expect(await cubit.deleteCategory('nope'), 0);
    verifyNever(() => repository.saveCategories(any()));
    verifyNever(() => repository.saveReminders(any()));
    expect(cubit.state.reminders.single.categoryId, ReminderCategoryIds.work);
  });

  test('deleting an empty category does not resync schedules', () async {
    final cubit = await loaded(categories: [buildCategory(id: 'gym')]);
    clearInteractions(repository);
    clearInteractions(geofence);
    expect(await cubit.deleteCategory('gym'), 0);
    verify(() => repository.saveCategories(any())).called(1);
    verifyNever(() => repository.saveReminders(any()));
    verifyNoMoreInteractions(geofence);
  });

  test('clearAllData resets categories to built-ins', () async {
    final cubit = await loaded(categories: [buildCategory(id: 'gym')]);
    await cubit.clearAllData();
    expect(ids(cubit), ReminderCategoryIds.orderedIds);
  });
}
