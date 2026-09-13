import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/parsing/turkish_text.dart';

void main() {
  group('TurkishText.toLower', () {
    test('maps İ to i and I to ı', () {
      expect(TurkishText.toLower('İSTANBUL'), 'istanbul');
      expect(TurkishText.toLower('ILIK'), 'ılık');
      expect(TurkishText.toLower('IŞIK'), 'ışık');
      expect(TurkishText.toLower('ÇĞÖŞÜ'), 'çğöşü');
    });

    test('keeps the length (İ does not become two code units)', () {
      const input = 'İzmir İÇİN 🛒 Işık';
      expect(TurkishText.toLower(input).length, input.length);
      expect(TurkishText.toLower('I'), isNot('I'.toLowerCase()));
    });
  });

  group('TurkishText.toUpper', () {
    test('maps i to İ and ı to I', () {
      expect(TurkishText.toUpper('istanbul'), 'İSTANBUL');
      expect(TurkishText.toUpper('ılık'), 'ILIK');
      expect(TurkishText.toUpper('şişli'), 'ŞİŞLİ');
    });
  });

  group('TurkishText.fold', () {
    test('removes case and Turkish diacritics', () {
      expect(TurkishText.fold('SAĞLIK'), 'saglik');
      expect(TurkishText.fold('Sağlık'), 'saglik');
      expect(TurkishText.fold('saglik'), 'saglik');
      expect(TurkishText.fold('ÖBÜR GÜN'), 'obur gun');
      expect(TurkishText.fold('Çarşamba'), 'carsamba');
      expect(TurkishText.fold('İŞ'), 'is');
      expect(TurkishText.fold('IŞ'), 'is');
      expect(TurkishText.fold('Kâğıt'), 'kagit');
    });

    test('normalizes typographic apostrophes', () {
      expect(TurkishText.fold('9’da'), "9'da");
      expect(TurkishText.fold('17‘si'), "17'si");
    });

    test('keeps emoji and length', () {
      const input = '🎂 Doğum GÜNÜ';
      expect(TurkishText.fold(input), '🎂 dogum gunu');
      expect(TurkishText.fold(input).length, input.length);
    });
  });

  group('TurkishText.capitalizeFirst', () {
    test('uses Turkish upper case', () {
      expect(TurkishText.capitalizeFirst('istanbul'), 'İstanbul');
      expect(TurkishText.capitalizeFirst('ılık su'), 'Ilık su');
      expect(TurkishText.capitalizeFirst('ekmek al'), 'Ekmek al');
    });

    test('skips leading emoji and punctuation, not digits', () {
      expect(TurkishText.capitalizeFirst('🛒 ekmek'), '🛒 Ekmek');
      expect(TurkishText.capitalizeFirst('"iade" et'), '"İade" et');
      expect(TurkishText.capitalizeFirst('2 ekmek'), '2 ekmek');
      expect(TurkishText.capitalizeFirst(''), '');
      expect(TurkishText.capitalizeFirst('Zaten'), 'Zaten');
    });
  });
}
