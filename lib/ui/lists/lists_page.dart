import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/categories/category_list_section.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/lists/reminder_filter_page.dart';
import 'package:reminder/ui/lists/smart_list_page.dart';
import 'package:reminder/ui/lists/smart_lists.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class ListsPageKeys {
  static Key smartTile(SmartList list) => Key('lists.smart.${list.name}');
}

/// Listeler (§3.3.6): Ara, smart-list bento (2 × 3), Kategorilerim (icon
/// badge, name, open count) and Tamamlananlar.
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
    final now = NowScope.now(context);
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        int countOf(SmartList list) => list == SmartList.birthdays
            ? state.birthdays.length
            : list.filter(state.reminders, now).length;

        Widget tile(SmartList list) => SmartListTile(
              key: ListsPageKeys.smartTile(list),
              list: list,
              count: countOf(list),
              onTap: () => _push(
                context,
                list == SmartList.birthdays
                    ? const BirthdaysPage()
                    : SmartListPage(list: list),
              ),
            );

        const lists = SmartList.values;
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
              const TabHeader(
                title: 'Listeler',
                actions: [SearchIconButton()],
              ),
              const SizedBox(height: KorSpacing.s5),
              for (var i = 0; i < lists.length; i += 2) ...[
                if (i > 0) const SizedBox(height: KorSpacing.s5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(lists[i])),
                      const SizedBox(width: KorSpacing.s5),
                      Expanded(child: tile(lists[i + 1])),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: KorSpacing.s5),
              // F4.3: user categories, order, Düzenle, "+ Yeni kategori".
              CategoryListSection(
                onOpen: (id) => _push(
                  context,
                  ReminderFilterPage.category(categoryId: id),
                ),
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
                children: [
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

/// Bento tile (`components.SmartListTile`: 171 × 96, radius lg, surface,
/// level 1, 32 px icon container, count headlineSmall tabular, label
/// labelLarge). One button node: "Gecikmiş, 1 hatırlatıcı".
class SmartListTile extends StatelessWidget {
  const SmartListTile({
    super.key,
    required this.list,
    required this.count,
    required this.onTap,
  });

  static const double minHeight = 96;
  static const double iconSize = 32;

  final SmartList list;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (fg, bg) = SmartListVisuals.colors(context, list);
    final decoration =
        korCardDecoration(context, borderRadius: KorRadius.lgAll);
    final unit = list == SmartList.birthdays ? 'doğum günü' : 'hatırlatıcı';
    final border = decoration.border;

    return Semantics(
      button: true,
      label: '${list.label}, $count $unit',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: KorRadius.lgAll,
          boxShadow: decoration.boxShadow,
        ),
        child: Material(
          color: decoration.color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: KorRadius.lgAll,
            side: border is Border ? border.top : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.all(KorSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(
                          icon: SmartListVisuals.icon(list),
                          foreground: fg,
                          background: bg,
                          size: iconSize,
                        ),
                        const SizedBox(width: KorSpacing.s3),
                        Expanded(
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KorSpacing.s3),
                    Text(
                      list.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
