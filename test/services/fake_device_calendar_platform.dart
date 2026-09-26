import 'package:reminder/services/device_calendar_service.dart';

/// In-memory [DeviceCalendarPlatform] for tests (the same role
/// `FakeHomeWidgetPlatform` plays for `home_widget`): the real plugin has no
/// implementation on the test host, so every path — granted, denied, revoked,
/// all-day, recurring, no calendar app — is only reachable through this fake.
class FakeDeviceCalendarPlatform implements DeviceCalendarPlatform {
  FakeDeviceCalendarPlatform({
    this.calendarList = const [],
    this.eventList = const [],
  });

  List<DeviceCalendarInfo> calendarList;

  /// Every occurrence the fake device knows about; [events] returns the ones
  /// overlapping the asked-for range, like the platform does.
  List<DeviceCalendarEvent> eventList;

  /// When set, the next [calendars] / [events] call throws it.
  DeviceCalendarReadException? failure;

  /// Result of [openEvent] (`false` = "no calendar app", the sheet fallback).
  bool openSucceeds = true;

  /// Thrown by [openEvent] when set (a permission revoked meanwhile).
  DeviceCalendarReadException? openFailure;

  /// Recorded calls, so tests can assert reads are cached and not repeated.
  final List<String> calls = [];
  final List<(DateTime, DateTime, List<String>)> eventQueries = [];
  final List<String> openedEventIds = [];

  @override
  Future<List<DeviceCalendarInfo>> calendars() async {
    calls.add('calendars');
    final error = failure;
    if (error != null) throw error;
    return List.of(calendarList);
  }

  @override
  Future<List<DeviceCalendarEvent>> events({
    required DateTime from,
    required DateTime to,
    required List<String> calendarIds,
  }) async {
    calls.add('events');
    eventQueries.add((from, to, List.of(calendarIds)));
    final error = failure;
    if (error != null) throw error;
    return [
      for (final e in eventList)
        if ((calendarIds.isEmpty || calendarIds.contains(e.calendarId)) &&
            e.start.isBefore(to) &&
            (e.end.isAfter(from) || !e.end.isAfter(e.start)))
          e,
    ];
  }

  @override
  Future<bool> openEvent(String eventId) async {
    calls.add('openEvent');
    openedEventIds.add(eventId);
    final error = openFailure;
    if (error != null) throw error;
    return openSucceeds;
  }
}

/// Builds a [DeviceCalendarEvent]; [end] defaults to an hour after [start]
/// (or the next midnight for an all-day event).
DeviceCalendarEvent buildCalendarEvent({
  String id = 'event-1',
  String? eventId,
  String calendarId = 'cal-personal',
  String title = 'Diş hekimi',
  required DateTime start,
  DateTime? end,
  bool isAllDay = false,
  String? location,
}) {
  return DeviceCalendarEvent(
    id: id,
    eventId: eventId ?? id,
    calendarId: calendarId,
    title: title,
    start: start,
    end: end ??
        (isAllDay
            ? DateTime(start.year, start.month, start.day + 1)
            : start.add(const Duration(hours: 1))),
    isAllDay: isAllDay,
    location: location,
  );
}

/// Builds a [DeviceCalendarInfo].
DeviceCalendarInfo buildDeviceCalendar({
  String id = 'cal-personal',
  String name = 'Kişisel',
  String? accountName = 'me@example.com',
  String? colorHex = '#3F51B5',
}) =>
    DeviceCalendarInfo(
      id: id,
      name: name,
      accountName: accountName,
      colorHex: colorHex,
    );
