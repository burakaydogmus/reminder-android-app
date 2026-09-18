import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/calendar_dates.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/birthdays/birthday_groups.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/calendar/agenda_rows.dart';
import 'package:reminder/ui/calendar/reschedule.dart';
import 'package:reminder/ui/calendar/week_strip.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/components/birthday_row.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CalendarPageKeys {
  static const today = Key('calendar.today');
  static const toggleMonth = Key('calendar.toggleMonth');
  static const previous = Key('calendar.previous');
  static const next = Key('calendar.next');
  static const monthLabel = Key('calendar.monthLabel');
  static Key filter(CalendarFilter f) => ValueKey('calendar.filter.${f.name}');
}

/// Takvim (§3.3.5, F4.4): week strip (Mon-first, swipe between weeks) ⇄ 6×7
/// month grid, filter chips and a 30-day agenda from the selected day with
/// sticky day headers, recurring occurrences and "boş gün" rows.
///
/// Selecting a day (strip, grid, "Bugün") starts the agenda at that day.
/// Reminder cards can be dragged onto a strip/grid day to reschedule them
/// (menu › "Taşı…" and a semantics action are the alternatives).
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  static const days = 30;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _basePage = 10000;

  PageController _weekController = _controllerAt(_basePage);
  final _scroll = ScrollController();

  /// Monday of the week shown on [_basePage] (today's week at first build).
  DateTime? _baseWeek;

  /// `null` = today (follows the clock across midnight).
  DateTime? _selected;
  int _page = _basePage;
  bool _expanded = false;
  DateTime? _gridMonth;
  CalendarFilter _filter = CalendarFilter.all;

  // keepPage: false — a re-created strip must open on initialPage, not on a
  // page restored from PageStorage.
  static PageController _controllerAt(int page) =>
      PageController(initialPage: page, keepPage: false);

  @override
  void dispose() {
    _weekController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int _pageOf(DateTime day) =>
      _basePage + CalendarDates.weekDiff(_baseWeek!, day);

  DateTime _weekOfPage(int page) =>
      CalendarDates.addDays(_baseWeek!, (page - _basePage) * 7);

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _showWeekOf(DateTime day) {
    final page = _pageOf(day);
    _page = page;
    if (_weekController.hasClients) {
      if (_weekController.page?.round() != page) {
        _weekController.jumpToPage(page);
      }
    } else {
      _weekController.dispose();
      _weekController = _controllerAt(page);
    }
  }

  void _scrollAgendaToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _select(DateTime day, DateTime today) {
    setState(() {
      _selected = CalendarDates.isSameDay(day, today) ? null : day;
      _gridMonth = CalendarDates.monthStart(day);
      if (_expanded) {
        _expanded = false;
        _weekController.dispose();
        _weekController = _controllerAt(_pageOf(day));
        _page = _pageOf(day);
      } else {
        _showWeekOf(day);
      }
    });
    _scrollAgendaToTop();
  }

  void _goToToday(DateTime today) {
    setState(() {
      _selected = null;
      _gridMonth = CalendarDates.monthStart(today);
      if (!_expanded) _showWeekOf(today);
    });
    _scrollAgendaToTop();
  }

  void _toggleExpanded(DateTime selected) {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _gridMonth = CalendarDates.monthStart(
          CalendarDates.addDays(_weekOfPage(_page), 3),
        );
      } else {
        // Back to the selected day's week, or to the browsed month.
        final month = _gridMonth!;
        final week = CalendarDates.isSameDay(
          CalendarDates.monthStart(selected),
          month,
        )
            ? selected
            : month;
        _weekController.dispose();
        _page = _pageOf(week);
        _weekController = _controllerAt(_page);
      }
    });
  }

  void _step(int delta) {
    setState(() {
      if (_expanded) {
        _gridMonth = CalendarDates.addMonths(_gridMonth!, delta);
      } else {
        final page = _page + delta;
        _page = page;
        if (_reduceMotion || !_weekController.hasClients) {
          if (_weekController.hasClients) _weekController.jumpToPage(page);
        } else {
          _weekController.animateToPage(
            page,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  /// "Boş gün" tap: the reminder editor preset to [day] (today: the next
  /// full hour, other days 09:00).
  void _quickAdd(DateTime day, DateTime now) {
    final at = CalendarDates.isSameDay(day, now)
        ? DateTime(now.year, now.month, now.day, now.hour + 1)
        : DateTime(day.year, day.month, day.day, 9);
    showReminderEditorSheet(context, initialRemindAt: at);
  }

  @override
  Widget build(BuildContext context) {
    final now = NowScope.now(context);
    final today = CalendarDates.dateOnly(now);
    _baseWeek ??= CalendarDates.weekStart(today);
    final selected = _selected ?? today;
    _gridMonth ??= CalendarDates.monthStart(selected);
    final theme = Theme.of(context);

    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final agenda = buildAgenda(
          reminders: state.reminders,
          birthdays: state.birthdays,
          now: now,
          from: selected,
          days: CalendarPage.days,
          filter: _filter,
          includeEmptyDays: true,
        );
        final hasEntries = agenda.any((d) => !d.isEmpty);

        final week = _weekOfPage(_page);
        final grid = CalendarDates.monthGrid(_gridMonth!);
        final markers = calendarDayMarkers(
          reminders: state.reminders,
          birthdays: state.birthdays,
          now: now,
          from: _expanded ? grid.first : CalendarDates.addDays(week, -7),
          to: _expanded
              ? CalendarDates.addDays(grid.last, 1)
              : CalendarDates.addDays(week, 14),
          filter: _filter,
        );
        List<KorColorKey> dotsFor(DateTime d) => markers[d] ?? const [];

        final drop = DayDropHandler(
          canAccept: (r, d) => canRescheduleToDay(r, d, NowScope.now(context)),
          onAccept: (r, d) => rescheduleReminderWithUndo(context, r, d),
        );

        // Month of the shown week's Thursday (ISO rule), or the grid month.
        final labelMonth =
            _expanded ? _gridMonth! : CalendarDates.addDays(week, 3);
        final monthLabel = DateFormat('MMMM y', 'tr_TR').format(labelMonth);
        final bottom = MediaQuery.paddingOf(context).bottom;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: KorSpacing.screenPadding,
                child: TabHeader(
                  title: 'Takvim',
                  actions: [
                    TextButton(
                      key: CalendarPageKeys.today,
                      onPressed: () => _goToToday(today),
                      child: const Text('Bugün'),
                    ),
                    IconButton(
                      key: CalendarPageKeys.toggleMonth,
                      tooltip: _expanded
                          ? 'Hafta görünümüne geç'
                          : 'Ay görünümüne geç',
                      onPressed: () => _toggleExpanded(selected),
                      icon: Icon(
                        _expanded
                            ? Icons.view_week_rounded
                            : Icons.calendar_view_month_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: KorSpacing.screenPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        monthLabel,
                        key: CalendarPageKeys.monthLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: CalendarPageKeys.previous,
                      tooltip: _expanded ? 'Önceki ay' : 'Önceki hafta',
                      onPressed: () => _step(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      key: CalendarPageKeys.next,
                      tooltip: _expanded ? 'Sonraki ay' : 'Sonraki hafta',
                      onPressed: () => _step(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KorSpacing.s3,
                  ),
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) > 0) {
                        _toggleExpanded(selected);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WeekStrip(
                          controller: _weekController,
                          basePage: _basePage,
                          baseWeek: _baseWeek!,
                          today: today,
                          selected: selected,
                          dotsFor: dotsFor,
                          onSelect: (d) => _select(d, today),
                          onPageChanged: (page) => setState(() => _page = page),
                          drop: drop,
                        ),
                        ExpandHandle(
                          expanded: false,
                          onToggle: () => _toggleExpanded(selected),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    if (_expanded)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KorSpacing.s3,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MonthGrid(
                                month: _gridMonth!,
                                today: today,
                                selected: selected,
                                dotsFor: dotsFor,
                                onSelect: (d) => _select(d, today),
                                onMonthChange: _step,
                                drop: drop,
                              ),
                              ExpandHandle(
                                expanded: true,
                                onToggle: () => _toggleExpanded(selected),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        KorSpacing.screenEdge,
                        KorSpacing.s2,
                        KorSpacing.screenEdge,
                        KorSpacing.s3,
                      ),
                      sliver: SliverToBoxAdapter(child: _filters()),
                    ),
                    if (!hasEntries)
                      SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'Yaklaşan bir şey yok',
                          body: _filter == CalendarFilter.all
                              ? 'Önümüzdeki ${CalendarPage.days} günde planlı '
                                  'hatırlatma ya da doğum günü yok.'
                              : 'Bu filtreyle önümüzdeki '
                                  '${CalendarPage.days} günde bir şey yok.',
                          actionLabel: 'Hatırlatıcı ekle',
                          onAction: () => _quickAdd(selected, now),
                        ),
                      )
                    else
                      for (final day in agenda)
                        if (day.isEmpty)
                          SliverPadding(
                            padding: KorSpacing.screenPadding,
                            sliver: SliverToBoxAdapter(
                              child: EmptyDayRow(
                                day: day.date,
                                onTap: () => _quickAdd(day.date, now),
                              ),
                            ),
                          )
                        else
                          _daySliver(context, day, now, theme),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: bottom + KorSpacing.s7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filters() {
    IconData? icon(CalendarFilter f) => switch (f) {
          CalendarFilter.all => null,
          CalendarFilter.reminders => Icons.check_circle_outline_rounded,
          CalendarFilter.birthdays => Icons.cake_rounded,
          CalendarFilter.located => Icons.place_rounded,
        };
    return Wrap(
      spacing: KorSpacing.s3,
      runSpacing: KorSpacing.s3,
      children: [
        for (final f in CalendarFilter.values)
          ChoiceChip(
            key: CalendarPageKeys.filter(f),
            avatar: icon(f) == null ? null : Icon(icon(f)),
            label: Text(f.label),
            selected: _filter == f,
            onSelected: (_) => setState(() => _filter = f),
          ),
      ],
    );
  }

  Widget _daySliver(
    BuildContext context,
    AgendaDay day,
    DateTime now,
    ThemeData theme,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _DayHeaderDelegate(
            text: KorFormat.agendaDayHeader(day.date, now),
            textScaler: MediaQuery.textScalerOf(context),
            background: theme.scaffoldBackgroundColor,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SliverPadding(
          padding: KorSpacing.screenPadding,
          sliver: SliverList.list(
            children: [
              for (final o in day.birthdays)
                Padding(
                  padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
                  child: o.daysUntil >= 0
                      ? BirthdayCard(
                          occurrence: o,
                          now: now,
                          onTap: () => showBirthdayEditorSheet(
                            context,
                            existing: o.birthday,
                          ),
                        )
                      : BirthdayRow(
                          name: o.birthday.name,
                          subtitle: BirthdayGroups.rowSubtitle(o),
                          trailing: KorFormat.relativeDay(o.date, now),
                          onTap: () => showBirthdayEditorSheet(
                            context,
                            existing: o.birthday,
                          ),
                        ),
                ),
              for (final o in day.reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
                  child: o.isStored
                      ? AgendaReminderRow(
                          key: ValueKey(o.reminder.id),
                          occurrence: o,
                          now: now,
                        )
                      : AgendaOccurrenceRow(occurrence: o, now: now),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DayHeaderDelegate({
    required this.text,
    required this.textScaler,
    required this.background,
    required this.style,
  });

  final String text;
  final TextScaler textScaler;
  final Color background;
  final TextStyle? style;

  double get _extent {
    final lineHeight = (style?.fontSize ?? 14) * (style?.height ?? 1.43);
    return textScaler.scale(lineHeight) + KorSpacing.s6;
  }

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: background,
      alignment: AlignmentDirectional.centerStart,
      padding: KorSpacing.screenPadding,
      child: Semantics(
        header: true,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate old) =>
      old.text != text ||
      old.textScaler != textScaler ||
      old.background != background ||
      old.style != style;
}
