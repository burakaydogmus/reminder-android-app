import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Compact birthday row (§3.3.7 `BirthdayRow`, min 64 h): initials avatar on
/// the birthday container, name, subtitle lines and a trailing countdown.
/// One semantics node (button when [onTap] is set).
class BirthdayRow extends StatelessWidget {
  const BirthdayRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.note,
    this.onTap,
  });

  final String name;

  /// `14 Eylül · 30 yaşına`.
  final String subtitle;

  /// Second line, e.g. the 29 Şubat note.
  final String? note;

  /// `Yarın` / `8 gün`.
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CategoryVisuals.birthdayColorsOf(context);
    final secondary = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      button: onTap != null,
      label: [name, subtitle, if (note != null) note!, trailing].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: KorRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.container,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    BirthdayCard.initials(name),
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onContainer,
                    ),
                  ),
                ),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: KorSpacing.s1),
                      Text(subtitle, style: secondary),
                      if (note != null) Text(note!, style: secondary),
                    ],
                  ),
                ),
                const SizedBox(width: KorSpacing.s3),
                Text(
                  trailing,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
