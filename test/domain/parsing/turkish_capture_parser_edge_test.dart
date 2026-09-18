import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';

import 'cases/capture_case.dart';

/// Edge cases that need another clock, a custom config or exact offsets.
void main() {
  CaptureParseResult parse(
    String input,
    DateTime now, [
    CaptureParserConfig config = const CaptureParserConfig(),
  ]) =>
      CaptureParser.parse(input, now: now, config: config);

  group('month rollover (30 Eylül 2026 10:00)', () {
    final now = DateTime(2026, 9, 30, 10);
    test('yarın → 1 Ekim', () {
      expect(parse('yarın fatura', now).dateTime, DateTime(2026, 10, 1));
    });
    test("ayın 31'i → 31 Ekim (Eylül'de 31 yok)", () {
      expect(parse("ayın 31'i rapor", now).dateTime, DateTime(2026, 10, 31));
    });
    test('3 gün sonra → 3 Ekim', () {
      expect(parse('3 gün sonra ara', now).dateTime, DateTime(2026, 10, 3));
    });
    test("9'da geçmişse ertesi ay başı", () {
      expect(parse("9'da koşu", now).dateTime, DateTime(2026, 10, 1, 9));
    });
    test("her ayın 31'i → 31 Ekim", () {
      final r = parse("her ayın 31'i kira", now);
      expect(r.dateTime, DateTime(2026, 10, 31));
      expect(r.recurrence, monthly(31));
    });
  });

  group('year rollover (31 Aralık 2026 22:00)', () {
    final now = DateTime(2026, 12, 31, 22);
    test('yarın → 1 Ocak 2027', () {
      expect(parse('yarın', now).dateTime, DateTime(2027, 1, 1));
    });
    test('5 ocak → 2027', () {
      expect(parse('5 ocak kontrol', now).dateTime, DateTime(2027, 1, 5));
    });
    test('haftaya → 7 Ocak 2027', () {
      expect(parse('haftaya dişçi', now).dateTime, DateTime(2027, 1, 7));
    });
    test('cuma → 1 Ocak 2027', () {
      expect(parse('cuma sinema', now).dateTime, DateTime(2027, 1, 1));
    });
    test("her ayın 15'i → 15 Ocak 2027", () {
      expect(parse("her ayın 15'i aidat", now).dateTime, DateTime(2027, 1, 15));
    });
    test("9'da → 1 Ocak 2027 09:00", () {
      expect(parse("9'da koşu", now).dateTime, DateTime(2027, 1, 1, 9));
    });
    test('her gün 21:00 → yarından başlar', () {
      final r = parse('her gün 21:00 ilaç', now);
      expect(r.dateTime, DateTime(2027, 1, 1, 21));
      expect(r.recurrence, daily());
    });
    test('1 ocak 2026 yılı verilince geçmiş', () {
      final r = parse('1 ocak 2026 eski not', now);
      expect(r.dateTime, DateTime(2026, 1, 1));
      expect(r.isPast, isTrue);
    });
  });

  group('leap day', () {
    test('29 şubat → next leap year (2028)', () {
      final r = parse('29 şubat doğum günü', DateTime(2027, 3, 1, 9));
      expect(r.dateTime, DateTime(2028, 2, 29));
    });
    test('29.02 → 2028', () {
      expect(parse('29.02 kutlama', kNow).dateTime, DateTime(2028, 2, 29));
    });
    test('yarın from 28 Şubat 2028 → 29 Şubat', () {
      expect(parse('yarın', DateTime(2028, 2, 28, 9)).dateTime,
          DateTime(2028, 2, 29));
    });
    test('yarın from 28 Şubat 2027 → 1 Mart', () {
      expect(parse('yarın', DateTime(2027, 2, 28, 9)).dateTime,
          DateTime(2027, 3, 1));
    });
    test('29 şubat 2027 does not exist → text', () {
      final r = parse('29 şubat 2027 toplantı', kNow);
      expect(r.dateTime, isNull);
      expect(r.tokens, isEmpty);
      expect(r.title, '29 şubat 2027 toplantı');
    });
    test('1 ay sonra from 31 Ocak → 28 Şubat (clamped)', () {
      expect(parse('1 ay sonra', DateTime(2027, 1, 31, 9)).dateTime,
          DateTime(2027, 2, 28));
    });
    test('1 ay sonra from 31 Ocak 2028 → 29 Şubat', () {
      expect(parse('1 ay sonra', DateTime(2028, 1, 31, 9)).dateTime,
          DateTime(2028, 2, 29));
    });
  });

  group('exact token ranges', () {
    test('surrounding spaces, İ and punctuation', () {
      const input = "  Yarın  saat 9'da, #İş !!";
      final r = parse(input, kNow);
      expect(
        [for (final t in r.tokens) (t.kind, t.start, t.end)],
        [
          (CaptureTokenKind.date, 2, 7),
          (CaptureTokenKind.time, 9, 18),
          (CaptureTokenKind.category, 20, 23),
          (CaptureTokenKind.priority, 24, 26),
        ],
      );
      for (final t in r.tokens) {
        expect(input.substring(t.start, t.end), t.text);
      }
      expect(r.categoryId, ReminderCategoryIds.work);
    });
    test('emoji before a token (UTF-16 offsets)', () {
      const input = '🎂🎉 yarın parti';
      final t = parse(input, kNow).tokens.single;
      expect((t.start, t.end), (5, 10));
      expect(input.substring(t.start, t.end), 'yarın');
    });
    test('İ before a token does not shift offsets', () {
      const input = 'İİİ akşam 8de';
      final t = parse(input, kNow).tokens.single;
      expect(input.substring(t.start, t.end), 'akşam 8de');
      expect(t.start, 4);
    });
    test('tokens are in input order', () {
      final r = parse('!! #market 18:00 yarın', kNow);
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
          parse('sabah ilaç', kNow, config).dateTime, DateTime(2026, 9, 14, 7));
      expect(parse('yarın öğlen toplantı', kNow, config).dateTime,
          DateTime(2026, 9, 14, 13));
      expect(parse('öğleden sonra çay', kNow, config).dateTime,
          DateTime(2026, 9, 13, 16));
      expect(parse('akşam annemi ara', kNow, config).dateTime,
          DateTime(2026, 9, 13, 19));
      expect(
          parse('gece ilaç', kNow, config).dateTime, DateTime(2026, 9, 13, 23));
    });
    test('an explicit hour ignores the configured default', () {
      expect(parse("akşam 8'de maç", kNow, config).dateTime,
          DateTime(2026, 9, 13, 20));
    });
    test('custom list categories enable the split suggestion', () {
      const listConfig = CaptureParserConfig(
        listCategoryIds: {ReminderCategoryIds.market, ReminderCategoryIds.work},
      );
      expect(
          parse('#iş rapor, sunum ve bütçe', kNow, listConfig).splitSuggestion,
          ['rapor', 'sunum', 'bütçe']);
      expect(parse('#iş rapor, sunum ve bütçe', kNow).splitSuggestion, isEmpty);
    });
    test('custom category aliases', () {
      const aliasConfig = CaptureParserConfig(
        categoryAliases: {
          'custom-1': ['Kitap Kulübü'],
        },
      );
      final r = parse('romanı bitir #kitap_kulubu', kNow, aliasConfig);
      expect(r.categoryId, 'custom-1');
      expect(parse('ekmek #market', kNow, aliasConfig).categoryId, isNull);
    });
  });
}
