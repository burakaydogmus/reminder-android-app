import 'package:device_calendar_plus/device_calendar_plus.dart' as dcp;
import 'package:flutter/foundation.dart';

/// One calendar on the device (F8.1). Read-only: the app never creates,
/// renames or deletes a calendar.
@immutable
class DeviceCalendarInfo {
  const DeviceCalendarInfo({
    required this.id,
    required this.name,
    this.accountName,
    this.colorHex,
  });

  final String id;

  /// User-facing label, as the device's own calendar picker shows it.
  final String name;

  /// Owning account (`me@gmail.com`, `iCloud`, …) when the OS exposes it.
  final String? accountName;

  /// `#RRGGBB` from the OS, or `null`. Only used as a small dot, never as a
  /// text colour — the Kor palette owns every colour that carries text
  /// (see CLAUDE.md › Theme tokens).
  final String? colorHex;

  @override
  bool operator ==(Object other) =>
      other is DeviceCalendarInfo &&
      other.id == id &&
      other.name == name &&
      other.accountName == accountName &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(id, name, accountName, colorHex);

  @override
  String toString() => 'DeviceCalendarInfo($id, $name)';
}

/// One **occurrence** of a device calendar event inside a loaded range.
///
/// The platform expands recurring series, so a weekly meeting arrives as one
/// [DeviceCalendarEvent] per occurrence: they share [eventId] but each has its
/// own [id] (the platform's instance id, which is what opens that occurrence
/// in the system calendar).
@immutable
class DeviceCalendarEvent {
  const DeviceCalendarEvent({
    required this.id,
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.location,
  });

  /// Occurrence id (`eventId` for a one-off). Unstable across edits — never
  /// persisted, only used to open the occurrence.
  final String id;

  /// Series id; equal to [id] for a one-off event.
  final String eventId;
  final String calendarId;
  final String title;

  /// Local start. For an all-day event this is local midnight of the first day.
  final DateTime start;

  /// Local end, **exclusive** (`[start, end)`). For an all-day event this is
  /// local midnight after the last day.
  final DateTime end;
  final bool isAllDay;
  final String? location;

  /// Midnight of the first day the occurrence touches.
  DateTime get startDay => DateTime(start.year, start.month, start.day);

  /// `true` when the occurrence overlaps the day starting at [dayStart]
  /// (midnight), so a multi-day event shows on every day it covers.
  ///
  /// The range is half-open on both sides, so an event ending exactly at
  /// midnight does not leak into the next day. A zero-length event (start ==
  /// end, which some providers write for a point in time) still shows on its
  /// own day.
  bool coversDay(DateTime dayStart) {
    final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
    if (!start.isBefore(dayEnd)) return false;
    if (end.isAfter(dayStart)) return true;
    return !end.isAfter(start) && !start.isBefore(dayStart);
  }

  /// `true` when the occurrence covers more than one calendar day.
  bool get isMultiDay {
    final firstDay = startDay;
    final lastMoment = end.isAfter(start)
        ? end.subtract(const Duration(microseconds: 1))
        : start;
    return DateTime(lastMoment.year, lastMoment.month, lastMoment.day) !=
        firstDay;
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceCalendarEvent &&
      other.id == id &&
      other.eventId == eventId &&
      other.calendarId == calendarId &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.isAllDay == isAllDay &&
      other.location == location;

  @override
  int get hashCode => Object.hash(
        id,
        eventId,
        calendarId,
        title,
        start,
        end,
        isAllDay,
        location,
      );

  @override
  String toString() =>
      'DeviceCalendarEvent($id, $title, $start → $end, allDay: $isAllDay)';
}

/// Why a device calendar read failed (F8.1). Everything the platform can
/// throw collapses into one of these; the UI only distinguishes
/// [permissionDenied] (turn the feature back off) from the rest (keep the
/// last data, show nothing new).
enum DeviceCalendarFailure { permissionDenied, unavailable }

/// A read that could not be completed.
class DeviceCalendarReadException implements Exception {
  const DeviceCalendarReadException(this.failure, [this.message]);

  final DeviceCalendarFailure failure;
  final String? message;

