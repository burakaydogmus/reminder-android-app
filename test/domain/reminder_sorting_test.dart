import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';

import '../helpers/factories.dart';

List<String> _sortedIds(List<Reminder> reminders) =>
    ([...reminders]..sort(compareReminders)).map((r) => r.id).toList();

void main() {
  group('compareReminders', () {
    test('active reminders come before done ones', () {
      expect(
        _sortedIds([
          buildReminder(id: 'done', isDone: true, remindAt: DateTime(2020)),
          buildReminder(id: 'active', remindAt: DateTime(2030)),
        ]),
        ['active', 'done'],
      );
    });

    test('timed reminders are ordered by remindAt ascending', () {
      expect(
        _sortedIds([
          buildReminder(id: 'late', remindAt: DateTime(2026, 9, 1)),
          buildReminder(id: 'early', remindAt: DateTime(2026, 1, 1)),
        ]),
        ['early', 'late'],
      );
    });

    test('timed reminders come before untimed ones', () {
      expect(
        _sortedIds([
          buildReminder(id: 'untimed', createdAt: DateTime(2030)),
          buildReminder(id: 'timed', remindAt: DateTime(2020)),
        ]),
        ['timed', 'untimed'],
      );
    });

    test('untimed reminders are ordered by createdAt descending', () {
      expect(
        _sortedIds([
          buildReminder(id: 'old', createdAt: DateTime(2025)),
          buildReminder(id: 'new', createdAt: DateTime(2026)),
        ]),
        ['new', 'old'],
      );
    });

    test('done reminders use the same ordering among themselves', () {
      expect(
        _sortedIds([
          buildReminder(id: 'd-untimed', isDone: true),
          buildReminder(
              id: 'd-late', isDone: true, remindAt: DateTime(2026, 5)),
          buildReminder(
              id: 'd-early', isDone: true, remindAt: DateTime(2026, 1)),
        ]),
        ['d-early', 'd-late', 'd-untimed'],
      );
    });

    test('full mix', () {
      expect(
        _sortedIds([
          buildReminder(id: 'done', isDone: true, remindAt: DateTime(2020)),
          buildReminder(id: 'untimed-old', createdAt: DateTime(2025)),
          buildReminder(id: 'timed-late', remindAt: DateTime(2026, 9)),
          buildReminder(id: 'untimed-new', createdAt: DateTime(2026)),
          buildReminder(id: 'timed-early', remindAt: DateTime(2026, 1)),
        ]),
        ['timed-early', 'timed-late', 'untimed-new', 'untimed-old', 'done'],
      );
    });
  });

  group('compareReminders with pinned and priority (F3.4, §3.3.2)', () {
    test('pinned reminders come first, timed or untimed', () {
      expect(
        _sortedIds([
          buildReminder(id: 'timed', remindAt: DateTime(2026, 1, 1)),
          buildReminder(id: 'pinned-untimed', pinned: true),
          buildReminder(id: 'untimed', createdAt: DateTime(2030)),
          buildReminder(
            id: 'pinned-late',
            pinned: true,
            remindAt: DateTime(2026, 9, 1),
          ),
        ]),
        ['pinned-late', 'pinned-untimed', 'timed', 'untimed'],
      );
    });

    test('pinned reminders are ordered among themselves by the same rules', () {
      expect(
        _sortedIds([
          buildReminder(id: 'p-untimed-low', pinned: true, priority: 1),
          buildReminder(
            id: 'p-late',
            pinned: true,
            remindAt: DateTime(2026, 9, 2),
          ),
          buildReminder(id: 'p-untimed-high', pinned: true, priority: 3),
          buildReminder(
            id: 'p-early',
            pinned: true,
            remindAt: DateTime(2026, 9, 1),
          ),
        ]),
        ['p-early', 'p-late', 'p-untimed-high', 'p-untimed-low'],
      );
    });

    test('timed: time wins over priority', () {
      expect(
        _sortedIds([
          buildReminder(
              id: 'late-high', priority: 3, remindAt: DateTime(2026, 9, 2)),
          buildReminder(id: 'early-none', remindAt: DateTime(2026, 9, 1)),
        ]),
        ['early-none', 'late-high'],
      );
    });

    test('timed: same time → higher priority first', () {
      final at = DateTime(2026, 9, 13, 18, 30);
      expect(
        _sortedIds([
          buildReminder(id: 'none', remindAt: at),
          buildReminder(id: 'medium', priority: 2, remindAt: at),
          buildReminder(id: 'high', priority: 3, remindAt: at),
          buildReminder(id: 'low', priority: 1, remindAt: at),
        ]),
        ['high', 'medium', 'low', 'none'],
      );
    });

    test('untimed: priority first, then newest first', () {
      expect(
        _sortedIds([
          buildReminder(id: 'new-none', createdAt: DateTime(2026, 9)),
          buildReminder(id: 'old-high', priority: 3, createdAt: DateTime(2025)),
          buildReminder(
              id: 'new-high', priority: 3, createdAt: DateTime(2026, 5)),
          buildReminder(id: 'old-low', priority: 1, createdAt: DateTime(2024)),
        ]),
        ['new-high', 'old-high', 'old-low', 'new-none'],
      );
    });

    test('done items stay last even when pinned or high priority', () {
      expect(
        _sortedIds([
          buildReminder(
            id: 'done-pinned-high',
            isDone: true,
            pinned: true,
            priority: 3,
          ),
          buildReminder(id: 'open', createdAt: DateTime(2020)),
          buildReminder(id: 'done', isDone: true),
        ]),
        ['open', 'done-pinned-high', 'done'],
      );
    });

    test('full matrix', () {
      final at = DateTime(2026, 9, 13, 9);
      expect(
        _sortedIds([
          buildReminder(id: 'done', isDone: true, pinned: true),
          buildReminder(id: 'u-none', createdAt: DateTime(2026, 9)),
          buildReminder(id: 'u-high', priority: 3, createdAt: DateTime(2025)),
          buildReminder(id: 't-10', remindAt: at.add(const Duration(hours: 1))),
          buildReminder(id: 't-9-low', priority: 1, remindAt: at),
          buildReminder(id: 't-9-high', priority: 3, remindAt: at),
          buildReminder(id: 'p-untimed', pinned: true),
          buildReminder(
            id: 'p-11',
            pinned: true,
            remindAt: at.add(const Duration(hours: 2)),
          ),
        ]),
        [
          'p-11',
          'p-untimed',
          't-9-high',
          't-9-low',
          't-10',
          'u-high',
          'u-none',
          'done',
        ],
      );
    });

    test('is a consistent ordering (antisymmetric, reflexive zero)', () {
      final items = [
        buildReminder(id: 'a', pinned: true, priority: 2),
        buildReminder(id: 'b', priority: 3, remindAt: DateTime(2026, 9, 1)),
        buildReminder(id: 'c', isDone: true, priority: 1),
        buildReminder(id: 'd', createdAt: DateTime(2027)),
      ];
      for (final x in items) {
        expect(compareReminders(x, x), 0);
        for (final y in items) {
          expect(
            compareReminders(x, y).sign,
            -compareReminders(y, x).sign,
            reason: '${x.id} vs ${y.id}',
          );
        }
      }
    });
  });
}
