import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/l10n/app_localizations.dart';

/// Ayarlar › Görünüm › "Dil" (F6.1): follow the system language or force
/// Turkish / English.
enum AppLanguage {
  system('system'),
  turkish('tr'),
  english('en');

  const AppLanguage(this.storageKey);

  /// Persisted value (SharedPreferences); never rename.
  final String storageKey;

  static AppLanguage fromStorage(String? key) => AppLanguage.values
      .firstWhere((l) => l.storageKey == key, orElse: () => system);
}

/// The two app locales. Turkish is the ARB template.
abstract final class AppLocales {
  static const turkish = Locale('tr', 'TR');
  static const english = Locale('en', 'US');

  /// `MaterialApp.supportedLocales`.
  static const supported = <Locale>[turkish, english];

  /// The app locale for [language]. "Sistem" picks Turkish when the first
  /// preferred system language is Turkish, English for everything else.
  static Locale resolve(AppLanguage language, List<Locale> systemLocales) =>
      switch (language) {
        AppLanguage.turkish => turkish,
        AppLanguage.english => english,
        AppLanguage.system => systemLocales.isNotEmpty &&
                systemLocales.first.languageCode == turkish.languageCode
            ? turkish
            : english,
      };

  /// The device's preferred languages, also in background isolates
  /// (headless engines get the locales at start-up; `Platform.localeName`
  /// is the fallback when the list is empty).
  static List<Locale> systemLocales() {
    final locales = PlatformDispatcher.instance.locales;
    if (locales.isNotEmpty) return locales;
    try {
      final name = Platform.localeName; // e.g. "tr_TR", "en-US", "C"
      final code = name.split(RegExp('[_.-]')).first;
      return [Locale(code.isEmpty ? 'en' : code)];
    } catch (_) {
      return const [english];
    }
  }

  /// `intl` locale for [DateFormat] ("tr_TR", "en_US").
  static String intlLocaleOf(Locale locale) =>
      locale.languageCode == turkish.languageCode ? 'tr_TR' : 'en_US';
}

/// Persists the "Dil" choice (F6.1).
///
/// A SharedPreferences value like `HapticsStore` rather than an
/// `AppSettings` column: background isolates (notifications, geofence,
/// widget) read it without opening the database, and no schema bump (v6) is
/// needed for a UI preference.
class AppLanguageStore {
  AppLanguageStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance,
        _memory = null;

  /// Keeps the choice in memory only (widget tests).
  AppLanguageStore.memory({AppLanguage language = AppLanguage.system})
      : _preferences = null,
        _memory = language;

  static const languageKey = 'app_language_v1';

  final Future<SharedPreferences> Function()? _preferences;
  AppLanguage? _memory;

  /// The stored choice; [AppLanguage.system] when none (or unreadable).
  /// [reload] refreshes this isolate's SharedPreferences cache first
  /// (background isolates: the app may have changed it).
  Future<AppLanguage> load({bool reload = false}) async {
    final preferences = _preferences;
    if (preferences == null) return _memory!;
    try {
      final prefs = await preferences();
      if (reload) await prefs.reload();
      return AppLanguage.fromStorage(prefs.getString(languageKey));
    } catch (_) {
      return AppLanguage.system;
    }
  }

  Future<void> save(AppLanguage language) async {
    final preferences = _preferences;
    if (preferences == null) {
      _memory = language;
      return;
    }
    await (await preferences()).setString(languageKey, language.storageKey);
  }
}

/// Strings for code without a `BuildContext`: notifications, geofence
/// entries, the home widget payload, app icon shortcuts — in the app and in
/// background isolates. Resolves the stored "Dil" choice against the system
/// language exactly like the UI does and loads `intl` date symbols.
abstract final class BackgroundLocalizations {
  /// Stored choice + system language → [AppLocalizations].
  static Future<AppLocalizations> load({
    AppLanguageStore? store,
    List<Locale>? systemLocales,
  }) async {
    final language = await (store ?? AppLanguageStore()).load(reload: true);
    final locale = AppLocales.resolve(
      language,
      systemLocales ?? AppLocales.systemLocales(),
    );
    await initializeDateFormatting(AppLocales.intlLocaleOf(locale));
    return lookupAppLocalizations(locale);
  }
}

/// The "Dil" setting. Starts from the value `main` read from the
/// [AppLanguageStore] before `runApp` and writes changes back to it.
class AppLanguageController extends ChangeNotifier {
  AppLanguageController(this.store, {AppLanguage initial = AppLanguage.system})
      : _language = initial;

  final AppLanguageStore store;

  AppLanguage _language;
  bool _disposed = false;

  AppLanguage get language => _language;

  /// Saves first, so services reading the store (notification texts,
  /// widget labels) see the new choice when listeners resync.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    await store.save(language);
    if (_disposed) return;
    _language = language;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provides the "Dil" setting above `MaterialApp` (which takes its locale
/// from it) and to Ayarlar. [onChanged] runs after the user changed it (the
/// app resyncs notification texts, the widget and shortcuts).
class AppLanguageScope extends StatefulWidget {
  const AppLanguageScope({
    super.key,
    this.store,
    this.initial = AppLanguage.system,
    this.onChanged,
    required this.child,
  });

  /// Defaults to [AppLanguageStore] over SharedPreferences.
  final AppLanguageStore? store;

  /// The stored value read before `runApp` (`AppLanguageStore.load`), so the
  /// first frame is already in the right language.
  final AppLanguage initial;
  final ValueChanged<AppLanguage>? onChanged;
  final Widget child;

  /// The controller, rebuilding [context] when the setting changes; null
  /// without a scope.
  static AppLanguageController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_AppLanguageInherited>()
      ?.notifier;

  @override
  State<AppLanguageScope> createState() => _AppLanguageScopeState();
}

class _AppLanguageScopeState extends State<AppLanguageScope> {
  late final AppLanguageController _controller = AppLanguageController(
    widget.store ?? AppLanguageStore(),
    initial: widget.initial,
  );

  AppLanguage _last = AppLanguage.system;

  @override
  void initState() {
    super.initState();
    _last = _controller.language;
    _controller.addListener(_changed);
  }

  void _changed() {
    final language = _controller.language;
    if (language == _last) return;
    _last = language;
    widget.onChanged?.call(language);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AppLanguageInherited(notifier: _controller, child: widget.child);
}

class _AppLanguageInherited extends InheritedNotifier<AppLanguageController> {
  const _AppLanguageInherited({required super.notifier, required super.child});
}
