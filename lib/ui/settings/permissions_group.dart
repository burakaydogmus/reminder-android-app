import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/calendar/device_calendar_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class PermissionsGroupKeys {
  static const notifications = Key('permissions.notifications');
  static const location = Key('permissions.location');
  static const exactAlarms = Key('permissions.exactAlarms');
  static const calendar = Key('permissions.calendar');
}

/// Ayarlar → İzinler (§3.3.9): live status per permission with a fix action.
/// Re-checked when the page opens and whenever the app resumes
/// (`PermissionController`).
class PermissionsGroup extends StatefulWidget {
  const PermissionsGroup({super.key});

  @override
  State<PermissionsGroup> createState() => _PermissionsGroupState();
}

class _PermissionsGroupState extends State<PermissionsGroup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PermissionScope.read(context).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = PermissionScope.of(context).snapshot;
    return GroupedCard(
      icon: Icons.verified_user_outlined,
      title: context.l10n.permissionsTitle,
      children: [
        _notifications(context, snapshot?.notifications),
        _location(context, snapshot?.location),
        if (snapshot != null &&
            snapshot.exactAlarms != ExactAlarmState.notRequired)
          _exactAlarms(context, snapshot.exactAlarms),
        // F8.1: only while the user opted into calendar events — the app never
        // asks for the calendar on its own, so an untouched install should not
        // see a warning about a permission it does not need.
        if (DeviceCalendarScope.maybeOf(context)?.enabled ?? false)
          _calendar(context, snapshot?.calendar),
      ],
    );
  }

  /// Device calendar **read** access (F8.1). The app never writes, so a
  /// granted row says so explicitly.
  Widget _calendar(BuildContext context, CalendarPermissionState? state) {
    final l10n = context.l10n;
    final (status, level) = switch (state) {
      null => (l10n.permissionChecking, _Level.unknown),
      CalendarPermissionState.granted => (
          l10n.permissionCalendarGranted,
          _Level.ok,
        ),
      CalendarPermissionState.notRequested => (
          l10n.permissionCalendarNotRequested,
          _Level.warning,
        ),
      CalendarPermissionState.denied => (
          l10n.permissionCalendarDenied,
          _Level.warning,
        ),
    };
    final fix = state == null ? PermissionFix.none : calendarFix(state);
    return _PermissionRow(
      key: PermissionsGroupKeys.calendar,
      icon: Icons.event_available_outlined,
      title: l10n.permissionCalendar,
      status: status,
      level: level,
      actionLabel: switch (fix) {
        PermissionFix.none => null,
        PermissionFix.request => l10n.permissionAllow,
        PermissionFix.openSettings => l10n.permissionOpenSettings,
      },
      onAction: () => PermissionFlows.fixCalendar(context),
    );
  }

  Widget _notifications(
    BuildContext context,
    NotificationPermissionState? state,
  ) {
    final l10n = context.l10n;
    final (status, level) = switch (state) {
      null => (l10n.permissionChecking, _Level.unknown),
      NotificationPermissionState.granted => (l10n.permissionOn, _Level.ok),
      NotificationPermissionState.notRequested => (
          l10n.permissionNotificationsNotRequested,
          _Level.warning,
        ),
      NotificationPermissionState.denied => (
          l10n.permissionNotificationsDenied,
          _Level.warning,
        ),
    };
    final fix = state == null ? PermissionFix.none : notificationFix(state);
    return _PermissionRow(
      key: PermissionsGroupKeys.notifications,
      icon: Icons.notifications_outlined,
      title: l10n.permissionNotifications,
      status: status,
      level: level,
      actionLabel: switch (fix) {
        PermissionFix.none => null,
        PermissionFix.request => l10n.permissionAllow,
        PermissionFix.openSettings => l10n.permissionOpenSettings,
      },
      onAction: () => PermissionFlows.fixNotifications(context),
    );
  }

  Widget _location(BuildContext context, LocationPermissionState? state) {
    final l10n = context.l10n;
    final (status, level) = switch (state) {
      null => (l10n.permissionChecking, _Level.unknown),
      LocationPermissionState.always => (
          l10n.permissionLocationAlways,
          _Level.ok,
        ),
      LocationPermissionState.whileInUse => (
          l10n.permissionLocationWhileInUse,
          _Level.warning,
        ),
      LocationPermissionState.notRequested => (
          l10n.permissionLocationNotRequested,
          _Level.warning,
        ),
      LocationPermissionState.denied => (
          l10n.permissionLocationDenied,
          _Level.warning,
        ),
    };
    return _PermissionRow(
      key: PermissionsGroupKeys.location,
      icon: Icons.place_outlined,
      title: l10n.permissionLocation,
      status: status,
      level: level,
      actionLabel: switch (state) {
        null || LocationPermissionState.always => null,
        LocationPermissionState.whileInUse => l10n.permissionFix,
        LocationPermissionState.notRequested => l10n.permissionAllow,
        LocationPermissionState.denied => l10n.permissionOpenSettings,
      },
      onAction: () => PermissionFlows.fixLocation(context),
    );
  }

  Widget _exactAlarms(BuildContext context, ExactAlarmState state) {
    final granted = state != ExactAlarmState.denied;
    final l10n = context.l10n;
    return _PermissionRow(
      key: PermissionsGroupKeys.exactAlarms,
      icon: Icons.alarm_rounded,
      title: l10n.permissionExactAlarms,
      // Optional (F6.2c): reminders fall back to inexact alarms.
      status: granted ? l10n.permissionOn : l10n.permissionExactAlarmsOff,
      level: granted ? _Level.ok : _Level.warning,
      actionLabel: exactAlarmFix(state) == PermissionFix.none
          ? null
          : l10n.permissionOpenSettings,
      onAction: () => PermissionFlows.fixExactAlarms(context),
    );
  }
}

enum _Level { ok, warning, unknown }

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.level,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String status;
  final _Level level;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (statusIcon, statusColor) = switch (level) {
      _Level.ok => (Icons.check_circle_rounded, context.korColors.success),
      _Level.warning => (Icons.warning_amber_rounded, scheme.tertiary),
      _Level.unknown => (Icons.more_horiz_rounded, scheme.onSurfaceVariant),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: scheme.onSurfaceVariant),
                  const SizedBox(width: KorSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: KorSpacing.s1),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              statusIcon,
                              size: KorSizes.iconSm,
                              color: statusColor,
                            ),
                            const SizedBox(width: KorSpacing.s2),
                            Expanded(
                              child: Text(
                                status,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: KorSpacing.s3),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
