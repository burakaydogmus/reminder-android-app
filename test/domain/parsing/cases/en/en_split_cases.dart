import '../capture_case.dart';

/// English "split into items?" examples (design §3.3.3 › Liste algılama).
final enSplitCases = <CaptureCase>[
  const CaptureCase(
    '#market bread, milk and eggs',
    title: 'Bread, milk and eggs',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['bread', 'milk', 'eggs'],
  ),
  const CaptureCase(
    '#market buy bread and milk',
    title: 'Buy bread and milk',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['bread', 'milk'],
  ),
  CaptureCase(
    'friday 6pm buy bread and milk #market !!',
    title: 'Buy bread and milk',
    at: DateTime(2026, 9, 18, 18),
    tag: 'market',
    categoryId: 'market',
    priority: 2,
    tokens: const [
      'date:friday',
      'time:6pm',
      'category:#market',
      'priority:!!',
    ],
    split: const ['bread', 'milk'],
  ),
  const CaptureCase(
    '#groceries pick up milk, eggs & butter',
    title: 'Pick up milk, eggs & butter',
    tag: 'groceries',
    categoryId: 'market',
    tokens: ['category:#groceries'],
    split: ['milk', 'eggs', 'butter'],
  ),
  const CaptureCase(
    'tomatoes; peppers; aubergine #shopping',
    title: 'Tomatoes; peppers; aubergine',
    tag: 'shopping',
    categoryId: 'market',
    tokens: ['category:#shopping'],
    split: ['tomatoes', 'peppers', 'aubergine'],
  ),
  const CaptureCase(
    '#market 1,5 litres of milk, 2 kg tomatoes',
    title: '1,5 litres of milk, 2 kg tomatoes',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['1,5 litres of milk', '2 kg tomatoes'],
  ),
  const CaptureCase(
    '#Market Bread AND Cheese',
    title: 'Bread AND Cheese',
    tag: 'Market',
    categoryId: 'market',
    tokens: ['category:#Market'],
    split: ['Bread', 'Cheese'],
  ),
  const CaptureCase(
    '#market bread, , milk',
    title: 'Bread, milk',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
    split: ['bread', 'milk'],
  ),

  // no suggestion
  const CaptureCase(
    '#market buy milk',
    title: 'Buy milk',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
  ),
  const CaptureCase(
    'bread, milk and eggs',
    title: 'Bread, milk and eggs',
  ),
  const CaptureCase(
    '#work write the report and the deck',
    title: 'Write the report and the deck',
    tag: 'work',
    categoryId: 'work',
    tokens: ['category:#work'],
  ),
  const CaptureCase(
    '#corner-shop bread and milk',
    title: 'Bread and milk',
    tag: 'corner-shop',
    tokens: ['category:#corner-shop'],
  ),
  const CaptureCase(
    '#market tax return',
    title: 'Tax return',
    tag: 'market',
    categoryId: 'market',
    tokens: ['category:#market'],
  ),
];
