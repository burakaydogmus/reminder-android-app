import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/schedule_sync.dart';

import '../helpers/factories.dart';
import '../helpers/mocks.dart';

void main() {
  late MockNotificationSync notifications;
  late MockGeofenceSync geofence;
  late MockHomeWidgetSync homeWidget;
  late ScheduleSync schedules;

  final reminders = [buildReminder(id: 'a'), buildReminder(id: 'b')];
  final birthdays = [buildBirthday()];

  setUpAll(registerModelFallbackValues);

  setUp(() {
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

  for (final enabled in [true, false]) {
    test(
        'syncAll syncs notifications (with birthdays), geofences and the '
        'widget in order (notificationsEnabled: $enabled)', () async {
      await schedules.syncAll(
        reminders: reminders,
        birthdays: birthdays,
        settings: AppSettings(notificationsEnabled: enabled),
      );

      verifyInOrder([
        () => notifications.syncSchedules(
              reminders: reminders,
              birthdays: birthdays,
              notificationsEnabled: enabled,
            ),
        () => geofence.syncWithReminders(
              reminders,
              notificationsEnabled: enabled,
            ),
        () => homeWidget.sync(reminders),
      ]);
      verifyNoMoreInteractions(notifications);
      verifyNoMoreInteractions(geofence);
      verifyNoMoreInteractions(homeWidget);
    });
  }

  test('refreshHomeWidget only updates the widget', () async {
    await schedules.refreshHomeWidget(reminders);

    verify(() => homeWidget.sync(reminders)).called(1);
    verifyZeroInteractions(notifications);
    verifyZeroInteractions(geofence);
  });
}
