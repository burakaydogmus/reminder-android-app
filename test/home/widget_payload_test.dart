import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/home/widget_payload.dart';
import 'package:reminder/l10n/l10n.dart';

import '../helpers/factories.dart';
import '../helpers/l10n_setup.dart';

final _now = DateTime(2026, 9, 13, 14);

Map<String, Object?> _build({
  List<Reminder> reminders = const [],
  List<Birthday> birthdays = const [],
  bool notificationsEnabled = true,
  DateTime? now,
}) =>
    WidgetPayload.build(
      l10n: AppL10n.turkish,
      reminders: reminders,
      birthdays: birthdays,
      notificationsEnabled: notificationsEnabled,
      now: now ?? _now,
    );

List<Map<String, Object?>> _items(Map<String, Object?> payload) =>
    (payload['items']! as List).cast<Map<String, Object?>>();

Map<String, Object?> _counts(Map<String, Object?> payload) =>
    payload['counts']! as Map<String, Object?>;

Map<String, Object?>? _next(Map<String, Object?> payload) =>
    payload['next'] as Map<String, Object?>?;

void main() {
  setUpAll(initTestDateFormatting);

  final overdue = buildReminder(
    id: 'overdue',
    title: 'Elektrik faturasını öde',
    remindAt: DateTime(2026, 9, 13, 9),
  );
  final at16 = buildReminder(
    id: 'at16',
    title: "Ali'yi kurstan al",
    remindAt: DateTime(2026, 9, 13, 16),
  );
  final at18 = buildReminder(id: 'at18', remindAt: DateTime(2026, 9, 13, 18));
  final untimed = buildReminder(id: 'untimed', title: 'Süt');
  final tomorrow = buildReminder(
    id: 'tomorrow',
    remindAt: DateTime(2026, 9, 14, 10),
  );
  final october = buildReminder(
    id: 'october',
    remindAt: DateTime(2026, 10, 12, 9),
  );
  final nextYear = buildReminder(
    id: 'nextYear',
    remindAt: DateTime(2027, 1, 12, 9),
  );
  final done = buildReminder(
    id: 'done',
    isDone: true,
    remindAt: DateTime(2026, 9, 13, 17),
  );

  group('WidgetPayload.build', () {
    test('sections in order: overdue, today, untimed, later; done skipped', () {
      final payload = _build(
        reminders: [nextYear, done, untimed, at18, tomorrow, overdue, at16],
      );
      final items = _items(payload);

      expect(items.map((i) => i['id']), [
        'overdue',
        'at16',
        'at18',
        'untimed',
        'tomorrow',
        'nextYear',
      ]);
      expect(items.map((i) => i['section']), [
        WidgetPayload.sectionOverdue,
        WidgetPayload.sectionToday,
        WidgetPayload.sectionToday,
        WidgetPayload.sectionUntimed,
        WidgetPayload.sectionLater,
        WidgetPayload.sectionLater,
      ]);
      expect(payload['v'], WidgetPayload.version);
      expect(payload['generatedAt'], _now.millisecondsSinceEpoch);
    });

    test('time labels: Gecikti / clock / Yarın / "12 Eki" / other year', () {
      final items = _items(
        _build(
          reminders: [overdue, at16, untimed, tomorrow, october, nextYear],
        ),
      );
      final byId = {for (final i in items) i['id']: i};

      expect(byId['overdue']!['time'], 'Gecikti');
      expect(byId['overdue']!['overdue'], isTrue);
      expect(byId['overdue']!['clock'], '09:00');
      expect(byId['at16']!['time'], '16:00');
      expect(byId['at16']!['overdue'], isFalse);
      expect(byId['at16']!['dueAt'], at16.remindAt!.millisecondsSinceEpoch);
      expect(byId['untimed']!['time'], isNull);
      expect(byId['untimed']!['clock'], isNull);
      expect(byId['untimed']!['dueAt'], isNull);
      expect(byId['tomorrow']!['time'], 'Yarın');
      expect(byId['october']!['time'], '12 Eki');
      expect(byId['nextYear']!['time'], '12 Oca 2027');
    });

    test('pinned and priority order inside a section (compareReminders)', () {
      final plain = buildReminder(id: 'plain', createdAt: DateTime(2026, 9, 2));
      final high = buildReminder(
        id: 'high',
        priority: 3,
        createdAt: DateTime(2026, 9, 1),
      );
      final pinned = buildReminder(
        id: 'pinned',
        pinned: true,
        createdAt: DateTime(2026, 8, 1),
      );
      final ids = _items(_build(reminders: [plain, high, pinned]))
          .map((i) => i['id'])
          .toList();
      expect(ids, ['pinned', 'high', 'plain']);
    });

    test('category colour key, subtask progress and recurring flag', () {
      final market = buildReminder(
        id: 'market',
        categoryId: ReminderCategoryIds.market,
        remindAt: DateTime(2026, 9, 13, 16),
        recurrence: RecurrenceRule.weekly([DateTime.sunday]),
        subtasks: buildSubtasks(['Süt', 'Ekmek', 'Yumurta'], done: {0}),
      );
      final work = buildReminder(id: 'work', categoryId: 'work');
      final unknown = buildReminder(id: 'unknown', categoryId: 'custom-x');
      // A rule without a time is not recurring (Reminder.isRecurring).
      final ruleOnly = buildReminder(
        id: 'ruleOnly',
        recurrence: RecurrenceRule.daily(),
      );

      final byId = {
        for (final i in _items(
          _build(reminders: [market, work, unknown, ruleOnly]),
        ))
          i['id']: i,
      };

      expect(byId['market']!['category'], 'market');
      expect(byId['market']!['subtasks'], '1/3');
      expect(byId['market']!['recurring'], isTrue);
      expect(byId['work']!['category'], 'is');
      expect(byId['work']!['subtasks'], isNull);
      expect(byId['work']!['recurring'], isFalse);
      expect(byId['unknown']!['category'], 'diger');
      expect(byId['ruleOnly']!['recurring'], isFalse);
    });

    test('user categories resolve their colour key via the catalog (F4.3)', () {
      final gym = buildReminder(id: 'gym', categoryId: 'gym');
      Map<Object?, Map<String, Object?>> byId(CategoryCatalog? categories) => {
            for (final i in _items(WidgetPayload.build(
              l10n: AppL10n.turkish,
              reminders: [gym],
              birthdays: const [],
              notificationsEnabled: true,
              now: _now,
              categories: categories,
            )))
              i['id']: i,
          };

      expect(
        byId(CategoryCatalog([buildCategory(id: 'gym', colorKey: 'kiremit')]))[
            'gym']!['category'],
        'kiremit',
      );
      // Without a catalog (or after deletion) the item falls back to Diğer.
      expect(byId(null)['gym']!['category'], 'diger');
    });

    test('counts: today = today + untimed, overdue, open = all active', () {
      final counts = _counts(
        _build(reminders: [overdue, at16, at18, untimed, tomorrow, done]),
      );
      expect(counts, {'today': 3, 'overdue': 1, 'open': 5});
    });

    test('at most maxItems items; counts still cover every item', () {
      final many = [
        for (var i = 0; i < WidgetPayload.maxItems + 10; i++)
          buildReminder(id: 'r$i', remindAt: DateTime(2026, 9, 20, 9, i % 60)),
      ];
      final payload = _build(reminders: many);
      expect(_items(payload), hasLength(WidgetPayload.maxItems));
      expect(_counts(payload)['open'], WidgetPayload.maxItems + 10);
    });

    group('next', () {
      test('the first timed item of today; more = rest of today', () {
        final next = _next(
          _build(reminders: [overdue, at18, at16, untimed, tomorrow]),
        )!;
        expect(next['id'], 'at16');
        expect(next['title'], "Ali'yi kurstan al");
        expect(next['clock'], '16:00');
        expect(next['day'], 'Bugün');
        expect(next['overdue'], isFalse);
        expect(next['dueAt'], at16.remindAt!.millisecondsSinceEpoch);
        // overdue + at18 + untimed; the next item itself is not counted.
        expect(next['more'], 3);
      });

      test('falls back to a later day; more counts all of today', () {
        final next = _next(_build(reminders: [tomorrow, untimed]))!;
        expect(next['id'], 'tomorrow');
        expect(next['day'], 'Yarın');
        expect(next['clock'], '10:00');
        expect(next['more'], 1);
      });

      test('then the oldest overdue item', () {
        final older = buildReminder(
          id: 'older',
          remindAt: DateTime(2026, 9, 12, 9),
        );
        final next = _next(_build(reminders: [overdue, older]))!;
        expect(next['id'], 'older');
        expect(next['overdue'], isTrue);
        expect(next['day'], 'Gecikti');
        expect(next['more'], 1);
      });

      test('then the first untimed item without clock', () {
        final next = _next(_build(reminders: [untimed]))!;
        expect(next['id'], 'untimed');
        expect(next['clock'], isNull);
        expect(next['day'], isNull);
        expect(next['dueAt'], isNull);
        expect(next['more'], 0);
      });
    });

    test('birthdays today and tomorrow, nearest first, with age', () {
      final today = buildBirthday(
        id: 'today',
        name: 'Zeynep',
        date: DateTime(1990, 9, 13),
      );
      final tomorrowA = buildBirthday(
        id: 'tomorrowA',
        name: 'Ayşe',
        date: DateTime(Birthday.unknownYear, 9, 14),
      );
      final tomorrowB = buildBirthday(
        id: 'tomorrowB',
        name: 'Burak',
        date: DateTime(1985, 9, 14),
      );
      final later = buildBirthday(id: 'later', date: DateTime(1990, 9, 15));
      final past = buildBirthday(id: 'past', date: DateTime(1990, 9, 12));

      final birthdays = (_build(
        birthdays: [later, tomorrowB, past, tomorrowA, today],
      )['birthdays']! as List)
          .cast<Map<String, Object?>>();

      expect(
          birthdays.map((b) => b['id']), ['today', 'tomorrowA', 'tomorrowB']);
      expect(birthdays[0], {
        'id': 'today',
        'name': 'Zeynep',
        'label': 'Bugün',
        'date': DateTime(2026, 9, 13).millisecondsSinceEpoch,
        'age': 36,
      });
      expect(birthdays[1]['label'], 'Yarın');
      expect(birthdays[1]['age'], isNull, reason: 'year unknown');
      expect(
          birthdays[1]['date'], DateTime(2026, 9, 14).millisecondsSinceEpoch);
      expect(birthdays[2]['age'], 41);
    });

    test('empty state: no items, no next, zero counts', () {
      final payload = _build(reminders: [done]);
      expect(_items(payload), isEmpty);
      expect(_next(payload), isNull);
      expect(_counts(payload), {'today': 0, 'overdue': 0, 'open': 0});
      expect(payload['birthdays'], isEmpty);
      expect(payload['notificationsEnabled'], isTrue);
    });

    test('notifications flag is passed through', () {
      expect(
        _build(notificationsEnabled: false)['notificationsEnabled'],
        isFalse,
      );
    });

    test('round-trips through JSON (what Kotlin reads)', () {
      final payload = _build(
        reminders: [overdue, at16, untimed, tomorrow],
        birthdays: [buildBirthday(date: DateTime(1990, 9, 13))],
      );
      final decoded = jsonDecode(jsonEncode(payload)) as Map<String, Object?>;
      expect(decoded, payload);
    });
  });

  group('labels', () {
    test('clock is zero padded 24h', () {
      expect(WidgetPayload.clock(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(WidgetPayload.clock(DateTime(2026, 1, 1, 23, 59)), '23:59');
    });

    test('dayLabel crosses month and year ends', () {
      expect(
        WidgetPayload.dayLabel(
            DateTime(2027, 1, 1, 8), DateTime(2026, 12, 31), AppL10n.turkish),
        'Yarın',
      );
      expect(
        WidgetPayload.dayLabel(
            DateTime(2026, 2, 3), DateTime(2026, 1, 1), AppL10n.turkish),
        '3 Şub',
      );
    });

    test('subtaskProgress', () {
      expect(WidgetPayload.subtaskProgress(const []), isNull);
      expect(
        WidgetPayload.subtaskProgress(
          buildSubtasks(['a', 'b', 'c', 'd', 'e', 'f'], done: {0, 1}),
        ),
        '2/6',
      );
    });
  });
}
