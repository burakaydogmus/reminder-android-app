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
  String semanticLabel() {
    final at = reminder.remindAt?.toLocal();
    final place = reminder.locationTriggerEnabled
        ? ((reminder.locationPlaceLabel?.trim().isNotEmpty ?? false)
            ? reminder.locationPlaceLabel!.trim()
            : 'Konum')
        : null;
    return [
      reminder.title,
      reminder.categoryDisplayLabel,
      if (at != null)
        '${KorFormat.relativeDay(at, now)} ${KorFormat.spokenTime(at)}',
      if (_isOverdue) 'gecikti',
      if (place != null) 'konum: $place',
      if (reminder.hasSubtasks) SubtaskProgressText.spoken(reminder.subtasks),
      reminder.isDone ? 'tamamlandı' : 'tamamlanmadı',
    ].join(', ');
  }

  /// Category label, plus "☑ 2/6" when the reminder has subtasks (F3.3).
  InlineSpan _defaultSubtitle(Color categoryColor, Color mutedColor) {
    return TextSpan(
      children: [
        TextSpan(
          text: reminder.categoryDisplayLabel,
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
    final category = CategoryVisuals.colorsOf(context, reminder.categoryId);
    final done = reminder.isDone;

    void toggle() => toggleReminderDoneWithUndo(context, reminder);
    void snooze() => snoozeReminderWithUndo(context, reminder);
    void delete() => deleteReminderWithUndo(context, reminder);
    void edit() => showReminderEditorSheet(context, existing: reminder);

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
        label: semanticLabel(),
        customSemanticsActions: {
          CustomSemanticsAction(label: done ? 'Geri aç' : 'Tamamla'): toggle,
          if (!done) const CustomSemanticsAction(label: 'Ertele'): snooze,
          const CustomSemanticsAction(label: 'Düzenle'): edit,
          const CustomSemanticsAction(label: 'Sil'): delete,
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
                                  title ?? TextSpan(text: reminder.title),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                Text.rich(
                                  subtitle ??
                                      _defaultSubtitle(
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
