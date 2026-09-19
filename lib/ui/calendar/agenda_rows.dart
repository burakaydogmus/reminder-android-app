import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/calendar/agenda.dart';
import 'package:reminder/ui/calendar/reschedule.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/recurrence_text.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
import 'package:reminder/ui/reminders/reminder_actions.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/subtask_progress.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class AgendaRowKeys {
  static Key reminder(String id) => ValueKey('agenda.reminder.$id');
  static Key occurrence(String id, DateTime at) =>
      ValueKey('agenda.occurrence.$id.${at.toIso8601String()}');
  static Key emptyDay(DateTime d) =>
      ValueKey('agenda.empty.${d.year}-${d.month}-${d.day}');
}

/// Spoken label of an agenda reminder row (same wording as `ReminderCard`,
/// plus the series note for later occurrences).
String agendaReminderLabel(
  ReminderOccurrence o,
  DateTime now,
  AppLocalizations l10n, {
  String? categoryLabel,
}) {
  final r = o.reminder;
  final at = o.at;
  final overdue = o.isStored && at.isBefore(now);
  final place = r.locationTriggerEnabled
      ? ((r.locationPlaceLabel?.trim().isNotEmpty ?? false)
          ? r.locationPlaceLabel!.trim()
          : l10n.reminderPlaceFallback)
      : null;
  return [
    r.title,
    categoryLabel ?? CategoryVisuals.builtInName(r.categoryId, l10n),
    KorFormat.spokenWhen(at, now, l10n),
    if (overdue) l10n.reminderSpokenOverdue,
    if (r.isRecurring)
      l10n.reminderSpokenRecurring(RecurrenceText.summary(r.recurrence, l10n)),
    if (place != null) l10n.reminderSpokenPlace(place),
    if (r.hasSubtasks) SubtaskProgressText.spoken(r.subtasks, l10n),
    ...PriorityPinVisuals.spokenParts(r, l10n),
    if (o.isStored) l10n.reminderSpokenOpen else l10n.calendarSeriesNext,
  ].join(', ');
}

/// The stored reminder in the agenda: a [ReminderCard] that can be dragged
/// onto a week-strip / month-grid day (long-press, then move).
///
/// Long-press and release without moving opens the calendar menu (Taşı…,
/// Tamamla, Ertele, Düzenle, Sil). The row is one semantics node with the
/// same custom actions plus "Taşı…" (drag alternative, WCAG 2.5.7).
class AgendaReminderRow extends StatefulWidget {
  const AgendaReminderRow({
    super.key,
    required this.occurrence,
    required this.now,
    this.onDragActive,
  });

  final ReminderOccurrence occurrence;
  final DateTime now;

  /// Called with `true` when a drag starts and `false` when it ends.
  final ValueChanged<bool>? onDragActive;

  /// Slightly shorter than the card's own long-press, so the drag wins the
  /// gesture arena; a release without movement then shows the menu.
  static const dragDelay = Duration(milliseconds: 400);

  @override
  State<AgendaReminderRow> createState() => _AgendaReminderRowState();
}

class _AgendaReminderRowState extends State<AgendaReminderRow> {
  double _moved = 0;

  static const _menuSlop = 16.0;

  Reminder get _reminder => widget.occurrence.reminder;

