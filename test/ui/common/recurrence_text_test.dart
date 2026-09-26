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
      expect(RecurrenceText.summary(RecurrenceRule.yearly(), tr), 'Her yıl');
      expect(
        RecurrenceText.summary(RecurrenceRule.yearly(interval: 2), tr),
        '2 yılda bir',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.yearly(month: 2, dayOfMonth: 14), tr),
        'Her yıl 14 Şubat',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.yearly(month: 2, dayOfMonth: 29), tr),
        'Her yıl 29 Şubat',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.yearly(interval: 4, month: 11, dayOfMonth: 3), tr),
        '4 yılda bir 3 Kasım',
      );
      expect(
        RecurrenceText.summary(
            RecurrenceRule.yearly(until: DateTime(2030, 1, 1)), tr),
        'Her yıl · bitiş 1 Oca 2030',
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

    // F3.1c: the interval is counted from the completion, so the summary names
    // that instead of a calendar pattern.
    test('completion-anchored summaries', () {
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.daily,
            interval: 14,
          ),
          tr,
        ),
        'Tamamlandıktan 14 gün sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.daily),
          tr,
        ),
        'Tamamlandıktan 1 gün sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.weekly),
          tr,
        ),
        'Tamamlandıktan 1 hafta sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.weekly,
            interval: 2,
          ),
          tr,
        ),
        'Tamamlandıktan 2 hafta sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.monthly,
            interval: 3,
          ),
          tr,
        ),
        'Tamamlandıktan 3 ay sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.monthly),
          tr,
        ),
        'Tamamlandıktan 1 ay sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.yearly),
          tr,
        ),
        'Tamamlandıktan 1 yıl sonra',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.yearly,
            interval: 2,
          ),
          tr,
        ),
        'Tamamlandıktan 2 yıl sonra',
      );
      // An end date is appended the same way as for a calendar rule.
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.daily,
            interval: 14,
            until: DateTime(2027, 3, 1),
          ),
          tr,
        ),
        'Tamamlandıktan 14 gün sonra · bitiş 1 Mar 2027',
      );
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
      expect(RecurrenceText.summary(RecurrenceRule.yearly(), en), 'Every year');
      expect(
        RecurrenceText.summary(RecurrenceRule.yearly(interval: 2), en),
        'Every 2 years',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.yearly(month: 2, dayOfMonth: 14),
          en,
        ),
        'Every year on February 14',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.yearly(month: 2, dayOfMonth: 29),
          en,
        ),
        'Every year on February 29',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.yearly(interval: 4, month: 11, dayOfMonth: 3),
          en,
        ),
        'Every 4 years on November 3',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.yearly(until: DateTime(2030, 1, 1)),
          en,
        ),
        'Every year · until Jan 1, 2030',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.daily(until: DateTime(2026, 12, 31)),
          en,
        ),
        'Every day · until Dec 31, 2026',
      );
    });

    test('completion-anchored summaries', () {
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.daily,
            interval: 14,
          ),
          en,
        ),
        '14 days after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.daily),
          en,
        ),
        '1 day after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.weekly),
          en,
        ),
        '1 week after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.weekly,
            interval: 2,
          ),
          en,
        ),
        '2 weeks after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.monthly),
          en,
        ),
        '1 month after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.monthly,
            interval: 3,
          ),
          en,
        ),
        '3 months after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(RecurrenceFrequency.yearly),
          en,
        ),
        '1 year after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.yearly,
            interval: 2,
          ),
          en,
        ),
        '2 years after completion',
      );
      expect(
        RecurrenceText.summary(
          RecurrenceRule.afterCompletion(
            RecurrenceFrequency.daily,
            interval: 14,
            until: DateTime(2027, 3, 1),
          ),
          en,
        ),
        '14 days after completion · until Mar 1, 2027',
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
