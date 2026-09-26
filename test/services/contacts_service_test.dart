import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/contacts_service.dart';

fc.Contact _contact({
  String? displayName = 'Ayşe Yılmaz',
  List<fc.Event> events = const [],
}) =>
    fc.Contact(displayName: displayName, events: events);

fc.Event _event(
  int month,
  int day, {
  int? year,
  fc.EventLabel label = fc.EventLabel.birthday,
}) =>
    fc.Event(
      month: month,
      day: day,
      year: year,
      label: fc.Label(label),
    );

void main() {
  group('birthdayOf', () {
    test('picks the birthday event and keeps a null year', () {
      final found = PluginContactsPlatform.birthdayOf(
        _contact(events: [_event(9, 14)]),
      );
      expect(
          found, const ContactBirthday(name: 'Ayşe Yılmaz', month: 9, day: 14));
      expect(found!.year, isNull);
      expect(found.hasYear, isFalse);
    });

    test('keeps a plausible year', () {
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(events: [_event(9, 14, year: 1990)]),
        )?.year,
        1990,
      );
    });

    test('a contact with no birthday event is filtered out', () {
      expect(PluginContactsPlatform.birthdayOf(_contact()), isNull);
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(
            events: [
              _event(3, 1, label: fc.EventLabel.anniversary),
              _event(4, 2, label: fc.EventLabel.other),
              _event(5, 3, label: fc.EventLabel.custom),
            ],
          ),
        ),
        isNull,
        reason: 'anniversaries and custom events are not birthdays',
      );
    });

    test('ignores non-birthday events before the birthday one', () {
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(
            events: [
              _event(3, 1, label: fc.EventLabel.anniversary),
              _event(9, 14),
            ],
          ),
        )?.month,
        9,
      );
    });

    test('a blank or missing display name is dropped', () {
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(displayName: '   ', events: [_event(9, 14)]),
        ),
        isNull,
      );
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(displayName: null, events: [_event(9, 14)]),
        ),
        isNull,
      );
    });

    test('trims the display name', () {
      expect(
        PluginContactsPlatform.birthdayOf(
          _contact(displayName: '  Ayşe  ', events: [_event(9, 14)]),
        )?.name,
        'Ayşe',
      );
    });
  });

  group('validBirthday', () {
    ContactBirthday? check(int month, int day, {int? year}) =>
        PluginContactsPlatform.validBirthday(
          name: 'Ayşe',
          month: month,
          day: day,
          year: year,
        );

    test('rejects impossible months and days', () {
      expect(check(0, 10), isNull);
      expect(check(13, 10), isNull);
      expect(check(5, 0), isNull);
      expect(check(5, 32), isNull);
      expect(check(2, 30), isNull, reason: 'February never has 30 days');
      expect(check(4, 31), isNull, reason: 'April has 30 days');
    });

    test('29 February stays importable', () {
      expect(check(2, 29)?.day, 29);
    });

    test('an implausible year is dropped to null, the date is kept', () {
      for (final year in [0, 4, 999, DateTime.now().year + 1]) {
        final found = check(5, 10, year: year);
        expect(found, isNotNull, reason: 'year $year');
        expect(found!.year, isNull, reason: 'year $year must not be stored');
        expect(found.month, 5);
        expect(found.day, 10);
      }
    });
  });
}
