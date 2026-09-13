import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/lists/reminder_filter_page.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Listeler: categories (icon badge, name, open count), Doğum günleri and
/// Tamamlananlar. Smart-list bento is F3.6.
class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NowScope.carry(context, page)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        int openIn(String id) => state.reminders
            .where((r) => !r.isDone && r.categoryId == id)
            .length;
        final birthdayColors = CategoryVisuals.birthdayColorsOf(context);

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              KorSpacing.screenEdge,
              0,
              KorSpacing.screenEdge,
              bottom + KorSpacing.s7,
            ),
            children: [
              const TabHeader(title: 'Listeler'),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                title: 'Kategorilerim',
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
                children: [
                  for (final id in ReminderCategoryIds.orderedIds)
                    ListEntryRow(
                      leading: CategoryIconBadge(categoryId: id),
                      title: ReminderCategoryIds.defaultLabel(id),
                      count: openIn(id),
                      countLabel: 'açık',
                      onTap: () => _push(
                        context,
                        ReminderFilterPage.category(categoryId: id),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
                children: [
                  ListEntryRow(
                    leading: IconBadge(
                      icon: CategoryVisuals.birthdayIcon,
                      foreground: birthdayColors.fg,
                      background: birthdayColors.container,
                    ),
                    title: 'Doğum günleri',
                    count: state.birthdays.length,
                    countLabel: 'kayıt',
                    onTap: () => _push(context, const BirthdaysPage()),
                  ),
                  ListEntryRow(
                    leading: IconBadge(
                      icon: Icons.task_alt_rounded,
                      foreground: scheme.onSurface,
                      background: scheme.surfaceContainerHigh,
                    ),
                    title: 'Tamamlananlar',
                    count: state.completed.length,
                    countLabel: 'tamamlandı',
                    onTap: () => _push(
                      context,
                      const ReminderFilterPage.completed(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 56 dp list row: badge, title, count, chevron.
class ListEntryRow extends StatelessWidget {
  const ListEntryRow({
    super.key,
    required this.leading,
    required this.title,
    required this.count,
    required this.countLabel,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final int count;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '$title, $count $countLabel',
      excludeSemantics: true,
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
                leading,
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Text(title, style: theme.textTheme.bodyLarge),
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
