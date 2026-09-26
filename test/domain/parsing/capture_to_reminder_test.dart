import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/parsing/capture_to_reminder.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';

// Pazar 13 Eylül 2026, 14:32 (same clock as the parser tables).
final _now = DateTime(2026, 9, 13, 14, 32);

CaptureDraft _map(
  String input, {
  bool acceptSplit = false,
  DateTime? now,
  CaptureLocale locale = CaptureLocale.turkish,
}) {
  final clock = now ?? _now;
  var n = 0;
  return CaptureToReminder.map(
    CaptureParser.parse(input, now: clock, locale: locale),
    now: clock,
    id: 'r1',
    newSubtaskId: () => 's${n++}',
    acceptSplit: acceptSplit,
  );
}

/// The same mapping on an English parse (F4.6c): `CaptureToReminder` is
/// locale-agnostic, it only ever sees a `CaptureParseResult`.
CaptureDraft _mapEn(String input, {bool acceptSplit = false}) =>
    _map(input, acceptSplit: acceptSplit, locale: CaptureLocale.english);

void main() {
  group('CaptureToReminder dates and times', () {
    test('explicit date and time', () {
      final d = _map('yarın 18:00 süt al');
      expect(d.reminder.title, 'Süt al');
      expect(d.reminder.remindAt, DateTime(2026, 9, 14, 18));
      expect(d.reminder.recurrence.isNone, isTrue);
      expect(d.isPast, isFalse);
      expect(d.reminder.id, 'r1');
      expect(d.reminder.isDone, isFalse);
      expect(d.reminder.createdAt, _now);
    });

    test('a later day without a time gets the morning hour', () {
      final d = _map('yarın süt al');
      expect(d.reminder.remindAt, DateTime(2026, 9, 14, 9));
    });

    test('today without a time stays untimed', () {
      final d = _map('bugün süt al');
      expect(d.reminder.title, 'Süt al');
      expect(d.reminder.remindAt, isNull);
    });

    test('no date or time → untimed', () {
      final d = _map('süt al');
      expect(d.reminder.remindAt, isNull);
      expect(d.reminder.categoryId, ReminderCategoryIds.other);
      expect(d.reminder.priority, 0);
      expect(d.reminder.subtasks, isEmpty);
      expect(d.reminder.note, isNull);
    });

    test('a time alone is today when still ahead', () {
      final d = _map('18:30 spor');
      expect(d.reminder.remindAt, DateTime(2026, 9, 13, 18, 30));
    });

    test('an explicit past time is flagged, not shifted', () {
      final d = _map("bugün 9'da ilaç iç");
      expect(d.isPast, isTrue);
      expect(d.reminder.remindAt, DateTime(2026, 9, 13, 9));
    });

    test('a past day is flagged', () {
      final d = _map('17 eylül 2025 eski fatura');
      expect(d.isPast, isTrue);
      expect(d.reminder.remindAt, DateTime(2025, 9, 17, 9));
    });
  });

  group('CaptureToReminder recurrence', () {
    test('every day at a time', () {
      final d = _map('her gün 20:00 vitamin iç');
      expect(d.reminder.recurrence, RecurrenceRule.daily());
      expect(d.reminder.remindAt, DateTime(2026, 9, 13, 20));
      expect(d.reminder.isRecurring, isTrue);
      expect(d.isPast, isFalse);
    });

    test('weekly on a weekday', () {
      final d = _map('her pazartesi 09:00 toplantı');
      expect(d.reminder.recurrence, RecurrenceRule.weekly([DateTime.monday]));
      expect(d.reminder.remindAt, DateTime(2026, 9, 14, 9));
    });

    test('every N days without a time starts at the next morning slot', () {
      final d = _map('3 günde bir çiçek sula');
      expect(d.reminder.recurrence, RecurrenceRule.daily(interval: 3));
      // Today 09:00 has passed → the next occurrence of the series.
      expect(d.reminder.remindAt, DateTime(2026, 9, 16, 9));
    });

    test('monthly day 31 uses the clamped September occurrence', () {
      final parsed = CaptureParser.parse("her ayın 31'i kira öde", now: _now);
      // The parser skips September (no 31st) …
      expect(parsed.dateTime!.month, 10);
      final d = _map("her ayın 31'i kira öde");
      expect(d.reminder.recurrence, RecurrenceRule.monthly(dayOfMonth: 31));
      // … the rule clamps to 30 Eylül, so the series starts there.
      expect(d.reminder.remindAt, DateTime(2026, 9, 30, 9));
      final rule = d.reminder.recurrence;
      expect(
        rule.firstOnOrAfter(
          from: d.reminder.remindAt!,
          anchor: d.reminder.remindAt!,
        ),
        d.reminder.remindAt,
      );
    });

    test('monthly on a day every month has keeps the parser date', () {
      final d = _map("her ayın 17'si 10:00 aidat");
      expect(d.reminder.recurrence, RecurrenceRule.monthly(dayOfMonth: 17));
      expect(d.reminder.remindAt, DateTime(2026, 9, 17, 10));
    });

    test('ruleOf maps every kind', () {
      expect(
        CaptureToReminder.ruleOf(
          const RecurrenceSpec(kind: RecurrenceKind.everyNDays, interval: 2),
        ),
        RecurrenceRule.daily(interval: 2),
      );
      expect(
        CaptureToReminder.ruleOf(
          const RecurrenceSpec(
            kind: RecurrenceKind.weekly,
            interval: 2,
            weekdays: [1, 3],
          ),
        ),
        RecurrenceRule.weekly([1, 3], interval: 2),
      );
      expect(
        CaptureToReminder.ruleOf(
          const RecurrenceSpec(kind: RecurrenceKind.monthly),
        ),
        RecurrenceRule.none,
      );
      expect(
        CaptureToReminder.ruleOf(
          const RecurrenceSpec(kind: RecurrenceKind.yearly, interval: 2),
        ),
        RecurrenceRule.yearly(interval: 2),
      );
    });

    test('yearly without a time starts at the next morning slot', () {
      final d = _map('her yıl vergi öde');
      expect(d.reminder.recurrence, RecurrenceRule.yearly());
      // Today 09:00 has passed → the next occurrence, a year later.
      expect(d.reminder.remindAt, DateTime(2027, 9, 13, 9));
    });

    test('yearly with an explicit date keeps the parser date', () {
      final d = _map('her yıl 14 Şubat 09:00 yıl dönümü');
      expect(d.reminder.recurrence, RecurrenceRule.yearly());
      expect(d.reminder.remindAt, DateTime(2027, 2, 14, 9));
    });
  });

  group('CaptureToReminder tags', () {
    test('priority 0–3', () {
      expect(_map('rapor !').reminder.priority, 1);
      expect(_map('rapor !!').reminder.priority, 2);
      expect(_map('rapor !!!').reminder.priority, 3);
    });

    test('a matched #tag sets the category', () {
      final d = _map('rapor yaz #iş');
      expect(d.reminder.categoryId, ReminderCategoryIds.work);
      expect(d.newCategoryTag, isNull);
    });

    test('an unmatched #tag goes to Diğer with a hint', () {
      final d = _map('koşu #spor');
      expect(d.reminder.categoryId, ReminderCategoryIds.other);
      expect(d.reminder.customCategoryLabel, isNull);
      expect(d.newCategoryTag, 'spor');
    });

    test('@place is kept in the note, never as a geofence', () {
      final d = _map('çamaşır as @ev');
      expect(d.placeLabel, 'ev');
      expect(d.reminder.note, 'Yer: ev');
      expect(d.reminder.locationTriggerEnabled, isFalse);
      expect(d.reminder.locationPlaceLabel, isNull);
    });
  });

  group('CaptureToReminder "Maddelere böl?"', () {
    const input = '#market ekmek, süt ve yumurta';

    test('accepted → list title and subtasks', () {
      final d = _map(input, acceptSplit: true);
      expect(d.reminder.title, 'Market alışverişi');
      expect(d.reminder.categoryId, ReminderCategoryIds.market);
      expect(
        [for (final s in d.reminder.subtasks) s.title],
        ['Ekmek', 'Süt', 'Yumurta'],
      );
      expect([for (final s in d.reminder.subtasks) s.position], [0, 1, 2]);
      expect([for (final s in d.reminder.subtasks) s.id], ['s0', 's1', 's2']);
      expect(d.reminder.subtasks.every((s) => !s.isDone), isTrue);
    });

    test('declined → parser title, no subtasks', () {
      final d = _map(input);
      expect(d.reminder.title, 'Ekmek, süt ve yumurta');
      expect(d.reminder.subtasks, isEmpty);
    });

    test('accepting without a suggestion changes nothing', () {
      final d = _map('süt al', acceptSplit: true);
      expect(d.reminder.title, 'Süt al');
      expect(d.reminder.subtasks, isEmpty);
    });

    test('list titles', () {
      expect(
        CaptureToReminder.listTitle(ReminderCategoryIds.market),
        'Market alışverişi',
      );
      expect(
        CaptureToReminder.listTitle(ReminderCategoryIds.home),
        'Ev İşleri listesi',
      );
    });
  });

  group('CaptureToReminder on an English parse (F4.6c)', () {
    test('explicit date and time', () {
      final d = _mapEn('tomorrow at 18:00 buy milk');
      expect(d.reminder.title, 'Buy milk');
      expect(d.reminder.remindAt, DateTime(2026, 9, 14, 18));
      expect(d.isPast, isFalse);
    });

    test('a later day without a time gets the morning hour', () {
      expect(_mapEn('tomorrow dentist').reminder.remindAt,
          DateTime(2026, 9, 14, 9));
    });

    test('today without a time stays untimed', () {
      expect(_mapEn('today buy milk').reminder.remindAt, isNull);
    });

    test('recurrence, category and priority', () {
      final d = _mapEn('every monday at 9 #work standup !!');
      expect(d.reminder.title, 'Standup');
      expect(d.reminder.recurrence, RecurrenceRule.weekly(const {1}));
      expect(d.reminder.remindAt, DateTime(2026, 9, 14, 9));
      expect(d.reminder.categoryId, ReminderCategoryIds.work);
      expect(d.reminder.priority, 2);
    });

    test('an English list becomes subtasks', () {
      final d =
          _mapEn('#groceries buy bread, milk and eggs', acceptSplit: true);
      expect(d.reminder.categoryId, ReminderCategoryIds.market);
      expect(
        [for (final s in d.reminder.subtasks) s.title],
        ['Bread', 'Milk', 'Eggs'],
      );
    });

    test('a past one-off is flagged, never shifted', () {
      final d = _mapEn('today at 9 take the pills');
      expect(d.isPast, isTrue);
      expect(d.reminder.remindAt, DateTime(2026, 9, 13, 9));

      final past = _mapEn('September 17 2025 old invoice');
      expect(past.isPast, isTrue);
      expect(past.reminder.remindAt, DateTime(2025, 9, 17, 9));
    });
  });
}
