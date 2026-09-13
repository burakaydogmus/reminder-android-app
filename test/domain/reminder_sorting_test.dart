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
}
