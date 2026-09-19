import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/ui/permissions/permission_sheet.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';

/// Contextual permission flows (F1.6). Nothing is requested at app start;
/// each flow explains first, asks the system once and afterwards only points
/// to settings.
abstract final class PermissionFlows {
  /// Before saving something that schedules a notification (a timed reminder
  /// or a birthday): notification pre-permission sheet the first time, then
  /// the exact-alarm sheet on Android if exact alarms are not allowed.
  static Future<void> beforeScheduling(BuildContext context) async {
    final controller = PermissionScope.read(context);
    final service = controller.service;
    final snapshot = await controller.refresh();

    if (snapshot.notifications == NotificationPermissionState.notRequested) {
      if (!await service.shouldShowPrompt(PermissionPrompt.notifications)) {
        return;
      }
      await service.markPromptShown(PermissionPrompt.notifications);
      if (!context.mounted) return;
      final l10n = context.l10n;
      final ok = await showPermissionSheet(
        context,
        icon: Icons.notifications_active_outlined,
        title: l10n.permNotifTitle,
        body: l10n.permNotifBody,
        points: [
          l10n.permNotifPoint1,
          l10n.permNotifPoint2,
          l10n.permNotifPoint3,
        ],
        confirmLabel: l10n.permNotifConfirm,
        dismissLabel: l10n.permNotNow,
      );
      if (ok) await service.requestNotifications();
      await controller.refresh();
      return;
    }

    if (snapshot.notifications == NotificationPermissionState.granted &&
        snapshot.exactAlarms == ExactAlarmState.denied) {
      if (!await service.shouldShowPrompt(PermissionPrompt.exactAlarms)) {
        return;
      }
      await service.markPromptShown(PermissionPrompt.exactAlarms);
      if (!context.mounted) return;
      final ok = await _showExactAlarmSheet(context);
      if (ok) await service.openExactAlarmSettings();
      await controller.refresh();
    }
  }

  /// When the user turns on "Nerede" or opens the location picker: two-step
  /// flow (§3.3.10). Step 1 explains and asks "while in use"; step 2 explains
  /// "Her zaman" and opens the system flow. Each step is shown once.
  static Future<void> location(BuildContext context) async {
    final controller = PermissionScope.read(context);
    final service = controller.service;
    var state = (await controller.refresh()).location;

    if (state == LocationPermissionState.notRequested) {
      if (!await service.shouldShowPrompt(PermissionPrompt.locationWhenInUse)) {
        return;
      }
      await service.markPromptShown(PermissionPrompt.locationWhenInUse);
      if (!context.mounted) return;
      final ok = await _showLocationStep1(context);
      if (!ok) return;
      state = await service.requestLocationWhenInUse();
      await controller.refresh();
    }

    if (state == LocationPermissionState.whileInUse) {
      if (!await service.shouldShowPrompt(PermissionPrompt.locationAlways)) {
        return;
      }
      await service.markPromptShown(PermissionPrompt.locationAlways);
      if (!context.mounted) return;
      final ok = await _showLocationStep2(context);
      if (ok) await service.requestLocationAlways();
      await controller.refresh();
    }
  }

  /// "Düzelt" / "Ayarları aç" for notifications (Settings, Bugün banner).
  static Future<void> fixNotifications(BuildContext context) async {
    final controller = PermissionScope.read(context);
    final state = (await controller.refresh()).notifications;
    switch (notificationFix(state)) {
      case PermissionFix.none:
        break;
      case PermissionFix.request:
        await controller.service.requestNotifications();
      case PermissionFix.openSettings:
        await controller.service.openNotificationSettings();
    }
    await controller.refresh();
  }

  /// Fix action for location (Settings "Düzelt", editor warning).
  static Future<void> fixLocation(BuildContext context) async {
    final controller = PermissionScope.read(context);
    final service = controller.service;
    final state = (await controller.refresh()).location;
    switch (locationFix(state)) {
      case PermissionFix.none:
        break;
      case PermissionFix.request:
        if (state == LocationPermissionState.notRequested) {
          await service.requestLocationWhenInUse();
          await controller.refresh();
          if (!context.mounted) return;
          // Straight on to the background step with its explanation.
          if (controller.snapshot?.location ==
              LocationPermissionState.whileInUse) {
            final ok = await _showLocationStep2(context);
            if (ok) await service.requestLocationAlways();
          }
        } else {
          await service.requestLocationAlways();
        }
      case PermissionFix.openSettings:
        await service.openAppSettings();
    }
    await controller.refresh();
  }

  /// Exact alarms are optional (F6.2c): without them reminders are scheduled
  /// inexact and may arrive a few minutes late.
  static String exactAlarmTradeOff(AppLocalizations l10n) =>
      l10n.permExactTradeOff;

  /// "Ayarları aç" for exact alarms (Settings). When the user comes back with
  /// a different state, schedules are recomputed right away (F6.2c) so a
  /// granted permission upgrades pending notifications to exact alarms; the
  /// resume reload (`AppStateReloader`) does the same, the diff sync makes the
  /// second pass a no-op.
  static Future<void> fixExactAlarms(BuildContext context) async {
    final controller = PermissionScope.read(context);
    final cubit = context.read<ReminderCubit>();
    final before = controller.snapshot?.exactAlarms;
    await controller.service.openExactAlarmSettings();
    final after = (await controller.refresh()).exactAlarms;
    if (after != before) await cubit.load();
  }

  static Future<bool> _showExactAlarmSheet(BuildContext context) {
    final l10n = context.l10n;
    return showPermissionSheet(
      context,
      icon: Icons.alarm_rounded,
      title: l10n.permExactTitle,
      body: l10n.permExactBody(exactAlarmTradeOff(l10n)),
      confirmLabel: l10n.permissionOpenSettings,
      dismissLabel: l10n.actionLater,
    );
  }

  static Future<bool> _showLocationStep1(BuildContext context) {
    final l10n = context.l10n;
    return showPermissionSheet(
      context,
      icon: Icons.place_outlined,
      step: '1/2',
      title: l10n.permLocationTitle,
      body: l10n.permLocationBody,
      confirmLabel: l10n.permContinue,
      dismissLabel: l10n.permNotNow,
    );
  }

  static Future<bool> _showLocationStep2(BuildContext context) {
    final ios = PlatformChrome.isCupertino(context);
    final l10n = context.l10n;
    return showPermissionSheet(
      context,
      icon: Icons.my_location_rounded,
      step: '2/2',
      title: l10n.permLocationAlwaysTitle,
      body: ios
          ? l10n.permLocationAlwaysBodyIos
          : l10n.permLocationAlwaysBodyAndroid,
      illustration: const LocationAlwaysIllustration(),
      confirmLabel: l10n.permissionOpenSettings,
      dismissLabel: l10n.actionLater,
    );
  }
}
