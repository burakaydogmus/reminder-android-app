import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/home/app_lifecycle_reloader.dart';
import 'package:reminder/ui/onboarding/onboarding_gate.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

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
        child: BlocBuilder<ReminderCubit, ReminderState>(
          buildWhen: (a, b) => a.settings.themeMode != b.settings.themeMode,
          builder: (context, state) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Hatırlatıcı',
              theme: KorTheme.light(),
              darkTheme: KorTheme.dark(),
              themeMode: themeModeFor(state.settings.themeMode),
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [
                Locale('tr', 'TR'),
                Locale('en', 'US'),
              ],
              // material_ui: includes the Cupertino and Widgets delegates.
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  child: HapticsScope(child: child ?? const SizedBox.shrink()),
                );
              },
              home: const OnboardingGate(),
            );
          },
        ),
      ),
    );
  }
}
