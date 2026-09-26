import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// 48 dp circular weekday toggle (`Pzt` / `Mon`), spoken with the full
/// weekday name.
///
/// Shared by the recurrence sheet (F3.1) and the routine editor's repeat row
/// (F3.7), so both look and sound the same.
class WeekdayToggle extends StatelessWidget {
  const WeekdayToggle({
    super.key,
    required this.weekday,
    required this.selected,
    required this.onTap,
  });

  /// `DateTime.monday` … `DateTime.sunday`.
  final int weekday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: KorFormat.weekdayName(weekday, context.l10n),
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: KorSizes.minTouch,
            child: Center(
              child: Text(
                KorFormat.weekdayShort(weekday, context.l10n),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
