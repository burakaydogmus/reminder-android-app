import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/components/kor_checkbox.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/reminder_actions.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/reminder_swipe.dart';
import 'package:reminder/ui/reminders/subtask_progress.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// How the trailing time is written.
enum ReminderTimeStyle {
  /// `18:30` today, `Yarın 09:00` / `14 Eyl 09:00` otherwise.
  relative,

  /// Always `18:30` (the day is given by a surrounding header).
  timeOnly,

  /// No trailing time (the Bugün ribbon shows it in its gutter).
  hidden,
}

/// Reminder card (§3.3.2, `components.ReminderCard`).
///
/// The leading [KorCheckbox] is its own 48 dp toggle target (cookie morph,
/// completion after a 900 ms hold, F4.7). Tap opens the editor,
/// long-press opens Tamamla / Ertele / Düzenle / Sil, and the same actions
/// are swipes ([ReminderSwipe]) and semantics custom actions (F3.5). Every
/// action offers "Geri al". Overdue is signalled by text + icon ("Gecikti"),
/// not by colour alone.
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.now,
    this.timeStyle = ReminderTimeStyle.relative,
  });

  final Reminder reminder;
  final DateTime now;
  final ReminderTimeStyle timeStyle;

  bool get _isOverdue {
    final at = reminder.remindAt;
    return !reminder.isDone && at != null && at.toLocal().isBefore(now);
  }

  String? get _placeLabel {
    if (!reminder.locationTriggerEnabled) return null;
    final label = reminder.locationPlaceLabel?.trim();
    return label != null && label.isNotEmpty ? label : 'Konum';
  }

  String _semanticLabel() {
    final at = reminder.remindAt?.toLocal();
    return [
      reminder.title,
      reminder.categoryDisplayLabel,
      if (at != null)
        '${KorFormat.relativeDay(at, now)} ${KorFormat.spokenTime(at)}',
      if (_isOverdue) 'gecikti',
      if (reminder.isRecurring) 'tekrar: ${reminder.recurrence.summary}',
      if (_placeLabel != null) 'konum: $_placeLabel',
      if (reminder.hasSubtasks) SubtaskProgressText.spoken(reminder.subtasks),
      reminder.isDone ? 'tamamlandı' : 'tamamlanmadı',
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = CategoryVisuals.colorsOf(context, reminder.categoryId);
    final done = reminder.isDone;
    final overdue = _isOverdue;
    final at = reminder.remindAt?.toLocal();
    final note = reminder.note?.trim();

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
    const separator = TextSpan(text: '  ·  ');

    final meta = TextSpan(
      style: metaStyle,
      children: [
        metaIcon(CategoryVisuals.iconFor(reminder.categoryId), category.fg),
        TextSpan(
          text: reminder.categoryDisplayLabel,
          style: TextStyle(color: category.fg),
        ),
        if (overdue) ...[
          separator,
          metaIcon(Icons.schedule_rounded, scheme.primary),
          TextSpan(text: 'Gecikti', style: TextStyle(color: scheme.primary)),
        ],
        if (reminder.isRecurring) ...[
          separator,
          metaIcon(Icons.repeat_rounded, scheme.onSurfaceVariant),
          TextSpan(text: reminder.recurrence.summary),
        ],
        if (_placeLabel != null) ...[
          separator,
          metaIcon(Icons.place_rounded, scheme.onSurfaceVariant),
          TextSpan(text: _placeLabel),
        ],
        if (reminder.hasSubtasks) ...[
          separator,
          metaIcon(Icons.check_box_outlined, scheme.onSurfaceVariant),
          TextSpan(text: SubtaskProgressText.count(reminder.subtasks)),
        ],
      ],
    );

    final timeText = at == null || timeStyle == ReminderTimeStyle.hidden
        ? null
        : (timeStyle == ReminderTimeStyle.timeOnly
            ? KorFormat.time(at)
            : KorFormat.when(at, now));

    void toggle() => toggleReminderDoneWithUndo(context, reminder);
    void snooze() => snoozeReminderWithUndo(context, reminder);
    void delete() => deleteReminderWithUndo(context, reminder);

    return ReminderSwipe(
      done: done,
      onComplete: toggle,
      onSnooze: done ? null : snooze,
      onDelete: delete,
      child: Semantics(
        container: true,
        label: _semanticLabel(),
        customSemanticsActions: {
          CustomSemanticsAction(label: done ? 'Geri aç' : 'Tamamla'): toggle,
          if (!done) const CustomSemanticsAction(label: 'Ertele'): snooze,
          const CustomSemanticsAction(label: 'Düzenle'): () =>
              showReminderEditorSheet(context, existing: reminder),
          const CustomSemanticsAction(label: 'Sil'): delete,
        },
        child: DecoratedBox(
          decoration: korCardDecoration(context, flat: done),
          child: Material(
            type: MaterialType.transparency,
            child: Builder(
              builder: (anchorContext) => InkWell(
                borderRadius: KorRadius.cardAll,
                onTap: () =>
                    showReminderEditorSheet(context, existing: reminder),
                onLongPress: () => showReminderMenu(anchorContext, reminder),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: KorSpacing.reminderCardPadding,
                    child: Row(
                      children: [
                        KorCheckbox(
                          value: done,
                          color: category.fg,
                          onColor: category.onFg,
                          onToggle: () => prepareToggleReminderDone(
                            context,
                            reminder,
                            hapticPlayed: true,
                          ),
                        ),
                        const SizedBox(width: KorSpacing.s3),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reminder.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        done ? scheme.onSurfaceVariant : null,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: KorSpacing.s1),
                                Text.rich(
                                  meta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (reminder.hasSubtasks)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: KorSpacing.s2,
                                      bottom: KorSpacing.s1,
                                    ),
                                    child: SubtaskProgressBar(
                                      subtasks: reminder.subtasks,
                                      color: category.fg,
                                      height: 3,
                                    ),
                                  ),
                                if (note != null && note.isNotEmpty)
                                  Text(
                                    note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (timeText != null) ...[
                          const SizedBox(width: KorSpacing.s3),
                          ExcludeSemantics(
                            child: Text(
                              timeText,
                              style: KorTimeText.of(context).copyWith(
                                color: overdue
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tabular time style derived from the theme (labelLarge + tabular figures).
abstract final class KorTimeText {
  static TextStyle of(BuildContext context) =>
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
