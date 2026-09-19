import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CategoryListKeys {
  static const editToggle = Key('categories.editToggle');
  static const newCategory = Key('categories.new');
  static Key row(String id) => Key('categories.row.$id');
  static Key editRow(String id) => Key('categories.editRow.$id');
  static Key handle(String id) => Key('categories.handle.$id');
}

/// Listeler › Kategorilerim (§3.3.6, F4.3): every category in the user's
/// order with its open count, "+ Yeni kategori" and a "Düzenle" mode.
///
/// - Normal mode: a row opens the category's list ([onOpen]).
/// - Düzenle: a `ReorderableListView` with ≡ handles (its items expose the
///   "Yukarı taşı / Aşağı taşı" semantics actions, the non-drag
///   alternative); tapping a user category opens the category editor.
///   Built-in categories can only be moved.
class CategoryListSection extends StatefulWidget {
  const CategoryListSection({super.key, required this.onOpen});

  /// Opens the reminder list of a category.
  final ValueChanged<String> onOpen;

  @override
  State<CategoryListSection> createState() => _CategoryListSectionState();
}

class _CategoryListSectionState extends State<CategoryListSection> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<ReminderCubit>().state;
    final categories = state.categories.ordered;
    int openIn(String id) =>
        state.reminders.where((r) => !r.isDone && r.categoryId == id).length;

    return GroupedCard(
      title: context.l10n.categoryListTitle,
      padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
      headerTrailing: Padding(
        padding: const EdgeInsets.only(right: KorSpacing.s3),
        child: TextButton(
          key: CategoryListKeys.editToggle,
          onPressed: () => setState(() => _editing = !_editing),
          child: Text(
            _editing ? context.l10n.actionFinish : context.l10n.actionEdit,
          ),
        ),
      ),
      children: [
        if (_editing)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorderItem: (from, to) =>
                context.read<ReminderCubit>().moveCategory(from, to),
            // §3.1 Haptik: lift medium, drop light (F4.7).
            onReorderStart: (_) => KorHaptics.of(context).reorderPickUp(),
            onReorderEnd: (_) => KorHaptics.of(context).reorderDrop(),
            children: [
              for (final (index, c) in categories.indexed)
                _EditRow(
                  key: CategoryListKeys.editRow(c.id),
                  category: c,
                  index: index,
                ),
            ],
          )
        else
          for (final c in categories)
            _CategoryRow(
              key: CategoryListKeys.row(c.id),
              category: c,
              count: openIn(c.id),
              onTap: () => widget.onOpen(c.id),
            ),
        Semantics(
          button: true,
          label: context.l10n.categoryNew,
          excludeSemantics: true,
          onTap: () => showCategoryEditorSheet(context),
          child: InkWell(
            key: CategoryListKeys.newCategory,
            onTap: () => showCategoryEditorSheet(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
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
                        context.l10n.categoryNew,
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

/// 56 dp row: badge, name, open count, chevron. One button node:
/// "Spor salonu, 3 açık".
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  final ReminderCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.categoryRowSpoken(
        CategoryVisuals.nameOf(category, context.l10n),
        count,
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s5,
              vertical: KorSpacing.s3,
            ),
            child: Row(
              children: [
                CategoryBadge(category: category),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Text(
                    CategoryVisuals.nameOf(category, context.l10n),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

/// Düzenle row: badge, name, (user categories) edit button, ≡ handle.
class _EditRow extends StatelessWidget {
  const _EditRow({
    super.key,
    required this.category,
    required this.index,
  });

  final ReminderCategory category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editable = !category.isBuiltIn;
    void edit() => showCategoryEditorSheet(context, existing: category);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: editable ? edit : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.only(
              left: KorSpacing.s5,
              right: KorSpacing.s3,
            ),
            child: Row(
              children: [
                CategoryBadge(category: category),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Text(
                    CategoryVisuals.nameOf(category, context.l10n),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: context.l10n.categoryEditTooltip(category.name),
                    onPressed: edit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ReorderableDragStartListener(
                  key: CategoryListKeys.handle(category.id),
                  index: index,
                  child: Semantics(
                    label: context.l10n.categoryMoveSpoken(
                      CategoryVisuals.nameOf(category, context.l10n),
                    ),
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
