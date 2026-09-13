import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/today/today_sections.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_banner.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';

/// Keys for tests.
abstract final class TodayPageKeys {
  static const notificationBanner = Key('today.notificationBanner');
}

/// Bugün (§3.3.2 without the time ribbon, F3.6): header, birthday banner,
/// Kaçanlar, Bugün, Zamansız and collapsible Tamamlananlar.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final now = NowScope.now(context);
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final sections = TodaySections.from(
          reminders: state.reminders,
          birthdays: state.birthdays,
          now: now,
        );
        final bottom = MediaQuery.paddingOf(context).bottom;

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              _padded(
                SliverToBoxAdapter(
                    child: _Header(sections: sections, now: now)),
              ),
              if (_needsNotificationBanner(context, state, now))
                _padded(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: KorSpacing.s3),
                      child: PermissionBanner(
                        key: TodayPageKeys.notificationBanner,
                        title: 'Bildirimler kapalı',
                        body: 'Hatırlatmalar zamanında gelmeyecek.',
                        actionLabel: 'Ayarları aç',
                        onAction: () =>
                            PermissionFlows.fixNotifications(context),
                      ),
                    ),
                  ),
                ),
              for (final o in sections.birthdays)
                _padded(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: KorSpacing.s3),
                      child: BirthdayCard(
                        occurrence: o,
                        now: now,
                        onTap: () => showBirthdayEditorSheet(
                          context,
                          existing: o.birthday,
                        ),
                      ),
                    ),
                  ),
                ),
              if (sections.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Bugün boş',
                    body: 'Keyfine bak ya da aklındakini aşağıya yaz.',
                    actionLabel: 'Yarını planla',
                    onAction: () => showReminderEditorSheet(
                      context,
                      initialRemindAt: DateTime(
                        now.year,
                        now.month,
                        now.day + 1,
                        9,
                      ),
                    ),
                  ),
                )
              else if (sections.allDone && !_showCompleted)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Hepsi tamam.',
                    body: 'Bugünkü ${sections.doneCount} hatırlatmanın '
                        'hepsini bitirdin.',
                    actionLabel: 'Tamamlananları göster',
                    onAction: () => setState(() => _showCompleted = true),
                  ),
                ),
              ..._section(
                context,
                title: 'Kaçanlar',
                icon: Icons.history_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
                items: sections.overdue,
                now: now,
                timeStyle: ReminderTimeStyle.relative,
              ),
              ..._section(
                context,
                title: 'Bugün',
                icon: Icons.schedule_rounded,
                items: sections.today,
                now: now,
                timeStyle: ReminderTimeStyle.timeOnly,
              ),
              ..._section(
                context,
                title: 'Zamansız',
                icon: Icons.inbox_rounded,
                items: sections.untimed,
                now: now,
                timeStyle: ReminderTimeStyle.timeOnly,
              ),
              if (sections.completed.isNotEmpty) ...[
                _padded(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: KorSpacing.s5),
                      child: _CompletedToggle(
                        count: sections.completed.length,
                        expanded: _showCompleted,
                        onTap: () =>
                            setState(() => _showCompleted = !_showCompleted),
                      ),
                    ),
                  ),
                ),
                if (_showCompleted)
                  _cards(
                    sections.completed,
                    now,
                    ReminderTimeStyle.timeOnly,
                  ),
              ],
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottom + KorSpacing.s7),
              ),
            ],
          ),
        );
      },
    );
  }

  /// §3.3.2 "İzin reddedildi": notifications are on in the app but the OS
  /// permission is missing while something is waiting to notify.
  static bool _needsNotificationBanner(
    BuildContext context,
    ReminderState state,
    DateTime now,
  ) {
    final permission = PermissionScope.of(context).snapshot?.notifications;
    if (permission == null ||
        permission == NotificationPermissionState.granted ||
        !state.settings.notificationsEnabled) {
      return false;
    }
    return state.birthdays.isNotEmpty ||
        state.reminders.any(
          (r) => !r.isDone && r.remindAt != null && r.remindAt!.isAfter(now),
        );
  }

  static Widget _padded(Widget sliver) => SliverPadding(
        padding: KorSpacing.screenPadding,
        sliver: sliver,
      );

  static List<Widget> _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Reminder> items,
    required DateTime now,
    required ReminderTimeStyle timeStyle,
  }) {
    if (items.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      _padded(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KorSpacing.s5),
            child: SectionHeader(
              title: title,
              icon: icon,
              iconColor: iconColor,
              trailing: Text(
                '${items.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      _cards(items, now, timeStyle),
    ];
  }

  static Widget _cards(
    List<Reminder> items,
    DateTime now,
    ReminderTimeStyle timeStyle,
  ) {
    return _padded(
      SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: KorSpacing.cardGap),
        itemBuilder: (context, i) => ReminderCard(
          key: ValueKey(items[i].id),
          reminder: items[i],
          now: now,
          timeStyle: timeStyle,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sections, required this.now});

  final TodaySections sections;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabHeader(title: 'Bugün', overline: KorFormat.headerDate(now)),
        Text(
          sections.summary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KorSpacing.s3),
        Semantics(
          label: 'İlerleme: ${sections.doneCount} / ${sections.totalCount} '
              'tamamlandı',
          excludeSemantics: true,
          child: LinearProgressIndicator(value: sections.progress),
        ),
        const SizedBox(height: KorSpacing.s2),
      ],
    );
  }
}

class _CompletedToggle extends StatelessWidget {
  const _CompletedToggle({
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
      label: 'Tamamlananlar, $count, ${expanded ? 'gizle' : 'göster'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(KorSpacing.s3)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
          child: Row(
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: KorSizes.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: KorSpacing.s3),
              Expanded(
                child: Text(
                  'Tamamlananlar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
