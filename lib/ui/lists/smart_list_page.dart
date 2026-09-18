import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/lists/smart_lists.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Icon and container colours of a smart list (`kor-screens.json`
/// lists.smartGrid).
abstract final class SmartListVisuals {
  static IconData icon(SmartList list) => switch (list) {
        SmartList.overdue => Icons.history_rounded,
        SmartList.today => Icons.today_rounded,
        SmartList.scheduled => Icons.date_range_rounded,
        SmartList.untimed => Icons.inbox_rounded,
        SmartList.birthdays => CategoryVisuals.birthdayIcon,
        SmartList.located => Icons.place_rounded,
      };

  /// (foreground, background).
  static (Color, Color) colors(BuildContext context, SmartList list) {
    final scheme = Theme.of(context).colorScheme;
    switch (list) {
      case SmartList.overdue:
        return (scheme.onPrimaryContainer, scheme.primaryContainer);
      case SmartList.today:
        return (scheme.onTertiaryContainer, scheme.tertiaryContainer);
      case SmartList.scheduled:
      case SmartList.untimed:
        return (scheme.onSurface, scheme.surfaceContainerHigh);
      case SmartList.birthdays:
        final c = CategoryVisuals.birthdayColorsOf(context);
        return (c.fg, c.container);
      case SmartList.located:
        final c = CategoryVisuals.colorsOf(context, ReminderCategoryIds.home);
        return (c.fg, c.container);
    }
  }

  /// §3.3.11 empty-state texts.
  static (String, String) empty(SmartList list) => switch (list) {
        SmartList.overdue => (
            'Gecikmiş bir şey yok',
            'Her şey zamanında, böyle devam.',
          ),
        SmartList.today => (
            'Bugün için saatli bir şey yok',
            'Bugüne saat verdiğin hatırlatmalar burada görünür.',
          ),
        SmartList.scheduled => (
            'Planlı hatırlatma yok',
            'Saat verdiğin hatırlatmalar burada birikir.',
          ),
        SmartList.untimed => (
            'Zamansız hatırlatma yok',
            'Saati olmayan hatırlatmalar burada durur.',
          ),
        SmartList.birthdays => (
            'Henüz doğum günü yok',
            'Sevdiklerinin gününü kaçırma.',
          ),
        SmartList.located => (
            'Konumlu hatırlatma yok',
            "Bir yere varınca hatırlatmak için hatırlatıcıda 'Nerede'yi aç.",
          ),
      };
}

/// A smart list opened from the Listeler bento (open reminders only).
/// [SmartList.birthdays] opens `BirthdaysPage` instead.
class SmartListPage extends StatelessWidget {
  const SmartListPage({super.key, required this.list})
      : assert(list != SmartList.birthdays);

  final SmartList list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = NowScope.now(context);
    final (fg, bg) = SmartListVisuals.colors(context, list);

    return Scaffold(
      appBar: AppBar(actions: const [SearchIconButton()]),
      body: BlocBuilder<ReminderCubit, ReminderState>(
        builder: (context, state) {
          final items = list.filter(state.reminders, now);
          final bottom = MediaQuery.paddingOf(context).bottom;
          final (emptyTitle, emptyBody) = SmartListVisuals.empty(list);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: KorSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconBadge(
                        icon: SmartListVisuals.icon(list),
                        foreground: fg,
                        background: bg,
                      ),
                      const SizedBox(width: KorSpacing.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                list.label,
                                style: theme.textTheme.headlineLarge,
                              ),
                            ),
                            Text(
                              '${items.length} açık',
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
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(title: emptyTitle, body: emptyBody),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: KorSpacing.s5),
                ),
                SliverPadding(
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
                ),
              ],
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottom + KorSpacing.s7),
              ),
            ],
          );
        },
      ),
    );
  }
}
