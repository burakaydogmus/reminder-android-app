import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_widgets.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Step 3/4: notification pre-permission. Only notifications are requested
/// here; exact alarms and location stay contextual (F1.6).
class NotificationStep extends StatefulWidget {
  const NotificationStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<NotificationStep> createState() => _NotificationStepState();
}

class _NotificationStepState extends State<NotificationStep> {
  bool _busy = false;

  /// Result of a request made on this step (`null` until then).
  NotificationPermissionState? _result;

  Future<void> _request() async {
    setState(() => _busy = true);
    // System prompt the first time, system settings after a denial.
    await PermissionFlows.fixNotifications(context);
    if (!mounted) return;
    final state = PermissionScope.read(context).snapshot?.notifications;
    setState(() {
      _busy = false;
      _result = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = PermissionScope.of(context).snapshot?.notifications;
    final granted = current == NotificationPermissionState.granted ||
        _result == NotificationPermissionState.granted;
    final deniedHere = !granted && _result != null;
    final l10n = context.l10n;

    final List<Widget> footer;
    if (granted) {
      footer = [
        const _StatusLine(granted: true),
        const SizedBox(height: KorSpacing.s4),
        OnboardingPrimaryButton(
          key: OnboardingKeys.next,
          label: l10n.onboardingContinue,
          onPressed: widget.onNext,
        ),
      ];
    } else if (deniedHere) {
      footer = [
        const _StatusLine(granted: false),
        const SizedBox(height: KorSpacing.s4),
        OnboardingPrimaryButton(
          key: OnboardingKeys.next,
          label: l10n.onboardingContinue,
          onPressed: widget.onNext,
        ),
      ];
    } else {
      final askedBefore = current == NotificationPermissionState.denied;
      footer = [
        OnboardingPrimaryButton(
          key: OnboardingKeys.allowNotifications,
          label:
              askedBefore ? l10n.permissionOpenSettings : l10n.permNotifConfirm,
          onPressed: _busy ? null : _request,
        ),
        OnboardingSecondaryButton(
          key: OnboardingKeys.notNow,
          label: l10n.permNotNow,
          onPressed: _busy ? null : widget.onNext,
        ),
      ];
    }

    return OnboardingStepFrame(
      index: 2,
      footer: footer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KorSpacing.s5),
          const NotificationMock(),
          const SizedBox(height: KorSpacing.s8),
          OnboardingCopy(title: l10n.onboardingNotifTitle, large: false),
          const SizedBox(height: KorSpacing.s5),
          _Benefit(
            icon: Icons.schedule_rounded,
            text: l10n.onboardingNotifBenefit1,
          ),
          _Benefit(
            icon: Icons.done_all_rounded,
            text: l10n.onboardingNotifBenefit2,
          ),
          _Benefit(
            icon: Icons.cake_rounded,
            text: l10n.onboardingNotifBenefit3,
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = granted ? context.korColors.success : scheme.onSurfaceVariant;
    final text = granted
        ? context.l10n.onboardingNotifOn
        : context.l10n.onboardingNotifOff;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            granted
                ? Icons.check_circle_rounded
                : Icons.notifications_off_outlined,
            color: color,
          ),
          const SizedBox(width: KorSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: granted ? color : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: KorSpacing.s4),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// Realistic (static) notification preview.
class NotificationMock extends StatelessWidget {
  const NotificationMock({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final action = theme.textTheme.labelLarge?.copyWith(color: scheme.primary);
    final l10n = context.l10n;
    return Semantics(
      label: l10n.onboardingMockSpoken,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(KorSpacing.s5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: KorRadius.lgAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(KorSpacing.s1),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      size: KorSizes.iconSm * 0.7,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: KorSpacing.s3),
                  Expanded(child: Text(l10n.onboardingMockApp, style: muted)),
                ],
              ),
              const SizedBox(height: KorSpacing.s3),
              Text(
                l10n.onboardingMockTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: KorSpacing.s1),
              Text(
                l10n.onboardingMockBody,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: KorSpacing.s4),
              Wrap(
                spacing: KorSpacing.s7,
                runSpacing: KorSpacing.s3,
                children: [
                  Text(l10n.actionComplete, style: action),
                  Text(l10n.onboardingMockSnooze, style: action),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
