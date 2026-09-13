import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/ui/common/kor_format.dart';

/// Date-only next occurrence of a birthday, counted from the day of [now].
///
/// Unlike `Birthday.nextOccurrence` this ignores the notification time, so a
/// birthday stays "today" for the whole day.
class BirthdayOccurrence {
  const BirthdayOccurrence({
    required this.birthday,
    required this.date,
    required this.daysUntil,
  });

  final Birthday birthday;

  /// Midnight of the occurrence.
  final DateTime date;
  final int daysUntil;

  /// Age reached on [date]; `null` when the stored year is not plausible.
  int? get age {
    final a = date.year - birthday.date.year;
    return a > 0 ? a : null;
  }

  factory BirthdayOccurrence.next(Birthday b, DateTime now) {
    final today = KorFormat.dateOnly(now);
    var date = DateTime(today.year, b.date.month, b.date.day);
    if (date.isBefore(today)) {
      date = DateTime(today.year + 1, b.date.month, b.date.day);
    }
    return BirthdayOccurrence(
      birthday: b,
      date: date,
      daysUntil: KorFormat.dayDiff(today, date),
    );
  }
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

  /// Timed, not-done reminders sorted by time.
  final List<Reminder> reminders;
}

/// Upcoming agenda ("Yaklaşan"): not-done timed reminders from [now] and
/// birthdays, grouped by day for [days] days starting today. Days without
/// entries are omitted.
List<AgendaDay> buildAgenda({
  required List<Reminder> reminders,
  required List<Birthday> birthdays,
  required DateTime now,
  int days = 30,
}) {
  final today = KorFormat.dateOnly(now);
  final end = DateTime(today.year, today.month, today.day + days);

  final remindersByDay = <DateTime, List<Reminder>>{};
  for (final r in reminders) {
    final at = r.remindAt?.toLocal();
    if (r.isDone || at == null) continue;
    if (at.isBefore(now) || !at.isBefore(end)) continue;
    remindersByDay.putIfAbsent(KorFormat.dateOnly(at), () => []).add(r);
  }

  final birthdaysByDay = <DateTime, List<BirthdayOccurrence>>{};
  for (final b in birthdays) {
    final o = BirthdayOccurrence.next(b, now);
    if (!o.date.isBefore(end)) continue;
    birthdaysByDay.putIfAbsent(o.date, () => []).add(o);
  }

  final dates = {...remindersByDay.keys, ...birthdaysByDay.keys}.toList()
    ..sort();
  return [
    for (final date in dates)
      AgendaDay(
        date: date,
        birthdays: List.unmodifiable(
          (birthdaysByDay[date] ?? <BirthdayOccurrence>[])
            ..sort((a, b) => a.birthday.name.compareTo(b.birthday.name)),
        ),
        reminders: List.unmodifiable(
          (remindersByDay[date] ?? <Reminder>[])..sort(compareReminders),
        ),
      ),
  ];
}