  @override
  Widget build(BuildContext context) {
    assert(AgendaReminderRow.dragDelay < kLongPressTimeout);
    final r = _reminder;
    final done = r.isDone;
    void toggle() => toggleReminderDoneWithUndo(context, r);
    void snooze() => snoozeReminderWithUndo(context, r);
    void edit() => showReminderEditorSheet(context, existing: r);
    void delete() => deleteReminderWithUndo(context, r);
    void move() => pickDayAndReschedule(context, r);
    void togglePin() => togglePinnedWithUndo(context, r);
    final l10n = context.l10n;

    final card = ReminderCard(
      reminder: r,
      now: widget.now,
      timeStyle: ReminderTimeStyle.timeOnly,
    );

    return Semantics(
      key: AgendaRowKeys.reminder(r.id),
      container: true,
      label: agendaReminderLabel(
        widget.occurrence,
        widget.now,
        l10n,
        categoryLabel: CategoryVisuals.labelOf(context, r.categoryId),
      ),
      onTap: edit,
      customSemanticsActions: {
        CustomSemanticsAction(
          label: done ? l10n.actionReopen : l10n.actionComplete,
        ): toggle,
        if (!done) CustomSemanticsAction(label: l10n.actionSnooze): snooze,
        CustomSemanticsAction(
          label: PriorityPinVisuals.pinActionLabel(r.pinned, l10n),
        ): togglePin,
        CustomSemanticsAction(label: l10n.actionEdit): edit,
        CustomSemanticsAction(label: l10n.calendarMove): move,
        CustomSemanticsAction(label: l10n.actionDelete): delete,
      },
      child: ExcludeSemantics(
        child: Builder(
          builder: (anchorContext) => LongPressDraggable<Reminder>(
            data: r,
            delay: AgendaReminderRow.dragDelay,
            feedback: _DragFeedback(reminder: r),
            childWhenDragging: Opacity(opacity: 0.4, child: card),
            onDragStarted: () {
              _moved = 0;
              widget.onDragActive?.call(true);
            },
            onDragUpdate: (d) => _moved += d.delta.distance,
            onDragEnd: (details) {
              widget.onDragActive?.call(false);
              if (!details.wasAccepted && _moved < _menuSlop && mounted) {
                showCalendarReminderMenu(anchorContext, r);
              }
            },
            child: card,
          ),
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CategoryVisuals.colorsOf(context, reminder.categoryId);
    final at = reminder.remindAt?.toLocal();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        elevation: 6,
        color: scheme.surfaceContainerHigh,
        borderRadius: KorRadius.cardAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KorSpacing.s4,
            vertical: KorSpacing.s3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CategoryVisuals.iconFor(context, reminder.categoryId),
                  color: colors.fg),
              const SizedBox(width: KorSpacing.s3),
              Flexible(
                child: Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (at != null) ...[
                const SizedBox(width: KorSpacing.s3),
                Text(KorFormat.time(at), style: KorTimeText.of(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CalendarMenuAction { move, toggleDone, snooze, togglePin, edit, delete }

/// Long-press menu of an agenda row: "Taşı…" first, then the card actions
/// (Tamamla / Geri aç, Ertele, Düzenle, Sil). Anchored to [context]'s widget.
Future<void> showCalendarReminderMenu(
  BuildContext context,
  Reminder reminder,
) async {
  final scheme = Theme.of(context).colorScheme;
  final l10n = context.l10n;
  final box = context.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null || !box.attached) return;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomRight = box.localToGlobal(
    box.size.bottomRight(Offset.zero),
    ancestor: overlay,
  );
  final position = RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    Offset.zero & overlay.size,
  );

  PopupMenuItem<_CalendarMenuAction> item(
    _CalendarMenuAction value,
    IconData icon,
    String label, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: KorSpacing.s4),
            Flexible(
              child: Text(
                label,
                style: color == null ? null : TextStyle(color: color),
              ),
            ),
          ],
        ),
      );

  final done = reminder.isDone;
  final action = await showMenu<_CalendarMenuAction>(
    context: context,
    position: position,
    items: [
      if (!done)
        item(
          _CalendarMenuAction.move,
          Icons.event_repeat_rounded,
          l10n.calendarMove,
        ),
      done
          ? item(
              _CalendarMenuAction.toggleDone,
              Icons.undo_rounded,
              l10n.actionReopen,
            )
          : item(
              _CalendarMenuAction.toggleDone,
              Icons.check_circle_outline_rounded,
              l10n.actionComplete,
            ),
      if (!done)
        item(
          _CalendarMenuAction.snooze,
          Icons.snooze_rounded,
          l10n.actionSnooze,
        ),
      item(
        _CalendarMenuAction.togglePin,
        PriorityPinVisuals.pinIcon(reminder.pinned),
        PriorityPinVisuals.pinActionLabel(reminder.pinned, l10n),
      ),
      item(_CalendarMenuAction.edit, Icons.edit_rounded, l10n.actionEdit),
      item(
        _CalendarMenuAction.delete,
        Icons.delete_outline_rounded,
        l10n.actionDelete,
        color: scheme.error,
      ),
    ],
  );
  if (!context.mounted) return;
  switch (action) {
    case _CalendarMenuAction.move:
      await pickDayAndReschedule(context, reminder);
    case _CalendarMenuAction.toggleDone:
      await toggleReminderDoneWithUndo(context, reminder);
    case _CalendarMenuAction.snooze:
      await snoozeReminderWithUndo(context, reminder);
    case _CalendarMenuAction.togglePin:
      await togglePinnedWithUndo(context, reminder);
    case _CalendarMenuAction.edit:
      await showReminderEditorSheet(context, existing: reminder);
    case _CalendarMenuAction.delete:
      await deleteReminderWithUndo(context, reminder);
    case null:
      break;
  }
}

/// A later occurrence of a recurring series: read-only, tap opens the
/// series in the editor (editing there changes the whole series).
class AgendaOccurrenceRow extends StatelessWidget {
  const AgendaOccurrenceRow({
    super.key,
    required this.occurrence,
    required this.now,
  });

  final ReminderOccurrence occurrence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = occurrence.reminder;
    final category = CategoryVisuals.colorsOf(context, r.categoryId);
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    WidgetSpan metaIcon(IconData icon, Color color) => WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: KorSpacing.s1),
            child: Icon(icon, size: 14, color: color),
          ),
        );

