import 'capture_case.dart';

/// Edge cases on the fixed clock: empty and tokens-only input, emoji and
/// punctuation, İ/ı in titles, conflicting slots (first wins).
final edgeCases = <CaptureCase>[
  // empty / tokens only
  const CaptureCase('', title: ''),
  const CaptureCase('   ', title: ''),
  CaptureCase(
    'yarın 18:00 #market !!',
    title: 'Yarın 18:00 #market !!',
    at: DateTime(2026, 9, 14, 18),
    tag: 'market',
    categoryId: 'market',
    priority: 2,
    tokens: const [
      'date:yarın',
      'time:18:00',
      'category:#market',
      'priority:!!',
    ],
  ),
  CaptureCase(
    '  yarın   akşam  ',
    title: 'Yarın akşam',
    at: DateTime(2026, 9, 14, 20),
    tokens: const ['date:yarın', 'time:akşam'],
  ),
  CaptureCase(
    'yarın!',
    title: 'Yarın!',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),

  // emoji and punctuation
  CaptureCase(
    '🎂 yarın annemin doğum günü!',
    title: '🎂 Annemin doğum günü!',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    '💊 ilaç iç 🙂 sabah',
    title: '💊 İlaç iç 🙂',
    at: DateTime(2026, 9, 14, 9),
    tokens: const ['time:sabah'],
  ),
  CaptureCase(
    'yarın!!! ekmek',
    title: 'Ekmek',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    '(yarın) dişçi',
    title: 'Dişçi',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    'Dişçi — yarın 10:00.',
    title: 'Dişçi.',
    at: DateTime(2026, 9, 14, 10),
    tokens: const ['date:yarın', 'time:10:00'],
  ),
  CaptureCase(
    'Dişçi, yarın 10:00?',
    title: 'Dişçi?',
    at: DateTime(2026, 9, 14, 10),
    tokens: const ['date:yarın', 'time:10:00'],
  ),
  CaptureCase(
    '"yarın" ödevi teslim et',
    title: 'Ödevi teslim et',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  const CaptureCase('!!!! acil', title: 'Acil'),

  // İ/ı in titles
  CaptureCase(
    "İstanbul'a bilet al yarın",
    title: "İstanbul'a bilet al",
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    'istanbul yarın',
    title: 'İstanbul',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    'ılık su iç sabah',
    title: 'Ilık su iç',
    at: DateTime(2026, 9, 14, 9),
    tokens: const ['time:sabah'],
  ),
  CaptureCase(
    'IŞIKLARI KAPAT AKŞAM',
    title: 'IŞIKLARI KAPAT',
    at: DateTime(2026, 9, 13, 20),
    tokens: const ['time:AKŞAM'],
  ),
  CaptureCase(
    'İLAÇ İÇ YARIN',
    title: 'İLAÇ İÇ',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:YARIN'],
  ),

  // conflicting slots: the first match wins, the rest stays text
  CaptureCase(
    '18:00 toplantı 19:00',
    title: 'Toplantı 19:00',
    at: DateTime(2026, 9, 13, 18),
    tokens: const ['time:18:00'],
  ),
  CaptureCase(
    'yarın cuma toplantı',
    title: 'Cuma toplantı',
    at: DateTime(2026, 9, 14),
    tokens: const ['date:yarın'],
  ),
  CaptureCase(
    'sabah akşam ilaç',
    title: 'Akşam ilaç',
    at: DateTime(2026, 9, 14, 9),
    tokens: const ['time:sabah'],
  ),
  CaptureCase(
    "saat 9'da ya da 10'da ara",
    title: "Ya da 10'da ara",
    at: DateTime(2026, 9, 14, 9),
    tokens: const ["time:saat 9'da"],
  ),
  const CaptureCase(
    '#market #iş !! ! ekmek',
    title: '#iş ! ekmek',
    tag: 'market',
    categoryId: 'market',
    priority: 2,
    tokens: ['category:#market', 'priority:!!'],
  ),
];
