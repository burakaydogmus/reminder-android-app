import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  static final _dateFmt = DateFormat('d MMM yyyy, HH:mm', 'tr_TR');
  static final _timeFmt = DateFormat('HH:mm', 'tr_TR');

  /// `null` -> tümü
  String? _categoryFilter;

  bool _matchesFilter(Reminder r) =>
      _categoryFilter == null || r.categoryId == _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final all = state.reminders;
        final active =
            state.active.where(_matchesFilter).toList(growable: false);
        final done =
            state.completed.where(_matchesFilter).toList(growable: false);
        final birthdays = state.upcomingBirthdays;

        return SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 32 + 64 + 24, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Hatırlatmalar',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Alınacaklar, yapılacaklar — tek listede',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryFilterStrip(
                      reminders: all,
                      selected: _categoryFilter,
                      onChanged: (id) => setState(() => _categoryFilter = id),
                    ),
                    if (birthdays.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _BirthdaysStrip(birthdays: birthdays),
                    ],
                    const SizedBox(height: 12),
                    Expanded(
                      child: active.isEmpty && done.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _categoryFilter == null
                                      ? 'Henüz not yok.\nSağ alttan yeni hatırlatıcı ekleyin.'
                                      : 'Bu kategoride hatırlatıcı yok.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                if (active.isNotEmpty) ...[
                                  _SectionTitle(label: 'Açık', theme: theme),
                                  ...active.map(
                                    (r) => _ReminderTile(
                                      reminder: r,
                                      dateFmt: _dateFmt,
                                      timeFmt: _timeFmt,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (done.isNotEmpty) ...[
                                  _SectionTitle(
                                    label: 'Tamamlandı',
                                    theme: theme,
                                  ),
                                  ...done.map(
                                    (r) => _ReminderTile(
                                      reminder: r,
                                      dateFmt: _dateFmt,
                                      timeFmt: _timeFmt,
                                      muted: true,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 32 + 64 + 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'fab-birthday',
                      backgroundColor: kBirthdayAccent,
                      foregroundColor: Colors.white,
                      onPressed: () => showBirthdayEditorSheet(context),
                      child: const Icon(Icons.cake_rounded),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'fab-reminder',
                      onPressed: () => showReminderEditorSheet(context),
                      child: const Icon(Icons.add),
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
}

class _BirthdaysStrip extends StatelessWidget {
  final List<Birthday> birthdays;

  const _BirthdaysStrip({required this.birthdays});

  static final _dateFmt = DateFormat('d MMM', 'tr_TR');

  String _countdownLabel(int daysUntil) {
    if (daysUntil == 0) return 'Bugün!';
    if (daysUntil == 1) return 'Yarın';
    return '$daysUntil gün kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              const Icon(
                Icons.cake_rounded,
                size: 18,
                color: kBirthdayAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Yaklaşan doğum günleri',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kBirthdayAccent,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: birthdays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final b = birthdays[i];
              final daysUntil = b.daysUntilNext();
              final age = b.upcomingAge;
              final isImminent = daysUntil <= 1;

              return _BirthdayCard(
                title: b.name,
                subtitle: _dateFmt.format(b.nextOccurrence()),
                countdown: _countdownLabel(daysUntil),
                ageLabel: age != null ? '$age yaşına' : null,
                emphasize: isImminent,
                onTap: () => showBirthdayEditorSheet(context, existing: b),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String countdown;
  final String? ageLabel;
  final bool emphasize;
  final VoidCallback onTap;

  const _BirthdayCard({
    required this.title,
    required this.subtitle,
    required this.countdown,
    required this.ageLabel,
    required this.emphasize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const base = kBirthdayAccent;
    final bg = emphasize ? base : base.withValues(alpha: 0.12);
    final fg = emphasize ? Colors.white : base;
    final subFg = emphasize
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 180,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emphasize
                      ? Colors.white.withValues(alpha: 0.22)
                      : base.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cake_rounded, size: 22, color: fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      ageLabel != null ? '$subtitle · $ageLabel' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subFg.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterStrip extends StatelessWidget {
  final List<Reminder> reminders;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterStrip({
    required this.reminders,
    required this.selected,
    required this.onChanged,
  });

  int _countFor(String? id) {
    if (id == null) return reminders.length;
    return reminders.where((r) => r.categoryId == id).length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Tümü',
            icon: Icons.apps_rounded,
            color: Theme.of(context).primaryColor,
            count: _countFor(null),
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final id in ReminderCategoryIds.orderedIds)
            _CategoryChip(
              label: ReminderCategoryIds.defaultLabel(id),
              icon: CategoryVisuals.iconFor(id),
              color: CategoryVisuals.colorFor(id),
              count: _countFor(id),
              selected: selected == id,
              onTap: () => onChanged(selected == id ? null : id),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? color : color.withValues(alpha: 0.12);
    final fg = selected ? Colors.white : color;
    final labelColor = selected
        ? color
        : theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: fg, size: 24),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionTitle({
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final bool muted;

  const _ReminderTile({
    required this.reminder,
    required this.dateFmt,
    required this.timeFmt,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ReminderCubit>();
    final categoryColor = CategoryVisuals.colorFor(reminder.categoryId);
    final onSurface = theme.colorScheme.onSurface;
    final mutedTitleColor = onSurface.withValues(alpha: 0.45);
    final mutedSubtleColor = onSurface.withValues(alpha: 0.6);
    final mutedTimeColor = onSurface.withValues(alpha: 0.38);

    final remindAtLocal = reminder.remindAt?.toLocal();
    final isToday =
        remindAtLocal != null && _isSameDay(remindAtLocal, DateTime.now());
    final timeLine = remindAtLocal == null
        ? null
        : (isToday
            ? timeFmt.format(remindAtLocal)
            : dateFmt.format(remindAtLocal));

    final noteText = reminder.note?.trim();
    final catLabel = reminder.categoryDisplayLabel;
    final hasLocation = reminder.locationTriggerEnabled &&
        reminder.locationLatitude != null &&
        reminder.locationLongitude != null;

    final subtitleParts = <String>[catLabel];
    if (hasLocation) {
      final placeLabel = reminder.locationPlaceLabel?.trim();
      subtitleParts.add(
        placeLabel != null && placeLabel.isNotEmpty ? placeLabel : 'Geofence',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: muted
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showReminderEditorSheet(context, existing: reminder),
          onLongPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Silinsin mi?'),
                content: const Text('Bu hatırlatıcı kalıcı olarak silinir.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await cubit.deleteReminder(reminder.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => cubit.toggleDone(reminder.id),
                  child: CategoryIconBadge(
                    categoryId: reminder.categoryId,
                    size: 44,
                    muted: muted || reminder.isDone,
                    showCheck: reminder.isDone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reminder.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color:
                              muted || reminder.isDone ? mutedTitleColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitleParts.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: categoryColor.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (hasLocation) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.place_rounded,
                              size: 12,
                              color: categoryColor.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                      if (noteText != null && noteText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          noteText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedSubtleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (timeLine != null)
                  Text(
                    timeLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted ? mutedTimeColor : mutedSubtleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Zamansız',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedTimeColor,
                      fontStyle: FontStyle.italic,
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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
