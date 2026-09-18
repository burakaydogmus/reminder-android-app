import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/subtask_progress.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class SubtasksCardKeys {
  static const addField = Key('subtasks.add');
  static const splitSuggestion = Key('subtasks.split');
  static const progress = Key('subtasks.progress');
  static const doneToggle = Key('subtasks.doneToggle');
  static const completeSuggestion = Key('subtasks.completeSuggestion');
  static Key row(String id) => ValueKey('subtasks.row.$id');
  static Key check(String id) => ValueKey('subtasks.check.$id');
  static Key field(String id) => ValueKey('subtasks.field.$id');
  static Key menu(String id) => ValueKey('subtasks.menu.$id');
  static Key handle(String id) => ValueKey('subtasks.handle.$id');
}

enum _RowAction { up, down, delete }

/// "Maddeler" card of the reminder editor (§3.3.4, F3.3).
///
/// - Header "Maddeler" with "2/6" and a 6 px progress bar in the category
///   colour.
/// - Open items first, in order: a 48 dp circle toggle, the title edited in
///   place, a row menu (Yukarı taşı / Aşağı taşı / Sil) and a drag handle.
///   Reordering is `ReorderableListView` (drag the handle); its items also
///   carry the "Yukarı taşı / Aşağı taşı" semantics actions, and the menu is
///   the single-pointer alternative (WCAG 2.5.7). Deleting is menu only (no
///   swipe).
/// - "+ Madde ekle": Enter adds the item and keeps the field focused for the
///   next one; pasting several lines adds one item per line. When the text
///   reads like a list ("süt, ekmek ve yumurta"), a "Maddelere böl" button
///   splits it with [splitSubtaskText].
/// - Completed items sit under a collapsible "Tamamlanan N madde".
/// - When every item is done and [onCompleteReminder] is given, a suggestion
///   chip offers to complete the reminder; nothing is completed
///   automatically.
///
/// The card edits a list it doesn't own: every change goes to [onChanged]
/// and the editor saves it with the reminder.
class SubtasksCard extends StatefulWidget {
  const SubtasksCard({
    super.key,
    required this.subtasks,
    required this.onChanged,
    required this.categoryId,
    this.onCompleteReminder,
    this.newId,
  });

  final List<Subtask> subtasks;
  final ValueChanged<List<Subtask>> onChanged;
  final String categoryId;

  /// Shown as "Tümü tamam — hatırlatıcıyı tamamla?" when every item is done.
  final VoidCallback? onCompleteReminder;

  /// Id factory for new items (tests); defaults to UUID v4.
  final String Function()? newId;

  @override
  State<SubtasksCard> createState() => _SubtasksCardState();
}

class _SubtasksCardState extends State<SubtasksCard> {
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode(debugLabel: 'subtasks.add');
  final Map<String, TextEditingController> _titleCtrls = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _showDone = false;

  List<Subtask> get _items => widget.subtasks;

