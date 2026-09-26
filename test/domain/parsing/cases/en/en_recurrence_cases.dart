import '../capture_case.dart';

/// English repeat examples (F4.6c). Clock: Sunday 13 September 2026, 14:32.
/// `at` is the **first occurrence** at or after that moment.
final enRecurrenceCases = <CaptureCase>[
  // --- daily --------------------------------------------------------------
  CaptureCase(
    'every day take the vitamins',
    title: 'Take the vitamins',
    at: DateTime(2026, 9, 13),
    rec: daily(),
    tokens: ['recurrence:every day'],
  ),
  CaptureCase(
    'water the plants everyday',
    title: 'Water the plants',
    at: DateTime(2026, 9, 13),
    rec: daily(),
    tokens: ['recurrence:everyday'],
  ),
  CaptureCase(
    'daily journal',
    title: 'Journal',
    at: DateTime(2026, 9, 13),
    rec: daily(),
    tokens: ['recurrence:daily'],
  ),
  CaptureCase(
    'every day at 9 take the pills',
    title: 'Take the pills',
    at: DateTime(2026, 9, 14, 9),
    rec: daily(),
    tokens: ['recurrence:every day', 'time:at 9'],
  ),
  CaptureCase(
    'every morning stretch',
    title: 'Stretch',
    at: DateTime(2026, 9, 14, 9),
    rec: daily(),
    tokens: ['recurrence:every morning'],
  ),
  CaptureCase(
    'every evening close the blinds',
    title: 'Close the blinds',
    at: DateTime(2026, 9, 13, 20),
    rec: daily(),
    tokens: ['recurrence:every evening'],
  ),
  CaptureCase(
    'every evening at 9 read',
    title: 'Read',
    at: DateTime(2026, 9, 13, 21),
    rec: daily(),
    tokens: ['recurrence:every evening', 'time:at 9'],
  ),
  CaptureCase(
    'every night lock the door',
    title: 'Lock the door',
    at: DateTime(2026, 9, 13, 22),
    rec: daily(),
    tokens: ['recurrence:every night'],
  ),
  CaptureCase(
    'nightly backup',
    title: 'Backup',
    at: DateTime(2026, 9, 13, 22),
    rec: daily(),
    tokens: ['recurrence:nightly'],
  ),
  CaptureCase(
    'evenings water the garden',
    title: 'Water the garden',
    at: DateTime(2026, 9, 13, 20),
    rec: daily(),
    tokens: ['recurrence:evenings'],
  ),
  CaptureCase(
    'mornings feed the cat',
    title: 'Feed the cat',
    at: DateTime(2026, 9, 14, 9),
    rec: daily(),
    tokens: ['recurrence:mornings'],
  ),

  // --- weekly -------------------------------------------------------------
  CaptureCase(
    'every week back up the laptop',
    title: 'Back up the laptop',
    at: DateTime(2026, 9, 13),
    rec: _weeklySunday,
    tokens: ['recurrence:every week'],
  ),
  CaptureCase(
    'weekly retro',
    title: 'Retro',
    at: DateTime(2026, 9, 13),
    rec: _weeklySunday,
    tokens: ['recurrence:weekly'],
  ),
  CaptureCase(
    'every monday team sync',
    title: 'Team sync',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonday,
    tokens: ['recurrence:every monday'],
  ),
  CaptureCase(
    'every Monday at 10:00 team sync',
    title: 'Team sync',
    at: DateTime(2026, 9, 14, 10),
    rec: _weeklyMonday,
    tokens: ['recurrence:every Monday', 'time:at 10:00'],
  ),
  CaptureCase(
    'mondays take out the bins',
    title: 'Take out the bins',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonday,
    tokens: ['recurrence:mondays'],
  ),
  CaptureCase(
    'on fridays pay the cleaner',
    title: 'Pay the cleaner',
    at: DateTime(2026, 9, 18),
    rec: _weeklyFriday,
    tokens: ['recurrence:on fridays'],
  ),
  CaptureCase(
    'every monday, wednesday and friday swim',
    title: 'Swim',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonWedFri,
    tokens: ['recurrence:every monday, wednesday and friday'],
  ),
  CaptureCase(
    'every mon & wed physio',
    title: 'Physio',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonWed,
    tokens: ['recurrence:every mon & wed'],
  ),
  CaptureCase(
    'mondays and thursdays language class',
    title: 'Language class',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonThu,
    tokens: ['recurrence:mondays and thursdays'],
  ),
  CaptureCase(
    'every week on friday call dad',
    title: 'Call dad',
    at: DateTime(2026, 9, 18),
    rec: _weeklyFriday,
    tokens: ['recurrence:every week on friday'],
  ),
  CaptureCase(
    'weekly on monday review the budget',
    title: 'Review the budget',
    at: DateTime(2026, 9, 14),
    rec: _weeklyMonday,
    tokens: ['recurrence:weekly on monday'],
  ),

  // --- weekdays / weekends ------------------------------------------------
  CaptureCase(
    'every weekday pack the lunch',
    title: 'Pack the lunch',
    at: DateTime(2026, 9, 14),
    rec: _weekdays,
    tokens: ['recurrence:every weekday'],
  ),
  CaptureCase(
    'on weekdays check the inbox',
    title: 'Check the inbox',
    at: DateTime(2026, 9, 14),
    rec: _weekdays,
    tokens: ['recurrence:on weekdays'],
  ),
  CaptureCase(
    'weekdays 8:00 school run',
    title: 'School run',
    at: DateTime(2026, 9, 14, 8),
    rec: _weekdays,
    tokens: ['recurrence:weekdays', 'time:8:00'],
  ),
  CaptureCase(
    'every weekend call the family',
    title: 'Call the family',
    at: DateTime(2026, 9, 13),
    rec: _weekends,
    tokens: ['recurrence:every weekend'],
  ),
  CaptureCase(
    'on weekends water the balcony',
    title: 'Water the balcony',
    at: DateTime(2026, 9, 13),
    rec: _weekends,
    tokens: ['recurrence:on weekends'],
  ),

  // --- monthly ------------------------------------------------------------
  CaptureCase(
    'every month pay the rent',
    title: 'Pay the rent',
    at: DateTime(2026, 9, 13),
    rec: _monthlyOn13,
    tokens: ['recurrence:every month'],
  ),
  CaptureCase(
    'monthly transfer to savings',
    title: 'Transfer to savings',
    at: DateTime(2026, 9, 13),
    rec: _monthlyOn13,
    tokens: ['recurrence:monthly'],
  ),
  CaptureCase(
    'every month on the 17th pay the rent',
    title: 'Pay the rent',
    at: DateTime(2026, 9, 17),
    rec: _monthlyOn17,
    tokens: ['recurrence:every month on the 17th'],
  ),
  CaptureCase(
    'monthly on the 17th water bill',
    title: 'Water bill',
    at: DateTime(2026, 9, 17),
    rec: _monthlyOn17,
    tokens: ['recurrence:monthly on the 17th'],
  ),
  CaptureCase(
    'every 17th of the month check the meter',
    title: 'Check the meter',
    at: DateTime(2026, 9, 17),
    rec: _monthlyOn17,
    tokens: ['recurrence:every 17th of the month'],
  ),
  CaptureCase(
    'every month on the 31st deep clean',
    title: 'Deep clean',
    at: DateTime(2026, 10, 31),
    rec: _monthlyOn31,
    tokens: ['recurrence:every month on the 31st'],
  ),

  // --- intervals ----------------------------------------------------------
  CaptureCase(
    'every 2 weeks empty the bins',
    title: 'Empty the bins',
    at: DateTime(2026, 9, 13),
    rec: _biweeklySunday,
    tokens: ['recurrence:every 2 weeks'],
  ),
  CaptureCase(
    'every other week clean the filter',
    title: 'Clean the filter',
    at: DateTime(2026, 9, 13),
    rec: _biweeklySunday,
    tokens: ['recurrence:every other week'],
  ),
  CaptureCase(
    'every 3 days water the cactus',
    title: 'Water the cactus',
    at: DateTime(2026, 9, 13),
    rec: _every3Days,
    tokens: ['recurrence:every 3 days'],
  ),
  CaptureCase(
    'every other day run',
    title: 'Run',
    at: DateTime(2026, 9, 13),
    rec: _every2Days,
    tokens: ['recurrence:every other day'],
  ),
  CaptureCase(
    'every 1 day stretch',
    title: 'Stretch',
    at: DateTime(2026, 9, 13),
    rec: daily(),
    tokens: ['recurrence:every 1 day'],
  ),
  CaptureCase(
    'every 3 months dentist',
    title: 'Dentist',
    at: DateTime(2026, 9, 13),
    rec: _quarterlyOn13,
    tokens: ['recurrence:every 3 months'],
  ),
  CaptureCase(
    'every other monday physio',
    title: 'Physio',
    at: DateTime(2026, 9, 14),
    rec: _biweeklyMonday,
    tokens: ['recurrence:every other monday'],
  ),

  // --- not repeats --------------------------------------------------------
  const CaptureCase('every year renew the passport',
      title: 'Every year renew the passport'),
  const CaptureCase('yearly checkup', title: 'Yearly checkup'),
  const CaptureCase('annually review the will',
      title: 'Annually review the will'),
  const CaptureCase('send the weekly report', title: 'Send the weekly report'),
  const CaptureCase('daily standup notes', title: 'Daily standup notes'),
  const CaptureCase('monthly invoice template',
      title: 'Monthly invoice template'),
];

final _weeklySunday = weekly([DateTime.sunday]);
final _weeklyMonday = weekly([DateTime.monday]);
final _weeklyFriday = weekly([DateTime.friday]);
final _weeklyMonWed = weekly([DateTime.monday, DateTime.wednesday]);
final _weeklyMonThu = weekly([DateTime.monday, DateTime.thursday]);
final _weeklyMonWedFri =
    weekly([DateTime.monday, DateTime.wednesday, DateTime.friday]);
final _weekdays = weekly([1, 2, 3, 4, 5]);
final _weekends = weekly([6, 7]);
final _biweeklySunday = weekly([DateTime.sunday], interval: 2);
final _biweeklyMonday = weekly([DateTime.monday], interval: 2);
final _monthlyOn13 = monthly(13);
final _monthlyOn17 = monthly(17);
final _monthlyOn31 = monthly(31);
final _quarterlyOn13 = monthly(13, interval: 3);
final _every2Days = everyDays(2);
final _every3Days = everyDays(3);
