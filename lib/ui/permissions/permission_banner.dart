import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Inline `tertiaryContainer` warning with one action (§3.3.2 "İzin
/// reddedildi"). The icon and text carry the state, not the colour alone.
class PermissionBanner extends StatelessWidget {
  const PermissionBanner({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.notifications_off_outlined,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onTertiaryContainer;
    return Material(
      color: scheme.tertiaryContainer,
      borderRadius: KorRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KorSpacing.s5,
          KorSpacing.s4,
          KorSpacing.s3,
          KorSpacing.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: KorSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: fg,
                          ),
                        ),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: fg),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
