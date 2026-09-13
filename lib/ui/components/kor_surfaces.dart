import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Level-1 card decoration: `surface` with a hairline in light, a
/// `surfaceContainer` step without border in dark.
BoxDecoration korCardDecoration(
  BuildContext context, {
  BorderRadius borderRadius = KorRadius.cardAll,
  bool flat = false,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final elevation = isDark ? KorElevation.dark : KorElevation.light;
  final border = elevation.level1Border;
  return BoxDecoration(
    color: flat
        ? scheme.surfaceContainerLow
        : (isDark ? scheme.surfaceContainer : scheme.surface),
    borderRadius: borderRadius,
    border: flat || border == null ? null : Border.fromBorderSide(border),
    boxShadow: flat ? KorElevation.level0 : elevation.level1,
  );
}

/// Section title row (`SectionHeader`: 40 h, labelLarge, onSurfaceVariant).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: KorSizes.iconSm,
              color: iconColor ?? scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KorSpacing.s3),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Grouped card (radius lg) with an optional icon + title header row.
class GroupedCard extends StatelessWidget {
  const GroupedCard({
    super.key,
    this.icon,
    this.title,
    this.headerTrailing,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      KorSpacing.s5,
      KorSpacing.s3,
      KorSpacing.s5,
      KorSpacing.s4,
    ),
    this.borderColor,
  });

  final IconData? icon;
  final String? title;
  final Widget? headerTrailing;
  final List<Widget> children;
  final EdgeInsets padding;

  /// Replaces the hairline, e.g. `error` for an inline validation state.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    var decoration = korCardDecoration(context, borderRadius: KorRadius.lgAll);
    if (borderColor != null) {
      decoration = decoration.copyWith(
        border: Border.all(color: borderColor!, width: 2),
      );
    }
    return Container(
      decoration: decoration,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: KorSizes.iconSm,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: KorSpacing.s3),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title!, style: theme.textTheme.labelLarge),
                    ),
                  ),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
