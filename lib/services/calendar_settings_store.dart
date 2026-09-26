import 'package:shared_preferences/shared_preferences.dart';

/// Persists the F8.1 "Takvim etkinlikleri" opt-in and the per-calendar
/// selection.
///
/// A UI-only SharedPreferences pair like [HapticsStore] / `OnboardingStore`:
/// deliberately **not** part of `AppSettings` or the Drift schema, so no
/// schema bump and no background isolate needs the database to read it.
class CalendarSettingsStore {
  CalendarSettingsStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance,
        _memoryEnabled = null,
        _memoryVisible = null,
        _memoryVisibleSet = false;

  /// Keeps both values in memory only (widget tests).
  CalendarSettingsStore.memory({
    bool enabled = defaultEnabled,
    List<String>? visibleCalendarIds,
  })  : _preferences = null,
        _memoryEnabled = enabled,
        _memoryVisible = visibleCalendarIds,
        _memoryVisibleSet = visibleCalendarIds != null;

  static const enabledKey = 'calendar_events_enabled_v1';
  static const visibleCalendarsKey = 'calendar_visible_ids_v1';

  /// **Off by default** (F8.1): nothing is read from the device calendar and
  /// no permission is requested until the user turns the toggle on.
  static const bool defaultEnabled = false;

  final Future<SharedPreferences> Function()? _preferences;
  bool? _memoryEnabled;
  List<String>? _memoryVisible;
  bool _memoryVisibleSet;

  Future<bool> isEnabled() async {
    final preferences = _preferences;
    if (preferences == null) return _memoryEnabled!;
    return (await preferences()).getBool(enabledKey) ?? defaultEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final preferences = _preferences;
    if (preferences == null) {
      _memoryEnabled = enabled;
      return;
    }
    await (await preferences()).setBool(enabledKey, enabled);
  }

  /// Ids of the calendars to show, or `null` when the user has not chosen yet
  /// — which means **all** calendars. An empty list means none (the user
  /// turned every calendar off), which is different from "not chosen".
  Future<List<String>?> visibleCalendarIds() async {
    final preferences = _preferences;
    if (preferences == null) {
      return _memoryVisibleSet ? List.of(_memoryVisible ?? const []) : null;
    }
    return (await preferences()).getStringList(visibleCalendarsKey);
  }

  Future<void> setVisibleCalendarIds(List<String> ids) async {
    final preferences = _preferences;
    if (preferences == null) {
      _memoryVisible = List.of(ids);
      _memoryVisibleSet = true;
      return;
    }
    await (await preferences()).setStringList(visibleCalendarsKey, ids);
  }
}
