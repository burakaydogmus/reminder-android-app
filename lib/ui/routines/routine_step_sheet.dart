import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
import 'package:reminder/ui/reminders/subtasks_card.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class RoutineStepKeys {
  static const title = Key('routineStep.title');
  static const save = Key('routineStep.save');
  static const timeSwitch = Key('routineStep.timeSwitch');
  static const timeChip = Key('routineStep.timeChip');
  static const priority = Key('routineStep.priority');
  static Key category(String id) => Key('routineStep.category.$id');
}

/// Opens the routine step editor (F3.7) for a new step or for [existing] and
/// returns the edited step; `null` when dismissed.
///
/// The step is **not saved** here: the routine editor keeps it and writes
/// everything with its own "Kaydet" (like the reminder editor's subtasks).
Future<RoutineItem?> showRoutineStepSheet(
  BuildContext context, {
  RoutineItem? existing,
  String Function()? newId,
}) {
  return showModalBottomSheet<RoutineItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (_) => RoutineStepSheet(existing: existing, newId: newId),
  );
}

/// Body of [showRoutineStepSheet]: Başlık, "Saat ver" + saat, Kategori chips,
/// Öncelik and the shared "Maddeler" card — the same fields the reminder
/// editor uses, because a step is a reminder template.
class RoutineStepSheet extends StatefulWidget {
  const RoutineStepSheet({super.key, this.existing, this.newId});

  final RoutineItem? existing;

  /// Id factory for the step and its subtasks (tests); defaults to UUID v4.
  final String Function()? newId;

  /// Time a step gets when the user turns "Saat ver" on without picking one.
  static const RoutineTime defaultTime = RoutineTime(9, 0);

  @override
  State<RoutineStepSheet> createState() => _RoutineStepSheetState();
}

class _RoutineStepSheetState extends State<RoutineStepSheet> {
  late final TextEditingController _title;
  late bool _timed;
  late RoutineTime _time;
  late String _categoryId;
  late int _priority;
  late List<Subtask> _subtasks;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _timed = e?.time != null;
    _time = e?.time ?? RoutineStepSheet.defaultTime;
    _categoryId = e?.categoryId ?? ReminderCategoryIds.other;
    _priority = e?.priority ?? ReminderPriority.none;
    _subtasks = [...?e?.subtasks];
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _newId() => widget.newId?.call() ?? const Uuid().v4();

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time.hour, minute: _time.minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = RoutineTime(picked.hour, picked.minute);
      _timed = true;
    });
  }

  void _save() {
    final title = RoutineItem.normalizeTitle(_title.text);
    if (title.isEmpty) {
      setState(() => _titleError = context.l10n.editorTitleEmpty);
      return;
    }
    Navigator.of(context).pop(RoutineItem(
      id: widget.existing?.id ?? _newId(),
      title: title,
      time: _timed ? _time : null,
      categoryId: _categoryId,
      priority: _priority,
      subtasks: _subtasks,
      position: widget.existing?.position ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    final isNew = widget.existing == null;
    final categories = CategoryVisuals.catalogOf(context);
    final at = _time.onDate(DateTime(2000));

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
                isNew ? l10n.routineStepNew : l10n.routineStepEdit,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: KorSpacing.s5),
            TextField(
              key: RoutineStepKeys.title,
              controller: _title,
              autofocus: isNew,
              maxLength: RoutineItem.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _titleError = null),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.editorTitleLabel,
                hintText: l10n.routineStepTitleHint,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: KorSpacing.s4),
            SectionHeader(
              title: l10n.routineStepTime,
              icon: Icons.schedule_rounded,
            ),
            SwitchListTile.adaptive(
              key: RoutineStepKeys.timeSwitch,
              value: _timed,
              title: Text(l10n.routineStepTimeSwitch),
              subtitle: Text(l10n.routineStepTimeHint),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _timed = value),
            ),
            if (_timed)
              Align(
                alignment: AlignmentDirectional.centerStart,
                // §3.6 rule 11: a time in semantics is spoken "saat 07:30".
                child: Semantics(
                  button: true,
                  label: KorFormat.spokenTime(at, l10n),
                  excludeSemantics: true,
                  onTap: _pickTime,
                  child: ActionChip(
                    key: RoutineStepKeys.timeChip,
                    avatar: const Icon(Icons.schedule_rounded),
                    label: Text(KorFormat.time(at)),
                    tooltip: l10n.editorTimePick,
                    onPressed: _pickTime,
                  ),
                ),
              ),
            const SizedBox(height: KorSpacing.s5),
            SectionHeader(
              title: l10n.editorCategory,
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: KorSpacing.s2),
            Wrap(
              spacing: KorSpacing.s2,
              runSpacing: KorSpacing.s2,
              children: [
                for (final category in categories.ordered)
                  ChoiceChip(
                    key: RoutineStepKeys.category(category.id),
                    avatar: Icon(
                      CategoryVisuals.iconOf(category),
                      color: CategoryVisuals.colorsOf(context, category.id).fg,
                    ),
                    label: Text(CategoryVisuals.nameOf(category, l10n)),
                    selected: category.id == _categoryId,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s5),
            SectionHeader(
              title: l10n.editorPriority,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: KorSpacing.s2),
            SegmentedButton<int>(
              key: RoutineStepKeys.priority,
              segments: [
                for (final level in ReminderPriority.values)
                  ButtonSegment(
                    value: level,
                    label: Text(PriorityPinVisuals.label(level, l10n)),
                  ),
              ],
              selected: {_priority},
              showSelectedIcon: false,
              onSelectionChanged: (values) =>
                  setState(() => _priority = values.first),
            ),
            const SizedBox(height: KorSpacing.s5),
            SubtasksCard(
              subtasks: _subtasks,
              categoryId: _categoryId,
              newId: widget.newId,
              onChanged: (next) => setState(() => _subtasks = next),
            ),
            const SizedBox(height: KorSpacing.s6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: RoutineStepKeys.save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    KorSizes.minTouch * 2,
                    KorSizes.minTouch,
                  ),
                ),
                onPressed: _save,
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
