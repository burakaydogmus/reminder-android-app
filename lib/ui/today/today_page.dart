import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/calendar/calendar_event_card.dart';
import 'package:reminder/ui/calendar/device_calendar_scope.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/today/overdue_actions.dart';
import 'package:reminder/ui/today/time_ribbon.dart';
import 'package:reminder/ui/today/today_sections.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_banner.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';

/// Keys for tests.
abstract final class TodayPageKeys {
  static const notificationBanner = Key('today.notificationBanner');
  static const calendarEvents = Key('today.calendarEvents');
  static const moveOverdue = Key('today.moveOverdue');
  static const ribbonCompletedToggle = Key('today.ribbonCompletedToggle');
}

/// Bugün (§3.3.2): header (Ara, Ayarlar), birthday banner, Kaçanlar with
/// "Hepsini yarına al", the time ribbon (timed items + ŞİMDİ line,
/// completed items compact), Bugün bir ara (untimed) and collapsible
/// Tamamlananlar (completed untimed items).
///
/// Reading order follows the tree: header → Kaçanlar → ribbon
/// (chronological) → Bugün bir ara → Tamamlananlar.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  /// Collapsible Tamamlananlar and the "Hepsi tamam" state.
  bool _showCompleted = false;

  /// Ribbon toggle "Tamamlananları gizle".
  bool _hideRibbonCompleted = false;

  /// The ŞİMDİ glow plays once, on the first ribbon build.
  bool _glowPlayed = false;

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
        final allDoneCollapsed = sections.allDone && !_showCompleted;

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
                        title: context.l10n.todayNotificationsOffTitle,
                        body: context.l10n.todayNotificationsOffBody,
                        // Same wording as Ayarlar → İzinler: ask while the
                        // system has never asked, settings after a denial.
                        actionLabel: PermissionScope.of(context)
                                    .snapshot
                                    ?.notifications ==
                                NotificationPermissionState.notRequested
                            ? context.l10n.permissionAllow
                            : context.l10n.permissionOpenSettings,
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
                    title: context.l10n.todayEmptyTitle,
                    body: context.l10n.todayEmptyBody,
                    actionLabel: context.l10n.todayEmptyAction,
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
              else if (allDoneCollapsed)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: context.l10n.todayAllDoneTitle,
                    body: context.l10n.todayAllDoneBody(sections.doneCount),
                    actionLabel: context.l10n.todayShowCompleted,
                    onAction: () => setState(() {
                      _showCompleted = true;
                      _hideRibbonCompleted = false;
                    }),
                  ),
                ),
              ..._overdue(context, sections, now),
              if (!allDoneCollapsed) ..._ribbon(context, sections, now),
              ..._calendarEvents(context, now),
              ..._section(
                context,
                title: context.l10n.todayUntimed,
                icon: Icons.inbox_rounded,
                items: sections.untimed,
                now: now,
              ),
              if (sections.completedUntimed.isNotEmpty) ...[
                _padded(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: KorSpacing.s5),
                      child: _CompletedToggle(
                        count: sections.completedUntimed.length,
                        expanded: _showCompleted,
                        onTap: () =>
                            setState(() => _showCompleted = !_showCompleted),
                      ),
                    ),
                  ),
                ),
                if (_showCompleted)
                  _cards(
                    sections.completedUntimed,
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

  /// Takvim (F8.1): today's device calendar events, read-only, below the
  /// ribbon. Absent entirely while the feature is off, while nothing is
  /// loaded yet and when the day has no event — never an empty header.
  List<Widget> _calendarEvents(BuildContext context, DateTime now) {
    final controller = DeviceCalendarScope.maybeOf(context);
    if (controller == null || !controller.enabled) return const [];
    final events = controller.eventsOnDay(now);
    if (events.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      _padded(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KorSpacing.s5),
            child: SectionHeader(
              key: TodayPageKeys.calendarEvents,
              title: context.l10n.calendarEventsSection,
              icon: Icons.event_outlined,
              trailing: Text(
                '${events.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      _padded(
        SliverList.separated(
          itemCount: events.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: KorSpacing.cardGap),
          itemBuilder: (context, i) => CalendarEventCard(
            key: ValueKey(events[i].id),
            event: events[i],
            now: now,
            calendarName: calendarNameOf(controller, events[i].calendarId),
            showDateRange: true,
          ),
        ),
      ),
    ];
  }

  List<Widget> _overdue(
    BuildContext context,
    TodaySections sections,
    DateTime now,
  ) {
    if (sections.overdue.isEmpty) return const [];
    final theme = Theme.of(context);
    final movable = movableOverdue(sections.overdue);
    return [
      _padded(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KorSpacing.s5),
            child: _HeaderWithAction(
              title: context.l10n.todayOverdue,
              icon: Icons.history_rounded,
              iconColor: theme.colorScheme.primary,
              action: movable.isEmpty
                  ? null
                  : TextButton(
                      key: TodayPageKeys.moveOverdue,
                      onPressed: () => moveOverdueToTomorrowWithUndo(
                        context,
                        overdue: sections.overdue,
                        now: now,
                      ),
                      child: Text(context.l10n.todayMoveOverdue),
                    ),
            ),
          ),
        ),
      ),
      _cards(sections.overdue, now, ReminderTimeStyle.relative),
    ];
  }

  List<Widget> _ribbon(
    BuildContext context,
    TodaySections sections,
    DateTime now,
  ) {
    final hasCompleted = sections.completedTimed.isNotEmpty;
    final entries = sections.timeline(
      now: now,
      includeCompleted: !_hideRibbonCompleted,
    );
    if (sections.today.isEmpty && !hasCompleted) return const [];

    final playGlow = !_glowPlayed;
    if (playGlow) _glowPlayed = true;

    return [
      _padded(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KorSpacing.s5),
            child: _HeaderWithAction(
              title: context.l10n.todayTimeline,
              icon: Icons.schedule_rounded,
              action: hasCompleted
                  ? TextButton(
                      key: TodayPageKeys.ribbonCompletedToggle,
                      onPressed: () => setState(
                        () => _hideRibbonCompleted = !_hideRibbonCompleted,
                      ),
                      child: Text(
                        _hideRibbonCompleted
                            ? context.l10n.todayShowCompleted
                            : context.l10n.todayHideCompleted,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
      _padded(
        SliverList.list(
          children: [
            for (final entry in entries)
              switch (entry) {
                TimelineNow(:final now) => NowLine(
                    key: TimeRibbonKeys.nowLine,
                    now: now,
                    playGlow: playGlow,
                  ),
                TimelineReminder(:final reminder) => TimeRibbonRow(
                    key: ValueKey(reminder.id),
                    reminder: reminder,
                    now: now,
                  ),
              },
          ],
        ),
      ),
    ];
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
    required List<Reminder> items,
    required DateTime now,
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
      _cards(items, now, ReminderTimeStyle.timeOnly),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabHeader(
          title: l10n.todayTitle,
          overline: KorFormat.headerDate(now, l10n),
          actions: const [SearchIconButton()],
        ),
        Text(
          sections.summary(l10n),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KorSpacing.s3),
        Semantics(
          label: l10n.todayProgressSpoken(
            sections.doneCount,
            sections.totalCount,
          ),
          excludeSemantics: true,
          child: LinearProgressIndicator(value: sections.progress),
        ),
        const SizedBox(height: KorSpacing.s2),
      ],
    );
  }
}

/// [SectionHeader] with a trailing text button; above the ribbon's
/// single-column text scale the button moves to its own line so neither the
/// title nor the button is cut off.
class _HeaderWithAction extends StatelessWidget {
  const _HeaderWithAction({
    required this.title,
    required this.icon,
    this.iconColor,
    this.action,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (action == null || !TimeRibbon.singleColumn(context)) {
      return SectionHeader(
        title: title,
        icon: icon,
        iconColor: iconColor,
        trailing: action,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, icon: icon, iconColor: iconColor),
        action!,
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
      label: expanded
          ? context.l10n.todayCompletedSpokenHide(count)
          : context.l10n.todayCompletedSpokenShow(count),
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
                  context.l10n.todayCompleted,
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
