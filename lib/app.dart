import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/home/home_page.dart';
import 'package:reminder/ui/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  ThemeMode _themeMode(String id) {
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
      child: BlocBuilder<ReminderCubit, ReminderState>(
        buildWhen: (a, b) => a.settings.themeMode != b.settings.themeMode,
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hatırlatıcı',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeMode(state.settings.themeMode),
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              final isDark = brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
