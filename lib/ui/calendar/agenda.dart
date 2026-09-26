import 'package:reminder/domain/calendar_dates.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/recurrence_expansion.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

/// Date-only occurrence of a birthday.
///
/// Unlike `Birthday.nextOccurrence` this ignores the notification time, so a
/// birthday stays "today" for the whole day. A 29 February birthday falls on
/// 28 February in non-leap years (`Birthday.occurrenceInYear`, like the
/// notifications).
class BirthdayOccurrence {
  const BirthdayOccurrence({
    required this.birthday,
    required this.date,
    required this.daysUntil,
  });

  final Birthday birthday;

  /// Midnight of the occurrence.
  final DateTime date;

  /// Days from today to [date] (negative for a past occurrence).
  final int daysUntil;

  /// Age reached on [date]; `null` when the year is unknown or not plausible.
  int? get age {
    final birthYear = birthday.year;
    if (birthYear == null) return null;
    final a = date.year - birthYear;
    return a > 0 ? a : null;
  }

  /// A 29 February birthday celebrated on 28 February this time.
  bool get movedFromLeapDay =>
      birthday.month == DateTime.february &&
      birthday.day == 29 &&
      date.day == 28;

  /// The occurrence in [year] (date only).
  factory BirthdayOccurrence.inYear(Birthday b, int year, DateTime now) {
    final date = CalendarDates.dateOnly(b.occurrenceInYear(year));
    return BirthdayOccurrence(
      birthday: b,
      date: date,
      daysUntil: CalendarDates.dayDiff(now, date),
    );
  }

  /// The next occurrence on or after the day of [now].
  factory BirthdayOccurrence.next(Birthday b, DateTime now) {
    final today = CalendarDates.dateOnly(now);
    final thisYear = BirthdayOccurrence.inYear(b, today.year, now);
    return thisYear.date.isBefore(today)
        ? BirthdayOccurrence.inYear(b, today.year + 1, now)
        : thisYear;
  }
}

/// One timed row in the agenda: a reminder at one of its occurrences.
class ReminderOccurrence {
  const ReminderOccurrence({required this.reminder, required this.at});

  final Reminder reminder;
  final DateTime at;

  /// `true` for the stored reminder itself (its `remindAt`); `false` for a
  /// later occurrence of a recurring series, shown read-only.
  bool get isStored => reminder.remindAt?.toLocal() == at;
}

/// Takvim filter chips (§3.3.5).
enum CalendarFilter {
  all,
  reminders,
  birthdays,
  located;

  String labelIn(AppLocalizations l10n) => switch (this) {
        all => l10n.calendarFilterAll,
        reminders => l10n.calendarFilterReminders,
        birthdays => l10n.calendarFilterBirthdays,
        located => l10n.calendarFilterLocated,
      };

  bool get showsBirthdays =>
      this == CalendarFilter.all || this == CalendarFilter.birthdays;

  bool includes(Reminder r) => switch (this) {
        CalendarFilter.all || CalendarFilter.reminders => true,
        CalendarFilter.birthdays => false,
        CalendarFilter.located => r.locationTriggerEnabled,
      };
}

/// One day in the Takvim agenda.
class AgendaDay {
  const AgendaDay({
    required this.date,
    required this.birthdays,
    required this.reminders,
  });

  /// Midnight of the day.
  final DateTime date;

  /// All-day rows, shown first.
  final List<BirthdayOccurrence> birthdays;

  /// Timed, not-done reminder occurrences sorted by time.
  final List<ReminderOccurrence> reminders;

  bool get isEmpty => birthdays.isEmpty && reminders.isEmpty;
}

/// Not-done timed reminders expanded to their occurrences in `[from, to)`.
List<ReminderOccurrence> _occurrences(
  List<Reminder> reminders,
  DateTime from,
  DateTime to,
  CalendarFilter filter,
) {
  return [
    for (final r in reminders)
      if (!r.isDone && filter.includes(r))
        for (final at in reminderOccurrences(r, from: from, to: to))
          ReminderOccurrence(reminder: r, at: at),
  ];
}

/// Birthday occurrences whose date is in `[from, to)`.
List<BirthdayOccurrence> _birthdayOccurrences(
  List<Birthday> birthdays,
  DateTime from,
  DateTime to,
  DateTime now,
) {
  return [
    for (final b in birthdays)
      for (var y = from.year; y <= to.year; y++)
        if (BirthdayOccurrence.inYear(b, y, now) case final o
            when !o.date.isBefore(from) && o.date.isBefore(to))
          o,
  ];
}

