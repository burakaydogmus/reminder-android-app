import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart'
    show PermissionStatus;
import 'package:reminder/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications implements NotificationPermissionBackend {
  bool enabled = false;
  bool grantOnRequest = true;
  bool? exact = true;
  final calls = <String>[];

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> request() async {
    calls.add('request');
    enabled = grantOnRequest;
    return enabled;
  }

  @override
  Future<bool?> canScheduleExact() async => exact;

  @override
  Future<void> openExactAlarmSettings() async => calls.add('exactSettings');

  @override
  Future<void> openSettings() async => calls.add('settings');
}

class _FakeLocation implements LocationPermissionBackend {
  PermissionStatus whenInUse = PermissionStatus.denied;
  PermissionStatus always = PermissionStatus.denied;
  PermissionStatus whenInUseResult = PermissionStatus.granted;
  PermissionStatus alwaysResult = PermissionStatus.granted;
  final calls = <String>[];

  @override
  Future<PermissionStatus> whenInUseStatus() async => whenInUse;

  @override
  Future<PermissionStatus> alwaysStatus() async => always;

  @override
  Future<PermissionStatus> requestWhenInUse() async {
    calls.add('requestWhenInUse');
    return whenInUse = whenInUseResult;
  }

  @override
  Future<PermissionStatus> requestAlways() async {
    calls.add('requestAlways');
    return always = alwaysResult;
  }

  @override
  Future<void> openAppSettings() async => calls.add('appSettings');
}

/// F8.1 calendar backend (`Permission.calendarFullAccess`).
class _FakeCalendar implements CalendarPermissionBackend {
  PermissionStatus current = PermissionStatus.denied;
  PermissionStatus result = PermissionStatus.granted;
  final calls = <String>[];

  @override
  Future<PermissionStatus> status() async => current;

  @override
  Future<PermissionStatus> request() async {
    calls.add('request');
    return current = result;
  }
}

