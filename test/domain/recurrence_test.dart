import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';

void main() {
  group('RecurrenceRule.nextOccurrence', () {
    test('none never repeats', () {
      final at = DateTime(2026, 9, 13, 9);
      expect(RecurrenceRule.none.nextOccurrence(after: at, anchor: at), isNull);
    });

    group('daily', () {
      final anchor = DateTime(2026, 9, 13, 9);

      test('every day keeps the wall-clock time', () {
        final rule = RecurrenceRule.daily();
        expect(
          rule.nextOccurrence(after: anchor, anchor: anchor),
          DateTime(2026, 9, 14, 9),
        );
        expect(
          rule.nextOccurrence(
              after: DateTime(2026, 9, 14, 8, 59), anchor: anchor),
          DateTime(2026, 9, 14, 9),
        );
      });

      test('the anchor itself counts when it is after the given time', () {
        expect(
          RecurrenceRule.daily().nextOccurrence(
            after: DateTime(2026, 9, 1),
            anchor: anchor,
          ),
          anchor,
        );
      });

      test('every N days stays on the anchor grid', () {
        final rule = RecurrenceRule.daily(interval: 3);
        // 13, 16, 19, 22 …
        expect(
          rule.nextOccurrence(after: DateTime(2026, 9, 20, 10), anchor: anchor),
          DateTime(2026, 9, 22, 9),
        );
        expect(
          rule.nextOccurrence(after: DateTime(2026, 9, 19, 8), anchor: anchor),
          DateTime(2026, 9, 19, 9),
        );
      });

      test('far in the future is computed directly', () {
        final rule = RecurrenceRule.daily(interval: 7);
        final old = DateTime(2020, 1, 1, 7, 30);
        final next =
            rule.nextOccurrence(after: DateTime(2026, 9, 13), anchor: old)!;
        expect(next, DateTime(2026, 9, 16, 7, 30));
        expect(next.weekday, old.weekday);
      });
    });

    group('weekly', () {
      test('single weekday: every Saturday', () {
        final sat = DateTime(2026, 9, 12, 16);
        final rule = RecurrenceRule.weekly([DateTime.saturday]);
        expect(
          rule.nextOccurrence(after: sat, anchor: sat),
          DateTime(2026, 9, 19, 16),
        );
      });

      test('every 2 weeks on Monday and Wednesday', () {
        final mon = DateTime(2026, 9, 14, 8);
        final rule = RecurrenceRule.weekly(
          [DateTime.wednesday, DateTime.monday],
          interval: 2,
        );
        expect(rule.weekdays, [DateTime.monday, DateTime.wednesday]);
        expect(
          rule.upcoming(from: mon, anchor: mon, count: 5),
          [
            DateTime(2026, 9, 14, 8),
            DateTime(2026, 9, 16, 8),
            DateTime(2026, 9, 28, 8),
            DateTime(2026, 9, 30, 8),
            DateTime(2026, 10, 12, 8),
          ],
        );
        expect(
          rule.nextOccurrence(after: DateTime(2026, 9, 17), anchor: mon),
          DateTime(2026, 9, 28, 8),
        );
      });

      test('days before the anchor in its first week are skipped', () {
        final wed = DateTime(2026, 9, 16, 8);
        final rule =
            RecurrenceRule.weekly([DateTime.monday, DateTime.wednesday]);
        expect(
          rule.upcoming(from: DateTime(2026, 9, 1), anchor: wed, count: 2),
          [DateTime(2026, 9, 16, 8), DateTime(2026, 9, 21, 8)],
        );
      });

      test('no weekdays means the anchor weekday', () {
        final sun = DateTime(2026, 9, 13, 20);
        expect(
          RecurrenceRule.weekly(const [])
              .nextOccurrence(after: sun, anchor: sun),
          DateTime(2026, 9, 20, 20),
        );
      });
    });

    group('monthly', () {
      test('day 31 clamps to the month end and comes back', () {
        final jan31 = DateTime(2026, 1, 31, 10);
        final rule = RecurrenceRule.monthly(dayOfMonth: 31);
        expect(
          rule.upcoming(from: jan31, anchor: jan31, count: 5),
          [
            DateTime(2026, 1, 31, 10),
            DateTime(2026, 2, 28, 10),
            DateTime(2026, 3, 31, 10),
            DateTime(2026, 4, 30, 10),
            DateTime(2026, 5, 31, 10),
          ],
        );
      });

      test('completing a clamped occurrence keeps the original day', () {
        final rule = RecurrenceRule.monthly(dayOfMonth: 31);
        final feb28 = DateTime(2026, 2, 28, 10);
        expect(
          rule.nextOccurrence(after: feb28, anchor: feb28),
          DateTime(2026, 3, 31, 10),
        );
      });

      test('leap years: Feb 29 exists only in leap years', () {
        final rule = RecurrenceRule.monthly(dayOfMonth: 29);
        final jan2027 = DateTime(2027, 1, 29, 9);
        expect(
          rule.nextOccurrence(after: jan2027, anchor: jan2027),
          DateTime(2027, 2, 28, 9),
        );
        final jan2028 = DateTime(2028, 1, 29, 9);
        expect(
          rule.nextOccurrence(after: jan2028, anchor: jan2028),
          DateTime(2028, 2, 29, 9),
        );
        expect(RecurrenceRule.daysInMonth(2100, 2), 28);
        expect(RecurrenceRule.daysInMonth(2000, 2), 29);
      });

      test('every 3 months and across the year end', () {
        final rule = RecurrenceRule.monthly(dayOfMonth: 17, interval: 3);
        final nov = DateTime(2026, 11, 17, 12);
        expect(
          rule.upcoming(from: nov, anchor: nov, count: 3),
          [
            DateTime(2026, 11, 17, 12),
            DateTime(2027, 2, 17, 12),
            DateTime(2027, 5, 17, 12),
          ],
        );
      });

      test('a day before the anchor day in the first month is skipped', () {
        final rule = RecurrenceRule.monthly(dayOfMonth: 5);
        final anchor = DateTime(2026, 9, 20, 9);
        expect(
          rule.nextOccurrence(after: DateTime(2026, 9, 1), anchor: anchor),
          DateTime(2026, 10, 5, 9),
        );
      });
    });

    test('until ends the series (inclusive, date only)', () {
      final anchor = DateTime(2026, 9, 13, 21);
      final rule = RecurrenceRule.daily(until: DateTime(2026, 9, 15, 3));
      expect(rule.until, DateTime(2026, 9, 15));
      expect(
        rule.upcoming(from: anchor, anchor: anchor, count: 10),
        [
          DateTime(2026, 9, 13, 21),
          DateTime(2026, 9, 14, 21),
          DateTime(2026, 9, 15, 21),
        ],
      );
      expect(
        rule.nextOccurrence(after: DateTime(2026, 9, 15, 22), anchor: anchor),
        isNull,
      );
    });

    // Europe/Istanbul has no DST; European zones switch on the last Sunday of
    // March and October. The rule builds each occurrence from calendar fields
    // (`DateTime(y, m, d, h, min)`), so the wall-clock time survives the switch
    // on any device time zone — a `Duration(days: 1)` add would move it by an
    // hour there.
    group('DST transitions keep the wall-clock time', () {
      for (final (name, anchor) in [
        ('spring forward (29 Mar 2026)', DateTime(2026, 3, 28, 9, 15)),
        ('fall back (25 Oct 2026)', DateTime(2026, 10, 24, 9, 15)),
      ]) {
        test('daily, $name', () {
          final next = RecurrenceRule.daily().nextOccurrence(
            after: anchor,
            anchor: anchor,
          )!;
          final day = DateTime(anchor.year, anchor.month, anchor.day + 1);
          expect((next.day, next.hour, next.minute), (day.day, 9, 15));
        });

        test('weekly, $name', () {
          final next = RecurrenceRule.weekly([anchor.weekday]).nextOccurrence(
            after: anchor,
            anchor: anchor,
          )!;
          final day = DateTime(anchor.year, anchor.month, anchor.day + 7);
          expect(
            (next.month, next.day, next.hour, next.minute),
            (day.month, day.day, 9, 15),
          );
        });
      }

      test('UTC anchors stay UTC', () {
        final anchor = DateTime.utc(2026, 3, 28, 9);
        final next = RecurrenceRule.daily().nextOccurrence(
          after: anchor,
          anchor: anchor,
        )!;
        expect(next.isUtc, isTrue);
        expect(next, DateTime.utc(2026, 3, 29, 9));
      });
    });
  });

  group('RecurrenceRule.summary', () {
    test('Turkish summaries', () {
      expect(RecurrenceRule.none.summary, 'Tekrar yok');
      expect(RecurrenceRule.daily().summary, 'Her gün');
      expect(RecurrenceRule.daily(interval: 3).summary, '3 günde bir');
      expect(
        RecurrenceRule.weekly([DateTime.saturday]).summary,
        'Her Cumartesi',
      );
      expect(
        RecurrenceRule.weekly([DateTime.monday, DateTime.wednesday],
                interval: 2)
            .summary,
        '2 haftada bir Pzt, Çar',
      );
      expect(
        RecurrenceRule.weekly([DateTime.tuesday, DateTime.friday]).summary,
        'Her hafta Sal, Cum',
      );
      expect(
        RecurrenceRule.weekly([DateTime.sunday], interval: 3).summary,
        '3 haftada bir Pazar',
      );
      expect(
        RecurrenceRule.weekly([1, 2, 3, 4, 5]).summary,
        'Hafta içi her gün',
      );
      expect(RecurrenceRule.weekly([1, 2, 3, 4, 5, 6, 7]).summary, 'Her gün');
      expect(RecurrenceRule.monthly(dayOfMonth: 17).summary, "Her ayın 17'si");
      expect(
        RecurrenceRule.monthly(dayOfMonth: 31, interval: 2).summary,
        "2 ayda bir, ayın 31'i",
      );
      expect(
        RecurrenceRule.daily(until: DateTime(2026, 12, 31)).summary,
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
        expect(RecurrenceRule.dayOfMonthLabel(day), label);
      });
    });
  });

  group('RecurrenceRule.alignedTo (moving the whole series)', () {
    final sunday = DateTime(2026, 9, 20);
    final monday = DateTime(2026, 9, 21);

    test('a single-day weekly rule moves to the new weekday', () {
      final until = DateTime(2026, 12, 31);
      expect(
        RecurrenceRule.weekly([DateTime.saturday], interval: 2, until: until)
            .alignedTo(sunday),
        RecurrenceRule.weekly([DateTime.sunday], interval: 2, until: until),
      );
    });

    test('a multi-day weekly rule gains the new weekday', () {
      expect(
        RecurrenceRule.weekly([DateTime.tuesday, DateTime.thursday])
            .alignedTo(monday),
        RecurrenceRule.weekly([1, 2, 4]),
      );
      final rule = RecurrenceRule.weekly([DateTime.monday]);
      expect(identical(rule.alignedTo(monday), rule), isTrue);
    });

    test('a monthly rule takes the new day unless it is the clamped day', () {
      expect(
        RecurrenceRule.monthly(dayOfMonth: 17).alignedTo(sunday),
        RecurrenceRule.monthly(dayOfMonth: 20),
      );
      final endOfMonth = RecurrenceRule.monthly(dayOfMonth: 31);
      expect(endOfMonth.alignedTo(DateTime(2026, 9, 30)), endOfMonth);
      expect(
        endOfMonth.alignedTo(DateTime(2026, 10, 30)),
        RecurrenceRule.monthly(dayOfMonth: 30),
      );
    });

    test('daily and none are unchanged', () {
      expect(RecurrenceRule.daily(interval: 3).alignedTo(sunday),
          RecurrenceRule.daily(interval: 3));
      expect(RecurrenceRule.none.alignedTo(sunday), RecurrenceRule.none);
    });
  });

  group('RecurrenceRule JSON', () {
    final rules = [
      RecurrenceRule.daily(),
      RecurrenceRule.daily(interval: 4, until: DateTime(2027, 1, 2)),
      RecurrenceRule.weekly([DateTime.saturday]),
      RecurrenceRule.weekly([1, 3], interval: 2),
      RecurrenceRule.monthly(dayOfMonth: 31, interval: 6),
    ];

    for (final rule in rules) {
      test('round-trips ${rule.summary}', () {
        expect(RecurrenceRule.fromJson(rule.toJson()), rule);
      });
    }

    test('none is written as null and read back from null', () {
      expect(RecurrenceRule.none.toJson(), isNull);
      expect(RecurrenceRule.fromJson(null), RecurrenceRule.none);
    });

    test('corrupt values load as none or are clamped', () {
      expect(RecurrenceRule.fromJson('daily'), RecurrenceRule.none);
      expect(
        RecurrenceRule.fromJson({'frequency': 'yearly'}),
        RecurrenceRule.none,
      );
      expect(
        RecurrenceRule.fromJson({'frequency': 'monthly'}),
        RecurrenceRule.none,
      );
      expect(
        RecurrenceRule.fromJson({'frequency': 'weekly', 'weekdays': 'x'}),
        RecurrenceRule.none,
      );
      expect(
        RecurrenceRule.fromJson(
          {
            'frequency': 'weekly',
            'interval': 0,
            'weekdays': [9, 2, 2]
          },
        ),
        RecurrenceRule.weekly([DateTime.tuesday]),
      );
    });

    test('equality and hashCode are by value', () {
      expect(
        RecurrenceRule.weekly([3, 1]),
        RecurrenceRule.weekly([1, 3]),
      );
      expect(
        RecurrenceRule.weekly([3, 1]).hashCode,
        RecurrenceRule.weekly([1, 3]).hashCode,
      );
      expect(RecurrenceRule.daily(), isNot(RecurrenceRule.daily(interval: 2)));
    });
  });
}
