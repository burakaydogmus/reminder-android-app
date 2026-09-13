import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-launch onboarding (F4.2) was completed.
///
/// Deliberately a UI-only SharedPreferences flag, independent of
/// `ReminderRepository` (whose storage is migrating in F2.1).
class OnboardingStore {
  OnboardingStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  static const completedKey = 'onboarding_completed_v1';

  final Future<SharedPreferences> Function() _preferences;

  Future<bool> isCompleted() async =>
      (await _preferences()).getBool(completedKey) ?? false;

  Future<void> markCompleted() async {
    await (await _preferences()).setBool(completedKey, true);
  }
}
