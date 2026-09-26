import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/recurrence_text.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

/// Colours, icons and row texts of routines (F3.7).
///
/// Routines reuse the **category visuals vocabulary**: a stored
/// `KorColorKey.storageKey` and a [CategoryIconKeys] key, resolved through
/// `KorColors` exactly like a category. A routine without a choice falls back
/// to [defaultColorKey] / [defaultIconKey].
abstract final class RoutineVisuals {
  /// Colour of a routine that stores none.
  static const defaultColorKey = KorColorKey.gunluk;

  /// Icon of a routine that stores none.
  static const defaultIconKey = CategoryIconKeys.sun;

  static KorColorKey colorKeyOf(Routine routine) =>
      KorColorKey.tryParse(routine.colorKey ?? '') ?? defaultColorKey;

  static String iconKeyOf(Routine routine) {
    final key = routine.iconKey;
    return key != null && CategoryIcons.byKey.containsKey(key)
        ? key
        : defaultIconKey;
  }

  static IconData iconOf(Routine routine) =>
      CategoryIcons.of(iconKeyOf(routine));

  static CategoryColors colorsOf(BuildContext context, Routine routine) =>
      context.korColors.category(colorKeyOf(routine));

  /// "3 adım" or, with a repeat, "3 adım · Her gün" — the row's second line
  /// and the spoken details of [RoutineRow].
  static String details(Routine routine, AppLocalizations l10n) {
    final steps = l10n.routineStepCount(routine.itemCount);
    if (!routine.repeats) return steps;
    return '$steps · ${RecurrenceText.summary(routine.repeat, l10n)}';
  }

  /// One step's meta line: "07:00 · Sağlık · !! Orta · 2 madde"; a step
  /// without a time starts with "Saat yok". Times are spoken with
  /// [KorFormat.spokenTime] through [stepSpokenDetails].
  static String stepDetails(
    RoutineItem item,
    CategoryCatalog categories,
    AppLocalizations l10n, {
    bool spokenTime = false,
  }) {
    final time = item.time;
    // Only the clock matters; the date is an arbitrary reference.
    final at = time?.onDate(_timeReference);
    final parts = <String>[
      if (at == null)
        l10n.routineStepTimeNone
      else if (spokenTime)
        KorFormat.spokenTime(at, l10n)
      else
        KorFormat.time(at),
      CategoryVisuals.labelIn(categories, item.categoryId, l10n),
      if (item.hasPriority)
        l10n.prioritySpoken(PriorityPinVisuals.label(item.priority, l10n)),
      if (item.hasSubtasks) l10n.captureSplitCount(item.subtasks.length),
    ];
    return parts.join(' · ');
  }

  /// [stepDetails] for screen readers (spoken time, "saat 07:00").
  static String stepSpokenDetails(
    RoutineItem item,
    CategoryCatalog categories,
    AppLocalizations l10n,
  ) =>
      stepDetails(item, categories, l10n, spokenTime: true);

  /// Reference date for formatting a bare [RoutineTime] as `HH:mm`.
  static final DateTime _timeReference = DateTime(2000);
}

/// Round tonal badge of a routine (decorative), like [CategoryBadge].
class RoutineBadge extends StatelessWidget {
  const RoutineBadge({super.key, required this.routine, this.size = 40});

  final Routine routine;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = RoutineVisuals.colorsOf(context, routine);
    return IconBadge(
      icon: RoutineVisuals.iconOf(routine),
      foreground: colors.fg,
      background: colors.container,
      size: size,
    );
  }
}
