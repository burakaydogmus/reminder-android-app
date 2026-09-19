import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/calendar_dates.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CalendarStripKeys {
  static Key day(DateTime d) =>
      ValueKey('calendar.day.${d.year}-${d.month}-${d.day}');
  static const strip = Key('calendar.weekStrip');
  static const grid = Key('calendar.monthGrid');
  static const handle = Key('calendar.expandHandle');
}

/// Drop handling shared by week-strip and month-grid days.
class DayDropHandler {
  const DayDropHandler({required this.canAccept, required this.onAccept});

  final bool Function(Reminder reminder, DateTime day) canAccept;
  final void Function(Reminder reminder, DateTime day) onAccept;
}

/// Spoken date for a day cell: `Pazartesi 14 Eylül, bugün, planlı kayıt var`.
String daySemanticsLabel(
  DateTime day,
  AppLocalizations l10n, {
  required bool today,
  required bool hasEntries,
}) {
  return [
    KorFormat.pattern(l10n.dateFormatAgenda, day, l10n),
    if (today) l10n.calendarDayToday,
    if (hasEntries) l10n.calendarDayHasEntries,
  ].join(', ');
}

/// ≤3 category dots (5 px).
class CategoryDots extends StatelessWidget {
  const CategoryDots({super.key, required this.keys});

  final List<KorColorKey> keys;

  static const double size = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.korColors;
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: KorSpacing.s1),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colors.category(keys[i]).fg,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One day (week-strip pill or month-grid cell): selected = `primary` fill,
/// today = 1.5 px `primary` ring, dots below, drop target while dragging a
/// reminder.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.today,
    required this.selected,
    required this.dots,
    required this.onTap,
    this.drop,
    this.showWeekday = true,
    this.outsideMonth = false,
  });

  final DateTime day;
  final bool today;
  final bool selected;
  final List<KorColorKey> dots;
  final VoidCallback onTap;
  final DayDropHandler? drop;
  final bool showWeekday;
  final bool outsideMonth;

  @override
  Widget build(BuildContext context) {
    final drop = this.drop;
    if (drop == null) return _cell(context, hovering: false);
    return DragTarget<Reminder>(
      onWillAcceptWithDetails: (d) => drop.canAccept(d.data, day),
      onAcceptWithDetails: (d) => drop.onAccept(d.data, day),
      builder: (context, candidates, _) =>
          _cell(context, hovering: candidates.isNotEmpty),
    );
  }

  Widget _cell(BuildContext context, {required bool hovering}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color? fill = selected
        ? scheme.primary
        : hovering
            ? scheme.primaryContainer
            : null;
    final Color text = selected
        ? scheme.onPrimary
        : hovering
            ? scheme.onPrimaryContainer
            : outsideMonth
                ? scheme.onSurfaceVariant
                : scheme.onSurface;
    final ring = (today && !selected) || hovering
        ? BorderSide(color: scheme.primary, width: hovering ? 2 : 1.5)
        : BorderSide.none;

    return Semantics(
      button: true,
      selected: selected,
      label: daySemanticsLabel(
        day,
        context.l10n,
        today: today,
        hasEntries: dots.isNotEmpty,
      ),
      excludeSemantics: true,
      child: InkWell(
        key: CalendarStripKeys.day(day),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: KorSizes.minTouch,
            minHeight: KorSizes.minTouch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s1),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: fill,
                shape: StadiumBorder(side: ring),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showWeekday)
                      Text(
                        KorFormat.weekdayShort(day.weekday, context.l10n),
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected || hovering
                              ? text
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      '${day.day}',
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: KorSpacing.s1),
                    CategoryDots(keys: dots),
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

/// Height of a week-strip pill for the current text scale (≥ 68, §3.3.5).
double weekStripHeight(BuildContext context) {
  final theme = Theme.of(context).textTheme;
  final scaler = MediaQuery.textScalerOf(context);
  double line(TextStyle? s) =>
      scaler.scale((s?.fontSize ?? 14) * (s?.height ?? 1.4));
  final content = line(theme.labelSmall) +
      line(theme.titleMedium) +
      KorSpacing.s1 +
      CategoryDots.size +
      KorSpacing.s3 * 2;
  // A little slack for font metrics rounding.
  return math.max(68, content + KorSpacing.s2);
}

/// Mon–Sun week strip; a horizontal swipe (fling) moves to the previous /
/// next week with a short slide (none under Reduce Motion). The header's
/// chevrons are the button alternative. Not a `Scrollable`, so the agenda
/// stays the page's only vertical scroll view.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.week,
    required this.today,
    required this.selected,
    required this.dotsFor,
    required this.onSelect,
    required this.onWeekChange,
    this.direction = 0,
    this.drop,
  });

  /// Any day of the shown week.
  final DateTime week;
  final DateTime today;
  final DateTime selected;
  final List<KorColorKey> Function(DateTime day) dotsFor;
  final ValueChanged<DateTime> onSelect;

  /// `-1` previous week, `1` next week.
  final ValueChanged<int> onWeekChange;

  /// Direction of the last change (slide-in side); `0` = no slide.
  final int direction;
  final DayDropHandler? drop;

  static const _swipeVelocity = 200.0;

  @override
  Widget build(BuildContext context) {
    final days = CalendarDates.weekDays(week);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: CalendarStripKeys.strip,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -_swipeVelocity) onWeekChange(1);
        if (v > _swipeVelocity) onWeekChange(-1);
      },
      child: SizedBox(
        height: weekStripHeight(context),
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(days.first);
              final dx = direction == 0
                  ? 0.0
                  : (incoming ? direction : -direction) * 0.3;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey(days.first),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in days)
                  Expanded(
                    child: CalendarDayCell(
                      day: d,
                      today: CalendarDates.isSameDay(d, today),
                      selected: CalendarDates.isSameDay(d, selected),
                      dots: dotsFor(d),
                      onTap: () => onSelect(d),
                      drop: drop,
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

/// 6×7 month grid (Mon-first) with the same day cells; horizontal fling
/// changes the month (the header's chevrons are the button alternative).
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.selected,
    required this.dotsFor,
    required this.onSelect,
    required this.onMonthChange,
    this.drop,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<KorColorKey> Function(DateTime day) dotsFor;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onMonthChange;
  final DayDropHandler? drop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = CalendarDates.monthGrid(month);
    return GestureDetector(
      key: CalendarStripKeys.grid,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) onMonthChange(1);
        if (v > 200) onMonthChange(-1);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  Expanded(
                    child: Text(
                      KorFormat.weekdayShort(d, context.l10n),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: KorSpacing.s2),
          for (var row = 0; row < 6; row++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in days.sublist(row * 7, row * 7 + 7))
                  Expanded(
                    child: CalendarDayCell(
                      day: d,
                      today: CalendarDates.isSameDay(d, today),
                      selected: CalendarDates.isSameDay(d, selected),
                      dots: dotsFor(d),
                      onTap: () => onSelect(d),
                      drop: drop,
                      showWeekday: false,
                      outsideMonth: d.month != month.month,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Drag handle under the strip: pull down → month grid, up → week strip.
/// Decorative for screen readers (the ▦ button is the alternative).
class ExpandHandle extends StatelessWidget {
  const ExpandHandle({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: GestureDetector(
        key: CalendarStripKeys.handle,
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if ((v > 0 && !expanded) || (v < 0 && expanded)) onToggle();
        },
        child: SizedBox(
          height: KorSpacing.s6,
          child: Center(
            child: Container(
              width: KorSpacing.s8,
              height: KorSpacing.s2,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: KorRadius.fullAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
