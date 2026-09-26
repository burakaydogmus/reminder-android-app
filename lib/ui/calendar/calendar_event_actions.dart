import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/ui/calendar/device_calendar_scope.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class CalendarEventSheetKeys {
  static const sheet = Key('calendarEventSheet');
  static const createReminder = Key('calendarEventSheet.createReminder');
}

/// Default hour for a reminder drafted from an all-day event.
const int kCalendarEventDraftHour = 9;

/// Opens [event] where the user expects it: the platform's own event view
/// (Android `ACTION_VIEW` on the event, i.e. the system calendar app; iOS
/// `EKEventViewController`), via the plugin's `showEventModal`.
///
/// `url_launcher` is deliberately not used — there is no cross-platform URL for
/// a calendar event, and probing one would need `<queries>` /
/// `LSApplicationQueriesSchemes` entries the project avoids (see CLAUDE.md ›
/// `config/app_links.dart`). When the platform cannot show the event (no
/// calendar app, the event disappeared) the read-only
/// [showCalendarEventSheet] is shown instead, so the tap is never a dead end.
Future<void> openCalendarEvent(
  BuildContext context,
  DeviceCalendarEvent event, {
  String? calendarName,
}) async {
  final controller = DeviceCalendarScope.maybeRead(context);
  final now = NowScope.clockOf(context);
  final opened = await (controller?.openEvent(event.id) ?? Future.value(false));
  if (opened || !context.mounted) return;
  await showCalendarEventSheet(
    context,
    event,
    calendarName: calendarName,
    now: now,
  );
}

/// Pre-fills the reminder editor from [event] (the one write-ish path, and it
/// writes only to this app's own store — never to the device calendar).
///
/// Title comes straight from the event. The time is the event's start; an
/// all-day event becomes [kCalendarEventDraftHour] on its first day. A start
/// that is already past becomes an **untimed** draft instead, because the
/// editor rightly refuses to save a past time (F1.8b) and a blocked save is
/// not a useful starting point.
Future<void> createReminderFromCalendarEvent(
  BuildContext context,
  DeviceCalendarEvent event, {
  String Function()? newId,
}) {
  final clock = NowScope.clockOf(context);
  final now = clock();
  return showReminderEditorSheet(
    context,
    draft: calendarEventDraft(
      event,
      now: now,
      id: (newId ?? const Uuid().v4)(),
    ),
    now: clock,
  );
}

/// Pure draft mapping for [createReminderFromCalendarEvent].
Reminder calendarEventDraft(
  DeviceCalendarEvent event, {
  required DateTime now,
  required String id,
}) {
  final at = event.isAllDay
      ? DateTime(
          event.start.year,
          event.start.month,
          event.start.day,
          kCalendarEventDraftHour,
        )
      : event.start;
  return Reminder(
    id: id,
    title: event.title,
    isDone: false,
    createdAt: now,
    remindAt: at.isAfter(now) ? at : null,
  );
}

/// Read-only detail sheet: the fallback when the platform cannot show the
/// event itself. It has no editing controls at all — only the facts and
/// "Hatırlatıcı oluştur".
Future<void> showCalendarEventSheet(
  BuildContext context,
  DeviceCalendarEvent event, {
  String? calendarName,
  DateTime Function()? now,
}) {
  final clock = now ?? NowScope.clockOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (ctx) => _CalendarEventSheet(
      event: event,
      calendarName: calendarName,
      clock: clock,
    ),
  );
}

class _CalendarEventSheet extends StatelessWidget {
  const _CalendarEventSheet({
    required this.event,
    required this.calendarName,
    required this.clock,
  });

  final DeviceCalendarEvent event;
  final String? calendarName;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final name = calendarName?.trim();
    final place = event.location;
    return SafeArea(
      key: CalendarEventSheetKeys.sheet,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KorSpacing.s6,
          KorSpacing.s5,
          KorSpacing.s6,
          KorSpacing.s6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.calendarEventDetailsTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: KorSpacing.s3),
            Text(event.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: KorSpacing.s5),
            GroupedCard(
              icon: Icons.schedule_rounded,
              title: l10n.calendarEventWhenLabel,
              children: [
                Text(_when(l10n), style: theme.textTheme.bodyLarge),
                if (name != null && name.isNotEmpty) ...[
                  const SizedBox(height: KorSpacing.s2),
                  Text(
                    l10n.calendarEventCalendarLabel(name),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (place != null) ...[
                  const SizedBox(height: KorSpacing.s2),
                  Text(
                    l10n.calendarEventLocationLabel(place),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: KorSpacing.s5),
            FilledButton.tonalIcon(
              key: CalendarEventSheetKeys.createReminder,
              onPressed: () {
                Navigator.of(context).pop();
                createReminderFromCalendarEvent(context, event);
              },
              icon: const Icon(Icons.add_alert_outlined),
              label: Text(l10n.calendarEventCreateReminder),
            ),
          ],
        ),
      ),
    );
  }

  /// Spoken-safe when line: an all-day event never shows a 00:00 time.
  String _when(AppLocalizations l10n) {
    final now = clock();
    final lastMoment = event.end.isAfter(event.start)
        ? event.end.subtract(const Duration(microseconds: 1))
        : event.start;
    final startDay = KorFormat.dayMonth(event.start, now, l10n);
    if (event.isAllDay) {
      final span = event.isMultiDay
          ? l10n.calendarEventMultiDay(
              startDay,
              KorFormat.dayMonth(lastMoment, now, l10n),
            )
          : startDay;
      return '$span  ·  ${l10n.calendarEventAllDay}';
    }
    final start = KorFormat.spokenWhen(event.start, now, l10n);
    if (!event.isMultiDay) {
      return '$start – ${KorFormat.spokenTime(event.end, l10n)}';
    }
    return l10n.calendarEventMultiDay(
      start,
      KorFormat.spokenWhen(event.end, now, l10n),
    );
  }
}
