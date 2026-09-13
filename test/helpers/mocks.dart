import 'package:mocktail/mocktail.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_service.dart';

import 'factories.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

/// `NotificationService`'in private constructor'ı olsa da `implements` ile
/// mock'lanabilir; mock gerçek plugin'e dokunmaz.
class MockNotificationService extends Mock implements NotificationService {}

/// `any()` eşleştiricileri için fallback değerleri. `setUpAll` içinde çağırın.
void registerModelFallbackValues() {
  registerFallbackValue(<Reminder>[]);
  registerFallbackValue(<Birthday>[]);
  registerFallbackValue(const AppSettings());
  registerFallbackValue(buildReminder());
  registerFallbackValue(buildBirthday());
}

/// Tüm yazma/senkron çağrılarını başarılı no-op olarak stub'lar.
void stubRepositoryWrites(MockReminderRepository repository) {
  when(() => repository.saveReminders(any())).thenAnswer((_) async {});
  when(() => repository.saveBirthdays(any())).thenAnswer((_) async {});
  when(() => repository.saveSettings(any())).thenAnswer((_) async {});
  when(() => repository.clearAll()).thenAnswer((_) async {});
}

void stubNotificationService(MockNotificationService notifications) {
  when(
    () => notifications.syncFromReminders(
      any(),
      notificationsEnabled: any(named: 'notificationsEnabled'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => notifications.scheduleBirthdays(
      any(),
      notificationsEnabled: any(named: 'notificationsEnabled'),
    ),
  ).thenAnswer((_) async {});
  when(() => notifications.cancelReminder(any())).thenAnswer((_) async {});
  when(() => notifications.cancelBirthday(any())).thenAnswer((_) async {});
  when(() => notifications.cancelAll()).thenAnswer((_) async {});
}
