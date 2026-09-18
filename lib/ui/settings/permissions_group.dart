import 'package:material_ui/material_ui.dart';

import 'package:reminder/services/permission_service.dart';
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
      title: 'İzinler',
      children: [
        _notifications(context, snapshot?.notifications),
        _location(context, snapshot?.location),
        if (snapshot != null &&
            snapshot.exactAlarms != ExactAlarmState.notRequired)
          _exactAlarms(context, snapshot.exactAlarms),
      ],
    );
  }

  Widget _notifications(
    BuildContext context,
    NotificationPermissionState? state,
  ) {
    final (status, level) = switch (state) {
      null => (_checking, _Level.unknown),
      NotificationPermissionState.granted => ('Açık', _Level.ok),
      NotificationPermissionState.notRequested => (
          'İzin verilmedi — hatırlatmalar bildirim olarak gelmez',
          _Level.warning,
        ),
      NotificationPermissionState.denied => (
          'Kapalı — hatırlatmalar zamanında gelmez',
          _Level.warning,
        ),
    };
    final fix = state == null ? PermissionFix.none : notificationFix(state);
    return _PermissionRow(
      key: PermissionsGroupKeys.notifications,
      icon: Icons.notifications_outlined,
      title: 'Bildirimler',
      status: status,
      level: level,
      actionLabel: switch (fix) {
        PermissionFix.none => null,
        PermissionFix.request => 'İzin ver',
        PermissionFix.openSettings => 'Ayarları aç',
      },
      onAction: () => PermissionFlows.fixNotifications(context),
    );
  }

  Widget _location(BuildContext context, LocationPermissionState? state) {
    final (status, level) = switch (state) {
      null => (_checking, _Level.unknown),
      LocationPermissionState.always => ('Her zaman', _Level.ok),
      LocationPermissionState.whileInUse => (
          'Yalnızca kullanırken — arka plan hatırlatmaları çalışmaz',
          _Level.warning,
        ),
      LocationPermissionState.notRequested => (
          'İzin verilmedi — konum hatırlatmaları çalışmaz',
          _Level.warning,
        ),
      LocationPermissionState.denied => (
          'Kapalı — konum hatırlatmaları çalışmaz',
          _Level.warning,
        ),
    };
    return _PermissionRow(
      key: PermissionsGroupKeys.location,
      icon: Icons.place_outlined,
      title: 'Konum',
      status: status,
      level: level,
      actionLabel: switch (state) {
        null || LocationPermissionState.always => null,
        LocationPermissionState.whileInUse => 'Düzelt',
        LocationPermissionState.notRequested => 'İzin ver',
        LocationPermissionState.denied => 'Ayarları aç',
      },
      onAction: () => PermissionFlows.fixLocation(context),
    );
  }

  Widget _exactAlarms(BuildContext context, ExactAlarmState state) {
    final granted = state != ExactAlarmState.denied;
    return _PermissionRow(
      key: PermissionsGroupKeys.exactAlarms,
      icon: Icons.alarm_rounded,
      title: 'Tam zamanlı alarmlar',
      // Optional (F6.2c): reminders fall back to inexact alarms.
      status: granted
          ? 'Açık'
          : 'Kapalı — izin olmadan hatırlatmalar birkaç dakika gecikebilir',
      level: granted ? _Level.ok : _Level.warning,
      actionLabel:
          exactAlarmFix(state) == PermissionFix.none ? null : 'Ayarları aç',
      onAction: () => PermissionFlows.fixExactAlarms(context),
    );
  }

  static const _checking = 'Denetleniyor…';
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
