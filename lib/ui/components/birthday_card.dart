import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Birthday row/banner (`BirthdayCard`): birthday container, initials avatar,
/// name, age or date, countdown pill.
class BirthdayCard extends StatelessWidget {
  const BirthdayCard({
    super.key,
    required this.occurrence,
    required this.now,
    this.onTap,
  });

  final BirthdayOccurrence occurrence;
  final DateTime now;
  final VoidCallback? onTap;

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return KorFormat.upperTr('$first$last');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CategoryVisuals.birthdayColorsOf(context);
    final l10n = context.l10n;
    final b = occurrence.birthday;
    final age = occurrence.age;
    final countdown = KorFormat.countdown(occurrence.daysUntil, l10n);

    final subtitleParts = <String>[
      age != null
          ? l10n.birthdayTurnsAge('$age')
          : KorFormat.dayMonth(occurrence.date, now, l10n),
      if (b.note != null && b.note!.trim().isNotEmpty) b.note!.trim(),
    ];
    final subtitle = subtitleParts.join(' · ');

    return Semantics(
      button: onTap != null,
      label: l10n.birthdaySpokenLabel(b.name, countdown, subtitle),
      excludeSemantics: true,
      child: Material(
        color: colors.container,
        borderRadius: KorRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: KorRadius.cardAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KorSpacing.s4,
                vertical: KorSpacing.s3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initials(b.name),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.fg,
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
                          b.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: KorSpacing.s1),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KorSpacing.s3),
                  Container(
                    constraints: const BoxConstraints(minHeight: 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KorSpacing.s4,
                      vertical: KorSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.fg,
                      borderRadius: KorRadius.fullAll,
                    ),
                    child: Text(
                      countdown,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onFg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
