import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('SnoozeOptions.from', () {
    test('afternoon: +10 min, +1 h, this evening, tomorrow morning', () {
      // Sunday 13 Sep 2026, 14:32:20.
      final options = SnoozeOptions.from(DateTime(2026, 9, 13, 14, 32, 20));
      expect(options.map((o) => o.kind), SnoozeKind.values);
      expect(options.map((o) => o.label), [
        '10 dakika',
        '1 saat',
        'Bu akşam',
        'Yarın sabah',
      ]);
      expect(options.map((o) => o.at), [
        DateTime(2026, 9, 13, 14, 42),
        DateTime(2026, 9, 13, 15, 32),
        DateTime(2026, 9, 13, 20),
        DateTime(2026, 9, 14, 9),
      ]);
    });

    test('after 20:00 the evening option moves to tomorrow', () {
      final options = SnoozeOptions.from(DateTime(2026, 9, 13, 21, 15));
      final evening = options[2];
      expect(evening.label, 'Yarın akşam');
      expect(evening.at, DateTime(2026, 9, 14, 20));
      expect(options.map((o) => o.label), isNot(contains('Bu akşam')));
      expect(options[3].at, DateTime(2026, 9, 14, 9));
    });

    test('exactly 20:00 counts as past', () {
      final options = SnoozeOptions.from(DateTime(2026, 9, 13, 20));
      expect(options[2].label, 'Yarın akşam');
    });

    test('late night: relative options cross midnight, month end handled', () {
      final options = SnoozeOptions.from(DateTime(2026, 9, 30, 23, 55));
      expect(options[0].at, DateTime(2026, 10, 1, 0, 5));
      expect(options[1].at, DateTime(2026, 10, 1, 0, 55));
      expect(options[2].at, DateTime(2026, 10, 1, 20));
      expect(options[3].at, DateTime(2026, 10, 1, 9));
    });
  });

  group('SnoozeOptions text', () {
    final now = DateTime(2026, 9, 13, 14, 32);

    test('timeLabel: time today, weekday + time otherwise', () {
      expect(
          SnoozeOptions.timeLabel(DateTime(2026, 9, 13, 14, 42), now), '14:42');
      expect(
          SnoozeOptions.timeLabel(DateTime(2026, 9, 14, 9), now), 'Pzt 09:00');
      expect(
          SnoozeOptions.timeLabel(DateTime(2026, 9, 19, 9), now), 'Cmt 09:00');
    });

    test('dativeSuffix follows the last spoken number word', () {
      final cases = {
        '00:00': 'a', // sıfır
        '08:00': 'e', // sekiz
        '09:00': 'a', // dokuz
        '10:30': 'a', // otuz
        '11:50': 'ye', // elli
        '12:05': 'e', // beş
        '13:00': 'e', // üç
        '14:00': 'e', // dört
        '14:42': 'ye', // iki
        '16:00': 'ya', // altı
        '17:00': 'ye', // yedi
        '18:40': 'a', // kırk
        '19:01': 'e', // bir
        '20:00': 'ye', // yirmi
        '21:10': 'a', // on
      };
      cases.forEach((time, suffix) {
        final parts = time.split(':').map(int.parse).toList();
        expect(
          SnoozeOptions.dativeSuffix(DateTime(2026, 1, 1, parts[0], parts[1])),
          suffix,
          reason: time,
        );
      });
    });

    test('snoozedMessage', () {
      expect(
        SnoozeOptions.snoozedMessage(DateTime(2026, 9, 14, 9), now),
        "Yarın 09:00'a ertelendi",
      );
      expect(
        SnoozeOptions.snoozedMessage(DateTime(2026, 9, 13, 14, 42), now),
        "14:42'ye ertelendi",
      );
    });
  });
}
