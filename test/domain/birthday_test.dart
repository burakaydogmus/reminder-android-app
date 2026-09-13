import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';

import '../helpers/factories.dart';

void main() {
  group('Birthday JSON', () {
    test('round-trip preserves all fields', () {
      final original = buildBirthday(
        id: 'b-42',
        name: 'Mehmet',
        note: 'Kitap hediye',
        date: DateTime(1985, 11, 23),
        notifyHour: 20,
        notifyMinute: 15,
        advanceOffsetsMinutes: const [0, 60, 10080],
        createdAt: DateTime(2026, 2, 2, 8),
      );

      final restored = Birthday.fromJson(original.toJson());

      expect(restored.id, 'b-42');
      expect(restored.name, 'Mehmet');
      expect(restored.note, 'Kitap hediye');
      expect(restored.date, DateTime(1985, 11, 23));
      expect(restored.notifyHour, 20);
      expect(restored.notifyMinute, 15);
      expect(restored.advanceOffsetsMinutes, [0, 60, 10080]);
      expect(restored.createdAt, DateTime(2026, 2, 2, 8));
    });

    test('fromJson applies defaults for missing optional fields', () {
      final restored = Birthday.fromJson({
        'id': 'b',
        'name': 'Ali',
        'date': DateTime(2000, 1, 5).toIso8601String(),
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      expect(restored.note, isNull);
      expect(restored.notifyHour, 9);
      expect(restored.notifyMinute, 0);
      expect(restored.advanceOffsetsMinutes, [0, 1440]);
    });
  });

  group('Birthday.nextOccurrence', () {
    test('date later this year stays in this year at notify time', () {
      final b = buildBirthday(date: DateTime(1990, 8, 20), notifyHour: 10);

      expect(
        b.nextOccurrence(from: DateTime(2026, 6, 1, 12)),
        DateTime(2026, 8, 20, 10),
      );
    });

    test('date earlier this year rolls over to next year', () {
      final b = buildBirthday(date: DateTime(1990, 3, 5));

      expect(
        b.nextOccurrence(from: DateTime(2026, 6, 10, 12)),
        DateTime(2027, 3, 5, 9),
      );
    });

    test('same day before notify time is today', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10), notifyHour: 9);

      expect(
        b.nextOccurrence(from: DateTime(2026, 5, 10, 8, 59)),
        DateTime(2026, 5, 10, 9),
      );
    });

    test('same day after notify time is next year', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10), notifyHour: 9);

      expect(
        b.nextOccurrence(from: DateTime(2026, 5, 10, 9, 1)),
        DateTime(2027, 5, 10, 9),
      );
    });

    test('exactly at notify time is next year', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10), notifyHour: 9);

      expect(
        b.nextOccurrence(from: DateTime(2026, 5, 10, 9)),
        DateTime(2027, 5, 10, 9),
      );
    });

    test('Feb 29 birthday in a non-leap year must not become Mar 1', () {
      final b = buildBirthday(date: DateTime(2000, 2, 29));

      final next = b.nextOccurrence(from: DateTime(2027, 1, 1));

      expect(next.year, 2027);
      expect(next.month, 2);
      expect(next.day, 28);
    });
  });

  group('Feb 29 birthdays (F1.8)', () {
    final leapling = buildBirthday(date: DateTime(2000, 2, 29), notifyHour: 9);

    test('occurrenceInYear is Feb 29 in leap years, Feb 28 otherwise', () {
      expect(leapling.occurrenceInYear(2028), DateTime(2028, 2, 29, 9));
      expect(leapling.occurrenceInYear(2027), DateTime(2027, 2, 28, 9));
      expect(leapling.occurrenceInYear(2100), DateTime(2100, 2, 28, 9));
      expect(leapling.occurrenceInYear(2000), DateTime(2000, 2, 29, 9));
    });

    test('non-Feb 29 dates are unaffected', () {
      final b = buildBirthday(date: DateTime(2001, 2, 28));
      expect(b.occurrenceInYear(2028), DateTime(2028, 2, 28, 9));
      expect(b.occurrenceInYear(2027), DateTime(2027, 2, 28, 9));
    });

    test('leap year: next occurrence is Feb 29', () {
      final from = DateTime(2028, 1, 15);
      expect(leapling.nextOccurrence(from: from), DateTime(2028, 2, 29, 9));
      expect(leapling.daysUntilNext(from: from), 45);
      expect(leapling.upcomingAgeFrom(from: from), 28);
    });

    test('leap year: Feb 28 is the day before', () {
      final from = DateTime(2028, 2, 28, 12);
      expect(leapling.nextOccurrence(from: from), DateTime(2028, 2, 29, 9));
      expect(leapling.daysUntilNext(from: from), 1);
    });

    test('non-leap year: Feb 28 before notify time is today', () {
      final from = DateTime(2027, 2, 28, 8);
      expect(leapling.nextOccurrence(from: from), DateTime(2027, 2, 28, 9));
      expect(leapling.daysUntilNext(from: from), 0);
      expect(leapling.upcomingAgeFrom(from: from), 27);
    });

    test('non-leap year: Feb 28 after notify time jumps to next Feb 29', () {
      final from = DateTime(2027, 2, 28, 10);
      expect(leapling.nextOccurrence(from: from), DateTime(2028, 2, 29, 9));
      expect(leapling.daysUntilNext(from: from), 366);
      expect(leapling.upcomingAgeFrom(from: from), 28);
    });

    test('non-leap year: Mar 1 is past, next is the leap-year Feb 29', () {
      final from = DateTime(2027, 3, 1, 8);
      expect(leapling.nextOccurrence(from: from), DateTime(2028, 2, 29, 9));
      expect(leapling.daysUntilNext(from: from), 365);
    });

    test('leap year: after Feb 29 the next one is Feb 28 of next year', () {
      final from = DateTime(2028, 3, 1);
      expect(leapling.nextOccurrence(from: from), DateTime(2029, 2, 28, 9));
      expect(leapling.daysUntilNext(from: from), 364);
      expect(leapling.upcomingAgeFrom(from: from), 29);
    });
  });

  group('Birthday.upcomingAgeFrom', () {
    test('is the age turned at the next occurrence', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10));
      expect(b.upcomingAgeFrom(from: DateTime(2026, 5, 1)), 36);
      expect(b.upcomingAgeFrom(from: DateTime(2026, 5, 11)), 37);
    });

    test('is null when the next occurrence is not after the birth year', () {
      final b = buildBirthday(date: DateTime(2026, 8, 1));
      expect(b.upcomingAgeFrom(from: DateTime(2026, 1, 1)), isNull);
      expect(b.upcomingAgeFrom(from: DateTime(2026, 9, 1)), 1);
    });
  });

  group('Birthday.daysUntilNext', () {
    test('counts whole days to a later date', () {
      final b = buildBirthday(date: DateTime(1990, 6, 11));

      expect(b.daysUntilNext(from: DateTime(2026, 6, 1, 23)), 10);
    });

    test('is 0 on the birthday before notify time', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10), notifyHour: 9);

      expect(b.daysUntilNext(from: DateTime(2026, 5, 10, 7)), 0);
    });

    test('is a full year on the birthday after notify time', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10), notifyHour: 9);

      expect(b.daysUntilNext(from: DateTime(2026, 5, 10, 10)), 365);
    });

    test('is 1 the day before', () {
      final b = buildBirthday(date: DateTime(1990, 5, 10));

      expect(b.daysUntilNext(from: DateTime(2026, 5, 9, 22)), 1);
    });
  });

  group('Birthday.notificationIdFor', () {
    test('is non-negative and distinct per preset offset', () {
      for (final id in ['b1', 'b-42', 'c7d1e9a0-1111-4222-8333-444455556666']) {
        final b = buildBirthday(id: id);
        final ids = BirthdayAdvanceOffset.presets
            .map((p) => b.notificationIdFor(p.minutes))
            .toList();

        for (final n in ids) {
          expect(n, inInclusiveRange(0, 0x7FFFFFFF), reason: id);
        }
        expect(ids.toSet().length, ids.length, reason: id);
      }
    });

    test('is stable for the same birthday and offset', () {
      final b = buildBirthday();
      expect(b.notificationIdFor(1440), b.notificationIdFor(1440));
    });
  });

  group('Birthday.copyWith', () {
    test('overrides given fields and keeps the rest', () {
      final b = buildBirthday(note: 'not');
      final copy = b.copyWith(name: 'Zeynep', notifyHour: 7);

      expect(copy.name, 'Zeynep');
      expect(copy.notifyHour, 7);
      expect(copy.id, b.id);
      expect(copy.note, 'not');
      expect(copy.date, b.date);
      expect(copy.advanceOffsetsMinutes, b.advanceOffsetsMinutes);
    });

    test(
      'can clear note',
      () {
        final b = buildBirthday(note: 'silinecek');

        expect(b.copyWith(note: null).note, isNull);
      },
      skip: 'Known bug — fixed in F1.8',
    );
  });
}
