import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_tap_router.dart';

NotificationResponse _tap(String? payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

void main() {
  late NotificationTapRouter router;
  late int notifications;

  setUp(() {
    router = NotificationTapRouter();
    notifications = 0;
    router.addListener(() => notifications++);
  });

  test('a tap queues its target once', () {
    router.openResponse(_tap('reminder:r1'));

    expect(notifications, 1);
    expect(router.take(), const ReminderPayload('r1'));
    expect(router.take(), isNull);
  });

  test('actions, dismissals and empty payloads are not taps', () {
    router
      ..openResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'reminder.complete',
          payload: 'reminder:r1',
        ),
      )
      ..openResponse(_tap(null))
      ..openResponse(null);

    expect(router.pending, isNull);
    expect(notifications, 0);
  });

  group('openFromLaunch', () {
    test('queues the tap that launched the app', () async {
      await router.openFromLaunch(
        () async => NotificationAppLaunchDetails(
          true,
          notificationResponse: _tap('birthday:b1'),
        ),
      );

      expect(router.pending, const BirthdayPayload('b1'));
    });

    test('ignores a normal launch', () async {
      await router.openFromLaunch(
        () async => NotificationAppLaunchDetails(
          false,
          notificationResponse: _tap('reminder:r1'),
        ),
      );
      await router.openFromLaunch(() async => null);

      expect(router.pending, isNull);
    });
  });
}
