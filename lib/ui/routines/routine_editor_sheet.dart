import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/recurrence_text.dart';
import 'package:reminder/ui/common/weekday_toggle.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/routines/routine_step_sheet.dart';
import 'package:reminder/ui/routines/routine_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/util/dialog.dart';

/// Keys for tests.
abstract final class RoutineEditorKeys {
  static const name = Key('routineEditor.name');
  static const save = Key('routineEditor.save');
  static const delete = Key('routineEditor.delete');
  static const addStep = Key('routineEditor.addStep');
  static const repeatSegments = Key('routineEditor.repeat');
  static Key swatch(KorColorKey key) => Key('routineEditor.swatch.${key.name}');
  static Key icon(String key) => Key('routineEditor.icon.$key');
  static Key step(String id) => Key('routineEditor.step.$id');
  static Key stepMenu(String id) => Key('routineEditor.stepMenu.$id');
  static Key stepHandle(String id) => Key('routineEditor.stepHandle.$id');
  static Key weekday(int weekday) => Key('routineEditor.weekday.$weekday');
}

/// Repeat choices the editor offers (F3.7); everything else a stored rule may
/// hold is kept as it is and passed to the created reminders.
enum RoutineRepeatMode { off, daily, weekly }

/// Opens the routine editor sheet (F3.7) for a new routine or for [existing].
///
/// Saves through [ReminderCubit.saveRoutine] and returns the saved routine;
/// `null` when dismissed or deleted. Deleting a routine never touches the
/// reminders it already created.
Future<Routine?> showRoutineEditorSheet(
  BuildContext context, {
  Routine? existing,
}) {
  return showModalBottomSheet<Routine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (_) => RoutineEditorSheet(existing: existing),
  );
}

/// Body of [showRoutineEditorSheet]: live preview, Ad, Renk, İkon, "Otomatik
/// uygula" (Yok / Her gün / Seçili günler) and the ordered steps,
/// [Sil] · [Kaydet].
///
/// Steps are edited in [showRoutineStepSheet] and reordered with a
/// `ReorderableListView` (handle only; the ⋮ menu is the single-pointer
/// alternative, WCAG 2.5.7). Nothing is written before "Kaydet".
class RoutineEditorSheet extends StatefulWidget {
  const RoutineEditorSheet({super.key, this.existing, this.newId});

  final Routine? existing;

  /// Id factory for the routine and its steps (tests); defaults to UUID v4.
  final String Function()? newId;

  /// Default colour of a new routine.
  static const KorColorKey defaultColor = RoutineVisuals.defaultColorKey;

  /// Default icon of a new routine.
  static const String defaultIcon = RoutineVisuals.defaultIconKey;

  /// Validation message for [name], `null` when it can be saved: not empty and
  /// no other routine with the same folded name (case and Turkish diacritics
  /// ignored).
  static String? validateName(
    String name,
    List<Routine> routines,
    AppLocalizations l10n, {
    String? exceptId,
  }) {
    final normalized = Routine.normalizeName(name);
    if (normalized.isEmpty) return l10n.routineNameEmpty;
    if (routines.byFoldedName(normalized, exceptId: exceptId) != null) {
      return l10n.routineNameTaken;
    }
    return null;
  }

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  late final TextEditingController _name;
  late KorColorKey _color;
  late String _icon;
  late List<RoutineItem> _items;
  late RoutineRepeatMode _repeatMode;
  late List<int> _weekdays;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _color = e == null
        ? RoutineEditorSheet.defaultColor
        : RoutineVisuals.colorKeyOf(e);
    _icon = e == null
        ? RoutineEditorSheet.defaultIcon
        : RoutineVisuals.iconKeyOf(e);
    _items = [...?e?.items];
    final repeat = e?.repeat ?? RecurrenceRule.none;
    _repeatMode = switch (repeat.frequency) {
      RecurrenceFrequency.none => RoutineRepeatMode.off,
      RecurrenceFrequency.weekly => RoutineRepeatMode.weekly,
      _ => RoutineRepeatMode.daily,
    };
    _weekdays = repeat.weekdays.isEmpty ? [] : [...repeat.weekdays];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _newId() => widget.newId?.call() ?? const Uuid().v4();

  RecurrenceRule get _repeat => switch (_repeatMode) {
        RoutineRepeatMode.off => RecurrenceRule.none,
        RoutineRepeatMode.daily => RecurrenceRule.daily(),
        // An empty weekday set means "the reminder's own day"
        // (`RecurrenceRule.weekly`), so the rule stays valid either way.
        RoutineRepeatMode.weekly => RecurrenceRule.weekly(_weekdays),
      };

