import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/birthday_card.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Listeler › Doğum günleri: all birthdays, soonest first (hero card and
/// month grouping are F4.4).
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
          final items = [
            for (final b in state.birthdays) BirthdayOccurrence.next(b, now),
          ]..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
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
              if (items.isEmpty)
                EmptyState(
                  title: 'Henüz doğum günü yok',
                  body: 'Sevdiklerinin gününü kaçırma. Rehberden içe aktarma '
                      'yakında.',
                  actionLabel: 'Doğum günü ekle',
                  onAction: () => showBirthdayEditorSheet(context),
                ),
              for (final o in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
                  child: BirthdayCard(
                    occurrence: o,
                    now: now,
                    onTap: () =>
                        showBirthdayEditorSheet(context, existing: o.birthday),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
