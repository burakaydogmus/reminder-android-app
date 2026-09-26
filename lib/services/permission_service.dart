import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

/// Notification permission as the app sees it.
enum NotificationPermissionState {
  granted,

  /// The system prompt has not been shown by this app yet.
  notRequested,

  /// Asked before and not granted: only system settings can fix it.
  denied,
}

/// Exact alarms (Android 12+ `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`).
enum ExactAlarmState { granted, denied, notRequired }

/// Location permission level for geofence reminders.
enum LocationPermissionState {
  /// Background ("Her zaman") access: geofences fire while the app is closed.
  always,

  /// Foreground only: the map works, background reminders do not.
  whileInUse,
  notRequested,

  /// Asked before (or blocked by the OS) and not granted.
  denied,
}

/// Calendar read access for device calendar events (F8.1).
///
/// The app only ever **reads**; there is no write state, because neither
/// platform has a read-only tier: Android needs `READ_CALENDAR` and iOS 17+
/// needs EventKit's *full* access (`requestFullAccessToEvents`).
enum CalendarPermissionState {
  granted,

  /// The system prompt has not been shown by this app yet.
  notRequested,

  /// Asked before (or blocked by the OS) and not granted.
  denied,
}

/// What a "fix" control should do for a permission state.
enum PermissionFix { none, request, openSettings }

