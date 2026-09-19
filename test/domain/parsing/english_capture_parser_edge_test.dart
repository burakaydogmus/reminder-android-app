import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/capture_parser.dart';

import 'cases/capture_case.dart';

/// English edge cases that need another clock, a custom config or exact
/// offsets (F4.6c) — the mirror of `turkish_capture_parser_edge_test.dart`.
void main() {
  CaptureParseResult parse(
    String input,
    DateTime now, [
    CaptureParserConfig config = const CaptureParserConfig(),
  ]) =>
      CaptureParser.parse(
        input,
        now: now,
        config: config,
        locale: CaptureLocale.english,
      );

  group('month rollover (30 September 2026 10:00)', () {
    final now = DateTime(2026, 9, 30, 10);
    test('tomorrow → 1 October', () {
      expect(parse('tomorrow the bill', now).dateTime, DateTime(2026, 10, 1));
    });
    test('the 31st → 31 October (September has no 31st)', () {
      expect(parse('the 31st report', now).dateTime, DateTime(2026, 10, 31));
    });
    test('in 3 days → 3 October', () {
      expect(parse('call in 3 days', now).dateTime, DateTime(2026, 10, 3));
    });
    test('a past "at 9" moves to the next month', () {
      expect(parse('at 9 run', now).dateTime, DateTime(2026, 10, 1, 9));
    });
    test('every month on the 31st → 31 October', () {
      final r = parse('every month on the 31st rent', now);
      expect(r.dateTime, DateTime(2026, 10, 31));
      expect(r.recurrence, monthly(31));
    });
  });

  group('year rollover (31 December 2026 22:00)', () {
    final now = DateTime(2026, 12, 31, 22);
    test('tomorrow → 1 January 2027', () {
      expect(parse('tomorrow', now).dateTime, DateTime(2027, 1, 1));
    });
    test('January 5 → 2027', () {
      expect(parse('January 5 check', now).dateTime, DateTime(2027, 1, 5));
    });
    test('next week → 7 January 2027', () {
      expect(parse('next week dentist', now).dateTime, DateTime(2027, 1, 7));
    });
    test('friday → 1 January 2027', () {
      expect(parse('friday cinema', now).dateTime, DateTime(2027, 1, 1));
    });
    test('every month on the 15th → 15 January 2027', () {
      expect(
        parse('every month on the 15th fees', now).dateTime,
        DateTime(2027, 1, 15),
      );
    });
    test('at 9 → 1 January 2027 09:00', () {
      expect(parse('at 9 run', now).dateTime, DateTime(2027, 1, 1, 9));
    });
    test('every day at 21:00 starts tomorrow', () {
      final r = parse('every day at 21:00 pills', now);
      expect(r.dateTime, DateTime(2027, 1, 1, 21));
      expect(r.recurrence, daily());
    });
    test('an explicit past year stays in the past', () {
      final r = parse('January 1 2026 old note', now);
      expect(r.dateTime, DateTime(2026, 1, 1));
      expect(r.isPast, isTrue);
    });
  });

  group('leap day', () {
    test('29 February → next leap year (2028)', () {
      final r = parse('29 February birthday', DateTime(2027, 3, 1, 9));
      expect(r.dateTime, DateTime(2028, 2, 29));
    });
    test('2/29 → 2028', () {
      expect(parse('2/29 party', kNow).dateTime, DateTime(2028, 2, 29));
    });
    test('tomorrow from 28 February 2028 → 29 February', () {
      expect(
        parse('tomorrow', DateTime(2028, 2, 28, 9)).dateTime,
        DateTime(2028, 2, 29),
      );
    });
    test('tomorrow from 28 February 2027 → 1 March', () {
      expect(
        parse('tomorrow', DateTime(2027, 2, 28, 9)).dateTime,
        DateTime(2027, 3, 1),
      );
    });
    test('29 February 2027 does not exist → text', () {
      final r = parse('29 February 2027 meeting', kNow);
      expect(r.dateTime, isNull);
      expect(r.tokens, isEmpty);
      expect(r.title, '29 February 2027 meeting');
    });
    test('in a month from 31 January → 28 February (clamped)', () {
      expect(
        parse('in a month', DateTime(2027, 1, 31, 9)).dateTime,
        DateTime(2027, 2, 28),
      );
    });
    test('in a month from 31 January 2028 → 29 February', () {
      expect(
        parse('in a month', DateTime(2028, 1, 31, 9)).dateTime,
        DateTime(2028, 2, 29),
      );
    });
  });

  group('numeric dates are month/day (en_US)', () {
    test('both numbers can be a month → month first', () {
      expect(parse('5/3', kNow).dateTime, DateTime(2027, 5, 3));
      expect(parse('3/5', kNow).dateTime, DateTime(2027, 3, 5));
      expect(parse('1/2/2027', kNow).dateTime, DateTime(2027, 1, 2));
    });
    test('the first number cannot be a month → day/month', () {
      expect(parse('25/12', kNow).dateTime, DateTime(2026, 12, 25));
      expect(parse('31/10/2027', kNow).dateTime, DateTime(2027, 10, 31));
    });
    test('neither number can be a month → text', () {
      final r = parse('13/25 boxes', kNow);
      expect(r.dateTime, isNull);
      expect(r.tokens, isEmpty);
    });
    test('an impossible day is text', () {
      expect(parse('2/30 meeting', kNow).tokens, isEmpty);
      expect(parse('4/31 meeting', kNow).tokens, isEmpty);
    });
    test('a dot form is a time, not a date', () {
      final r = parse('5.30 call', kNow);
      expect(r.tokens.single.kind, CaptureTokenKind.time);
      expect(r.dateTime, DateTime(2026, 9, 14, 5, 30));
    });
    test('ISO is year-month-day', () {
      expect(parse('2027-05-03 renew', kNow).dateTime, DateTime(2027, 5, 3));
    });
  });

  group('exact token ranges', () {
    test('surrounding spaces and punctuation', () {
      const input = '  Tomorrow  at 9, #work !!';
      final r = parse(input, kNow);
      expect(
        [for (final t in r.tokens) (t.kind, t.start, t.end)],
        [
          (CaptureTokenKind.date, 2, 10),
          (CaptureTokenKind.time, 12, 16),
          (CaptureTokenKind.category, 18, 23),
          (CaptureTokenKind.priority, 24, 26),
        ],
      );
      for (final t in r.tokens) {
        expect(input.substring(t.start, t.end), t.text);
      }
      expect(r.categoryId, ReminderCategoryIds.work);
    });
    test('emoji before a token (UTF-16 offsets)', () {
      const input = '🎂🎉 tomorrow party';
      final t = parse(input, kNow).tokens.single;
      expect((t.start, t.end), (5, 13));
      expect(input.substring(t.start, t.end), 'tomorrow');
    });
    test('İ before a token does not shift offsets', () {
      const input = 'İİİ evening 8';
      final t = parse(input, kNow).tokens.single;
      expect(input.substring(t.start, t.end), 'evening 8');
      expect(t.start, 4);
    });
    test('tokens are in input order', () {
      final r = parse('!! #market 18:00 tomorrow', kNow);
      final starts = [for (final t in r.tokens) t.start];
      expect(starts, [...starts]..sort());
      expect(r.tokens.map((t) => t.kind), [
        CaptureTokenKind.priority,
        CaptureTokenKind.category,
        CaptureTokenKind.time,
        CaptureTokenKind.date,
      ]);
    });
  });

  group('custom config', () {
    const config = CaptureParserConfig(
      morningHour: 7,
      noonHour: 13,
      afternoonHour: 16,
      eveningHour: 19,
      nightHour: 23,
    );
    test('bare day parts use the configured hours', () {
      expect(
        parse('morning pills', kNow, config).dateTime,
        DateTime(2026, 9, 14, 7),
      );
      expect(
        parse('tomorrow afternoon meeting', kNow, config).dateTime,
        DateTime(2026, 9, 14, 16),
      );
      expect(
        parse('evening call mom', kNow, config).dateTime,
        DateTime(2026, 9, 13, 19),
      );
      expect(
        parse('night pills', kNow, config).dateTime,
        DateTime(2026, 9, 13, 23),
      );
      expect(
        parse('at noon lunch', kNow, config).dateTime,
        DateTime(2026, 9, 14, 13),
      );
    });
    test('an explicit hour ignores the configured default', () {
      expect(
        parse('evening at 8 match', kNow, config).dateTime,
        DateTime(2026, 9, 13, 20),
      );
    });
    test('custom list categories enable the split suggestion', () {
      const listConfig = CaptureParserConfig(
        listCategoryIds: {ReminderCategoryIds.market, ReminderCategoryIds.work},
      );
      expect(
        parse('#work report, deck and budget', kNow, listConfig)
            .splitSuggestion,
        ['report', 'deck', 'budget'],
      );
      expect(
        parse('#work report, deck and budget', kNow).splitSuggestion,
        isEmpty,
      );
    });
    test('custom category aliases replace the built-ins', () {
      const aliasConfig = CaptureParserConfig(
        categoryAliases: {
          'custom-1': ['Book Club'],
        },
      );
      final r = parse('finish the novel #book_club', kNow, aliasConfig);
      expect(r.categoryId, 'custom-1');
      expect(parse('bread #market', kNow, aliasConfig).categoryId, isNull);
    });
    test('without aliases the built-ins of the locale are used', () {
      expect(parse('bread #groceries', kNow).categoryId, 'market');
      expect(
        CaptureParser.parse('bread #groceries', now: kNow).categoryId,
        isNull,
        reason: 'Turkish has no #groceries alias',
      );
    });
  });
}
