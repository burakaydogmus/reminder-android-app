import 'package:reminder/services/permission_service.dart';

/// In-memory [PermissionService] for widget tests: returns [snapshot],
/// records calls and applies the configured request results.
class FakePermissionService implements PermissionService {
  FakePermissionService([this.snapshot = PermissionSnapshot.allGranted]);

  PermissionSnapshot snapshot;

  /// State after [requestNotifications] (default: granted).
  NotificationPermissionState notificationRequestResult =
      NotificationPermissionState.granted;

  /// State after [requestLocationWhenInUse] (default: while in use).
  LocationPermissionState whenInUseRequestResult =
      LocationPermissionState.whileInUse;

  /// State after [requestLocationAlways] (default: always).
  LocationPermissionState alwaysRequestResult = LocationPermissionState.always;

  final Set<PermissionPrompt> shownPrompts = {};
  final List<String> calls = [];

  @override
  Future<PermissionSnapshot> check() async => snapshot;

  @override
  Future<NotificationPermissionState> requestNotifications() async {
    calls.add('requestNotifications');
    snapshot = snapshot.copyWith(notifications: notificationRequestResult);
    return notificationRequestResult;
  }

  @override
  Future<void> openNotificationSettings() async {
    calls.add('openNotificationSettings');
  }

  @override
  Future<void> openExactAlarmSettings() async {
    calls.add('openExactAlarmSettings');
    final result = exactAlarmSettingsResult;
    if (result != null) snapshot = snapshot.copyWith(exactAlarms: result);
  }

  /// Exact-alarm state after returning from [openExactAlarmSettings]
  /// (default: unchanged).
  ExactAlarmState? exactAlarmSettingsResult;

  @override
  Future<LocationPermissionState> requestLocationWhenInUse() async {
    calls.add('requestLocationWhenInUse');
    snapshot = snapshot.copyWith(location: whenInUseRequestResult);
    return whenInUseRequestResult;
  }

  @override
  Future<LocationPermissionState> requestLocationAlways() async {
    calls.add('requestLocationAlways');
    snapshot = snapshot.copyWith(location: alwaysRequestResult);
    return alwaysRequestResult;
  }

  @override
  Future<void> openAppSettings() async {
    calls.add('openAppSettings');
  }

  @override
  Future<bool> shouldShowPrompt(PermissionPrompt prompt) async =>
      !shownPrompts.contains(prompt);

  @override
  Future<void> markPromptShown(PermissionPrompt prompt) async {
    shownPrompts.add(prompt);
  }
}
