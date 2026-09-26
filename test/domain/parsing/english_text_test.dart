import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/parsing/capture_locale.dart';
import 'package:reminder/domain/parsing/english_text.dart';
import 'package:reminder/domain/parsing/turkish_text.dart';

/// The English counterpart of `turkish_text_test.dart` (F4.6c): casing,
/// folding and — the part the parser depends on — **offset stability**.
void main() {
  group('EnglishText.toLower', () {
    test('maps I to i and İ to a single i', () {
      expect(EnglishText.toLower('ISTANBUL'), 'istanbul');
      expect(EnglishText.toLower('İSTANBUL'), 'istanbul');
      expect(EnglishText.toLower('TOMORROW'), 'tomorrow');
      expect(EnglishText.toLower('ÇĞÖŞÜ'), 'çğöşü');
    });

    test('differs from Turkish exactly in the dotted/dotless i', () {
      expect(EnglishText.toLower('I'), 'i');
      expect(TurkishText.toLower('I'), 'ı');
      expect(EnglishText.toLower('İ'), 'i');
      expect(TurkishText.toLower('İ'), 'i');
    });

    test('keeps the length (İ does not become two code units)', () {
      const input = 'İzmir MILK 🛒 Işık';
      expect(EnglishText.toLower(input).length, input.length);
    });
  });

  group('EnglishText.fold', () {
    test('removes case and diacritics', () {
      expect(EnglishText.fold('SAĞLIK'), 'saglik');
      expect(EnglishText.fold('Sağlık'), 'saglik');
      expect(EnglishText.fold('saglik'), 'saglik');
      expect(EnglishText.fold('CAFÉ'), 'cafe');
      expect(EnglishText.fold('Résumé'), 'resume');
      expect(EnglishText.fold('Naïve'), 'naive');
    });

    test('folds a Turkish tag the same way the Turkish grammar does', () {
      for (final input in const ['#Sağlık', '#SAĞLIK', '#saglik', '#SAGLIK']) {
        expect(EnglishText.fold(input), '#saglik', reason: input);
        expect(TurkishText.fold(input), '#saglik', reason: input);
      }
    });

    test('normalizes typographic apostrophes', () {
      expect(EnglishText.fold('mum’s'), "mum's");
      expect(EnglishText.fold('MUM‘S'), "mum's");
      expect(EnglishText.fold('o`clock'), "o'clock");
    });

    test('keeps emoji and length', () {
      const input = '🎂 Mum’s BIRTHDAY';
      expect(EnglishText.fold(input), "🎂 mum's birthday");
      expect(EnglishText.fold(input).length, input.length);
    });
  });

  group('offset stability', () {
    test('every folded code unit maps to exactly one code unit', () {
      const inputs = [
        '',
        'tomorrow at 9',
        'İİİ evening 8',
        'ILIK water in the morning',
        '🎂🎉 tomorrow party',
        'Café ’o clock — ÂÊÎÔÛ',
        '#sağlık ilaç',
      ];
      for (final input in inputs) {
        expect(EnglishText.toLower(input).length, input.length, reason: input);
        expect(EnglishText.fold(input).length, input.length, reason: input);
      }
    });

    test('a token found in the folded text has the same range as typed', () {
      const input = 'İİİ Tomorrow MORNING';
      final folded = EnglishText.fold(input);
      final start = folded.indexOf('tomorrow');
      expect(start, 4);
      expect(input.substring(start, start + 'tomorrow'.length), 'Tomorrow');
    });
  });

  group('EnglishText.capitalizeFirst', () {
    test('uses English upper case', () {
      expect(EnglishText.capitalizeFirst('istanbul'), 'Istanbul');
      expect(TurkishText.capitalizeFirst('istanbul'), 'İstanbul');
      expect(EnglishText.capitalizeFirst('buy milk'), 'Buy milk');
    });

    test('skips leading emoji and punctuation, not digits or tags', () {
      expect(EnglishText.capitalizeFirst('🛒 milk'), '🛒 Milk');
      expect(EnglishText.capitalizeFirst('"return" it'), '"Return" it');
      expect(EnglishText.capitalizeFirst('2 eggs'), '2 eggs');
      expect(EnglishText.capitalizeFirst('#work report'), '#work report');
      expect(EnglishText.capitalizeFirst('@home water'), '@home water');
      expect(EnglishText.capitalizeFirst(''), '');
      expect(EnglishText.capitalizeFirst('Already'), 'Already');
    });
  });

  group('CaptureLocale.forLanguageCode', () {
    test('Turkish locale names pick the Turkish grammar', () {
      for (final name in const ['tr', 'tr_TR', 'tr-TR', 'TR', 'tr_CY']) {
        expect(
          CaptureLocale.forLanguageCode(name),
          CaptureLocale.turkish,
          reason: name,
        );
      }
    });

    test('anything else picks English', () {
      for (final name in const ['en', 'en_US', 'en-GB', 'EN', 'de', '']) {
        expect(
          CaptureLocale.forLanguageCode(name),
          CaptureLocale.english,
          reason: name,
        );
      }
    });

    test('the locale delegates casing to the matching helper', () {
      expect(CaptureLocale.english.toLower('I'), 'i');
      expect(CaptureLocale.turkish.toLower('I'), 'ı');
      expect(CaptureLocale.english.fold('IŞIK'), 'isik');
      expect(CaptureLocale.turkish.fold('IŞIK'), 'isik');
      expect(CaptureLocale.english.capitalizeFirst('ilac'), 'Ilac');
      expect(CaptureLocale.turkish.capitalizeFirst('ilac'), 'İlac');
    });
  });
}
