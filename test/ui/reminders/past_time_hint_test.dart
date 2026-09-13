import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('PastTime.isPast', () {
    final now = DateTime(2026, 9, 13, 18, 0, 20);

    test('the current minute has already passed', () {
      expect(PastTime.isPast(DateTime(2026, 9, 13, 18), now), isTrue);
    });

    test('the next minute is in the future', () {
      expect(PastTime.isPast(DateTime(2026, 9, 13, 18, 1), now), isFalse);
    });
  });

  group('PastTime.suggestion', () {
    test('earlier today → same time tomorrow', () {
      final now = DateTime(2026, 9, 13, 18);
      expect(
        PastTime.suggestion(DateTime(2026, 9, 13, 17, 30), now),
        DateTime(2026, 9, 14, 17, 30),
      );
    });

    test('earlier day, time still ahead today → today', () {
      final now = DateTime(2026, 9, 13, 18);
      expect(
        PastTime.suggestion(DateTime(2026, 9, 10, 19), now),
        DateTime(2026, 9, 13, 19),
      );
    });

    test('earlier day, time already passed today → tomorrow', () {
      final now = DateTime(2026, 9, 13, 18);
      expect(
        PastTime.suggestion(DateTime(2026, 9, 10, 9), now),
        DateTime(2026, 9, 14, 9),
      );
    });

    test('just before midnight: the current minute → tomorrow', () {
      final now = DateTime(2026, 9, 13, 23, 59);
      expect(
        PastTime.suggestion(DateTime(2026, 9, 13, 23, 59), now),
        DateTime(2026, 9, 14, 23, 59),
      );
    });

    test('just after midnight: yesterday late evening → today', () {
      final now = DateTime(2026, 9, 14, 0, 5);
      expect(
        PastTime.suggestion(DateTime(2026, 9, 13, 23, 30), now),
        DateTime(2026, 9, 14, 23, 30),
      );
    });

    test('rolls over month and year ends', () {
      expect(
        PastTime.suggestion(
          DateTime(2026, 9, 30, 8),
          DateTime(2026, 9, 30, 9),
        ),
        DateTime(2026, 10, 1, 8),
      );
      expect(
        PastTime.suggestion(
          DateTime(2026, 12, 31, 8),
          DateTime(2026, 12, 31, 9),
        ),
        DateTime(2027, 1, 1, 8),
      );
    });
  });

  group('labels', () {
    final now = DateTime(2026, 9, 13, 18);

    test('suggestion chip text', () {
      expect(
        PastTime.suggestionLabel(DateTime(2026, 9, 14, 18, 30), now),
        'Yarın 18:30 mı?',
      );
      expect(
        PastTime.suggestionLabel(DateTime(2026, 9, 13, 19), now),
        'Bugün 19:00 mı?',
      );
    });

    test('screen reader label', () {
      expect(
        PastTime.suggestionSemantics(DateTime(2026, 9, 14, 7, 5), now),
        'Yarın saat 07:05 olarak ayarla',
      );
    });
  });
}
