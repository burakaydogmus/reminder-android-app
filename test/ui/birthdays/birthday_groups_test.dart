import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/ui/birthdays/birthday_groups.dart';
import 'package:reminder/ui/calendar/agenda.dart';

import '../../helpers/factories.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  // Sunday 13 Sep 2026.
  final now = DateTime(2026, 9, 13, 14, 32);

  final birthdays = [
    buildBirthday(
        id: 'deniz', name: 'Deniz Yılmaz', date: DateTime(2000, 2, 29)),
    buildBirthday(id: 'mert', name: 'Mert Kaya', date: DateTime(1999, 9, 21)),
    buildBirthday(
        id: 'zeynep', name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
    buildBirthday(
      id: 'annem',
      name: 'Annem',
      date: DateTime(Birthday.unknownYear, 10, 3),
    ),
    buildBirthday(id: 'past', name: 'Ali', date: DateTime(1980, 9, 1)),
  ];

  test('upcoming: soonest first, a passed day goes to next year', () {
    expect(
      [for (final o in BirthdayGroups.upcoming(birthdays, now)) o.birthday.id],
      ['zeynep', 'mert', 'annem', 'deniz', 'past'],
    );
  });

  test('hero is the soonest; today beats tomorrow; none when empty', () {
    expect(BirthdayGroups.hero(birthdays, now)!.birthday.id, 'zeynep');
    final withToday = [
      ...birthdays,
      buildBirthday(id: 'today', name: 'Bugünkü', date: DateTime(1990, 9, 13)),
    ];
    final hero = BirthdayGroups.hero(withToday, now)!;
    expect(hero.birthday.id, 'today');
    expect(hero.daysUntil, 0);
    expect(BirthdayGroups.hero(const [], now), isNull);
  });

  test('grouped by month from this month on, across the year end', () {
    final groups = BirthdayGroups.byMonth(birthdays, now);
    expect(
      [for (final g in groups) BirthdayGroups.monthHeader(g.month, now)],
      ['Eylül', 'Ekim', 'Şubat 2027', 'Eylül 2027'],
    );
    expect([for (final o in groups.first.items) o.birthday.id],
        ['zeynep', 'mert']);
  });

  test('row subtitles: age or "yaş bilinmiyor"', () {
    final list = BirthdayGroups.upcoming(birthdays, now);
    String sub(String id) =>
        BirthdayGroups.rowSubtitle(list.firstWhere((o) => o.birthday.id == id));
    expect(sub('zeynep'), '14 Eylül · 30 yaşına');
    expect(sub('annem'), '3 Ekim · yaş bilinmiyor');
    expect(sub('deniz'), '29 Şubat · 27 yaşına');
  });

  test('29 Şubat note only in non-leap years', () {
    final b = buildBirthday(date: DateTime(2000, 2, 29));
    final next = BirthdayOccurrence.next(b, now); // 2027
    expect(
      BirthdayGroups.leapDayNote(next),
      "Artık yıl değil: 28 Şubat'ta hatırlatılır",
    );
    final leap = BirthdayOccurrence.inYear(b, 2028, now);
    expect(BirthdayGroups.leapDayNote(leap), isNull);
    expect(
      BirthdayGroups.leapDayNote(
        BirthdayOccurrence.next(
            buildBirthday(date: DateTime(2000, 2, 28)), now),
      ),
      isNull,
    );
  });

  test('hero line', () {
    final list = BirthdayGroups.upcoming(birthdays, now);
    expect(BirthdayGroups.heroLine(list[0], now), 'Yarın · 30 yaşına giriyor');
    expect(BirthdayGroups.heroLine(list[2], now), '3 Ekim');
  });
}
