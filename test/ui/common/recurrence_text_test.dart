import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/recurrence_text.dart';

import '../../helpers/l10n_setup.dart';

void main() {
  setUpAll(initTestDateFormatting);
  final tr = AppL10n.turkish;
  final en = AppL10n.english;

  group('RecurrenceText (Turkish)', () {
    test('Turkish summaries', () {
      expect(RecurrenceText.summary(RecurrenceRule.none, tr), 'Tekrar yok');
      expect(RecurrenceText.summary(RecurrenceRule.daily(), tr), 'Her gün');
      expect(RecurrenceText.summary(RecurrenceRule.daily(interval: 3), tr),
          '3 günde bir');
      expect(
        RecurrenceText.summary(RecurrenceRule.weekly([DateTime.saturday]), tr),
        'Her Cumartesi',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.weekly([DateTime.monday, DateTime.wednesday],
                interval: 2),
            tr),
        '2 haftada bir Pzt, Çar',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.weekly([DateTime.tuesday, DateTime.friday]), tr),
        'Her hafta Sal, Cum',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.weekly([DateTime.sunday], interval: 3), tr),
        '3 haftada bir Pazar',
      );
      expect(
        RecurrenceText.summary(RecurrenceRule.weekly([1, 2, 3, 4, 5]), tr),
        'Hafta içi her gün',
      );
      expect(
          RecurrenceText.summary(
              RecurrenceRule.weekly([1, 2, 3, 4, 5, 6, 7]), tr),
          'Her gün');
      expect(RecurrenceText.summary(RecurrenceRule.monthly(dayOfMonth: 17), tr),
          "Her ayın 17'si");
      expect(
        RecurrenceText.summary(
            RecurrenceRule.monthly(dayOfMonth: 31, interval: 2), tr),
        "2 ayda bir, ayın 31'i",
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.daily(until: DateTime(2026, 12, 31)), tr),
        'Her gün · bitiş 31 Ara 2026',
      );
    });

    test('day-of-month suffixes follow vowel harmony', () {
      const expected = {
        1: "1'i",
        2: "2'si",
        3: "3'ü",
        4: "4'ü",
        5: "5'i",
        6: "6'sı",
        7: "7'si",
        8: "8'i",
        9: "9'u",
        10: "10'u",
        13: "13'ü",
        16: "16'sı",
        20: "20'si",
        26: "26'sı",
        29: "29'u",
        30: "30'u",
        31: "31'i",
      };
      expected.forEach((day, label) {
        expect(RecurrenceText.dayOfMonthLabel(day, tr), label);
      });
    });
  });

  group('RecurrenceText (English, F6.1)', () {
    test('summaries', () {
      expect(RecurrenceText.summary(RecurrenceRule.none, en), 'No repeat');
      expect(RecurrenceText.summary(RecurrenceRule.daily(), en), 'Every day');
      expect(
        RecurrenceText.summary(RecurrenceRule.daily(interval: 3), en),
        'Every 3 days',
      );
      expect(
        RecurrenceText.summary(RecurrenceRule.weekly([DateTime.saturday]), en),
        'Every Saturday',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.weekly(
            [DateTime.monday, DateTime.wednesday],
            interval: 2,
          ),
          en,
        ),
        'Every 2 weeks on Mon, Wed',
      );
      expect(
        RecurrenceText.summary(RecurrenceRule.weekly([1, 2, 3, 4, 5]), en),
        'Every weekday',
      );
      expect(
        RecurrenceText.summary(RecurrenceRule.monthly(dayOfMonth: 22), en),
        'Monthly on the 22nd',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.monthly(dayOfMonth: 31, interval: 2),
          en,
        ),
        'Every 2 months on the 31st',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.daily(until: DateTime(2026, 12, 31)),
          en,
        ),
        'Every day · until Dec 31, 2026',
      );
    });

    test('ordinals', () {
      const expected = {
        1: '1st',
        2: '2nd',
        3: '3rd',
        4: '4th',
        11: '11th',
        12: '12th',
        13: '13th',
        21: '21st',
        22: '22nd',
        23: '23rd',
        30: '30th',
        31: '31st',
      };
      expected.forEach((day, label) {
        expect(RecurrenceText.dayOfMonthLabel(day, en), label);
      });
    });
  });
}