/// Takvim agenda: [days] days starting at the day of [from] (default: the
/// day of [now]).
///
/// - Reminders: not done, timed, matching [filter]; recurring ones appear at
///   every occurrence in the range ([reminderOccurrences]). Overdue items of
///   the range are kept (the card says "Gecikti").
/// - Birthdays: all-day rows (not with [CalendarFilter.reminders] /
///   [CalendarFilter.located]).
/// - With [includeEmptyDays] every day of the range is returned (the page
///   shows "boş gün" rows); otherwise days without entries are omitted.
List<AgendaDay> buildAgenda({
  required List<Reminder> reminders,
  required List<Birthday> birthdays,
  required DateTime now,
  DateTime? from,
  int days = 30,
  CalendarFilter filter = CalendarFilter.all,
  bool includeEmptyDays = false,
}) {
  final start = CalendarDates.dateOnly(from ?? now);
  final end = CalendarDates.addDays(start, days);

  final remindersByDay = <DateTime, List<ReminderOccurrence>>{};
  for (final o in _occurrences(reminders, start, end, filter)) {
    remindersByDay.putIfAbsent(CalendarDates.dateOnly(o.at), () => []).add(o);
  }

  final birthdaysByDay = <DateTime, List<BirthdayOccurrence>>{};
  if (filter.showsBirthdays) {
    for (final o in _birthdayOccurrences(birthdays, start, end, now)) {
      birthdaysByDay.putIfAbsent(o.date, () => []).add(o);
    }
  }

  final dates = includeEmptyDays
      ? [for (var i = 0; i < days; i++) CalendarDates.addDays(start, i)]
      : ({...remindersByDay.keys, ...birthdaysByDay.keys}.toList()..sort());
  return [
    for (final date in dates)
      AgendaDay(
        date: date,
        birthdays: List.unmodifiable(
          (birthdaysByDay[date] ?? <BirthdayOccurrence>[])
            ..sort((a, b) => a.birthday.name.compareTo(b.birthday.name)),
        ),
        reminders: List.unmodifiable(
          (remindersByDay[date] ?? <ReminderOccurrence>[])
            ..sort((a, b) {
              final byTime = a.at.compareTo(b.at);
              return byTime != 0
                  ? byTime
                  : compareReminders(a.reminder, b.reminder);
            }),
        ),
      ),
  ];
}

/// One dot on a week strip / month grid day.
///
/// Either a category colour (a reminder's category, or `dogumGunu` for a
/// birthday) or the **neutral** device calendar marker (F8.3): a device event
/// has no category, so it cannot be expressed as a [KorColorKey] and gets its
/// own token (`KorColors.deviceEvent`). The UI decides the colour
/// (`CategoryDots`); this stays a pure value.
class CalendarDayMarker {
  /// A reminder category or birthday colour.
  const CalendarDayMarker.category(KorColorKey key) : colorKey = key;

  /// A device calendar event (F8.1) — neutral, no category.
  const CalendarDayMarker.deviceEvent() : colorKey = null;

  /// The category colour, or `null` for [CalendarDayMarker.deviceEvent].
  final KorColorKey? colorKey;

  bool get isDeviceEvent => colorKey == null;

  @override
  bool operator ==(Object other) =>
      other is CalendarDayMarker && other.colorKey == colorKey;

  @override
  int get hashCode => colorKey.hashCode;

  @override
  String toString() =>
      colorKey == null ? 'CalendarDayMarker.deviceEvent' : 'marker:$colorKey';
}

/// Day dots for the week strip / month grid: per day in `[from, to)`, at most
/// [maxDots] distinct markers — birthdays (`dogumGunu`) first, then reminder
/// categories in time order, then the neutral device calendar marker for every
/// day in [deviceEventDays]. Days without entries are absent.
///
/// The device marker comes **last** on purpose: on a day already at [maxDots]
/// the user's own reminders keep their dots, and a read-only device event never
/// pushes one out. Unlike reminders and birthdays it is not gated by [filter] —
/// the agenda shows device event cards under every filter too, so the dots
/// follow the rows.
///
/// [deviceEventDays] holds midnights (`CalendarDates.dateOnly`) of days that
/// have at least one device event. The caller passes it only while the calendar
/// feature is on, and the controller has already applied the per-calendar
/// selection when it read those events, so there is nothing to filter here.
Map<DateTime, List<CalendarDayMarker>> calendarDayMarkers({
  required List<Reminder> reminders,
  required List<Birthday> birthdays,
  required DateTime now,
  required DateTime from,
  required DateTime to,
  CalendarFilter filter = CalendarFilter.all,
  int maxDots = 3,
  CategoryCatalog? categories,
  Set<DateTime> deviceEventDays = const {},
}) {
  final start = CalendarDates.dateOnly(from);
  final end = CalendarDates.dateOnly(to);
  final keys = <DateTime, List<CalendarDayMarker>>{};
  void add(DateTime day, CalendarDayMarker marker) {
    final list = keys.putIfAbsent(day, () => []);
    if (list.length < maxDots && !list.contains(marker)) list.add(marker);
  }

  if (filter.showsBirthdays) {
    for (final o in _birthdayOccurrences(birthdays, start, end, now)) {
      add(
        o.date,
        const CalendarDayMarker.category(CategoryVisuals.birthdayColorKey),
      );
    }
  }
  final occurrences = _occurrences(reminders, start, end, filter)
    ..sort((a, b) => a.at.compareTo(b.at));
  for (final o in occurrences) {
    add(
      CalendarDates.dateOnly(o.at),
      CalendarDayMarker.category(
        CategoryVisuals.colorKeyFor(o.reminder.categoryId, categories),
      ),
    );
  }
  for (final day in deviceEventDays) {
    if (day.isBefore(start) || !day.isBefore(end)) continue;
    add(day, const CalendarDayMarker.deviceEvent());
  }
  return {
    for (final e in keys.entries) e.key: List.unmodifiable(e.value),
  };
}
