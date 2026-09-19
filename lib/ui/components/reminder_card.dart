import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/recurrence_text.dart';
import 'package:reminder/ui/components/kor_checkbox.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
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

  /// Text scale above which the time sits under the title (§3.6 rule 6:
  /// "11 Eyl 09:15" beside the title overflows at 200 %).
  static const double stackedTimeScale = 1.3;

  /// Whether the time is written under the title in [context].
  static bool stacksTime(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(100) / 100 > stackedTimeScale;

  bool get _isOverdue {
    final at = reminder.remindAt;
    return !reminder.isDone && at != null && at.toLocal().isBefore(now);
  }

  String? _placeLabel(AppLocalizations l10n) {
    if (!reminder.locationTriggerEnabled) return null;
    final label = reminder.locationPlaceLabel?.trim();
    return label != null && label.isNotEmpty
        ? label
        : l10n.reminderPlaceFallback;
  }

  String _semanticLabel(String categoryLabel, AppLocalizations l10n) {
    final at = reminder.remindAt?.toLocal();
    final place = _placeLabel(l10n);
    return [
      reminder.title,
      categoryLabel,
      if (at != null) KorFormat.spokenWhen(at, now, l10n),
      if (_isOverdue) l10n.reminderSpokenOverdue,
      if (reminder.isRecurring)
        l10n.reminderSpokenRecurring(
          RecurrenceText.summary(reminder.recurrence, l10n),
        ),
      if (place != null) l10n.reminderSpokenPlace(place),
      if (reminder.hasSubtasks)
        SubtaskProgressText.spoken(reminder.subtasks, l10n),
      ...PriorityPinVisuals.spokenParts(reminder, l10n),
      reminder.isDone ? l10n.reminderSpokenDone : l10n.reminderSpokenOpen,
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final category = CategoryVisuals.colorsOf(context, reminder.categoryId);
    final categoryLabel = CategoryVisuals.labelOf(context, reminder.categoryId);
    final placeLabel = _placeLabel(l10n);
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
        metaIcon(
            CategoryVisuals.iconFor(context, reminder.categoryId), category.fg),
        TextSpan(
          text: categoryLabel,
          style: TextStyle(color: category.fg),
        ),
        if (overdue) ...[
          separator,
          metaIcon(Icons.schedule_rounded, scheme.primary),
          TextSpan(
            text: l10n.reminderOverdue,
            style: TextStyle(color: scheme.primary),
          ),
        ],
        if (reminder.isRecurring) ...[
          separator,
          metaIcon(Icons.repeat_rounded, scheme.onSurfaceVariant),
          TextSpan(text: RecurrenceText.summary(reminder.recurrence, l10n)),
        ],
        if (placeLabel != null) ...[
          separator,
          metaIcon(Icons.place_rounded, scheme.onSurfaceVariant),
          TextSpan(text: placeLabel),
        ],
        if (reminder.hasSubtasks) ...[
          separator,
          metaIcon(Icons.check_box_outlined, scheme.onSurfaceVariant),
          TextSpan(text: SubtaskProgressText.count(reminder.subtasks)),
        ],
        if (reminder.hasPriority) ...[
          separator,
          ...PriorityPinVisuals.metaSpans(scheme, reminder.priority, l10n),
        ],
      ],
    );

    final timeText = at == null || timeStyle == ReminderTimeStyle.hidden
        ? null
        : (timeStyle == ReminderTimeStyle.timeOnly
            ? KorFormat.time(at)
            : KorFormat.when(at, now, l10n));

    final timeWidget = timeText == null
        ? null
        : ExcludeSemantics(
            child: Text(
              timeText,
              style: KorTimeText.of(context).copyWith(
                color: overdue ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          );
    // Large text: the time moves under the title instead of squeezing it.
    final stackTime = timeWidget != null && ReminderCard.stacksTime(context);

    void toggle() => toggleReminderDoneWithUndo(context, reminder);
    void snooze() => snoozeReminderWithUndo(context, reminder);
    void delete() => deleteReminderWithUndo(context, reminder);
    void togglePin() => togglePinnedWithUndo(context, reminder);

    return ReminderSwipe(
      done: done,
      onComplete: toggle,
      onSnooze: done ? null : snooze,
      onDelete: delete,
      child: Semantics(
        container: true,
        label: _semanticLabel(categoryLabel, l10n),
        customSemanticsActions: {
          CustomSemanticsAction(
            label: done ? l10n.actionReopen : l10n.actionComplete,
          ): toggle,
          if (!done) CustomSemanticsAction(label: l10n.actionSnooze): snooze,
          CustomSemanticsAction(
            label: PriorityPinVisuals.pinActionLabel(reminder.pinned, l10n),
          ): togglePin,
          CustomSemanticsAction(label: l10n.actionEdit): () =>
              showReminderEditorSheet(context, existing: reminder),
          CustomSemanticsAction(label: l10n.actionDelete): delete,
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
                          ring: PriorityPinVisuals.checkboxRing(
                            context,
                            reminder,
                          ),
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
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      if (reminder.pinned)
                                        PriorityPinVisuals.titlePin(scheme),
                                      TextSpan(text: reminder.title),
                                    ],
                                  ),
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
                                if (stackTime) timeWidget,
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
                        if (timeWidget != null && !stackTime) ...[
                          const SizedBox(width: KorSpacing.s3),
                          timeWidget,
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
