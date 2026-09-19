import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// A filtered reminder list opened from Listeler: one category (open first,
/// then its completed items) or all completed reminders.
class ReminderFilterPage extends StatelessWidget {
  const ReminderFilterPage.category(
      {super.key, required String this.categoryId});

  const ReminderFilterPage.completed({super.key}) : categoryId = null;

  /// `null` → Tamamlananlar.
  final String? categoryId;

  String _titleOf(BuildContext context) => categoryId == null
      ? context.l10n.listsCompleted
      : CategoryVisuals.labelOf(context, categoryId!);

  /// App bar "Kategoriyi düzenle" for user categories (F4.3); leaves the
  /// page when the category was deleted.
  Widget? _editAction(BuildContext context) {
    final id = categoryId;
    if (id == null || ReminderCategoryIds.isBuiltIn(id)) return null;
    final category = CategoryVisuals.catalogOf(context).byId(id);
    if (category == null) return null;
    return IconButton(
      tooltip: context.l10n.filterEditCategory,
      icon: const Icon(Icons.edit_outlined),
      onPressed: () async {
        await showCategoryEditorSheet(context, existing: category);
        if (!context.mounted) return;
        final exists =
            context.read<ReminderCubit>().state.categories.contains(id);
        if (!exists) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = NowScope.now(context);
    final title = _titleOf(context);
    final edit = _editAction(context);

    return Scaffold(
      appBar: AppBar(actions: [if (edit != null) edit]),
      body: BlocBuilder<ReminderCubit, ReminderState>(
        builder: (context, state) {
          final List<Reminder> open;
          final List<Reminder> done;
          if (categoryId == null) {
            open = const [];
            done = [...state.completed]..sort(compareReminders);
          } else {
            open = state.active
                .where((r) => r.categoryId == categoryId)
                .toList()
              ..sort(compareReminders);
            done = state.completed
                .where((r) => r.categoryId == categoryId)
                .toList()
              ..sort(compareReminders);
          }
          final bottom = MediaQuery.paddingOf(context).bottom;
          final summary = categoryId == null
              ? context.l10n.filterCompletedSummary(done.length)
              : context.l10n.filterCategorySummary(open.length, done.length);

          Widget cards(List<Reminder> items) => SliverPadding(
                padding: KorSpacing.screenPadding,
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KorSpacing.cardGap),
                  itemBuilder: (context, i) => ReminderCard(
                    key: ValueKey(items[i].id),
                    reminder: items[i],
                    now: now,
                  ),
                ),
              );

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: KorSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      if (categoryId != null) ...[
                        CategoryIconBadge(categoryId: categoryId!),
                        const SizedBox(width: KorSpacing.s4),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: theme.textTheme.headlineLarge,
                              ),
                            ),
                            Text(
                              summary,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
              if (open.isEmpty && done.isEmpty)
                SliverToBoxAdapter(
                  child: categoryId == null
                      ? EmptyState(
                          title: context.l10n.filterNoCompletedTitle,
                          body: context.l10n.filterNoCompletedBody,
                        )
                      : EmptyState(
                          title: context.l10n.filterListEmptyTitle(title),
                          body: context.l10n.filterListEmptyBody,
                          actionLabel: context.l10n.calendarAddReminder,
                          onAction: () => showReminderEditorSheet(
                            context,
                            initialCategoryId: categoryId,
                          ),
                        ),
                ),
              if (open.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: KorSpacing.s5),
                ),
                cards(open),
              ],
              if (done.isNotEmpty) ...[
                if (categoryId != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      KorSpacing.screenEdge,
                      KorSpacing.s5,
                      KorSpacing.screenEdge,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: context.l10n.listsCompleted,
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: SizedBox(height: KorSpacing.s5),
                  ),
                cards(done),
              ],
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottom + KorSpacing.s7),
              ),
            ],
          );
        },
      ),
      floatingActionButton: categoryId == null
          ? null
          : FloatingActionButton(
              heroTag: null,
              tooltip: context.l10n.filterAddToList,
              onPressed: () => showReminderEditorSheet(
                context,
                initialCategoryId: categoryId,
              ),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}
