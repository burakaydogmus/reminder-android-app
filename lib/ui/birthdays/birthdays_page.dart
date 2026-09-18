import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/birthdays/birthday_groups.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_row.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/theme/tokens/kor_typography.dart';

/// Keys for tests.
abstract final class BirthdaysPageKeys {
  static const hero = Key('birthdays.hero');
}

/// Listeler › Doğum günleri (§3.3.7): "SIRADAKİ" hero card, then every
/// birthday grouped by the month of its next occurrence.
class BirthdaysPage extends StatelessWidget {
  const BirthdaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = NowScope.now(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Doğum günü ekle',
            onPressed: () => showBirthdayEditorSheet(context),
            icon: const Icon(Icons.person_add_alt_rounded),
          ),
        ],
      ),
      body: BlocBuilder<ReminderCubit, ReminderState>(
        builder: (context, state) {
          final hero = BirthdayGroups.hero(state.birthdays, now);
          final groups = BirthdayGroups.byMonth(state.birthdays, now);
          final bottom = MediaQuery.paddingOf(context).bottom;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              KorSpacing.screenEdge,
              0,
              KorSpacing.screenEdge,
              bottom + KorSpacing.s7,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Doğum günleri',
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: KorSpacing.s5),
              if (hero == null)
                EmptyState(
                  title: 'Henüz doğum günü yok',
                  body: 'Sevdiklerinin gününü kaçırma. Rehberden içe aktarma '
                      'yakında.',
                  actionLabel: 'Doğum günü ekle',
                  onAction: () => showBirthdayEditorSheet(context),
                )
              else ...[
                _HeroCard(occurrence: hero, now: now),
                const SizedBox(height: KorSpacing.sectionGap),
              ],
              for (final group in groups) ...[
                SectionHeader(
                  title: KorFormat.upperTr(
                    BirthdayGroups.monthHeader(group.month, now),
                  ),
                ),
                for (final o in group.items)
                  BirthdayRow(
                    name: o.birthday.name,
                    subtitle: BirthdayGroups.rowSubtitle(o),
                    note: BirthdayGroups.leapDayNote(o),
                    trailing: KorFormat.countdown(o.daysUntil),
                    onTap: () =>
                        showBirthdayEditorSheet(context, existing: o.birthday),
                  ),
                const SizedBox(height: KorSpacing.s4),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "SIRADAKİ" card: birthday container, radius xl, name, "Yarın · 30
/// yaşına giriyor" and a large countdown. Text on the container uses
/// `onContainer` (icons would use `fg`).
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.occurrence, required this.now});

  final BirthdayOccurrence occurrence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CategoryVisuals.birthdayColorsOf(context);
    final b = occurrence.birthday;
    final line = BirthdayGroups.heroLine(occurrence, now);
    final note = BirthdayGroups.leapDayNote(occurrence);
    final days = occurrence.daysUntil;

    final Widget countdown = days == 0
        ? Text(
            'Bugün',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onContainer,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: KorTypography.displayTime.copyWith(
                  color: colors.onContainer,
                ),
              ),
              Text(
                'gün',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onContainer,
                ),
              ),
            ],
          );

    return Semantics(
      key: BirthdaysPageKeys.hero,
      button: true,
      label: [
        'Sıradaki doğum günü: ${b.name}',
        line,
        if (days > 1) '$days gün kaldı',
        if (note != null) note,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: colors.container,
        borderRadius: KorRadius.xlAll,
        child: InkWell(
          borderRadius: KorRadius.xlAll,
          onTap: () => showBirthdayEditorSheet(context, existing: b),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 152),
            child: Padding(
              padding: const EdgeInsets.all(KorSpacing.s6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SIRADAKİ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onContainer,
                          ),
                        ),
                        const SizedBox(height: KorSpacing.s2),
                        Text(
                          b.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: KorSpacing.s2),
                        Text(
                          line,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        if (note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: KorSpacing.s2),
                            child: Text(
                              note,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KorSpacing.s4),
                  countdown,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
