import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/calendar/device_calendar_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CalendarSettingsKeys {
  static const toggle = Key('settings.calendarEvents');
  static Key calendar(String id) => ValueKey('settings.calendar.$id');
}

/// Ayarlar → Takvim etkinlikleri (F8.1): the opt-in switch and, once on, a
/// per-calendar picker.
///
/// **Off by default.** Turning it on runs `PermissionFlows.calendar` first; a
/// refused permission leaves the switch off (the controller never stores an
/// opt-in it cannot honour). The group renders nothing but the switch while the
/// feature is off, so there is no empty section.
class CalendarSettingsGroup extends StatelessWidget {
  const CalendarSettingsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DeviceCalendarScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final calendarPermission = PermissionScope.of(context).snapshot?.calendar;

    return GroupedCard(
      icon: Icons.event_available_outlined,
      title: l10n.settingsCalendar,
      children: [
        MergeSemantics(
          child: ListTile(
            key: CalendarSettingsKeys.toggle,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsCalendarToggle),
            subtitle: Text(l10n.settingsCalendarToggleHint),
            trailing: Switch.adaptive(
              value: controller.enabled,
              onChanged: (value) => _toggle(context, controller, value),
            ),
            onTap: () => _toggle(context, controller, !controller.enabled),
          ),
        ),
        if (controller.enabled) ...[
          const SizedBox(height: KorSpacing.s4),
          Text(
            l10n.settingsCalendarPickerTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: KorSpacing.s2),
          Text(l10n.settingsCalendarPickerHint, style: muted),
          const SizedBox(height: KorSpacing.s3),
          ..._picker(context, controller, muted),
        ] else if (calendarPermission == CalendarPermissionState.denied) ...[
          const SizedBox(height: KorSpacing.s3),
          Text(l10n.settingsCalendarDenied, style: muted),
        ],
      ],
    );
  }

  List<Widget> _picker(
    BuildContext context,
    DeviceCalendarController controller,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    if (controller.calendars.isEmpty) {
      return [
        Text(
          controller.unavailable
              ? l10n.settingsCalendarUnavailable
              : (controller.loading
                  ? l10n.settingsCalendarLoading
                  : l10n.settingsCalendarNone),
          style: muted,
        ),
      ];
    }
    return [
      for (final calendar in controller.calendars)
        _CalendarRow(
          key: CalendarSettingsKeys.calendar(calendar.id),
          calendar: calendar,
          visible: controller.isCalendarVisible(calendar.id),
          onChanged: (value) =>
              controller.setCalendarVisible(calendar.id, value),
        ),
      if (controller.allCalendarsHidden) ...[
        const SizedBox(height: KorSpacing.s2),
        Text(l10n.settingsCalendarAllHidden, style: muted),
      ],
    ];
  }

  /// Turning on: explain, ask, then store. Turning off: store and forget the
  /// cached events at once.
  Future<void> _toggle(
    BuildContext context,
    DeviceCalendarController controller,
    bool value,
  ) async {
    if (!value) {
      await controller.setEnabled(false);
      return;
    }
    await PermissionFlows.calendar(context);
    await controller.setEnabled(true);
  }
}

/// One calendar row: colour dot, name, owning account and a switch. The whole
/// row toggles and the semantics merge into one node.
class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    super.key,
    required this.calendar,
    required this.visible,
    required this.onChanged,
  });

  final DeviceCalendarInfo calendar;
  final bool visible;
  final ValueChanged<bool> onChanged;

  /// The OS colour of a calendar, or `null` when it is absent or unparseable.
  /// Only ever painted as a dot — no text sits on it, so it needs no contrast
  /// guarantee (CLAUDE.md › Theme tokens).
  static Color? colorOf(String? hex) {
    if (hex == null) return null;
    final digits = hex.replaceFirst('#', '');
    if (digits.length != 6) return null;
    final value = int.tryParse(digits, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final account = calendar.accountName?.trim();
    final dot = colorOf(calendar.colorHex) ?? scheme.outlineVariant;
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox.square(
          dimension: KorSizes.icon,
          child: Center(
            child: SizedBox.square(
              dimension: KorSpacing.s4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dot,
                  borderRadius: KorRadius.fullAll,
                ),
              ),
            ),
          ),
        ),
        title: Text(calendar.name),
        subtitle: account == null || account.isEmpty || account == calendar.name
            ? null
            : Text(account),
        trailing: Switch.adaptive(value: visible, onChanged: onChanged),
        onTap: () => onChanged(!visible),
      ),
    );
  }
}
