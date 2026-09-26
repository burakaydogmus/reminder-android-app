import '../capture_case.dart';

/// English clock and day-part examples (F4.6c). Clock: Sunday
/// 13 September 2026, 14:32 — a time without a date is today when it is
/// still ahead, otherwise tomorrow.
final enTimeCases = <CaptureCase>[
  // --- explicit clocks ----------------------------------------------------
  CaptureCase(
    'standup at 9',
    title: 'Standup',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['time:at 9'],
  ),
  CaptureCase(
    'call the office at 16:00',
    title: 'Call the office',
    at: DateTime(2026, 9, 13, 16),
    tokens: ['time:at 16:00'],
  ),
  CaptureCase(
    'meeting 9:30',
    title: 'Meeting',
    at: DateTime(2026, 9, 14, 9, 30),
    tokens: ['time:9:30'],
  ),
  CaptureCase(
    'meeting 21:45',
    title: 'Meeting',
    at: DateTime(2026, 9, 13, 21, 45),
    tokens: ['time:21:45'],
  ),
  CaptureCase(
    'pills at 9am',
    title: 'Pills',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['time:at 9am'],
  ),
  CaptureCase(
    'pills at 9 am',
    title: 'Pills',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['time:at 9 am'],
  ),
  // The trailing full stop is punctuation, so it stays in the title and
  // outside the token range.
  CaptureCase(
    'pills 9 a.m.',
    title: 'Pills.',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['time:9 a.m'],
  ),
  CaptureCase(
    'dinner 7pm',
    title: 'Dinner',
    at: DateTime(2026, 9, 13, 19),
    tokens: ['time:7pm'],
  ),
  CaptureCase(
    'dinner at 7 PM',
    title: 'Dinner',
    at: DateTime(2026, 9, 13, 19),
    tokens: ['time:at 7 PM'],
  ),
  CaptureCase(
    'film 9.30pm',
    title: 'Film',
    at: DateTime(2026, 9, 13, 21, 30),
    tokens: ['time:9.30pm'],
  ),
  CaptureCase(
    'film 9:30 pm',
    title: 'Film',
    at: DateTime(2026, 9, 13, 21, 30),
    tokens: ['time:9:30 pm'],
  ),
  CaptureCase(
    'flight 12am',
    title: 'Flight',
    at: DateTime(2026, 9, 14),
    timed: true,
    tokens: ['time:12am'],
  ),
  CaptureCase(
    'lunch 12pm',
    title: 'Lunch',
    at: DateTime(2026, 9, 14, 12),
    tokens: ['time:12pm'],
  ),
  CaptureCase(
    'alarm 18.30',
    title: 'Alarm',
    at: DateTime(2026, 9, 13, 18, 30),
    tokens: ['time:18.30'],
  ),
  CaptureCase(
    'meet at 5 o\'clock',
    title: 'Meet',
    at: DateTime(2026, 9, 14, 5),
    tokens: ["time:at 5 o'clock"],
  ),
  CaptureCase(
    'meet 5 o\'clock',
    title: 'Meet',
    at: DateTime(2026, 9, 14, 5),
    tokens: ["time:5 o'clock"],
  ),
  CaptureCase(
    'deliver by 17:00',
    title: 'Deliver',
    at: DateTime(2026, 9, 13, 17),
    tokens: ['time:by 17:00'],
  ),

  // --- noon, midnight, fractions -----------------------------------------
  CaptureCase(
    'lunch at noon',
    title: 'Lunch',
    at: DateTime(2026, 9, 14, 12),
    tokens: ['time:at noon'],
  ),
  CaptureCase(
    'noon walk the dog',
    title: 'Walk the dog',
    at: DateTime(2026, 9, 14, 12),
    tokens: ['time:noon'],
  ),
  CaptureCase(
    'backup at midnight',
    title: 'Backup',
    at: DateTime(2026, 9, 14),
    timed: true,
    tokens: ['time:at midnight'],
  ),
  CaptureCase(
    'standup at half past 8',
    title: 'Standup',
    at: DateTime(2026, 9, 14, 8, 30),
    tokens: ['time:at half past 8'],
  ),
  CaptureCase(
    'half past 8 standup',
    title: 'Standup',
    at: DateTime(2026, 9, 14, 8, 30),
    tokens: ['time:half past 8'],
  ),
  CaptureCase(
    'call at quarter past 8',
    title: 'Call',
    at: DateTime(2026, 9, 14, 8, 15),
    tokens: ['time:at quarter past 8'],
  ),
  CaptureCase(
    'call at quarter to 9',
    title: 'Call',
    at: DateTime(2026, 9, 14, 8, 45),
    tokens: ['time:at quarter to 9'],
  ),

  // --- day parts ----------------------------------------------------------
  CaptureCase(
    'tonight take out the bins',
    title: 'Take out the bins',
    at: DateTime(2026, 9, 13, 20),
    tokens: ['time:tonight'],
  ),
  CaptureCase(
    'call mom tonight at 9',
    title: 'Call mom',
    at: DateTime(2026, 9, 13, 21),
    tokens: ['time:tonight at 9'],
  ),
  CaptureCase(
    'this evening read the report',
    title: 'Read the report',
    at: DateTime(2026, 9, 13, 20),
    tokens: ['time:this evening'],
  ),
  CaptureCase(
    'this morning stretch',
    title: 'Stretch',
    at: DateTime(2026, 9, 13, 9),
    past: true,
    tokens: ['time:this morning'],
  ),
  CaptureCase(
    'this afternoon post the letter',
    title: 'Post the letter',
    at: DateTime(2026, 9, 13, 15),
    tokens: ['time:this afternoon'],
  ),
  CaptureCase(
    'water the plants in the morning',
    title: 'Water the plants',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['time:in the morning'],
  ),
  CaptureCase(
    'stretch in the evening',
    title: 'Stretch',
    at: DateTime(2026, 9, 13, 20),
    tokens: ['time:in the evening'],
  ),
  CaptureCase(
    'take the pills at night',
    title: 'Take the pills',
    at: DateTime(2026, 9, 13, 22),
    tokens: ['time:at night'],
  ),
  CaptureCase(
    'tomorrow morning dentist',
    title: 'Dentist',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['date:tomorrow', 'time:morning'],
  ),
  CaptureCase(
    'friday evening dinner with Ann',
    title: 'Dinner with Ann',
    at: DateTime(2026, 9, 18, 20),
    tokens: ['date:friday', 'time:evening'],
  ),
  CaptureCase(
    'tomorrow night lock the gate',
    title: 'Lock the gate',
    at: DateTime(2026, 9, 14, 22),
    tokens: ['date:tomorrow', 'time:night'],
  ),
  CaptureCase(
    'tomorrow evening at 8 dinner',
    title: 'Dinner',
    at: DateTime(2026, 9, 14, 20),
    tokens: ['date:tomorrow', 'time:evening at 8'],
  ),
  CaptureCase(
    'this evening 8 dinner',
    title: 'Dinner',
    at: DateTime(2026, 9, 13, 20),
    tokens: ['time:this evening 8'],
  ),
  CaptureCase(
    'tomorrow afternoon 3 call the vet',
    title: 'Call the vet',
    at: DateTime(2026, 9, 14, 15),
    tokens: ['date:tomorrow', 'time:afternoon 3'],
  ),
  const CaptureCase(
    'morning run',
    title: 'Morning run',
  ),
  const CaptureCase(
    'the morning meeting notes',
    title: 'The morning meeting notes',
  ),
  const CaptureCase(
    'buy night cream',
    title: 'Buy night cream',
  ),
  const CaptureCase(
    'one morning we will see',
    title: 'One morning we will see',
  ),

  // --- instants -----------------------------------------------------------
  CaptureCase(
    'call back in 2 hours',
    title: 'Call back',
    at: DateTime(2026, 9, 13, 16, 32),
    tokens: ['time:in 2 hours'],
  ),
  CaptureCase(
    'in 45 minutes take the cake out',
    title: 'Take the cake out',
    at: DateTime(2026, 9, 13, 15, 17),
    tokens: ['time:in 45 minutes'],
  ),
  CaptureCase(
    'check the oven in 10 mins',
    title: 'Check the oven',
    at: DateTime(2026, 9, 13, 14, 42),
    tokens: ['time:in 10 mins'],
  ),
  CaptureCase(
    'in half an hour call the plumber',
    title: 'Call the plumber',
    at: DateTime(2026, 9, 13, 15, 2),
    tokens: ['time:in half an hour'],
  ),
  CaptureCase(
    'stir the sauce in an hour',
    title: 'Stir the sauce',
    at: DateTime(2026, 9, 13, 15, 32),
    tokens: ['time:in an hour'],
  ),
];
