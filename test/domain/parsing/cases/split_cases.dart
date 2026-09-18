import 'capture_case.dart';

/// "Maddelere böl?" examples (design §3.3.3 › Liste algılama).
final splitCases = <CaptureCase>[
  const CaptureCase(
    '#market ekmek, süt ve yumurta',
    title: 'Ekmek, süt ve yumurta',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['ekmek', 'süt', 'yumurta'],
  ),
  CaptureCase(
    'cuma 18:00 ekmek ve süt al #market !!',
    title: 'Ekmek ve süt al',
    at: DateTime(2026, 9, 18, 18),
    tag: 'market',
    categoryId: 'market',
    priority: 2,
    tokens: const [
      'date:cuma',
      'time:18:00',
      'category:#market',
      'priority:!!',
    ],
    split: const ['ekmek', 'süt'],
  ),
  const CaptureCase(
    'domates; biber; patlıcan #alışveriş',
    title: 'Domates; biber; patlıcan',
    tag: 'alışveriş',
    categoryId: 'market',
    tokens: ['category:#alışveriş'],
    split: ['domates', 'biber', 'patlıcan'],
  ),
  const CaptureCase(
    '#market 1,5 litre süt, 2 kg domates',
    title: '1,5 litre süt, 2 kg domates',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['1,5 litre süt', '2 kg domates'],
  ),
  const CaptureCase(
    '#Market Ekmek VE Peynir alınacak',
    title: 'Ekmek VE Peynir alınacak',
    tag: 'Market',
    categoryId: 'market',
    tokens: ['category:#Market'],
    split: ['Ekmek', 'Peynir'],
  ),
  const CaptureCase(
    '#market ekmek, , süt',
    title: 'Ekmek, süt',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['ekmek', 'süt'],
  ),
  const CaptureCase(
    '#market çay, şeker, İzmir köftesi malzemeleri',
    title: 'Çay, şeker, İzmir köftesi malzemeleri',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['çay', 'şeker', 'İzmir köftesi malzemeleri'],
  ),

  // no suggestion
  const CaptureCase(
    '#market süt al',
    title: 'Süt al',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
  ),
  const CaptureCase(
    'ekmek, süt ve yumurta al',
    title: 'Ekmek, süt ve yumurta al',
  ),
  const CaptureCase(
    '#iş rapor ve sunum hazırla',
    title: 'Rapor ve sunum hazırla',
    tag: 'iş',
    categoryId: 'work',
    tokens: ['category:#iş'],
  ),
  const CaptureCase(
    '#bakkal ekmek ve süt',
    title: 'Ekmek ve süt',
    tag: 'bakkal',
    tokens: ['category:#bakkal'],
  ),
  const CaptureCase(
    '#market vergi beyannamesi',
    title: 'Vergi beyannamesi',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
  ),
];
