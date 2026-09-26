import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/routines/routine_apply_sheet.dart';
import 'package:reminder/ui/routines/routine_editor_sheet.dart';
import 'package:reminder/ui/routines/routine_visuals.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class RoutineListKeys {
  static const editToggle = Key('routines.editToggle');
  static const newRoutine = Key('routines.new');
  static const empty = Key('routines.empty');
  static Key row(String id) => Key('routines.row.$id');
  static Key editRow(String id) => Key('routines.editRow.$id');
  static Key handle(String id) => Key('routines.handle.$id');
}

/// Listeler › Rutinlerim (§3.3.6, F3.7): the user's routines in their order,
/// "+ Yeni rutin" and a "Düzenle" mode — the same shape as Kategorilerim, so
/// the tab keeps one information architecture instead of growing a new tab.
///
/// - Normal mode: a row opens the **apply** sheet (that is what a routine is
///   for), showing the step count and, for a repeating routine, its repeat
///   summary.
/// - Düzenle: a `ReorderableListView` with ≡ handles (its items expose the
///   localized "Yukarı taşı / Aşağı taşı" semantics actions, the non-drag
///   alternative); tapping a row opens the routine editor.
class RoutineListSection extends StatefulWidget {
  const RoutineListSection({super.key});

  @override
  State<RoutineListSection> createState() => _RoutineListSectionState();
}

class _RoutineListSectionState extends State<RoutineListSection> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final routines = context.select<ReminderCubit, List<Routine>>(
      (cubit) => cubit.state.routines,
    );
    final editing = _editing && routines.isNotEmpty;

    return GroupedCard(
      title: context.l10n.routinesTitle,
      padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
      headerTrailing: routines.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: KorSpacing.s3),
              child: TextButton(
                key: RoutineListKeys.editToggle,
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(
                  editing ? context.l10n.actionFinish : context.l10n.actionEdit,
                ),
              ),
            ),
      children: [
        if (routines.isEmpty)
          Padding(
            key: RoutineListKeys.empty,
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s5,
              vertical: KorSpacing.s2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.routinesEmpty,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: KorSpacing.s1),
                Text(
                  context.l10n.routinesEmptyHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else if (editing)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorderItem: (from, to) =>
                context.read<ReminderCubit>().moveRoutine(from, to),
            // §3.1 Haptik: lift medium, drop light (F4.7).
            onReorderStart: (_) => KorHaptics.of(context).reorderPickUp(),
            onReorderEnd: (_) => KorHaptics.of(context).reorderDrop(),
            children: [
              for (final (index, routine) in routines.indexed)
                _EditRow(
                  key: RoutineListKeys.editRow(routine.id),
                  routine: routine,
                  index: index,
                ),
            ],
          )
        else
          for (final routine in routines)
            _RoutineRow(
              key: RoutineListKeys.row(routine.id),
              routine: routine,
            ),
        Semantics(
          button: true,
          label: context.l10n.routineNew,
          excludeSemantics: true,
          onTap: () => showRoutineEditorSheet(context),
          child: InkWell(
            key: RoutineListKeys.newRoutine,
            onTap: () => showRoutineEditorSheet(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KorSpacing.s5,
                  vertical: KorSpacing.s3,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: Icon(Icons.add_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: KorSpacing.s4),
                    Expanded(
                      child: Text(
                        context.l10n.routineNew,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 56 dp row: badge, name, "3 adım · Her gün", chevron. One button node
/// ("Sabah rutini, 3 adım · Her gün") that opens the apply sheet.
class _RoutineRow extends StatelessWidget {
  const _RoutineRow({super.key, required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final details = RoutineVisuals.details(routine, l10n);
    void open() => showRoutineApplySheet(context, routine: routine);

    return Semantics(
      button: true,
      label: l10n.routineRowSpoken(routine.name, details),
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s5,
              vertical: KorSpacing.s3,
            ),
            child: Row(
              children: [
                RoutineBadge(routine: routine),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(routine.name, style: theme.textTheme.bodyLarge),
                      Text(
                        details,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KorSpacing.s2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Düzenle row: badge, name, edit button, ≡ handle.
class _EditRow extends StatelessWidget {
  const _EditRow({super.key, required this.routine, required this.index});

  final Routine routine;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void edit() => showRoutineEditorSheet(context, existing: routine);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: edit,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.only(
              left: KorSpacing.s5,
              right: KorSpacing.s3,
            ),
            child: Row(
              children: [
                RoutineBadge(routine: routine),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Text(routine.name, style: theme.textTheme.bodyLarge),
                ),
                IconButton(
                  tooltip: context.l10n.routineEditTooltip(routine.name),
                  onPressed: edit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                ReorderableDragStartListener(
                  key: RoutineListKeys.handle(routine.id),
                  index: index,
                  child: Semantics(
                    label: context.l10n.routineMoveSpoken(routine.name),
                    child: SizedBox.square(
                      dimension: KorSizes.minTouch,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
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
