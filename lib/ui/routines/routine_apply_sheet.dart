import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/routine_apply.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/routines/routine_editor_sheet.dart';
import 'package:reminder/ui/routines/routine_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class RoutineApplyKeys {
  static const apply = Key('routineApply.apply');
  static const anyway = Key('routineApply.anyway');
  static const day = Key('routineApply.day');
  static const warning = Key('routineApply.warning');
  static const edit = Key('routineApply.edit');
  static Key step(String id) => Key('routineApply.step.$id');
}

/// Opens the "Rutini uygula" sheet (F3.7) for [routine].
///
/// [now] is the clock (default: `NowScope`); the chosen day starts at today.
Future<void> showRoutineApplySheet(
  BuildContext context, {
  required Routine routine,
  DateTime Function()? now,
}) {
  final clock = now ?? NowScope.clockOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (_) => RoutineApplySheet(routine: routine, now: clock),
  );
}

/// Body of [showRoutineApplySheet]: the day (default today, any day can be
/// picked), the steps that would be created and — when the routine was already
/// applied — the duplicate choice.
///
/// **Duplicate rule** (`RoutineApplyPlan.from`): a step whose reminder this
/// routine already created counts as a duplicate; for a repeating routine the
/// whole series counts, whatever day it sits on. The user then either updates
/// the existing reminders ([RoutineApplyMode.replaceExisting], repeating
/// routines), adds only the new steps ([RoutineApplyMode.onlyNew]) or adds
/// everything anyway ([RoutineApplyMode.addAll]). Nothing is ever duplicated
/// silently.
class RoutineApplySheet extends StatefulWidget {
  const RoutineApplySheet({
    super.key,
    required this.routine,
    required this.now,
  });

  final Routine routine;
  final DateTime Function() now;

  @override
  State<RoutineApplySheet> createState() => _RoutineApplySheetState();
}

class _RoutineApplySheetState extends State<RoutineApplySheet> {
  DateTime? _day;

  DateTime get _date {
    final now = widget.now();
    return _day ?? DateTime(now.year, now.month, now.day);
  }

  bool get _isToday {
    final now = widget.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  Future<void> _pickDay() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _apply(RoutineApplyMode mode) async {
    final cubit = context.read<ReminderCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final outcome = await cubit.applyRoutine(
      widget.routine,
      date: _date,
      mode: mode,
    );
    navigator.pop();
    final message = switch (outcome) {
      RoutineApplyOutcome(created: [], updated: []) => l10n.routineApplyNothing,
      RoutineApplyOutcome(created: []) =>
        l10n.routineAppliedUpdated(outcome.updated.length),
      _ => l10n.routineApplied(outcome.created.length),
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;
    final routine = context.select<ReminderCubit, Routine>(
      (cubit) => cubit.state.routines.byId(widget.routine.id) ?? widget.routine,
    );
    final plan = context.select<ReminderCubit, RoutineApplyPlan>(
      (cubit) => cubit.planRoutine(routine, date: _date),
    );
    final categories = CategoryVisuals.catalogOf(context);
    final dayLabel = _isToday
        ? l10n.dayToday
        : KorFormat.dayMonth(_date, widget.now(), l10n);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        KorSpacing.s5,
        0,
        KorSpacing.s5,
        KorSpacing.s5 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RoutineBadge(routine: routine),
              const SizedBox(width: KorSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        routine.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      RoutineVisuals.details(routine, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: RoutineApplyKeys.edit,
                tooltip: l10n.routineEditTooltip(routine.name),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final updated =
                      await showRoutineEditorSheet(context, existing: routine);
                  if (updated == null && mounted) navigator.pop();
                },
                icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: KorSpacing.s5),
          SectionHeader(
            title: l10n.routineApplyDay,
            icon: Icons.event_rounded,
          ),
          const SizedBox(height: KorSpacing.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              label: l10n.routineApplyDaySpoken(dayLabel),
              excludeSemantics: true,
              onTap: _pickDay,
              child: ActionChip(
                key: RoutineApplyKeys.day,
                avatar: const Icon(Icons.event_rounded),
                label: Text(dayLabel),
                tooltip: l10n.editorDatePick,
                onPressed: _pickDay,
              ),
            ),
          ),
          const SizedBox(height: KorSpacing.s5),
          if (plan.isEmpty)
            Text(
              l10n.routineApplyEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (plan.hasDuplicates)
              _Warning(
                key: RoutineApplyKeys.warning,
                title: routine.repeats
                    ? l10n.routineApplySeriesTitle
                    : _isToday
                        ? l10n.routineApplyDuplicateToday
                        : l10n.routineApplyDuplicateOnDay(dayLabel),
                body: routine.repeats
                    ? l10n.routineApplySeriesBody
                    : l10n.routineApplyDuplicateBody(plan.duplicates.length),
              ),
            if (plan.hasDuplicates) const SizedBox(height: KorSpacing.s4),
            SectionHeader(
              title: l10n.routineStepsTitle,
              icon: Icons.checklist_rounded,
            ),
            for (final entry in plan.entries)
              _StepPreview(
                key: RoutineApplyKeys.step(entry.item.id),
                entry: entry,
                categories: categories,
              ),
          ],
          const SizedBox(height: KorSpacing.s6),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: KorSpacing.s3,
            children: [
              if (plan.hasDuplicates)
                TextButton(
                  key: RoutineApplyKeys.anyway,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      KorSizes.minTouch,
                      KorSizes.minTouch,
                    ),
                  ),
                  onPressed: () => _apply(RoutineApplyMode.addAll),
                  child: Text(l10n.routineApplyAnyway),
                ),
              FilledButton(
                key: RoutineApplyKeys.apply,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    KorSizes.minTouch * 2,
                    KorSizes.minTouch,
                  ),
                ),
                onPressed: plan.isEmpty || (!plan.hasNew && !plan.hasLinked)
                    ? null
                    : () => _apply(
                          plan.hasLinked && routine.repeats
                              ? RoutineApplyMode.replaceExisting
                              : RoutineApplyMode.onlyNew,
                        ),
                child: Text(
                  plan.hasLinked && routine.repeats
                      ? l10n.routineApplyUpdate
                      : plan.hasDuplicates
                          ? l10n.routineApplyOnlyNew
                          : l10n.routineApplyAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning block (icon + title + sentence); state is never colour alone.
class _Warning extends StatelessWidget {
  const _Warning({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      label: '$title. $body',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(KorSpacing.s4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KorSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: KorSizes.iconSm,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: KorSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: KorSpacing.s1),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One planned step: title, meta line and, for a duplicate, a "zaten var"
/// marker (icon + text, never colour alone).
class _StepPreview extends StatelessWidget {
  const _StepPreview({
    super.key,
    required this.entry,
    required this.categories,
  });

  final RoutineApplyEntry entry;
  final CategoryCatalog categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final item = entry.item;
    final details = RoutineVisuals.stepDetails(item, categories, l10n);
    final spoken = RoutineVisuals.stepSpokenDetails(item, categories, l10n);
    final already = entry.isDuplicate ? l10n.routineApplyStepAlready : null;

    return Semantics(
      label: l10n.routineStepRowSpoken(
        item.title,
        already == null ? spoken : '$spoken, $already',
      ),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
          child: Row(
            children: [
              Icon(
                entry.isDuplicate
                    ? Icons.check_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: KorSizes.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: KorSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title, style: theme.textTheme.bodyLarge),
                    Text(
                      already == null ? details : '$details · $already',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
