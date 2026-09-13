import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/tab_header.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Takvim — simple "Yaklaşan" agenda (week strip / month grid are F4.4):
/// next 30 days grouped by day with sticky headers, birthdays as all-day
/// rows.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  static const days = 30;

  @override
  Widget build(BuildContext context) {
    final now = NowScope.now(context);
    final theme = Theme.of(context);
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final agenda = buildAgenda(
          reminders: state.reminders,
          birthdays: state.birthdays,
          now: now,
          days: days,
        );
        final bottom = MediaQuery.paddingOf(context).bottom;

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: KorSpacing.screenPadding,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TabHeader(title: 'Takvim'),
                      Text(
                        'Yaklaşan · $days gün',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KorSpacing.s3),
                    ],
                  ),
                ),
              ),
              if (agenda.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Yaklaşan bir şey yok',
                    body: 'Önümüzdeki $days günde planlı hatırlatma ya da '
                        'doğum günü yok.',
                    actionLabel: 'Hatırlatıcı ekle',
                    onAction: () => showReminderEditorSheet(context),
                  ),
                )
              else
                for (final day in agenda)
                  SliverMainAxisGroup(
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
                                padding: const EdgeInsets.only(
                                  bottom: KorSpacing.cardGap,
                                ),
                                child: BirthdayCard(
                                  occurrence: o,
                                  now: now,
                                  onTap: () => showBirthdayEditorSheet(
                                    context,
                                    existing: o.birthday,
                                  ),
                                ),
                              ),
                            for (final r in day.reminders)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: KorSpacing.cardGap,
                                ),
                                child: ReminderCard(
                                  key: ValueKey(r.id),
                                  reminder: r,
                                  now: now,
                                  timeStyle: ReminderTimeStyle.timeOnly,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottom + KorSpacing.s7),
              ),
            ],
          ),
        );
      },
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
