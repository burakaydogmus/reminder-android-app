import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';
import 'package:reminder/ui/capture/capture_text.dart';

final _now = DateTime(2026, 9, 13, 14, 32);

void main() {
  group('CaptureText.parse', () {
    test('without suppressed phrases equals the parser', () {
      const input = 'yarın 18:00 süt al #market';
      final a = CaptureText.parse(input, now: _now);
      final b = CaptureParser.parse(input, now: _now);
      expect(a.title, b.title);
      expect(a.tokens, b.tokens);
      expect(a.dateTime, b.dateTime);
    });

    test('a suppressed phrase stays in the title as typed', () {
      final r = CaptureText.parse(
        'yarın 18:00 süt al',
        now: _now,
        suppressed: {'yarın'},
      );
      expect(r.tokensOf(CaptureTokenKind.date), isEmpty);
      expect(r.tokensOf(CaptureTokenKind.time).single.text, '18:00');
      expect(r.title, 'Yarın süt al');
      // The time alone is today when still ahead.
      expect(r.dateTime, DateTime(2026, 9, 13, 18));
    });

    test('the first plain word keeps its typed case', () {
      final r = CaptureText.parse(
        'cuma 18:00 ekmek al',
        now: _now,
        suppressed: {'cuma', '18:00'},
      );
      expect(r.tokens, isEmpty);
      expect(r.title, 'Cuma 18:00 ekmek al');
      expect(r.dateTime, isNull);
    });

    test('only whole words are suppressed', () {
      final r = CaptureText.parse(
        'cumartesi pazar cuma',
        now: _now,
        suppressed: {'cuma'},
      );
      // "cumartesi" is still a date; the standalone "cuma" is text.
      expect(r.tokensOf(CaptureTokenKind.date).single.text, 'cumartesi');
      expect(r.title, contains('cuma'));
    });

    test('a suppressed #tag drops the category and the split', () {
      final r = CaptureText.parse(
        '#market ekmek, süt',
        now: _now,
        suppressed: {'#market'},
      );
      expect(r.categoryId, isNull);
      expect(r.splitSuggestion, isEmpty);
      expect(r.title, '#market ekmek, süt');
    });

    test('token ranges index the original input', () {
      const input = 'yarın 18:00 süt al !!';
      final r = CaptureText.parse(input, now: _now, suppressed: {'yarın'});
      for (final t in r.tokens) {
        expect(input.substring(t.start, t.end), t.text);
      }
    });
  });
}