  @override
  String toString() => 'DeviceCalendarReadException($failure, $message)';
}

/// The **only** seam over `device_calendar_plus` and the platform (the same
/// role `HomeWidgetPlatform` plays for `home_widget`): tests pass a fake, so
/// every path is exercised on the test host where no plugin exists.
///
/// Read-only by contract — there is no write method, so no code path can
/// create or change a device event.
abstract class DeviceCalendarPlatform {
  /// Every calendar the device exposes.
  Future<List<DeviceCalendarInfo>> calendars();

  /// Occurrences overlapping `[from, to)` in [calendarIds] (empty = all
  /// calendars), recurring series already expanded by the platform.
  Future<List<DeviceCalendarEvent>> events({
    required DateTime from,
    required DateTime to,
    required List<String> calendarIds,
  });

  /// Shows the occurrence [eventId] in the platform's own event view
  /// (Android: `ACTION_VIEW` on the event, i.e. the system calendar app;
  /// iOS: `EKEventViewController`). `false` when the platform cannot — the
  /// caller then shows the in-app read-only sheet.
  Future<bool> openEvent(String eventId);
}

/// [DeviceCalendarPlatform] over `device_calendar_plus`.
///
/// Only the read side of the plugin is used. Its own permission calls
/// (`requestPermissions` / `hasPermissions`) are deliberately **not** used:
/// they require `WRITE_CALENDAR` to be declared in the manifest even for a
/// read, while the plugin's read endpoints gate on `READ_CALENDAR` alone
/// (`PermissionGates.readAccessFailure`). Permission therefore goes through
/// `PermissionService.requestCalendar` like every other permission, and
/// `DeviceCalendar.autoPermissions` stays at its default `null` so the plugin
/// never prompts by itself.
class PluginDeviceCalendarPlatform implements DeviceCalendarPlatform {
  const PluginDeviceCalendarPlatform();

  dcp.DeviceCalendar get _plugin => dcp.DeviceCalendar.instance;

  @override
  Future<List<DeviceCalendarInfo>> calendars() async {
    try {
      final calendars = await _plugin.listCalendars();
      return [
        for (final c in calendars)
          if (!c.hidden)
            DeviceCalendarInfo(
              id: c.id,
              name: c.name,
              accountName: c.accountName,
              colorHex: c.colorHex,
            ),
      ];
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<List<DeviceCalendarEvent>> events({
    required DateTime from,
    required DateTime to,
    required List<String> calendarIds,
  }) async {
    try {
      final events = await _plugin.listEvents(
        from,
        to,
        calendarIds: calendarIds.isEmpty ? null : calendarIds,
      );
      return [for (final e in events) _map(e)];
    } on Object catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<bool> openEvent(String eventId) async {
    try {
      // `edit: false` (the default) → ACTION_VIEW / EKEventViewController,
      // both read-only views.
      await _plugin.showEventModal(eventId);
      return true;
    } on Object catch (error) {
      final translated = _translate(error);
      // A revoked permission must reach the caller so the feature turns
      // itself off; "no calendar app" / "not found" just falls back to the
      // in-app sheet.
      if (translated.failure == DeviceCalendarFailure.permissionDenied) {
        throw translated;
      }
      return false;
    }
  }

  static DeviceCalendarEvent _map(dcp.Event e) {
    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();
    return DeviceCalendarEvent(
      id: e.instanceId,
      eventId: e.eventId,
      calendarId: e.calendarId,
      title: e.title,
      start: start,
      // A provider may report an all-day event as a single instant; widen it
      // to the whole day so the row renders as all-day.
      end: e.isAllDay && !end.isAfter(start)
          ? DateTime(start.year, start.month, start.day + 1)
          : end,
      isAllDay: e.isAllDay,
      location: (e.location?.trim().isEmpty ?? true) ? null : e.location!.trim(),
    );
  }

  /// Only a real denial becomes [DeviceCalendarFailure.permissionDenied];
  /// `permissionsNotDeclared` is a build-configuration bug (a missing
  /// manifest entry or Info.plist key), not a user decision, so it stays
  /// `unavailable` instead of silently turning the feature off.
  static DeviceCalendarReadException _translate(Object error) {
    if (error is dcp.DeviceCalendarException &&
        error.errorCode == dcp.DeviceCalendarError.permissionDenied) {
      return DeviceCalendarReadException(
        DeviceCalendarFailure.permissionDenied,
        error.message,
      );
    }
    return DeviceCalendarReadException(
      DeviceCalendarFailure.unavailable,
      error.toString(),
    );
  }
}