  Routine _draft() => Routine(
        id: widget.existing?.id ?? 'draft',
        name: Routine.normalizeName(_name.text),
        colorKey: _color.storageKey,
        iconKey: _icon,
        items: _items,
        repeat: _repeat,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        position: widget.existing?.position ?? 0,
      );

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final error = RoutineEditorSheet.validateName(
      _name.text,
      cubit.state.routines,
      context.l10n,
      exceptId: widget.existing?.id,
    );
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    final routine = _draft().copyWith(id: widget.existing?.id ?? _newId());
    await cubit.saveRoutine(routine);
    if (!mounted) return;
    Navigator.of(context).pop(cubit.state.routines.byId(routine.id));
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final cubit = context.read<ReminderCubit>();
    final l10n = context.l10n;
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.routineDeleteTitle(existing.name),
      content: l10n.routineDeleteContent,
    );
    if (!confirmed || !mounted) return;
    await cubit.deleteRoutine(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _editStep([RoutineItem? existing]) async {
    final item = await showRoutineStepSheet(
      context,
      existing: existing,
      newId: widget.newId,
    );
    if (item == null || !mounted) return;
    setState(() =>
        _items = existing == null ? _items.added(item) : _items.updated(item));
  }

  void _moveStep(String id, int delta) {
    setState(() => _items = _items.moved(id, delta));
  }

  void _removeStep(String id) {
    setState(() => _items = _items.removed(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final isNew = widget.existing == null;
    final l10n = context.l10n;
    final draft = _draft();
    final categories = CategoryVisuals.catalogOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
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
            Semantics(
              header: true,
              child: Text(
                isNew ? l10n.routineNew : l10n.routineEdit,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: KorSpacing.s5),
            _RoutinePreview(routine: draft),
            const SizedBox(height: KorSpacing.s5),
            TextField(
              key: RoutineEditorKeys.name,
              controller: _name,
              autofocus: isNew,
              maxLength: Routine.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _nameError = null),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.categoryNameLabel,
                hintText: l10n.routineNameHint,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: KorSpacing.s4),
            SectionHeader(
              title: l10n.categoryColor,
              icon: Icons.palette_outlined,
            ),
            _Grid(
              children: [
                for (final key in KorColorKey.values)
                  ColorSwatchButton(
                    key: RoutineEditorKeys.swatch(key),
                    colorKey: key,
                    selected: key == _color,
                    onTap: () => setState(() => _color = key),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s5),
            SectionHeader(
              title: l10n.categoryIcon,
              icon: Icons.category_outlined,
            ),
            _Grid(
              children: [
                for (final key in CategoryIconKeys.all)
                  _IconCell(
                    key: RoutineEditorKeys.icon(key),
                    iconKey: key,
                    colors: context.korColors.category(_color),
                    selected: key == _icon,
                    onTap: () => setState(() => _icon = key),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s6),
            SectionHeader(
              title: l10n.routineRepeatTitle,
              icon: Icons.repeat_rounded,
            ),
            const SizedBox(height: KorSpacing.s2),
            Text(
              l10n.routineRepeatHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KorSpacing.s3),
            SegmentedButton<RoutineRepeatMode>(
              key: RoutineEditorKeys.repeatSegments,
              segments: [
                ButtonSegment(
                  value: RoutineRepeatMode.off,
                  label: Text(l10n.routineRepeatOff),
                ),
                ButtonSegment(
                  value: RoutineRepeatMode.daily,
                  label: Text(l10n.routineRepeatDaily),
                ),
                ButtonSegment(
                  value: RoutineRepeatMode.weekly,
                  label: Text(l10n.routineRepeatWeekly),
                ),
              ],
              selected: {_repeatMode},
              showSelectedIcon: false,
              onSelectionChanged: (values) =>
                  setState(() => _repeatMode = values.first),
            ),
            if (_repeatMode == RoutineRepeatMode.weekly) ...[
              const SizedBox(height: KorSpacing.s4),
              Text(l10n.recurrenceDays, style: theme.textTheme.titleSmall),
              const SizedBox(height: KorSpacing.s3),
              Wrap(
                spacing: KorSpacing.s2,
                runSpacing: KorSpacing.s2,
                children: [
                  for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                    WeekdayToggle(
                      key: RoutineEditorKeys.weekday(d),
                      weekday: d,
                      selected: _weekdays.contains(d),
                      onTap: () => setState(() {
                        _weekdays = _weekdays.contains(d)
                            ? [..._weekdays.where((v) => v != d)]
                            : [..._weekdays, d];
                      }),
                    ),
                ],
              ),
            ],
            if (_repeatMode != RoutineRepeatMode.off) ...[
              const SizedBox(height: KorSpacing.s3),
              Text(
                '${RecurrenceText.summary(_repeat, l10n)}\n'
                '${l10n.routineRepeatNoTimeNote}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: KorSpacing.s6),
            SectionHeader(
              title: l10n.routineStepsTitle,
              icon: Icons.checklist_rounded,
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
                child: Text(
                  l10n.routineStepsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                onReorderItem: (from, to) =>
                    setState(() => _items = _items.reordered(from, to)),
                onReorderStart: (_) => KorHaptics.of(context).reorderPickUp(),
                onReorderEnd: (_) => KorHaptics.of(context).reorderDrop(),
                children: [
                  for (final (index, item) in _items.indexed)
                    _StepRow(
                      key: RoutineEditorKeys.step(item.id),
                      item: item,
                      index: index,
                      categories: categories,
                      onTap: () => _editStep(item),
                      onMove: (delta) => _moveStep(item.id, delta),
                      onDelete: () => _removeStep(item.id),
                    ),
                ],
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: RoutineEditorKeys.addStep,
                style: TextButton.styleFrom(
                  minimumSize: const Size(KorSizes.minTouch, KorSizes.minTouch),
                ),
                onPressed: _editStep,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.routineStepAdd),
              ),
            ),
            const SizedBox(height: KorSpacing.s6),
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                if (!isNew)
                  TextButton.icon(
                    key: RoutineEditorKeys.delete,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      minimumSize: const Size(
                        KorSizes.minTouch,
                        KorSizes.minTouch,
                      ),
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.actionDelete),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  key: RoutineEditorKeys.save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      KorSizes.minTouch * 2,
                      KorSizes.minTouch,
                    ),
                  ),
                  onPressed: _save,
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview: the routine as a tonal pill (icon `fg`, name `onContainer`).
class _RoutinePreview extends StatelessWidget {
  const _RoutinePreview({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = RoutineVisuals.colorsOf(context, routine);
    final l10n = context.l10n;
    final name = routine.name.isEmpty ? l10n.routineNew : routine.name;
    return Semantics(
      label: '$name, ${RoutineVisuals.details(routine, l10n)}',
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.container,
            borderRadius: KorRadius.fullAll,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s5,
              vertical: KorSpacing.s3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(RoutineVisuals.iconOf(routine), color: colors.fg),
                const SizedBox(width: KorSpacing.s3),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onContainer,
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

enum _StepAction { up, down, delete }

/// One step row: title, meta line, ⋮ menu (Yukarı taşı / Aşağı taşı / Sil) and
/// a drag handle. Tapping the row edits the step.
class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.item,
    required this.index,
    required this.categories,
    required this.onTap,
    required this.onMove,
    required this.onDelete,
  });

  final RoutineItem item;
  final int index;
  final CategoryCatalog categories;
  final VoidCallback onTap;
  final ValueChanged<int> onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final details = RoutineVisuals.stepDetails(item, categories, l10n);
    final spoken = RoutineVisuals.stepSpokenDetails(item, categories, l10n);

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        button: true,
        label: l10n.routineStepRowSpoken(item.title, spoken),
        onTap: onTap,
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.subtaskMoveUp): () => onMove(-1),
          CustomSemanticsAction(label: l10n.subtaskMoveDown): () => onMove(1),
          CustomSemanticsAction(label: l10n.actionDelete): onDelete,
        },
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.title, style: theme.textTheme.bodyLarge),
                        Text(
                          details,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_StepAction>(
                    key: RoutineEditorKeys.stepMenu(item.id),
                    tooltip: l10n.routineStepActions,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (action) => switch (action) {
                      _StepAction.up => onMove(-1),
                      _StepAction.down => onMove(1),
                      _StepAction.delete => onDelete(),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _StepAction.up,
                        child: Text(l10n.subtaskMoveUp),
                      ),
                      PopupMenuItem(
                        value: _StepAction.down,
                        child: Text(l10n.subtaskMoveDown),
                      ),
                      PopupMenuItem(
                        value: _StepAction.delete,
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                  ReorderableDragStartListener(
                    key: RoutineEditorKeys.stepHandle(item.id),
                    index: index,
                    child: Semantics(
                      label: l10n.routineStepMoveSpoken(item.title),
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
      ),
    );
  }
}

/// Rows of six 48 dp cells (same grid as the category editor).
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const columns = CategoryEditorSheet.columns;
    return Column(
      children: [
        for (var i = 0; i < children.length; i += columns)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var j = i; j < i + columns; j++)
                j < children.length
                    ? children[j]
                    : const SizedBox.square(dimension: KorSizes.minTouch),
            ],
          ),
      ],
    );
  }
}

/// One icon choice in a 48 dp cell; selected → tonal circle, `fg` icon and a
/// 2 px `fg` ring (same visual as the category editor's icon grid).
class _IconCell extends StatelessWidget {
  const _IconCell({
    super.key,
    required this.iconKey,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final CategoryColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: CategoryIcons.spokenName(iconKey, context.l10n),
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: KorSizes.minTouch / 2,
        child: Container(
          width: KorSizes.minTouch,
          height: KorSizes.minTouch,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.container : null,
            border: selected ? Border.all(color: colors.fg, width: 2) : null,
          ),
          child: Icon(
            CategoryIcons.of(iconKey),
            color: selected ? colors.fg : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
