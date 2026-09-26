import 'dart:io' show Platform;

import 'package:material_ui/material_ui.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show LiquidGlassWidgets;

import 'package:reminder/app.dart';
import 'package:reminder/config/app_licenses.dart';
import 'package:reminder/home/reminder_home_widget_callback.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/services/app_shortcuts.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/ios_widget_completions.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/services/widget_launch_router.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/util/local_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAppLicenses();
  // F5.2: iOS'ta veri App Group üzerinden WidgetKit extension'ına gider;
  // Android'de grup kimliği yok sayılır ama tek doğru değer burada durur.
  if (Platform.isAndroid || Platform.isIOS) {
    await HomeWidget.setAppGroupId(kHomeWidgetAppGroupId);
  }
  if (Platform.isAndroid) {
    // Etkileşim callback'i yalnız Android'de: iOS widget'ı "tamamla"yı App
    // Group'a yazar, uygulama aşağıda uygular (F5.2).
    await HomeWidget.registerInteractivityCallback(reminderHomeWidgetCallback);
  }
  // F5.4: pre-warm the glass shaders (async disk-to-RAM I/O only, no GPU
  // work) so the iOS tab bar has no placeholder frame; runs alongside the
  // steps below and is awaited before runApp. A failure is only reported:
  // glass then loads its shaders lazily. Android never uses glass.
  final glassWarmUp = Platform.isIOS
      ? LiquidGlassWidgets.initialize().catchError(
          (Object error, StackTrace stack) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'liquid_glass_widgets',
            ),
          ),
        )
      : Future<void>.value();
  await initializeDateFormatting('tr_TR');
  await initializeDateFormatting('en_US');
  // F6.1: the stored "Dil" choice, so the first frame is already localized.
  final language = await AppLanguageStore().load();
  await configureLocalTimezone();
  await NotificationService.instance.initialize();
  // F3.2: a tap that launched the app opens its reminder once HomeShell is up.
  await NotificationTapRouter.instance
      .openFromLaunch(NotificationService.instance.appLaunchDetails);
  // F5.1/F5.2: widget "+", row and permission taps open their screen in
  // HomeShell — Android via HomeWidgetLaunchIntent, iOS via the
  // `reminderwidget://` URL scheme (Runner Info.plist CFBundleURLTypes).
  if (Platform.isAndroid || Platform.isIOS) {
    await WidgetLaunchRouter.instance.attach(
      initialLaunch: HomeWidget.initiallyLaunchedFromHomeWidget,
      clicks: HomeWidget.widgetClicked,
    );
  }
  // F5.2: "tamamla" istekleri iOS widget'ından App Group'a yazılır; burada
  // depoya uygulanır (ön plana dönüşte AppStateReloader tekrar dener).
  await applyPendingIosWidgetCompletions();
  // F5.3: app icon shortcuts (both platforms) use the same router, so they
  // also wait for onboarding and HomeShell.
  final shortcuts = ShortcutRouter(router: WidgetLaunchRouter.instance);
  await shortcuts.attach(
    const PluginQuickActions(),
    l10n: await BackgroundLocalizations.load(),
  );
  // No permission prompts at launch (F1.6): notification, exact alarm and
  // location permissions are asked in context via PermissionFlows.
  await GeofenceService.instance.initialize();
  GeofenceService.instance.startListening(NotificationService.instance);
  await glassWarmUp;
  runApp(
    PermissionScope(
      service: PlatformPermissionService.platform(),
      child: App(
        initialLanguage: language,
        // F6.1: shortcut titles follow the in-app language.
        onLanguageChanged: (_) async =>
            shortcuts.publish(await BackgroundLocalizations.load()),
      ),
    ),
  );
}
