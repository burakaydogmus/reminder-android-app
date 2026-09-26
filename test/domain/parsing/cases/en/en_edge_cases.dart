import '../capture_case.dart';

/// English edge cases on the fixed clock: empty and tokens-only input,
/// emoji and punctuation, conflicting slots (first wins) and — most
/// importantly — text that must **not** be read as a date or a time.
final enEdgeCases = <CaptureCase>[
  // empty / tokens only
  const CaptureCase('', title: ''),
  const CaptureCase('   ', title: ''),
  CaptureCase(
    'tomorrow 18:00 #market !!',
    title: 'Tomorrow 18:00 #market !!',
    at: DateTime(2026, 9, 14, 18),
    tag: 'market',
    categoryId: 'market',
    priority: 2,
    tokens: const [
      'date:tomorrow',
      'time:18:00',
      'category:#market',
      'priority:!!',
    ],
  ),
  CaptureCase(
    '  tomorrow   evening  ',
    title: 'Tomorrow evening',
    at: DateTime(2026, 9, 14, 20),
    tokens: const ['date:tomorrow', 'time:evening'],
  ),
  CaptureCase(
    'tomorrow!',
    title: 'Tomorrow!',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),

  // emoji and punctuation
  CaptureCase(
    '🎂 tomorrow is mum\'s birthday!',
    title: "🎂 Is mum's birthday!",
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),
  CaptureCase(
    '💊 take the pills 🙂 in the morning',
    title: '💊 Take the pills 🙂',
    at: DateTime(2026, 9, 14, 9),
    tokens: const ['time:in the morning'],
  ),
  CaptureCase(
    'tomorrow!!! bread',
    title: 'Bread',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),
  CaptureCase(
    '(tomorrow) dentist',
    title: 'Dentist',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),
  CaptureCase(
    'Dentist — tomorrow 10:00.',
    title: 'Dentist.',
    at: DateTime(2026, 9, 14, 10),
    tokens: const ['date:tomorrow', 'time:10:00'],
  ),
  CaptureCase(
    'bread and milk tomorrow',
    title: 'Bread and milk',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),

  // first wins
  CaptureCase(
    'tomorrow friday dentist',
    title: 'Friday dentist',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:tomorrow'],
  ),
  CaptureCase(
    'at 9 at 10 standup',
    title: 'At 10 standup',
    at: DateTime(2026, 9, 14, 9),
    tokens: const ['time:at 9'],
  ),
  CaptureCase(
    'every day every monday vitamins',
    title: 'Every monday vitamins',
    at: DateTime(2026, 9, 13),
    rec: _dailyRec,
    tokens: const ['recurrence:every day'],
  ),

  // not dates
  const CaptureCase('I may need 3 boxes', title: 'I may need 3 boxes'),
  const CaptureCase('march to the station', title: 'March to the station'),
  const CaptureCase('book April 31 slot', title: 'Book April 31 slot'),
  const CaptureCase('the sun is out', title: 'The sun is out'),
  const CaptureCase('we sat outside', title: 'We sat outside'),
  const CaptureCase('last friday receipt', title: 'Last friday receipt'),
  const CaptureCase('a day at the beach', title: 'A day at the beach'),
  const CaptureCase('day trip ideas', title: 'Day trip ideas'),

  // not times
  const CaptureCase('buy 1.5 kg flour', title: 'Buy 1.5 kg flour'),
  const CaptureCase('pay 1.50 usd', title: 'Pay 1.50 usd'),
  const CaptureCase('room 9 key', title: 'Room 9 key'),
  const CaptureCase('call 112', title: 'Call 112'),
  const CaptureCase('read 12 pages', title: 'Read 12 pages'),
  const CaptureCase('email ann at example.org',
      title: 'Email ann at example.org'),
  const CaptureCase('the milk is in the fridge',
      title: 'The milk is in the fridge'),
  const CaptureCase('look at the invoice', title: 'Look at the invoice'),
];

final _dailyRec = daily();