  @override
  void didUpdateWidget(SubtasksCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = {for (final s in _items) s.id};
    for (final id in [..._titleCtrls.keys]) {
      if (ids.contains(id)) continue;
      _titleCtrls.remove(id)!.dispose();
      _focusNodes.remove(id)?.dispose();
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _addFocus.dispose();
    for (final c in _titleCtrls.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _newId() => widget.newId?.call() ?? const Uuid().v4();

  TextEditingController _controllerFor(Subtask s) {
    final controller = _titleCtrls.putIfAbsent(
      s.id,
      () => TextEditingController(text: s.title),
    );
    // Follow outside changes (e.g. a split), never while the user types.
    if (controller.text != s.title && !_focusFor(s.id).hasFocus) {
      controller.text = s.title;
    }
    return controller;
  }

  FocusNode _focusFor(String id) =>
      _focusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'subtask.$id'));

  void _emit(List<Subtask> next) => widget.onChanged(next);

  /// Open items reordered by [reorder], done items after them.
  void _reorderOpen(List<Subtask> Function(List<Subtask> open) reorder) {
    _emit(SubtaskList.inOrder([...reorder(_items.open), ..._items.done]));
  }

  void _add(List<String> titles) {
    if (titles.isEmpty) return;
    _emit(_items.addedAll([
      for (final title in titles) Subtask(id: _newId(), title: title),
    ]));
  }

  void _commitAddField({bool splitAll = false}) {
    final text = _addCtrl.text;
    _add(splitAll ? splitSubtaskText(text) : splitSubtaskLines(text));
    _addCtrl.clear();
    setState(() {});
    _addFocus.requestFocus();
  }

  void _onAddChanged(String text) {
    // A pasted multi-line text (or a hardware Enter) arrives as newlines.
    if (text.contains('\n') || text.contains('\r')) {
      _commitAddField();
    } else {
      setState(() {});
    }
  }

  void _onTitleChanged(Subtask s, String text) {
    if (!text.contains('\n') && !text.contains('\r')) {
      _emit(_items.renamed(s.id, text));
      return;
    }
    // Several lines pasted into an item: the first stays, the rest follow.
    final lines = splitSubtaskLines(text);
    final first = lines.isEmpty ? '' : lines.first;
    _titleCtrls[s.id]?.text = first;
    final index = _items.indexWhere((e) => e.id == s.id);
    _emit(
      _items.renamed(s.id, first).addedAll(
        [for (final t in lines.skip(1)) Subtask(id: _newId(), title: t)],
        index: index + 1,
      ),
    );
  }

  void _onRowAction(Subtask s, _RowAction action) {
    switch (action) {
      case _RowAction.up:
        _reorderOpen((open) => open.moved(s.id, -1));
      case _RowAction.down:
        _reorderOpen((open) => open.moved(s.id, 1));
      case _RowAction.delete:
        _emit(_items.removed(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = CategoryVisuals.colorsOf(context, widget.categoryId);
    final open = _items.open;
    final done = _items.done;
    final showSplit =
        looksLikeSubtaskList(_addCtrl.text) && !_addCtrl.text.contains('\n');

    return GroupedCard(
      icon: Icons.checklist_rounded,
      title: 'Maddeler',
      headerTrailing: _items.isEmpty
          ? null
          : Semantics(
              label: SubtaskProgressText.spoken(_items),
              excludeSemantics: true,
              child: Text(
                SubtaskProgressText.count(_items),
                key: SubtasksCardKeys.progress,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
      children: [
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KorSpacing.s3),
            child: SubtaskProgressBar(subtasks: _items, color: category.fg),
          ),
        if (widget.onCompleteReminder != null && _items.allDone)
          Padding(
            padding: const EdgeInsets.only(bottom: KorSpacing.s3),
            child: Semantics(
              liveRegion: true,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionChip(
                  key: SubtasksCardKeys.completeSuggestion,
                  avatar: Icon(Icons.task_alt_rounded, color: category.fg),
                  label: const Text('Tümü tamam — hatırlatıcıyı tamamla?'),
                  onPressed: widget.onCompleteReminder,
                ),
              ),
            ),
          ),
        if (open.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorderItem: (from, to) =>
                _reorderOpen((items) => items.reordered(from, to)),
            // §3.1 Haptik: lift medium, drop light (F4.7).
            onReorderStart: (_) => KorHaptics.of(context).reorderPickUp(),
            onReorderEnd: (_) => KorHaptics.of(context).reorderDrop(),
            children: [
              for (final (index, s) in open.indexed)
                _SubtaskRow(
                  key: SubtasksCardKeys.row(s.id),
                  subtask: s,
                  index: index,
                  isFirst: index == 0,
                  isLast: index == open.length - 1,
                  color: category.fg,
                  onColor: category.onFg,
                  controller: _controllerFor(s),
                  focusNode: _focusFor(s.id),
                  onToggle: () => _emit(_items.toggled(s.id)),
                  onChanged: (text) => _onTitleChanged(s, text),
                  onSubmitted: () => _addFocus.requestFocus(),
                  onAction: (action) => _onRowAction(s, action),
                ),
            ],
          ),
        _AddRow(
          controller: _addCtrl,
          focusNode: _addFocus,
          showSplit: showSplit,
          onChanged: _onAddChanged,
          onSubmitted: _commitAddField,
          onSplit: () => _commitAddField(splitAll: true),
        ),
        if (done.isNotEmpty) ...[
          _DoneHeader(
            count: done.length,
            expanded: _showDone,
            onTap: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone)
            for (final s in done)
              _SubtaskRow(
                key: SubtasksCardKeys.row(s.id),
                subtask: s,
                color: category.fg,
                onColor: category.onFg,
                controller: _controllerFor(s),
                focusNode: _focusFor(s.id),
                onToggle: () => _emit(_items.toggled(s.id)),
                onChanged: (text) => _onTitleChanged(s, text),
                onSubmitted: () => _addFocus.requestFocus(),
                onAction: (action) => _onRowAction(s, action),
              ),
        ],
      ],
    );
  }
}

/// One item: toggle, inline title, menu and (open items) drag handle.
class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    super.key,
    required this.subtask,
    this.index,
    this.isFirst = true,
    this.isLast = true,
    required this.color,
    required this.onColor,
    required this.controller,
    required this.focusNode,
    required this.onToggle,
    required this.onChanged,
    required this.onSubmitted,
    required this.onAction,
  });

