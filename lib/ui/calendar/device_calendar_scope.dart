import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:reminder/services/calendar_settings_store.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';

/// Holds the opt-in state, the calendar selection and one cached window of
/// device calendar occurrences (F8.1).
///
/// Loading is **lazy and cached**: [eventsInRange] answers from the cached
/// window and only schedules a platform read when the asked-for range is not
/// covered yet, so a rebuild (the shell's minute tick, a theme change, a
/// scroll) never touches the calendar API. The window is padded around the
/// request, so paging the Takvim agenda by a week usually hits the cache.
///
/// It reloads on foreground return ([didChangeAppLifecycleState], the same
/// trigger `AppStateReloader` uses for stored state) and whenever the visible
/// range moves outside the window.
///
/// A revoked permission **degrades gracefully**: the read fails, the toggle is
/// persisted back to off, the cache is cleared and the sections disappear
/// instead of showing an empty header.
class DeviceCalendarController extends ChangeNotifier
    with WidgetsBindingObserver {
  DeviceCalendarController({
    required this.permissions,
    DeviceCalendarPlatform platform = const PluginDeviceCalendarPlatform(),
    CalendarSettingsStore? store,
  })  : _platform = platform,
        _store = store ?? CalendarSettingsStore();

  /// Used to verify calendar access before enabling and on every reload.
  final PermissionService permissions;
  final DeviceCalendarPlatform _platform;
  final CalendarSettingsStore _store;

  /// Days loaded before the requested range (paging back a week stays cached).
  static const int padBeforeDays = 7;

  /// Days loaded after the requested range.
  static const int padAfterDays = 45;

  bool _disposed = false;
  bool _ready = false;
  bool _enabled = CalendarSettingsStore.defaultEnabled;
  bool _loading = false;
  bool _unavailable = false;
  List<DeviceCalendarInfo> _calendars = const [];
  Set<String>? _visibleIds;

  List<DeviceCalendarEvent> _events = const [];
  DateTime? _windowFrom;
  DateTime? _windowTo;
  List<String> _windowIds = const [];
  Future<void>? _pending;

  /// `false` until [load] read the stored opt-in; the UI shows nothing yet.
  bool get ready => _ready;

  /// Whether the user opted in (Ayarlar › Takvim etkinlikleri).
  bool get enabled => _enabled;

  /// A platform read is in flight.
  bool get loading => _loading;

  /// The last read failed for a reason that is not a denied permission (no
  /// calendar provider, a plugin error). The feature stays on; the UI just has
  /// nothing new to show.
  bool get unavailable => _unavailable;

  /// Calendars on the device, empty while off or not loaded.
  List<DeviceCalendarInfo> get calendars => _calendars;

  /// Ids the user chose to show, or `null` for "all" (nothing chosen yet).
  Set<String>? get visibleCalendarIds {
    final visible = _visibleIds;
    return visible == null ? null : Set.unmodifiable(visible);
  }

  /// Whether [id] is shown. Unchosen (`null`) means every calendar is shown.
  bool isCalendarVisible(String id) => _visibleIds?.contains(id) ?? true;

  /// The user turned **every** calendar off, so there is deliberately nothing
  /// to show. An untouched selection (`null` = all) is never "hidden".
  bool get allCalendarsHidden =>
      _enabled &&
      _calendars.isNotEmpty &&
      _visibleIds != null &&
      _visibleCalendarIdList().isEmpty;

  /// Reads the stored opt-in and, when on, the calendar list. Called once by
  /// [DeviceCalendarScope].
  Future<void> load() async {
    _enabled = await _store.isEnabled();
    _visibleIds = (await _store.visibleCalendarIds())?.toSet();
    _ready = true;
    if (_enabled) {
      await _loadCalendars();
    }
    _notify();
  }

  /// Re-checks access and re-reads the current window (foreground return, or
  /// after the user came back from system settings).
  Future<void> refresh() async {
    if (!_enabled) return;
    if (!await _hasAccess()) {
      await _degrade();
      return;
    }
    await _loadCalendars();
    final from = _windowFrom;
    final to = _windowTo;
    _invalidate();
    if (from != null && to != null) {
      await _read(from, to);
    }
    _notify();
  }

  /// Turns the feature on or off. Turning it **on** only succeeds when
  /// calendar access is already granted, so the caller runs
  /// `PermissionFlows.calendar` first; a refused permission leaves the toggle
  /// off and returns `false`.
  Future<bool> setEnabled(bool enabled) async {
    if (!enabled) {
      await _degrade(persist: true);
      return false;
    }
    if (!await _hasAccess()) {
      // Never store an opt-in we cannot honour.
      if (_enabled) await _degrade(persist: true);
      return false;
    }
    _enabled = true;
    _unavailable = false;
    await _store.setEnabled(true);
    await _loadCalendars();
    _invalidate();
    _notify();
    return true;
  }

  /// Shows or hides one calendar; persisted and applied to the next read.
  Future<void> setCalendarVisible(String id, bool visible) async {
    final current = _visibleIds ?? {for (final c in _calendars) c.id};
    final next = {...current};
    if (visible) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _visibleIds = next;
    await _store.setVisibleCalendarIds(next.toList()..sort());
    _invalidate();
    _notify();
  }

  /// Cached occurrences overlapping `[from, to)`, sorted all-day first then by
  /// start. Safe to call from `build`: a missing range is loaded in a
  /// microtask, never synchronously.
  List<DeviceCalendarEvent> eventsInRange(DateTime from, DateTime to) {
    if (!_enabled || !_ready) return const [];
    if (!_covers(from, to)) _scheduleRead(from, to);
    return [
      for (final e in _events)
        if (e.start.isBefore(to) &&
            (e.end.isAfter(from) || !e.end.isAfter(e.start)))
          e,
    ];
  }

  /// Shows one occurrence in the platform's own (read-only) event view.
  /// `false` when the platform could not, so the caller can fall back to the
  /// in-app sheet; a revoked permission degrades the feature to off.
  Future<bool> openEvent(String occurrenceId) async {
    if (!_enabled) return false;
    try {
      return await _platform.openEvent(occurrenceId);
    } on DeviceCalendarReadException catch (error) {
      if (error.failure == DeviceCalendarFailure.permissionDenied) {
        await _degrade();
      }
      return false;
    }
  }

  /// Cached occurrences covering the day starting at [day] (midnight).
  List<DeviceCalendarEvent> eventsOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day + 1);
    return [
      for (final e in eventsInRange(dayStart, dayEnd))
        if (e.coversDay(dayStart)) e,
    ];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  @override
  void dispose() {
    // Idempotent: the scope and a test tear-down may both dispose.
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  // --- internals -----------------------------------------------------------

  List<String> _visibleCalendarIdList() {
    final visible = _visibleIds;
    if (visible == null) return const [];
    return [
      for (final c in _calendars)
        if (visible.contains(c.id)) c.id,
    ];
  }

  Future<bool> _hasAccess() async {
    final snapshot = await permissions.check();
    return snapshot.calendar == CalendarPermissionState.granted;
  }

  Future<void> _loadCalendars() async {
    try {
      _calendars = List.unmodifiable(await _platform.calendars());
      _unavailable = false;
    } on DeviceCalendarReadException catch (error) {
      if (error.failure == DeviceCalendarFailure.permissionDenied) {
        await _degrade();
        return;
      }
      _unavailable = true;
    }
  }

  void _invalidate() {
    _events = const [];
    _windowFrom = null;
    _windowTo = null;
    _windowIds = const [];
  }

  /// Persists the feature back to off and forgets everything read so far.
  Future<void> _degrade({bool persist = true}) async {
    _enabled = false;
    _calendars = const [];
    _unavailable = false;
    _loading = false;
    _invalidate();
    if (persist) await _store.setEnabled(false);
    _notify();
  }

  bool _covers(DateTime from, DateTime to) {
    final windowFrom = _windowFrom;
    final windowTo = _windowTo;
    if (windowFrom == null || windowTo == null) return false;
    if (!_sameIds(_windowIds, _visibleCalendarIdList())) return false;
    return !from.isBefore(windowFrom) && !to.isAfter(windowTo);
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _scheduleRead(DateTime from, DateTime to) {
    if (_pending != null) return;
    final padded = _padded(from, to);
    _pending = Future.microtask(() async {
      try {
        await _read(padded.$1, padded.$2);
      } finally {
        _pending = null;
      }
      _notify();
    });
  }

  static (DateTime, DateTime) _padded(DateTime from, DateTime to) => (
        DateTime(from.year, from.month, from.day - padBeforeDays),
        DateTime(to.year, to.month, to.day + padAfterDays),
      );

  Future<void> _read(DateTime from, DateTime to) async {
    if (_disposed || !_enabled) return;
    final ids = _visibleCalendarIdList();
    // Nothing selected: no read at all, and an empty (not stale) cache.
    if (_calendars.isNotEmpty && _visibleIds != null && ids.isEmpty) {
      _events = const [];
      _windowFrom = from;
      _windowTo = to;
      _windowIds = ids;
      return;
    }
    _loading = true;
    _notify();
    try {
      final events = await _platform.events(
        from: from,
        to: to,
        calendarIds: ids,
      );
      if (_disposed || !_enabled) return;
      _events = List.unmodifiable(events..sort(compareCalendarEvents));
      _windowFrom = from;
      _windowTo = to;
      _windowIds = ids;
      _unavailable = false;
    } on DeviceCalendarReadException catch (error) {
      if (error.failure == DeviceCalendarFailure.permissionDenied) {
        await _degrade();
        return;
      }
      _unavailable = true;
    } finally {
      _loading = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// Name of the calendar [calendarId] belongs to, or `null` when it is unknown
/// (a calendar added since the last read).
String? calendarNameOf(DeviceCalendarController controller, String calendarId) {
  for (final c in controller.calendars) {
    if (c.id == calendarId) return c.name;
  }
  return null;
}

/// Row order inside a day: all-day events first, then by start, then by title
/// so the list is stable.
int compareCalendarEvents(DeviceCalendarEvent a, DeviceCalendarEvent b) {
  if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
  final byStart = a.start.compareTo(b.start);
  if (byStart != 0) return byStart;
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
}

/// Provides a [DeviceCalendarController] above `MaterialApp` (wired in
/// `app.dart`, so pushed routes like Ayarlar see it too; widget tests pass a
/// controller over a fake platform).
class DeviceCalendarScope extends StatefulWidget {
  const DeviceCalendarScope({
    super.key,
    this.controller,
    required this.child,
  });

  /// Injected by tests; otherwise built from the ambient [PermissionService].
  final DeviceCalendarController? controller;
  final Widget child;

  /// Controller that rebuilds [context] when the state changes.
  static DeviceCalendarController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DeviceCalendarInherited>()
      ?.notifier;

  /// Controller without registering a dependency (event handlers).
  static DeviceCalendarController? maybeRead(BuildContext context) => context
      .getInheritedWidgetOfExactType<_DeviceCalendarInherited>()
      ?.notifier;

  @override
  State<DeviceCalendarScope> createState() => _DeviceCalendarScopeState();
}

class _DeviceCalendarScopeState extends State<DeviceCalendarScope> {
  DeviceCalendarController? _owned;

  DeviceCalendarController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      // `read` uses getInheritedWidgetOfExactType, which initState allows.
      _owned = DeviceCalendarController(
        permissions: PermissionScope.read(context).service,
      );
    }
    WidgetsBinding.instance.addObserver(_controller);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_controller);
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DeviceCalendarInherited(
      notifier: _controller,
      child: widget.child,
    );
  }
}

class _DeviceCalendarInherited
    extends InheritedNotifier<DeviceCalendarController> {
  const _DeviceCalendarInherited({
    required super.notifier,
    required super.child,
  });
}
