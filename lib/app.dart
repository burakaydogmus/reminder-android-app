import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/home/app_lifecycle_reloader.dart';
import 'package:reminder/ui/onboarding/onboarding_gate.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    this.initialLanguage = AppLanguage.system,
    this.onLanguageChanged,
  });

  /// The stored "Dil" choice read before `runApp` (F6.1), so the first frame
  /// is already in the right language.
  final AppLanguage initialLanguage;

  /// Called after the user changed the language (besides the resync below);
  /// `main` republishes the app icon shortcut titles.
  final ValueChanged<AppLanguage>? onLanguageChanged;

  /// `MaterialApp` locale for [language]: `null` for "Sistem" so
  /// [resolveSystemLocale] follows device language changes.
  static Locale? localeFor(AppLanguage language) =>
      language == AppLanguage.system
          ? null
          : AppLocales.resolve(language, const []);

  /// "Sistem": Turkish when the first preferred language is Turkish,
  /// English otherwise.
  static Locale resolveSystemLocale(
    List<Locale>? locales,
    Iterable<Locale> supported,
  ) =>
      AppLocales.resolve(AppLanguage.system, locales ?? const []);

  /// App strings + material_ui's Material/Cupertino/Widgets delegates.
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ];

  static ThemeMode themeModeFor(String id) {
    switch (id) {
      case AppThemeModeIds.light:
        return ThemeMode.light;
      case AppThemeModeIds.dark:
        return ThemeMode.dark;
      case AppThemeModeIds.system:
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReminderCubit(
        ReminderRepository(),
        NotificationService.instance,
        geofence: GeofenceService.instance,
        homeWidget: const PlatformHomeWidgetSync(),
      )..load(),
      // F1.3: widget değişikliklerini ezmemek için depodan yeniden yükler.
      child: AppStateReloader(
        child: Builder(
          builder: (context) => AppLanguageScope(
            initial: initialLanguage,
            // F6.1: notification texts, widget labels and shortcut titles
            // follow the new language (services read the stored choice).
            onChanged: (language) {
              context.read<ReminderCubit>().load();
              onLanguageChanged?.call(language);
            },
            child: BlocBuilder<ReminderCubit, ReminderState>(
              buildWhen: (a, b) => a.settings.themeMode != b.settings.themeMode,
              builder: (context, state) {
                final language = AppLanguageScope.maybeOf(context)?.language ??
                    AppLanguage.system;
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  onGenerateTitle: (context) => context.l10n.appTitle,
                  theme: KorTheme.light(),
                  darkTheme: KorTheme.dark(),
                  themeMode: themeModeFor(state.settings.themeMode),
                  locale: localeFor(language),
                  localeListResolutionCallback: resolveSystemLocale,
                  supportedLocales: AppLocales.supported,
                  localizationsDelegates: localizationsDelegates,
                  builder: (context, child) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final iconBrightness =
                        isDark ? Brightness.light : Brightness.dark;
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle(
                        statusBarColor: const Color(0x00000000),
                        systemNavigationBarColor: const Color(0x00000000),
                        systemNavigationBarIconBrightness: iconBrightness,
                        statusBarIconBrightness: iconBrightness,
                        statusBarBrightness:
                            isDark ? Brightness.dark : Brightness.light,
                      ),
                      // F4.7: "Titreşim geri bildirimi" for every route.
                      child: HapticsScope(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    );
                  },
                  home: const OnboardingGate(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
