import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/text_search.dart';
import 'package:reminder/ui/search/reminder_search.dart';

import '../../helpers/factories.dart';

void main() {
  final reminders = [
    buildReminder(
      id: 'electric',
      title: 'Elektrik faturasını öde',
      categoryId: ReminderCategoryIds.home,
      remindAt: DateTime(2026, 9, 12, 18),
    ),
    buildReminder(
      id: 'water',
      title: 'Su faturası',
      categoryId: ReminderCategoryIds.home,
      remindAt: DateTime(2026, 9, 17, 19),
    ),
    buildReminder(
      id: 'internet',
      title: 'İnternet itirazı',
      categoryId: ReminderCategoryIds.work,
      note: 'Geçen ayki FATURADA fazladan ücret var',
    ),
    buildReminder(
      id: 'invoice-prefix',
      title: 'Faturalar klasörü',
      isDone: true,
    ),
    buildReminder(
      id: 'market',
      title: 'Kedi maması',
      categoryId: ReminderCategoryIds.market,
    ),
    buildReminder(
      id: 'place',
      title: 'Ekmek al',
      locationTriggerEnabled: true,
      locationPlaceLabel: 'Migros Kadıköy',
    ),
  ];

  List<String> ids(List<ReminderMatch> items) =>
      [for (final m in items) m.reminder.id];

  test('empty query has no results', () {
    expect(ReminderSearch.run(reminders, '   ').isEmpty, isTrue);
  });

  test('groups title matches and note-only matches; open by default', () {
    final r = ReminderSearch.run(reminders, 'fatura');
    expect(ids(r.inReminders), ['electric', 'water']);
    expect(ids(r.inNotes), ['internet']);
    expect(r.total, 3);
  });

  test('word start ranks before a match inside a word, then list order', () {
    final r = ReminderSearch.run(
      reminders,
      'FATURA',
      statuses: const {SearchStatus.open, SearchStatus.completed},
    );
    // "Faturalar" and "Su faturası" start a word; "Elektrik faturasını"
    // too — ties fall back to compareReminders (active before done, time).
    expect(ids(r.inReminders), ['electric', 'water', 'invoice-prefix']);
  });

  test('statuses filter: completed only', () {
    final r = ReminderSearch.run(
      reminders,
      'fatura',
      statuses: const {SearchStatus.completed},
    );
    expect(ids(r.inReminders), ['invoice-prefix']);
    expect(r.inNotes, isEmpty);
  });

  test('category filter', () {
    final r = ReminderSearch.run(
      reminders,
      'fatura',
      categoryId: ReminderCategoryIds.work,
    );
    expect(ids(r.inReminders), isEmpty);
    expect(ids(r.inNotes), ['internet']);
  });

  test('matches category and place labels, Turkish-insensitive', () {
    expect(ids(ReminderSearch.run(reminders, 'ev isleri').inReminders), [
      'electric',
      'water',
    ]);
    expect(ids(ReminderSearch.run(reminders, 'kadikoy').inReminders), [
      'place',
    ]);
    expect(ids(ReminderSearch.run(reminders, 'INTERNET').inReminders), [
      'internet',
    ]);
  });

  test('every word must match somewhere', () {
    expect(ids(ReminderSearch.run(reminders, 'su fatura').inReminders), [
      'water',
    ]);
    expect(ReminderSearch.run(reminders, 'fatura kedi').isEmpty, isTrue);
  });

  test('highlight ranges for title and note', () {
    final r = ReminderSearch.run(reminders, 'fatura');
    final electric = r.inReminders.firstWhere(
      (m) => m.reminder.id == 'electric',
    );
    expect(electric.titleRanges, [const MatchRange(9, 15)]);
    final internet = r.inNotes.single;
    final note = internet.reminder.note!;
    final range = internet.noteRanges.single;
    expect(note.substring(range.start, range.end), 'FATURA');
  });

  test('note context trims long prefixes at a word boundary', () {
    const note = 'Bu ay dikkat: geçen ayki fatura da fazladan ücret var';
    final ranges = TextSearch.ranges(note, TextSearch.tokens('fatura'));
    final ctx = ReminderSearch.noteContext(note, ranges, before: 12);
    expect(ctx.text, startsWith('…'));
    final m = ctx.ranges.single;
    expect(ctx.text.substring(m.start, m.end), 'fatura');

    final short = ReminderSearch.noteContext('fatura', [
      const MatchRange(0, 6),
    ]);
    expect(short.text, 'fatura');
  });
}