    return Semantics(
      key: AgendaRowKeys.occurrence(r.id, occurrence.at),
      container: true,
      button: true,
      label: agendaReminderLabel(
        occurrence,
        now,
        context.l10n,
        categoryLabel: CategoryVisuals.labelOf(context, r.categoryId),
      ),
      hint: context.l10n.calendarEditSeries,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: korCardDecoration(context, flat: true),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: KorRadius.cardAll,
            onTap: () => showReminderEditorSheet(context, existing: r),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: KorSpacing.reminderCardPadding,
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: KorSizes.minTouch,
                      child: Icon(
                        Icons.repeat_rounded,
                        size: KorSizes.iconSm,
                        color: category.fg,
                      ),
                    ),
                    const SizedBox(width: KorSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: KorSpacing.s1),
                          Text.rich(
                            TextSpan(
                              style: metaStyle,
                              children: [
                                metaIcon(
                                  CategoryVisuals.iconFor(
                                      context, r.categoryId),
                                  category.fg,
                                ),
                                TextSpan(
                                  text: CategoryVisuals.labelOf(
                                    context,
                                    r.categoryId,
                                  ),
                                  style: TextStyle(color: category.fg),
                                ),
                                const TextSpan(text: '  ·  '),
                                TextSpan(
                                  text: RecurrenceText.summary(
                                    r.recurrence,
                                    context.l10n,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: KorSpacing.s3),
                    Text(
                      KorFormat.time(occurrence.at),
                      style: KorTimeText.of(context).copyWith(
                        color: scheme.onSurfaceVariant,
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

/// `16 Eylül — boş gün` (48 h touch target, onSurfaceVariant); tap opens the reminder
/// editor preset to that day.
class EmptyDayRow extends StatelessWidget {
  const EmptyDayRow({super.key, required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  static String text(DateTime day, AppLocalizations l10n) =>
      l10n.calendarEmptyDay(
        KorFormat.pattern(l10n.dateFormatDayMonth, day, l10n),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.calendarEmptyDaySpoken(
        KorFormat.pattern(
            context.l10n.dateFormatDayMonthWeekday, day, context.l10n),
      ),
      hint: context.l10n.calendarEmptyDayHint,
      excludeSemantics: true,
      child: InkWell(
        key: AgendaRowKeys.emptyDay(day),
        onTap: onTap,
        borderRadius: KorRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text(day, context.l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  size: KorSizes.iconSm,
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
