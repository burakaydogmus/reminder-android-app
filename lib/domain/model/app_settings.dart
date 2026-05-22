/// Tema modu seçenekleri. UI bağımsız kalsın diye [String] olarak saklanır;
/// `App` katmanı bunları `ThemeMode`'a eşler.
abstract class AppThemeModeIds {
  static const system = 'system';
  static const light = 'light';
  static const dark = 'dark';

  static const List<String> values = [system, light, dark];

  static String normalize(String? raw) {
    switch (raw) {
      case light:
      case dark:
      case system:
        return raw!;
      default:
        return system;
    }
  }
}

class AppSettings {
  final bool notificationsEnabled;
  final String themeMode;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = AppThemeModeIds.system,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? themeMode,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'themeMode': themeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      themeMode: AppThemeModeIds.normalize(json['themeMode'] as String?),
    );
  }
}
