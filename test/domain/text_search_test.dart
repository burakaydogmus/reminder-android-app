import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/text_search.dart';

void main() {
  group('TextSearch.fold', () {
    test('keeps the length of the input (1:1 index mapping)', () {
      for (final s in ['İstanbul', 'IŞIK', 'ÇĞŞÖÜ çğşöü', 'Â î û', 'Kedi']) {
        expect(TextSearch.fold(s).length, s.length, reason: s);
      }
    });

    test('İstanbul / istanbul / ISTANBUL fold alike', () {
      expect(TextSearch.fold('İstanbul'), 'istanbul');
      expect(TextSearch.fold('ISTANBUL'), 'istanbul');
      expect(TextSearch.fold('istanbul'), 'istanbul');
    });

    test('ışık / IŞIK / isik fold alike', () {
      expect(TextSearch.fold('ışık'), 'isik');
      expect(TextSearch.fold('IŞIK'), 'isik');
      expect(TextSearch.fold('isik'), 'isik');
    });

    test('ÇĞŞÖÜ and çğşöü fold to cgsou', () {
      expect(TextSearch.fold('ÇĞŞÖÜ'), 'cgsou');
      expect(TextSearch.fold('çğşöü'), 'cgsou');
    });

    test('circumflex vowels fold', () {
      expect(TextSearch.fold('Kâğıt hâlâ'), 'kagit hala');
    });
  });

  group('TextSearch.contains', () {
    test('matches across Turkish letters and case', () {
      expect(TextSearch.contains('İstanbul yolculuğu', 'istanbul'), isTrue);
      expect(TextSearch.contains('istanbul', 'İSTANBUL'), isTrue);
      expect(TextSearch.contains('Işıkları kapat', 'isik'), isTrue);
      expect(TextSearch.contains('Çöp poşeti', 'cop poseti'), isTrue);
      expect(TextSearch.contains('Doğum günü', 'DOGUM GUNU'), isTrue);
      expect(TextSearch.contains('Elektrik faturası', 'fatura'), isTrue);
    });

    test('empty query or a miss does not match', () {
      expect(TextSearch.contains('Ekmek', '   '), isFalse);
      expect(TextSearch.contains('Ekmek', 'faturaa'), isFalse);
    });
  });

  group('TextSearch.tokens', () {
    test('splits on whitespace and folds', () {
      expect(TextSearch.tokens('  Elektrik   FATURASI '), [
        'elektrik',
        'faturasi',
      ]);
      expect(TextSearch.tokens('   '), isEmpty);
    });
  });

  group('TextSearch.ranges', () {
    test('ranges point into the original text', () {
      const text = 'Elektrik faturasını öde';
      final r = TextSearch.ranges(text, TextSearch.tokens('FATURA'));
      expect(r, [const MatchRange(9, 15)]);
      expect(text.substring(r.first.start, r.first.end), 'fatura');
    });

    test('Turkish letters in the original are highlighted correctly', () {
      const text = 'Işıkları kapat, İstanbul';
      final r = TextSearch.ranges(text, TextSearch.tokens('isik istanbul'));
      expect(
        [for (final m in r) text.substring(m.start, m.end)],
        ['Işık', 'İstanbul'],
      );
    });

    test('every occurrence, overlapping tokens merged', () {
      final r = TextSearch.ranges('fatura fatura', TextSearch.tokens('fat'));
      expect(r, [const MatchRange(0, 3), const MatchRange(7, 10)]);
      final merged =
          TextSearch.ranges('faturasi', TextSearch.tokens('fatu tura'));
      expect(merged, [const MatchRange(0, 6)]);
    });
  });

  test('startsWord', () {
    expect(TextSearch.startsWord('Su faturası', 'fat'), isTrue);
    expect(TextSearch.startsWord('Elektrik-faturası', 'fat'), isTrue);
    expect(TextSearch.startsWord('Kedimama', 'mama'), isFalse);
  });
}