/// One-time contextual explanation sheets (shown at most once each).
enum PermissionPrompt {
  notifications,
  exactAlarms,
  locationWhenInUse,
  locationAlways,
  calendar,
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.notifications,
    required this.exactAlarms,
    required this.location,
    this.calendar = CalendarPermissionState.notRequested,
  });

  final NotificationPermissionState notifications;
  final ExactAlarmState exactAlarms;
  final LocationPermissionState location;

  /// Device calendar read access (F8.1). Off by default: nothing asks for it
  /// until the user turns "Takvim etkinlikleri" on.
  final CalendarPermissionState calendar;

  static const allGranted = PermissionSnapshot(
    notifications: NotificationPermissionState.granted,
    exactAlarms: ExactAlarmState.granted,
    location: LocationPermissionState.always,
    calendar: CalendarPermissionState.granted,
  );

  PermissionSnapshot copyWith({
    NotificationPermissionState? notifications,
    ExactAlarmState? exactAlarms,
    LocationPermissionState? location,
    CalendarPermissionState? calendar,
  }) {
    return PermissionSnapshot(
      notifications: notifications ?? this.notifications,
      exactAlarms: exactAlarms ?? this.exactAlarms,
      location: location ?? this.location,
      calendar: calendar ?? this.calendar,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PermissionSnapshot &&
      other.notifications == notifications &&
      other.exactAlarms == exactAlarms &&
      other.location == location &&
      other.calendar == calendar;

  @override
  int get hashCode =>
      Object.hash(notifications, exactAlarms, location, calendar);

  @override
  String toString() => 'PermissionSnapshot($notifications, $exactAlarms, '
      '$location, $calendar)';
}

/// Fix action for the notification permission.
PermissionFix notificationFix(NotificationPermissionState state) {
  switch (state) {
    case NotificationPermissionState.granted:
      return PermissionFix.none;
    case NotificationPermissionState.notRequested:
      return PermissionFix.request;
    case NotificationPermissionState.denied:
      return PermissionFix.openSettings;
  }
}

/// Fix action for exact alarms (only settings can grant them).
PermissionFix exactAlarmFix(ExactAlarmState state) =>
    state == ExactAlarmState.denied
        ? PermissionFix.openSettings
        : PermissionFix.none;

/// Fix action for location. `whileInUse` asks for the background upgrade
/// (the service falls back to settings once that was requested).
PermissionFix locationFix(LocationPermissionState state) {
  switch (state) {
    case LocationPermissionState.always:
      return PermissionFix.none;
    case LocationPermissionState.whileInUse:
    case LocationPermissionState.notRequested:
      return PermissionFix.request;
    case LocationPermissionState.denied:
      return PermissionFix.openSettings;
  }
}

/// Fix action for calendar read access (F8.1).
PermissionFix calendarFix(CalendarPermissionState state) {
  switch (state) {
    case CalendarPermissionState.granted:
      return PermissionFix.none;
    case CalendarPermissionState.notRequested:
      return PermissionFix.request;
    case CalendarPermissionState.denied:
      return PermissionFix.openSettings;
  }
}

/// Maps the OS notification state plus the persisted "requested" flag.
NotificationPermissionState resolveNotificationState({
  required bool enabled,
  required bool requested,
}) {
  if (enabled) return NotificationPermissionState.granted;
  return requested
      ? NotificationPermissionState.denied
      : NotificationPermissionState.notRequested;
}

/// Maps permission_handler statuses plus the persisted "requested" flag.
LocationPermissionState resolveLocationState({
  required ph.PermissionStatus whenInUse,
  required ph.PermissionStatus always,
  required bool requested,
}) {
  if (always.isGranted) return LocationPermissionState.always;
  if (whenInUse.isGranted || whenInUse.isLimited) {
    return LocationPermissionState.whileInUse;
  }
  if (whenInUse.isPermanentlyDenied || whenInUse.isRestricted || requested) {
    return LocationPermissionState.denied;
  }
  return LocationPermissionState.notRequested;
}

/// Maps the permission_handler calendar status plus the persisted "requested"
/// flag (F8.1).
///
/// iOS reports EventKit's `notDetermined` as plain `denied`
/// (`EventPermissionStrategy`), so — exactly like location — only the stored
/// flag tells "never asked" from "asked and refused" apart.
CalendarPermissionState resolveCalendarState({
  required ph.PermissionStatus status,
  required bool requested,
}) {
  if (status.isGranted || status.isLimited) return CalendarPermissionState.granted;
  if (status.isPermanentlyDenied || status.isRestricted || requested) {
    return CalendarPermissionState.denied;
  }
  return CalendarPermissionState.notRequested;
}

/// Permission checks and requests used by the UI. Injected through
/// `PermissionScope` so widgets can be tested with a fake.
abstract class PermissionService {
  Future<PermissionSnapshot> check();

  /// Shows the system notification prompt (or does nothing if already asked
  /// on platforms that only ask once) and returns the new state.
  Future<NotificationPermissionState> requestNotifications();

  Future<void> openNotificationSettings();

  /// Opens the Android "Alarms & reminders" screen for this app.
  Future<void> openExactAlarmSettings();

  Future<LocationPermissionState> requestLocationWhenInUse();

  /// Asks for background location: the system flow the first time (Android
  /// 11+ opens the app's location page, iOS shows the upgrade prompt), app
  /// settings afterwards.
  Future<LocationPermissionState> requestLocationAlways();

  /// Asks for device calendar **read** access (F8.1): the system prompt the
  /// first time, app settings afterwards.
  Future<CalendarPermissionState> requestCalendar();

  Future<void> openAppSettings();

  /// Whether the one-time explanation sheet [prompt] may still be shown.
  Future<bool> shouldShowPrompt(PermissionPrompt prompt);

  Future<void> markPromptShown(PermissionPrompt prompt);
}

/// Platform notification permission calls (flutter_local_notifications).
abstract class NotificationPermissionBackend {
  Future<bool> areEnabled();
  Future<bool> request();

  /// `null` where exact alarms do not exist (iOS).
  Future<bool?> canScheduleExact();
  Future<void> openExactAlarmSettings();
  Future<void> openSettings();
}

/// Platform location permission calls (permission_handler).
abstract class LocationPermissionBackend {
  Future<ph.PermissionStatus> whenInUseStatus();
  Future<ph.PermissionStatus> alwaysStatus();
  Future<ph.PermissionStatus> requestWhenInUse();
  Future<ph.PermissionStatus> requestAlways();
  Future<void> openAppSettings();
}

/// Platform calendar permission calls (permission_handler, F8.1).
abstract class CalendarPermissionBackend {
  Future<ph.PermissionStatus> status();
  Future<ph.PermissionStatus> request();
}

/// `Permission.calendarFullAccess` — the only tier that can **read** events:
/// Android `READ_CALENDAR` (+ `WRITE_CALENDAR` when declared; this app
/// declares only read, and permission_handler asks for declared permissions
/// only, see `PermissionUtils.getManifestNames`) and, on iOS 17+,
/// `EKEventStore.requestFullAccessToEvents` — EventKit's write-only tier
/// cannot read. Needs `PERMISSION_EVENTS=1` and
/// `PERMISSION_EVENTS_FULL_ACCESS=1` in the Podfile.
class PermissionHandlerCalendarBackend implements CalendarPermissionBackend {
  const PermissionHandlerCalendarBackend();

  @override
  Future<ph.PermissionStatus> status() =>
      ph.Permission.calendarFullAccess.status;

  @override
  Future<ph.PermissionStatus> request() =>
      ph.Permission.calendarFullAccess.request();
}

class LocalNotificationsPermissionBackend
    implements NotificationPermissionBackend {
  LocalNotificationsPermissionBackend(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> areEnabled() async {
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> request() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<bool?> canScheduleExact() async {
    final android = _android;
    if (android == null) return null;
    return await android.canScheduleExactNotifications() ?? true;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openSettings() async {
    final android = _android;
    if (android != null) {
      await android.openAppNotificationSettings();
      return;
    }
    await _ios?.openAppNotificationSettings();
  }
}

class PermissionHandlerLocationBackend implements LocationPermissionBackend {
  const PermissionHandlerLocationBackend();

  @override
  Future<ph.PermissionStatus> whenInUseStatus() =>
      ph.Permission.locationWhenInUse.status;

  @override
  Future<ph.PermissionStatus> alwaysStatus() =>
      ph.Permission.locationAlways.status;

  @override
  Future<ph.PermissionStatus> requestWhenInUse() =>
      ph.Permission.locationWhenInUse.request();

  @override
  Future<ph.PermissionStatus> requestAlways() =>
      ph.Permission.locationAlways.request();

  @override
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}

/// Real [PermissionService]. "Requested" and "prompt shown" flags live in
/// SharedPreferences so the app never re-asks after a denial.
class PlatformPermissionService implements PermissionService {
  PlatformPermissionService({
    required NotificationPermissionBackend notifications,
    required LocationPermissionBackend location,
    required CalendarPermissionBackend calendar,
    Future<SharedPreferences> Function()? preferences,
  })  : _notifications = notifications,
        _location = location,
        _calendar = calendar,
        _preferences = preferences ?? SharedPreferences.getInstance;

  factory PlatformPermissionService.platform() => PlatformPermissionService(
        notifications: LocalNotificationsPermissionBackend(
          FlutterLocalNotificationsPlugin(),
        ),
        location: const PermissionHandlerLocationBackend(),
        calendar: const PermissionHandlerCalendarBackend(),
      );

  final NotificationPermissionBackend _notifications;
  final LocationPermissionBackend _location;
  final CalendarPermissionBackend _calendar;
  final Future<SharedPreferences> Function() _preferences;

  static const _requestedNotificationsKey =
      'permissions.requested.notifications';
  static const _requestedLocationKey = 'permissions.requested.location';
  static const _requestedLocationAlwaysKey =
      'permissions.requested.locationAlways';
  static const _requestedCalendarKey = 'permissions.requested.calendar';
  static String _promptKey(PermissionPrompt p) =>
      'permissions.prompt.${p.name}';

  Future<bool> _flag(String key) async =>
      (await _preferences()).getBool(key) ?? false;

  Future<void> _setFlag(String key) async {
    await (await _preferences()).setBool(key, true);
  }

  Future<NotificationPermissionState> _notificationState() async {
    return resolveNotificationState(
      enabled: await _notifications.areEnabled(),
      requested: await _flag(_requestedNotificationsKey),
    );
  }

  Future<LocationPermissionState> _locationState() async {
    return resolveLocationState(
      whenInUse: await _location.whenInUseStatus(),
      always: await _location.alwaysStatus(),
      requested: await _flag(_requestedLocationKey),
    );
  }

  Future<CalendarPermissionState> _calendarState() async {
    return resolveCalendarState(
      status: await _calendar.status(),
      requested: await _flag(_requestedCalendarKey),
    );
  }

  @override
  Future<PermissionSnapshot> check() async {
    final exact = await _notifications.canScheduleExact();
    return PermissionSnapshot(
      notifications: await _notificationState(),
      exactAlarms: exact == null
          ? ExactAlarmState.notRequired
          : (exact ? ExactAlarmState.granted : ExactAlarmState.denied),
      location: await _locationState(),
      calendar: await _calendarState(),
    );
  }

  @override
  Future<NotificationPermissionState> requestNotifications() async {
    final current = await _notificationState();
    switch (notificationFix(current)) {
      case PermissionFix.none:
        return current;
      case PermissionFix.openSettings:
        await _notifications.openSettings();
      case PermissionFix.request:
        await _setFlag(_requestedNotificationsKey);
        await _notifications.request();
    }
    return _notificationState();
  }

  @override
  Future<void> openNotificationSettings() => _notifications.openSettings();

  @override
  Future<void> openExactAlarmSettings() =>
      _notifications.openExactAlarmSettings();

  @override
  Future<LocationPermissionState> requestLocationWhenInUse() async {
    final current = await _locationState();
    switch (current) {
      case LocationPermissionState.always:
      case LocationPermissionState.whileInUse:
        return current;
      case LocationPermissionState.denied:
        await _location.openAppSettings();
      case LocationPermissionState.notRequested:
        await _setFlag(_requestedLocationKey);
        await _location.requestWhenInUse();
    }
    return _locationState();
  }

  @override
  Future<LocationPermissionState> requestLocationAlways() async {
    final current = await _locationState();
    switch (current) {
      case LocationPermissionState.always:
        return current;
      case LocationPermissionState.notRequested:
        // Background access needs foreground access first.
        return requestLocationWhenInUse();
      case LocationPermissionState.denied:
        await _location.openAppSettings();
      case LocationPermissionState.whileInUse:
        if (await _flag(_requestedLocationAlwaysKey)) {
          await _location.openAppSettings();
        } else {
          await _setFlag(_requestedLocationAlwaysKey);
          await _location.requestAlways();
        }
    }
    return _locationState();
  }

  @override
  Future<CalendarPermissionState> requestCalendar() async {
    final current = await _calendarState();
    switch (calendarFix(current)) {
      case PermissionFix.none:
        return current;
      case PermissionFix.openSettings:
        await _location.openAppSettings();
      case PermissionFix.request:
        await _setFlag(_requestedCalendarKey);
        await _calendar.request();
    }
    return _calendarState();
  }

  @override
  Future<void> openAppSettings() => _location.openAppSettings();

  @override
  Future<bool> shouldShowPrompt(PermissionPrompt prompt) async =>
      !await _flag(_promptKey(prompt));

  @override
  Future<void> markPromptShown(PermissionPrompt prompt) =>
      _setFlag(_promptKey(prompt));
}
