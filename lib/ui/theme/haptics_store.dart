import 'package:shared_preferences/shared_preferences.dart';

/// Persists Ayarlar › Görünüm › "Titreşim geri bildirimi" (F4.7).
///
/// A UI-only SharedPreferences flag like `OnboardingStore`: deliberately not
/// part of `AppSettings` or the Drift schema.
class HapticsStore {
  HapticsStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance,
        _memory = null;

  /// Keeps the flag in memory only (widget tests).
  HapticsStore.memory({bool enabled = defaultEnabled})
      : _preferences = null,
        _memory = enabled;

  static const enabledKey = 'haptics_enabled_v1';

  /// Haptics are on until the user turns them off.
  static const bool defaultEnabled = true;

  final Future<SharedPreferences> Function()? _preferences;
  bool? _memory;

  Future<bool> isEnabled() async {
    final preferences = _preferences;
    if (preferences == null) return _memory!;
    return (await preferences()).getBool(enabledKey) ?? defaultEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final preferences = _preferences;
    if (preferences == null) {
      _memory = enabled;
      return;
    }
    await (await preferences()).setBool(enabledKey, enabled);
  }
}
