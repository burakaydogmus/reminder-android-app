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

    group('yearly', () {
      test('every year repeats on the anchor month and day', () {
        final anchor = DateTime(2026, 3, 17, 8, 30);
        final rule = RecurrenceRule.yearly();
        expect(
          rule.nextOccurrence(after: anchor, anchor: anchor),
          DateTime(2027, 3, 17, 8, 30),
        );
        expect(
          rule.upcoming(from: anchor, anchor: anchor, count: 3),
          [
            DateTime(2026, 3, 17, 8, 30),
            DateTime(2027, 3, 17, 8, 30),
            DateTime(2028, 3, 17, 8, 30),
          ],
        );
      });

      test('the anchor itself counts when it is after the given time', () {
        final anchor = DateTime(2026, 3, 17, 8, 30);
        expect(
          RecurrenceRule.yearly()
              .nextOccurrence(after: DateTime(2020, 1, 1), anchor: anchor),
          anchor,
        );
      });

      test('an explicit month and day win over the anchor', () {
        final anchor = DateTime(2026, 3, 17, 8, 30);
        final rule = RecurrenceRule.yearly(month: 12, dayOfMonth: 31);
        expect(
          rule.nextOccurrence(after: anchor, anchor: anchor),
          DateTime(2026, 12, 31, 8, 30),
        );
      });

      test('every N years keeps its phase from the anchor year', () {
        final anchor = DateTime(2026, 6, 1, 7);
        final rule = RecurrenceRule.yearly(interval: 3);
        // 2026, 2029, 2032 …
        expect(
          rule.upcoming(from: anchor, anchor: anchor, count: 3),
          [
            DateTime(2026, 6, 1, 7),
            DateTime(2029, 6, 1, 7),
            DateTime(2032, 6, 1, 7),
          ],
        );
        expect(
          rule.nextOccurrence(after: DateTime(2030, 1, 1), anchor: anchor),
          DateTime(2032, 6, 1, 7),
        );
      });

      test('far in the future is computed directly', () {
        final anchor = DateTime(2000, 5, 4, 6, 45);
        expect(
          RecurrenceRule.yearly(interval: 2)
              .nextOccurrence(after: DateTime(2099, 1, 1), anchor: anchor),
          DateTime(2100, 5, 4, 6, 45),
        );
      });

      // The same rule as birthdays (`Birthday.occurrenceInYear`), so a
      // 29 February reminder and a 29 February birthday behave alike.
      test('29 February falls on 28 February in non-leap years', () {
        final anchor = DateTime(2028, 2, 29, 10);
        expect(
          RecurrenceRule.yearly().upcoming(
            from: anchor,
            anchor: anchor,
            count: 5,
          ),
          [
            DateTime(2028, 2, 29, 10),
            DateTime(2029, 2, 28, 10),
            DateTime(2030, 2, 28, 10),
            DateTime(2031, 2, 28, 10),
            DateTime(2032, 2, 29, 10),
          ],
        );
      });

      test('29 February anchored earlier: 2027 is 28 Feb, 2028 is 29 Feb', () {
        final anchor = DateTime(2024, 2, 29, 9);
        final rule = RecurrenceRule.yearly();
        expect(
          rule.nextOccurrence(after: DateTime(2027, 1, 1), anchor: anchor),
          DateTime(2027, 2, 28, 9),
        );
        expect(
          rule.nextOccurrence(after: DateTime(2028, 1, 1), anchor: anchor),
          DateTime(2028, 2, 29, 9),
        );
      });

      test('an explicit 29 February is clamped the same way', () {
        final anchor = DateTime(2026, 9, 13, 20);
        expect(
          RecurrenceRule.yearly(month: 2, dayOfMonth: 29).upcoming(
            from: anchor,
            anchor: anchor,
            count: 3,
          ),
          [
            DateTime(2027, 2, 28, 20),
            DateTime(2028, 2, 29, 20),
            DateTime(2029, 2, 28, 20),
          ],
        );
      });

      test('until ends a yearly series', () {
        final anchor = DateTime(2026, 4, 2, 18);
        final rule = RecurrenceRule.yearly(until: DateTime(2028, 1, 1));
        expect(
          rule.upcoming(from: anchor, anchor: anchor, count: 10),
          [DateTime(2026, 4, 2, 18), DateTime(2027, 4, 2, 18)],
        );
      });

      test('the interval, month and day are clamped', () {
        expect(RecurrenceRule.yearly(interval: 0).interval, 1);
        expect(
          RecurrenceRule.yearly(interval: 500).interval,
          RecurrenceRule.maxInterval,
        );
        expect(RecurrenceRule.yearly(month: 0).month, 1);
        expect(RecurrenceRule.yearly(month: 13).month, 12);
        expect(RecurrenceRule.yearly(dayOfMonth: 40).dayOfMonth, 31);
        expect(RecurrenceRule.yearly().month, isNull);
      });

      test('yearlyTarget completes the month and day from the anchor', () {
        final anchor = DateTime(2026, 7, 8, 9);
        expect(
          RecurrenceRule.yearly().yearlyTarget(anchor),
          (month: 7, day: 8),
        );
        expect(
          RecurrenceRule.yearly(month: 2, dayOfMonth: 29).yearlyTarget(anchor),
          (month: 2, day: 29),
        );
        expect(RecurrenceRule.daily().yearlyTarget(anchor), isNull);
      });

      test('a UTC anchor stays UTC', () {
        final anchor = DateTime.utc(2026, 2, 28, 9);
        final next = RecurrenceRule.yearly()
            .nextOccurrence(after: anchor, anchor: anchor)!;
        expect(next.isUtc, isTrue);
        expect(next, DateTime.utc(2027, 2, 28, 9));
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

    test('an anchor-derived yearly rule already follows the new date', () {
      final rule = RecurrenceRule.yearly(interval: 2);
      expect(identical(rule.alignedTo(sunday), rule), isTrue);
    });

    test('an explicit yearly rule takes the new month and day', () {
      final until = DateTime(2030, 12, 31);
      expect(
        RecurrenceRule.yearly(
          interval: 2,
          month: 2,
          dayOfMonth: 14,
          until: until,
        ).alignedTo(sunday),
        RecurrenceRule.yearly(
          interval: 2,
          month: 9,
          dayOfMonth: 20,
          until: until,
        ),
      );
    });

    test('a 29 February rule survives a move to 28 February', () {
      final leapDay = RecurrenceRule.yearly(month: 2, dayOfMonth: 29);
      // 2027 is not a leap year: 28 February *is* this rule's occurrence.
      expect(leapDay.alignedTo(DateTime(2027, 2, 28)), leapDay);
      expect(
        leapDay.alignedTo(DateTime(2027, 3, 1)),
        RecurrenceRule.yearly(month: 3, dayOfMonth: 1),
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
      RecurrenceRule.yearly(),
      RecurrenceRule.yearly(interval: 2, until: DateTime(2031, 1, 1)),
      RecurrenceRule.yearly(month: 2, dayOfMonth: 29),
      RecurrenceRule.yearly(interval: 5, month: 11, dayOfMonth: 3),
    ];

    for (final rule in rules) {
      test('round-trips ${rule.toJson()}', () {
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
        RecurrenceRule.fromJson({'frequency': 'hourly'}),
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

    test('a yearly rule writes only the fields it has', () {
      expect(RecurrenceRule.yearly().toJson(), {
        'frequency': 'yearly',
        'interval': 1,
      });
      expect(
          RecurrenceRule.yearly(interval: 2, month: 2, dayOfMonth: 29).toJson(),
          {
            'frequency': 'yearly',
            'interval': 2,
            'month': 2,
            'dayOfMonth': 29,
          });
    });

    // The tolerance is deliberate: a build that predates `yearly` reads the
    // rule as `none`, so the reminder survives and only loses its repeat.
    test('an older reader falls back to none on an unknown frequency', () {
      final json = RecurrenceRule.yearly(month: 2, dayOfMonth: 29).toJson()!;
      // What an older `fromJson` sees: no `yearly` case, so it falls through.
      expect(json['frequency'], 'yearly');
      expect(
        RecurrenceRule.fromJson({...json, 'frequency': 'unknown-to-us'}),
        RecurrenceRule.none,
      );
    });

    test('corrupt yearly fields are clamped, never fatal', () {
      expect(
        RecurrenceRule.fromJson({
          'frequency': 'yearly',
          'interval': 0,
          'month': 99,
          'dayOfMonth': 99,
        }),
        RecurrenceRule.yearly(month: 12, dayOfMonth: 31),
      );
      expect(
        RecurrenceRule.fromJson({'frequency': 'yearly', 'month': 'x'}),
        RecurrenceRule.none,
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
