import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/contact_birthday_import.dart';
import 'package:reminder/domain/model/birthday.dart';

import '../helpers/factories.dart';
import '../services/fake_contacts_platform.dart';

void main() {
  final createdAt = DateTime(2026, 9, 26, 12);

  group('dedupeKey', () {
    test('folds Turkish case: İ / I / ı all match i', () {
      final a = ContactBirthdayImport.dedupeKey('İlkay', 3, 4);
      expect(ContactBirthdayImport.dedupeKey('ilkay', 3, 4), a);
      expect(ContactBirthdayImport.dedupeKey('ILKAY', 3, 4), a);
      expect(ContactBirthdayImport.dedupeKey('ılkay', 3, 4), a);
    });

    test('trims and collapses whitespace', () {
      expect(
        ContactBirthdayImport.dedupeKey('  Ayşe   Yılmaz ', 5, 10),
        ContactBirthdayImport.dedupeKey('ayse yilmaz', 5, 10),
      );
    });

    test('a different month or day is a different key', () {
      final a = ContactBirthdayImport.dedupeKey('Ayşe', 5, 10);
      expect(ContactBirthdayImport.dedupeKey('Ayşe', 6, 10), isNot(a));
      expect(ContactBirthdayImport.dedupeKey('Ayşe', 5, 11), isNot(a));
    });

    test('the year is not part of the key', () {
      expect(
        ContactBirthdayImport.keyOf(
          buildBirthday(name: 'Ayşe', date: DateTime(1990, 5, 10)),
        ),
        ContactBirthdayImport.keyOf(
          buildBirthday(
              name: 'Ayşe', date: DateTime(1990, 5, 10), yearKnown: false),
        ),
      );
    });
  });

  group('candidates', () {
    test('marks a stored birthday as already added, keeping the row', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [
          buildContactBirthday(name: 'ILKAY', month: 3, day: 4),
          buildContactBirthday(name: 'Zeynep', month: 7, day: 1),
        ],
        existing: [
          buildBirthday(id: 'b1', name: 'İlkay', date: DateTime(1988, 3, 4)),
        ],
      );
      expect(rows.length, 2);
      expect(rows.first.contact.name, 'ILKAY');
      expect(rows.first.alreadyAdded, isTrue,
          reason: 'İ/I folding must match the stored name');
      expect(rows.last.alreadyAdded, isFalse);
    });

    test('a stored birthday on another day is not a duplicate', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [buildContactBirthday(name: 'Ayşe', month: 5, day: 10)],
        existing: [
          buildBirthday(name: 'Ayşe', date: DateTime(1990, 5, 11)),
        ],
      );
      expect(rows.single.alreadyAdded, isFalse);
    });

    test('a year-less stored birthday still matches a year-known contact', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [
          buildContactBirthday(name: 'Ayşe', month: 5, day: 10, year: 1990),
        ],
        existing: [
          buildBirthday(
            name: 'Ayşe',
            date: DateTime(2000, 5, 10),
            yearKnown: false,
          ),
        ],
      );
      expect(rows.single.alreadyAdded, isTrue);
    });

    test('collapses duplicates inside the address book itself', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [
          buildContactBirthday(name: 'Ayşe Yılmaz', month: 5, day: 10),
          buildContactBirthday(name: 'ayse  yilmaz', month: 5, day: 10),
        ],
        existing: const [],
      );
      expect(rows.length, 1);
      expect(rows.single.contact.name, 'Ayşe Yılmaz',
          reason: 'the first spelling wins');
    });

    test('drops a contact whose name is blank', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [buildContactBirthday(name: '   ', month: 5, day: 10)],
        existing: const [],
      );
      expect(rows, isEmpty);
    });

    test('sorts by folded name, then month/day', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [
          buildContactBirthday(name: 'Zeynep', month: 1, day: 1),
          buildContactBirthday(name: 'Ömer', month: 2, day: 2),
          buildContactBirthday(name: 'ayşe', month: 12, day: 3),
          buildContactBirthday(name: 'Ayşe', month: 1, day: 9),
        ],
        existing: const [],
      );
      expect(
        [for (final r in rows) '${r.contact.name}/${r.contact.month}'],
        ['Ayşe/1', 'ayşe/12', 'Ömer/2', 'Zeynep/1'],
      );
    });

    test('selectableKeys leaves out the already added rows', () {
      final rows = ContactBirthdayImport.candidates(
        contacts: [
          buildContactBirthday(name: 'Ayşe', month: 5, day: 10),
          buildContactBirthday(name: 'Zeynep', month: 7, day: 1),
        ],
        existing: [buildBirthday(name: 'Ayşe', date: DateTime(1990, 5, 10))],
      );
      expect(
        ContactBirthdayImport.selectableKeys(rows),
        {ContactBirthdayImport.dedupeKey('Zeynep', 7, 1)},
      );
    });
  });

  group('toBirthday', () {
    test('a year-less contact imports with year == null, not a sentinel', () {
      final b = ContactBirthdayImport.toBirthday(
        buildContactBirthday(name: 'Ayşe', month: 5, day: 10),
        id: 'id-1',
        createdAt: createdAt,
      );
      expect(b.year, isNull);
      expect(b.hasYear, isFalse);
      expect(b.year, isNot(Birthday.legacyUnknownYear));
      expect(b.birthDate, isNull);
      expect(b.upcomingAge, isNull);
    });

    test('a year-known contact keeps its year and gets an age', () {
      final b = ContactBirthdayImport.toBirthday(
        buildContactBirthday(name: 'Ayşe', month: 5, day: 10, year: 1990),
        id: 'id-1',
        createdAt: createdAt,
      );
      expect(b.year, 1990);
      expect(b.upcomingAgeFrom(from: DateTime(2026, 1, 1)), 36);
    });

    test('uses the app defaults for time and offsets, and trims the name', () {
      final b = ContactBirthdayImport.toBirthday(
        buildContactBirthday(name: '  Ayşe  ', month: 5, day: 10),
        id: 'id-1',
        createdAt: createdAt,
      );
      expect(b.name, 'Ayşe');
      expect(b.notifyHour, 9);
      expect(b.notifyMinute, 0);
      expect(b.advanceOffsetsMinutes, const [0, 1440]);
      expect(b.createdAt, createdAt);
    });
  });

  group('plan', () {
    List<ContactImportCandidate> rowsWith({
      required List<Birthday> existing,
    }) =>
        ContactBirthdayImport.candidates(
          contacts: [
            buildContactBirthday(name: 'Ayşe', month: 5, day: 10),
            buildContactBirthday(name: 'Bora', month: 6, day: 2, year: 1985),
            buildContactBirthday(name: 'Zeynep', month: 7, day: 1),
          ],
          existing: existing,
        );

    test('imports only the selected rows', () {
      final rows = rowsWith(existing: const []);
      var n = 0;
      final (birthdays, result) = ContactBirthdayImport.plan(
        rows: rows,
        selectedKeys: {ContactBirthdayImport.dedupeKey('Bora', 6, 2)},
        newId: () => 'id-${++n}',
        createdAt: createdAt,
      );
      expect([for (final b in birthdays) b.name], ['Bora']);
      expect(birthdays.single.id, 'id-1');
      expect(result.imported, ['Bora']);
      expect(result.skipped, isEmpty);
    });

    test('never creates a second record for an already added birthday', () {
      final rows = rowsWith(
        existing: [buildBirthday(name: 'ayse', date: DateTime(1990, 5, 10))],
      );
      final (birthdays, result) = ContactBirthdayImport.plan(
        rows: rows,
        // Even if the key somehow ends up selected, the row is still skipped.
        selectedKeys: {for (final r in rows) r.key},
        newId: () => 'id',
        createdAt: createdAt,
      );
      expect([for (final b in birthdays) b.name], ['Bora', 'Zeynep']);
      expect(result.imported, ['Bora', 'Zeynep']);
      expect(result.skipped, ['Ayşe']);
    });

    test('an empty selection imports nothing but still reports duplicates', () {
      final rows = rowsWith(
        existing: [buildBirthday(name: 'Ayşe', date: DateTime(1990, 5, 10))],
      );
      final (birthdays, result) = ContactBirthdayImport.plan(
        rows: rows,
        selectedKeys: const {},
        newId: () => 'id',
        createdAt: createdAt,
      );
      expect(birthdays, isEmpty);
      expect(result.importedCount, 0);
      expect(result.skippedCount, 1);
      expect(result.isEmpty, isFalse);
    });
  });
}
