import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/ui/calendar/calendar_event_actions.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CalendarEventRowKeys {
  static Key event(String id) => ValueKey('calendarEvent.$id');
  static Key menu(String id) => ValueKey('calendarEvent.menu.$id');
}

/// A device calendar event in the Bugün ribbon area and the Takvim agenda
/// (F8.1).
///
/// Deliberately **not** a [ReminderCard]/[ReminderCompactCard]: a device event
/// is read-only, so this sibling has no completion toggle, no swipe and no
/// delete. What sets it apart visually is a 3 px leading rail in the
/// calendar's own colour (falling back to `outlineVariant`), the flat
/// `surfaceContainerLow` fill of a non-actionable card and a calendar glyph
/// where a reminder has its circle — state is never colour-only, so the
/// semantics label and the meta line both say it is a calendar event.
///
/// Tap opens the event in the platform's own calendar view; the ⋮ menu (and
/// the matching semantics actions, WCAG 2.5.7) offer "Takvimde aç" and
/// "Hatırlatıcı oluştur".
class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    required this.now,
    this.calendarName,
    this.showDateRange = false,
  });

  final DeviceCalendarEvent event;
  final DateTime now;

  /// Name of the owning calendar, shown in the meta line when known.
  final String? calendarName;

  /// Shows the day span instead of only the time (Bugün, where a multi-day
  /// event otherwise looks like it starts today).
  final bool showDateRange;

  /// Visual width of the calendar colour rail.
  static const double railWidth = 3;

  /// Trailing time text: "Tüm gün" for an all-day event, else `HH:mm`.
  static String trailingText(
    DeviceCalendarEvent event,
    AppLocalizations l10n,
  ) =>
      event.isAllDay ? l10n.calendarEventAllDay : KorFormat.time(event.start);

  /// Spoken label. Always names the row as a calendar event and says it is
  /// read-only, so a screen reader user does not look for a complete action;
  /// times go through [KorFormat.spokenTime] (§3.6 rule 11).
  static String semanticLabel(
    DeviceCalendarEvent event,
    DateTime now,
    AppLocalizations l10n, {
    String? calendarName,
  }) {
    final when = event.isAllDay
        ? l10n.calendarEventSpokenAllDay
        : KorFormat.spokenWhen(event.start, now, l10n);
    return [
      event.title,
      l10n.calendarEventSpoken,
      when,
      if (calendarName != null && calendarName.trim().isNotEmpty)
        calendarName.trim(),
      if (event.location != null) l10n.reminderSpokenPlace(event.location!),
      l10n.calendarEventSpokenReadOnly,
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final rail = event.isAllDay || event.isMultiDay
        ? scheme.secondary
        : scheme.outlineVariant;

    void open() =>
        openCalendarEvent(context, event, calendarName: calendarName);
    void createReminder() => createReminderFromCalendarEvent(context, event);

    return Semantics(
      key: CalendarEventRowKeys.event(event.id),
      container: true,
      button: true,
      label: semanticLabel(event, now, l10n, calendarName: calendarName),
      hint: l10n.calendarEventOpenInCalendar,
      onTap: open,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.calendarEventCreateReminder):
            createReminder,
        CustomSemanticsAction(label: l10n.calendarEventOpenInCalendar): open,
      },
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: korCardDecoration(context, flat: true),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: KorRadius.cardAll,
            onTap: open,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Non-semantic colour rail; the label carries the meaning.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: KorSpacing.s3,
                    ),
                    child: SizedBox(
                      width: railWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: rail,
                          borderRadius: KorRadius.smAll,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _body(context, theme, scheme, l10n)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final time = Text(
      trailingText(event, l10n),
      style: KorTimeText.of(context).copyWith(color: scheme.onSurfaceVariant),
    );
    // Large text: the time moves under the title instead of squeezing it,
    // exactly like `ReminderCard.stacksTime` (§3.6 rule 6).
    final stackTime = ReminderCard.stacksTime(context);
    return Padding(
      padding: KorSpacing.reminderCardPadding,
      child: Row(
        children: [
          Icon(
            Icons.event_outlined,
            size: KorSizes.iconSm,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: KorSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KorSpacing.s1),
                Text(
                  _meta(l10n),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
                if (stackTime) ...[
                  const SizedBox(height: KorSpacing.s1),
                  time,
                ],
              ],
            ),
          ),
          if (!stackTime) ...[
            const SizedBox(width: KorSpacing.s2),
            time,
          ],
          _menu(context, l10n),
        ],
      ),
    );
  }

  /// `Takvim etkinliği · <calendar> · <place>`, plus the day span for a
  /// multi-day event. The first part is always there, so the row never relies
  /// on its colour rail to say what it is.
  String _meta(AppLocalizations l10n) {
    final parts = <String>[l10n.calendarEventSpoken];
    if (showDateRange && (event.isMultiDay || event.isAllDay)) {
      parts.add(_span(l10n));
    }
    final name = calendarName?.trim();
    if (name != null && name.isNotEmpty) parts.add(name);
    final place = event.location;
    if (place != null) parts.add(place);
    return parts.join('  ·  ');
  }

  String _span(AppLocalizations l10n) {
    final lastMoment = event.end.isAfter(event.start)
        ? event.end.subtract(const Duration(microseconds: 1))
        : event.start;
    final start = KorFormat.pattern(l10n.dateFormatDayMonth, event.start, l10n);
    if (!event.isMultiDay) return start;
    final end = KorFormat.pattern(l10n.dateFormatDayMonth, lastMoment, l10n);
    return l10n.calendarEventMultiDay(start, end);
  }

  Widget _menu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<_CalendarEventAction>(
      key: CalendarEventRowKeys.menu(event.id),
      tooltip: l10n.calendarEventMoreActions,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _CalendarEventAction.open:
            openCalendarEvent(context, event, calendarName: calendarName);
          case _CalendarEventAction.createReminder:
            createReminderFromCalendarEvent(context, event);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _CalendarEventAction.createReminder,
          child: _MenuRow(
            icon: Icons.add_alert_outlined,
            label: l10n.calendarEventCreateReminder,
          ),
        ),
        PopupMenuItem(
          value: _CalendarEventAction.open,
          child: _MenuRow(
            icon: Icons.open_in_new_rounded,
            label: l10n.calendarEventOpenInCalendar,
          ),
        ),
      ],
    );
  }
}

enum _CalendarEventAction { open, createReminder }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: KorSpacing.s4),
        Flexible(child: Text(label)),
      ],
    );
  }
}
