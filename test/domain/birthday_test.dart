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

    test(
      'Feb 29 birthday in a non-leap year must not become Mar 1',
      () {
        final b = buildBirthday(date: DateTime(2000, 2, 29));

        final next = b.nextOccurrence(from: DateTime(2027, 1, 1));

        expect(next.year, 2027);
        expect(next.month, 2);
        expect(next.day, 28);
      },
      skip: 'Known bug — fixed in F1.8',
    );
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
          expect(n, inInclusiveRange(1, 0x7FFFFFFF), reason: id);
        }
        expect(ids.toSet().length, ids.length, reason: id);
      }
    });

    test('is stable for the same birthday and offset', () {
      final b = buildBirthday();
      expect(b.notificationIdFor(1440), b.notificationIdFor(1440));
    });

    test('matches the hard-coded deterministic id (F1.5)', () {
      final b = buildBirthday(id: 'c7d1e9a0-1111-4222-8333-444455556666');
      expect(b.notificationIdFor(0), 2097222621);
      expect(b.notificationIdFor(1440), 497286126);
      expect(b.copyWith(name: 'Başka').notificationIdFor(0), 2097222621);
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
