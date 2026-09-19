import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
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

/// A smaller reminder row with caller-provided text spans: completed items
/// on the Bugün ribbon (56 h, level 0) and search results (highlighted
/// title, note context).
///
/// Keeps every [ReminderCard] contract (F3.5): the leading circle is its own
/// 48 dp toggle, tap opens the editor, long-press opens the menu, swipes, and
/// the row is **one** semantics node with Tamamla / Geri aç, Ertele, Düzenle,
/// Sil custom actions.
class ReminderCompactCard extends StatelessWidget {
  const ReminderCompactCard({
    super.key,
    required this.reminder,
    required this.now,
    this.title,
    this.subtitle,
    this.detail,
    this.minHeight = 56,
    this.onOpen,
  });

  final Reminder reminder;
  final DateTime now;

  /// Title span; defaults to the plain title (struck through when done).
  final InlineSpan? title;

  /// First meta line; defaults to the category label.
  final InlineSpan? subtitle;

  /// Optional second line (e.g. note context).
  final InlineSpan? detail;
  final double minHeight;

  /// Called before the editor opens from a tap (e.g. to save a search).
  final VoidCallback? onOpen;

  bool get _isOverdue {
    final at = reminder.remindAt;
    return !reminder.isDone && at != null && at.toLocal().isBefore(now);
  }

  /// Same wording as [ReminderCard]'s label.
  String semanticLabel(String categoryLabel, AppLocalizations l10n) {
    final at = reminder.remindAt?.toLocal();
    final place = reminder.locationTriggerEnabled
        ? ((reminder.locationPlaceLabel?.trim().isNotEmpty ?? false)
            ? reminder.locationPlaceLabel!.trim()
            : l10n.reminderPlaceFallback)
        : null;
    return [
      reminder.title,
      categoryLabel,
      if (at != null) KorFormat.spokenWhen(at, now, l10n),
      if (_isOverdue) l10n.reminderSpokenOverdue,
      if (place != null) l10n.reminderSpokenPlace(place),
      if (reminder.hasSubtasks)
        SubtaskProgressText.spoken(reminder.subtasks, l10n),
      ...PriorityPinVisuals.spokenParts(reminder, l10n),
      reminder.isDone ? l10n.reminderSpokenDone : l10n.reminderSpokenOpen,
    ].join(', ');
  }

  /// Category label, plus "☑ 2/6" when the reminder has subtasks (F3.3).
  InlineSpan _defaultSubtitle(
    String categoryLabel,
    Color categoryColor,
    Color mutedColor,
  ) {
    return TextSpan(
      children: [
        TextSpan(
          text: categoryLabel,
          style: TextStyle(color: categoryColor),
        ),
        if (reminder.hasSubtasks) ...[
          const TextSpan(text: '  ·  '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: KorSpacing.s1),
              child:
                  Icon(Icons.check_box_outlined, size: 14, color: mutedColor),
            ),
          ),
          TextSpan(text: SubtaskProgressText.count(reminder.subtasks)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final category = CategoryVisuals.colorsOf(context, reminder.categoryId);
    final categoryLabel = CategoryVisuals.labelOf(context, reminder.categoryId);
    final done = reminder.isDone;

    void toggle() => toggleReminderDoneWithUndo(context, reminder);
    void snooze() => snoozeReminderWithUndo(context, reminder);
    void delete() => deleteReminderWithUndo(context, reminder);
    void edit() => showReminderEditorSheet(context, existing: reminder);
    void togglePin() => togglePinnedWithUndo(context, reminder);

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: done ? TextDecoration.lineThrough : null,
    );
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return ReminderSwipe(
      done: done,
      onComplete: toggle,
      onSnooze: done ? null : snooze,
      onDelete: delete,
      child: Semantics(
        container: true,
        label: semanticLabel(categoryLabel, l10n),
        customSemanticsActions: {
          CustomSemanticsAction(
            label: done ? l10n.actionReopen : l10n.actionComplete,
          ): toggle,
          if (!done) CustomSemanticsAction(label: l10n.actionSnooze): snooze,
          CustomSemanticsAction(
            label: PriorityPinVisuals.pinActionLabel(reminder.pinned, l10n),
          ): togglePin,
          CustomSemanticsAction(label: l10n.actionEdit): edit,
          CustomSemanticsAction(label: l10n.actionDelete): delete,
        },
        child: DecoratedBox(
          decoration: korCardDecoration(context, flat: done),
          child: Material(
            type: MaterialType.transparency,
            child: Builder(
              builder: (anchorContext) => InkWell(
                borderRadius: KorRadius.cardAll,
                onTap: () {
                  onOpen?.call();
                  edit();
                },
                onLongPress: () => showReminderMenu(anchorContext, reminder),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KorSpacing.s2,
                      KorSpacing.s2,
                      KorSpacing.s5,
                      KorSpacing.s2,
                    ),
                    child: Row(
                      children: [
                        KorCheckbox(
                          value: done,
                          size: compactCheckboxSize,
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
                        const SizedBox(width: KorSpacing.s2),
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
                                        PriorityPinVisuals.titlePin(
                                          scheme,
                                          size: 14,
                                        ),
                                      title ?? TextSpan(text: reminder.title),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                Text.rich(
                                  subtitle ??
                                      _defaultSubtitle(
                                        categoryLabel,
                                        category.fg,
                                        scheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: metaStyle,
                                ),
                                if (detail != null)
                                  Text.rich(
                                    detail!,
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
                        if (reminder.hasPriority)
                          // Trailing "!!" marker (§3.3.2); spoken through
                          // the row label.
                          ExcludeSemantics(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: KorSpacing.s2,
                              ),
                              child: Text(
                                ReminderPriority.marker(reminder.priority),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: PriorityPinVisuals.markerColor(
                                    scheme,
                                    reminder.priority,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

/// Visual size of the compact rows' [KorCheckbox] (48 dp target).
const double compactCheckboxSize = 22;