  final Subtask subtask;

  /// Index in the reorderable (open) list; `null` for done items.
  final int? index;
  final bool isFirst;
  final bool isLast;
  final Color color;
  final Color onColor;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final ValueChanged<_RowAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = subtask.isDone;
    final reorderable = index != null;
    final title = subtask.title.trim().isEmpty ? 'Madde' : subtask.title.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
      child: Row(
        children: [
          _SubtaskCheck(
            key: SubtasksCardKeys.check(subtask.id),
            done: done,
            title: title,
            color: color,
            onColor: onColor,
            onTap: onToggle,
          ),
          const SizedBox(width: KorSpacing.s2),
          Expanded(
            child: TextField(
              key: SubtasksCardKeys.field(subtask.id),
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
              // Keep focus handling in onSubmitted (no default next/unfocus).
              onEditingComplete: () {},
              onSubmitted: (_) => onSubmitted(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: done ? scheme.onSurfaceVariant : null,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              decoration: const InputDecoration.collapsed(hintText: 'Madde'),
            ),
          ),
          PopupMenuButton<_RowAction>(
            key: SubtasksCardKeys.menu(subtask.id),
            tooltip: '$title seçenekleri',
            icon: Icon(
              Icons.more_vert_rounded,
              color: scheme.onSurfaceVariant,
            ),
            onSelected: onAction,
            itemBuilder: (context) => [
              if (reorderable) ...[
                PopupMenuItem(
                  value: _RowAction.up,
                  enabled: !isFirst,
                  child: const Text('Yukarı taşı'),
                ),
                PopupMenuItem(
                  value: _RowAction.down,
                  enabled: !isLast,
                  child: const Text('Aşağı taşı'),
                ),
              ],
              const PopupMenuItem(
                value: _RowAction.delete,
                child: Text('Sil'),
              ),
            ],
          ),
          if (reorderable)
            // Pointer-only; the menu and the list's semantics actions are
            // the alternatives.
            ExcludeSemantics(
              child: ReorderableDragStartListener(
                key: SubtasksCardKeys.handle(subtask.id),
                index: index!,
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
    );
  }
}

/// 48 dp circle toggle of an item (visual 22 px, like compact rows).
class _SubtaskCheck extends StatelessWidget {
  const _SubtaskCheck({
    super.key,
    required this.done,
    required this.title,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final bool done;
  final String title;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  static const double _visual = 22;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : context.korMotion.short;
    return Semantics(
      container: true,
      checked: done,
      label: title,
      hint: done ? 'Geri açmak için dokun' : 'Tamamlamak için dokun',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: KorSizes.minTouch / 2,
        child: SizedBox.square(
          dimension: KorSizes.minTouch,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              width: _visual,
              height: _visual,
              decoration: ShapeDecoration(
                color: done ? color : null,
                shape: CircleBorder(side: BorderSide(color: color, width: 2)),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 16, color: onColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ Madde ekle" field.
class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.controller,
    required this.focusNode,
    required this.showSplit,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSplit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showSplit;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
      child: Row(
        children: [
          SizedBox.square(
            dimension: KorSizes.minTouch,
            child: Icon(Icons.add_rounded, color: scheme.primary),
          ),
          const SizedBox(width: KorSpacing.s2),
          Expanded(
            child: TextField(
              key: SubtasksCardKeys.addField,
              controller: controller,
              focusNode: focusNode,
              // Multi-line so a pasted list keeps its line breaks; Enter
              // submits (textInputAction) instead of adding a newline.
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
              // Keep focus handling in onSubmitted (no default next/unfocus).
              onEditingComplete: () {},
              onSubmitted: (_) => onSubmitted(),
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration.collapsed(
                hintText: 'Madde ekle',
              ),
            ),
          ),
          if (showSplit)
            IconButton(
              key: SubtasksCardKeys.splitSuggestion,
              tooltip: 'Maddelere böl',
              icon: const Icon(Icons.call_split_rounded),
              onPressed: onSplit,
            ),
        ],
      ),
    );
  }
}

/// Collapsible "Tamamlanan N madde" header.
class _DoneHeader extends StatelessWidget {
  const _DoneHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      expanded: expanded,
      label: 'Tamamlanan $count madde',
      excludeSemantics: true,
      child: InkWell(
        key: SubtasksCardKeys.doneToggle,
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(KorSpacing.s4)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
          child: Row(
            children: [
              const SizedBox(width: KorSpacing.s3),
              Expanded(
                child: Text(
                  'Tamamlanan $count madde',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: KorSpacing.s3),
            ],
          ),
        ),
      ),
    );
  }
}