void main() {
  group('decision logic', () {
    test('notification state: granted / not requested / denied', () {
      expect(
        resolveNotificationState(enabled: true, requested: true),
        NotificationPermissionState.granted,
      );
      expect(
        resolveNotificationState(enabled: false, requested: false),
        NotificationPermissionState.notRequested,
      );
      expect(
        resolveNotificationState(enabled: false, requested: true),
        NotificationPermissionState.denied,
      );
    });

    test('notification fix: request once, then settings', () {
      expect(
        notificationFix(NotificationPermissionState.granted),
        PermissionFix.none,
      );
      expect(
        notificationFix(NotificationPermissionState.notRequested),
        PermissionFix.request,
      );
      expect(
        notificationFix(NotificationPermissionState.denied),
        PermissionFix.openSettings,
      );
    });

    test('location state from permission_handler statuses', () {
      LocationPermissionState resolve(
        PermissionStatus whenInUse,
        PermissionStatus always, {
        bool requested = false,
      }) =>
          resolveLocationState(
            whenInUse: whenInUse,
            always: always,
            requested: requested,
          );

      expect(
        resolve(PermissionStatus.granted, PermissionStatus.granted),
        LocationPermissionState.always,
      );
      expect(
        resolve(PermissionStatus.granted, PermissionStatus.denied),
        LocationPermissionState.whileInUse,
      );
      expect(
        resolve(PermissionStatus.limited, PermissionStatus.denied),
        LocationPermissionState.whileInUse,
      );
      expect(
        resolve(PermissionStatus.denied, PermissionStatus.denied),
        LocationPermissionState.notRequested,
      );
      expect(
        resolve(
          PermissionStatus.denied,
          PermissionStatus.denied,
          requested: true,
        ),
        LocationPermissionState.denied,
      );
      expect(
        resolve(PermissionStatus.permanentlyDenied, PermissionStatus.denied),
        LocationPermissionState.denied,
      );
      expect(
        resolve(PermissionStatus.restricted, PermissionStatus.denied),
        LocationPermissionState.denied,
      );
    });

    test('location and exact alarm fixes', () {
      expect(locationFix(LocationPermissionState.always), PermissionFix.none);
      expect(
        locationFix(LocationPermissionState.whileInUse),
        PermissionFix.request,
      );
      expect(
        locationFix(LocationPermissionState.notRequested),
        PermissionFix.request,
      );
      expect(
        locationFix(LocationPermissionState.denied),
        PermissionFix.openSettings,
      );
      expect(exactAlarmFix(ExactAlarmState.granted), PermissionFix.none);
      expect(exactAlarmFix(ExactAlarmState.notRequired), PermissionFix.none);
      expect(
        exactAlarmFix(ExactAlarmState.denied),
        PermissionFix.openSettings,
      );
    });
  });

  group('PlatformPermissionService', () {
    late _FakeNotifications notifications;
    late _FakeLocation location;
    late _FakeCalendar calendar;
    late PermissionService service;

    PermissionService build() => PlatformPermissionService(
          notifications: notifications,
          location: location,
          calendar: calendar,
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifications = _FakeNotifications();
      location = _FakeLocation();
      calendar = _FakeCalendar();
      service = build();
    });

    test('check maps exact alarms (null means not required)', () async {
      expect((await service.check()).exactAlarms, ExactAlarmState.granted);
      notifications.exact = false;
      expect((await service.check()).exactAlarms, ExactAlarmState.denied);
      notifications.exact = null;
      expect(
        (await service.check()).exactAlarms,
        ExactAlarmState.notRequired,
      );
    });

    test('notifications: asks the system once, then opens settings', () async {
      notifications.grantOnRequest = false;
      expect(
        (await service.check()).notifications,
        NotificationPermissionState.notRequested,
      );

      expect(
        await service.requestNotifications(),
        NotificationPermissionState.denied,
      );
      expect(notifications.calls, ['request']);

      // "Requested" survives a restart (persisted).
      service = build();
      expect(
        (await service.check()).notifications,
        NotificationPermissionState.denied,
      );
      await service.requestNotifications();
      expect(notifications.calls, ['request', 'settings']);
    });

    test('notifications: granted does nothing', () async {
      notifications.enabled = true;
      expect(
        await service.requestNotifications(),
        NotificationPermissionState.granted,
      );
      expect(notifications.calls, isEmpty);
    });

    test('location: while in use, then always via the system once', () async {
      expect(
        await service.requestLocationWhenInUse(),
        LocationPermissionState.whileInUse,
      );
      location.alwaysResult = PermissionStatus.denied;
      expect(
        await service.requestLocationAlways(),
        LocationPermissionState.whileInUse,
      );
      // Second attempt goes to settings instead of re-asking.
      await service.requestLocationAlways();
      expect(
        location.calls,
        ['requestWhenInUse', 'requestAlways', 'appSettings'],
      );
    });

    test('location: always before foreground asks foreground first', () async {
      expect(
        await service.requestLocationAlways(),
        LocationPermissionState.whileInUse,
      );
      expect(location.calls, ['requestWhenInUse']);
    });

    test('location: denied goes to settings, never re-asks', () async {
      location.whenInUseResult = PermissionStatus.denied;
      expect(
        await service.requestLocationWhenInUse(),
        LocationPermissionState.denied,
      );
      expect(
        await service.requestLocationWhenInUse(),
        LocationPermissionState.denied,
      );
      await service.requestLocationAlways();
      expect(
        location.calls,
        ['requestWhenInUse', 'appSettings', 'appSettings'],
      );
    });

    test('prompts are shown once and remembered', () async {
      expect(
        await service.shouldShowPrompt(PermissionPrompt.locationAlways),
        isTrue,
      );
      await service.markPromptShown(PermissionPrompt.locationAlways);
      service = build();
      expect(
        await service.shouldShowPrompt(PermissionPrompt.locationAlways),
        isFalse,
      );
      expect(
        await service.shouldShowPrompt(PermissionPrompt.notifications),
        isTrue,
      );
    });
  });
}
