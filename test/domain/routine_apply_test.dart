import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/domain/routine_apply.dart';

import '../helpers/factories.dart';

/// 26 September 2026 is a Saturday.
final _now = DateTime(2026, 9, 26, 6, 30);
final _today = DateTime(2026, 9, 26);
final _tomorrow = DateTime(2026, 9, 27);

/// Deterministic ids so the expectations can name them.
String Function() _ids(String prefix) {
  var i = 0;
  return () => '$prefix${++i}';
}

Routine _morning({
  RecurrenceRule repeat = RecurrenceRule.none,
  List<RoutineItem>? items,
}) =>
    buildRoutine(
      repeat: repeat,
      items: items ??
          [
            buildRoutineStep(
              id: 'sport',
              title: 'Spor',
              time: '07:00',
              categoryId: ReminderCategoryIds.health,
              priority: ReminderPriority.medium,
            ),
            buildRoutineStep(
              id: 'vitamin',
              title: 'Vitamin',
              time: '07:30',
              categoryId: ReminderCategoryIds.health,
              subtasks: buildSubtasks(['D vitamini', 'Omega 3']),
            ),
            buildRoutineStep(id: 'water', title: 'Su iç'),
          ],
    );

RoutineApplyOutcome _apply(
  RoutineApplyPlan plan, {
  RoutineApplyMode mode = RoutineApplyMode.onlyNew,
}) =>
    plan.build(
      now: _now,
      newId: _ids('r'),
      newSubtaskId: _ids('s'),
      mode: mode,
    );

void main() {
  group('a fresh apply', () {
    test('creates one reminder per step with its time, category, priority', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: const [],
      );
      expect(plan.entries.map((e) => e.state), [
        RoutineItemState.create,
        RoutineItemState.create,
        RoutineItemState.create,
      ]);
      expect(plan.hasDuplicates, isFalse);

      final created = _apply(plan).created;
      expect(created.map((r) => r.title), ['Spor', 'Vitamin', 'Su iç']);
      expect(created.map((r) => r.remindAt), [
        DateTime(2026, 9, 26, 7, 0),
        DateTime(2026, 9, 26, 7, 30),
        // A step without a time becomes a timeless reminder, exactly like the
        // editor with "Zamanla ve bildir" off — no invented default hour.
        null,
      ]);
      expect(created.map((r) => r.categoryId), [
        ReminderCategoryIds.health,
        ReminderCategoryIds.health,
        ReminderCategoryIds.other,
      ]);
      expect(created.map((r) => r.priority), [
        ReminderPriority.medium,
        ReminderPriority.none,
        ReminderPriority.none,
      ]);
      expect(created.every((r) => !r.isDone), isTrue);
      expect(created.every((r) => r.createdAt == _now), isTrue);
      expect(created.every((r) => r.recurrence == RecurrenceRule.none), isTrue);
      expect(created.every((r) => !r.locationTriggerEnabled), isTrue);
    });

    test('copies the step subtasks as fresh, open items', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: const [],
      );
      final vitamin = _apply(plan).created[1];
      expect(vitamin.subtasks.map((s) => s.title), ['D vitamini', 'Omega 3']);
      expect(vitamin.subtasks.map((s) => s.position), [0, 1]);
      expect(vitamin.subtasks.every((s) => !s.isDone), isTrue);
      // New ids, not the template's.
      expect(vitamin.subtasks.map((s) => s.id), ['s1', 's2']);
    });

    test('links every created reminder back to the routine and the step', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: const [],
      );
      final created = _apply(plan).created;
      expect(created.every((r) => r.routineId == 'morning'), isTrue);
      expect(
        created.map((r) => r.routineItemId),
        ['sport', 'vitamin', 'water'],
      );
      expect(created.every((r) => r.isFromRoutine), isTrue);
    });

    test('applies the chosen day to timed steps only', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _tomorrow,
        existing: const [],
      );
      expect(plan.date, _tomorrow);
      final created = _apply(plan).created;
      expect(created[0].remindAt, DateTime(2026, 9, 27, 7, 0));
      expect(created[2].remindAt, isNull);
    });

    test('an empty routine plans and creates nothing', () {
      final plan = RoutineApplyPlan.from(
        routine: buildRoutine(),
        date: _today,
        existing: const [],
      );
      expect(plan.isEmpty, isTrue);
      expect(_apply(plan).isEmpty, isTrue);
      expect(_apply(plan).total, 0);
    });
  });

  group('automatic application through the recurrence engine', () {
    test('a daily routine creates reminders carrying that rule', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(repeat: RecurrenceRule.daily()),
        date: _today,
        existing: const [],
      );
      final created = _apply(plan).created;
      expect(created[0].recurrence, RecurrenceRule.daily());
      expect(created[0].remindAt, DateTime(2026, 9, 26, 7, 0));
      expect(created[0].isRecurring, isTrue);
      // A timeless step cannot repeat: without a time there is no notification.
      expect(created[2].recurrence, RecurrenceRule.none);
      expect(created[2].isRecurring, isFalse);
    });

    test('a weekday rule moves the first occurrence to a chosen day', () {
      final rule = RecurrenceRule.weekly(const [
        DateTime.monday,
        DateTime.wednesday,
      ]);
      final plan = RoutineApplyPlan.from(
        routine: _morning(repeat: rule),
        // Saturday is not in the rule, so the series starts on Monday.
        date: _today,
        existing: const [],
      );
      final created = _apply(plan).created;
      expect(created[0].recurrence, rule);
      expect(created[0].remindAt, DateTime(2026, 9, 28, 7, 0));
      expect(created[0].remindAt!.weekday, DateTime.monday);
    });

    test('a weekday rule that contains the chosen day starts on it', () {
      final rule = RecurrenceRule.weekly(const [DateTime.saturday]);
      final created = _apply(RoutineApplyPlan.from(
        routine: _morning(repeat: rule),
        date: _today,
        existing: const [],
      )).created;
      expect(created[0].remindAt, DateTime(2026, 9, 26, 7, 0));
    });

    test('completing a created series advances it (shared rule)', () {
      final created = _apply(RoutineApplyPlan.from(
        routine: _morning(repeat: RecurrenceRule.daily()),
        date: _today,
        existing: const [],
      )).created;
      final advanced =
          completeReminder(created[0], DateTime(2026, 9, 26, 7, 5));
      expect(advanced.isDone, isFalse);
      expect(advanced.remindAt, DateTime(2026, 9, 27, 7, 0));
      // The link survives the advance, so the guard still finds the series.
      expect(advanced.routineId, 'morning');
      expect(advanced.routineItemId, 'sport');
    });
  });

  group('duplicate guard', () {
    test('a linked reminder for the same day is a duplicate', () {
      final existing = [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 26, 7, 0),
          categoryId: ReminderCategoryIds.health,
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ];
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: existing,
      );
      expect(plan.entries.first.state, RoutineItemState.linked);
      expect(plan.entries.first.existing!.id, 'old');
      expect(plan.hasDuplicates, isTrue);
      expect(plan.hasLinked, isTrue);
      expect(plan.duplicates.length, 1);
      expect(plan.newEntries.length, 2);
    });

    test('a one-off routine applied on another day is not a duplicate', () {
      final existing = [
        buildReminder(
          id: 'old',
          title: 'Spor',
          remindAt: DateTime(2026, 9, 25, 7, 0),
          categoryId: ReminderCategoryIds.health,
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ];
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: existing,
      );
      expect(plan.hasDuplicates, isFalse);
    });

    test('a repeating routine sees its series whatever day it sits on', () {
      final existing = [
        buildReminder(
          id: 'series',
          title: 'Spor',
          remindAt: DateTime(2026, 10, 3, 7, 0),
          categoryId: ReminderCategoryIds.health,
          recurrence: RecurrenceRule.daily(),
          routineId: 'morning',
          routineItemId: 'sport',
        ),
      ];
      final plan = RoutineApplyPlan.from(
        routine: _morning(repeat: RecurrenceRule.daily()),
        date: _today,
        existing: existing,
      );
      expect(plan.entries.first.state, RoutineItemState.linked);
      expect(plan.hasLinked, isTrue);
    });

    test('a timeless step matches by its creation day', () {
      final existing = [
        buildReminder(
          id: 'old',
          title: 'Su iç',
          createdAt: DateTime(2026, 9, 26, 6, 45),
          routineId: 'morning',
          routineItemId: 'water',
        ),
      ];
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: existing,
      );
      expect(plan.entries.last.state, RoutineItemState.linked);

      final yesterday = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: [
          buildReminder(
            id: 'old',
            title: 'Su iç',
            createdAt: DateTime(2026, 9, 25, 6, 45),
            routineId: 'morning',
            routineItemId: 'water',
          ),
        ],
      );
      expect(yesterday.entries.last.state, RoutineItemState.create);
    });

    test('a completed reminder still counts as a duplicate', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: [
          buildReminder(
            id: 'old',
            title: 'Spor',
            isDone: true,
            remindAt: DateTime(2026, 9, 26, 7, 0),
            categoryId: ReminderCategoryIds.health,
            routineId: 'morning',
            routineItemId: 'sport',
          ),
        ],
      );
      expect(plan.entries.first.state, RoutineItemState.linked);
    });

    test('an unlinked reminder with the same title and day counts as similar',
        () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: [
          // Typed by hand (or created before F3.7): folded title match.
          buildReminder(
            id: 'manual',
            title: 'spor',
            remindAt: DateTime(2026, 9, 26, 19, 0),
            categoryId: ReminderCategoryIds.health,
          ),
        ],
      );
      expect(plan.entries.first.state, RoutineItemState.similar);
      expect(plan.entries.first.isLinked, isFalse);
      expect(plan.hasLinked, isFalse);
      expect(plan.hasDuplicates, isTrue);
    });

    test('another category or another routine is not a duplicate', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: [
          buildReminder(
            id: 'other-category',
            title: 'Spor',
            remindAt: DateTime(2026, 9, 26, 7, 0),
            categoryId: ReminderCategoryIds.work,
          ),
          buildReminder(
            id: 'other-routine',
            title: 'Vitamin',
            remindAt: DateTime(2026, 9, 26, 7, 30),
            categoryId: ReminderCategoryIds.health,
            routineId: 'evening',
            routineItemId: 'vitamin',
          ),
        ],
      );
      // "Vitamin" still matches by title (same category and day), "Spor" does
      // not, because the category differs.
      expect(plan.entries.map((e) => e.state), [
        RoutineItemState.create,
        RoutineItemState.similar,
        RoutineItemState.create,
      ]);
    });

    test('one reminder is consumed by one step only', () {
      final routine = _morning(items: [
        buildRoutineStep(id: 'a', title: 'Su iç'),
        buildRoutineStep(id: 'b', title: 'Su iç'),
      ]);
      final plan = RoutineApplyPlan.from(
        routine: routine,
        date: _today,
        existing: [
          buildReminder(id: 'old', title: 'Su iç', createdAt: _now),
        ],
      );
      expect(plan.entries.map((e) => e.state), [
        RoutineItemState.similar,
        RoutineItemState.create,
      ]);
    });
  });

  group('apply modes', () {
    RoutineApplyPlan planWithSeries({
      RecurrenceRule repeat = RecurrenceRule.none,
      DateTime? date,
    }) =>
        RoutineApplyPlan.from(
          routine: _morning(repeat: repeat),
          date: date ?? _today,
          existing: [
            buildReminder(
              id: 'old',
              title: 'Spor',
              note: 'kendi notum',
              pinned: true,
              remindAt: DateTime(2026, 9, 26, 7, 0),
              categoryId: ReminderCategoryIds.health,
              recurrence: repeat,
              routineId: 'morning',
              routineItemId: 'sport',
            ),
          ],
        );

    test('onlyNew skips duplicates and counts them', () {
      final outcome = _apply(planWithSeries());
      expect(outcome.created.map((r) => r.title), ['Vitamin', 'Su iç']);
      expect(outcome.updated, isEmpty);
      expect(outcome.skipped, 1);
      expect(outcome.total, 2);
    });

    test('addAll creates a second reminder for the duplicate too', () {
      final outcome = _apply(planWithSeries(), mode: RoutineApplyMode.addAll);
      expect(outcome.created.map((r) => r.title), ['Spor', 'Vitamin', 'Su iç']);
      expect(outcome.skipped, 0);
      expect(outcome.updated, isEmpty);
      // The new one is a different reminder, so the old one is untouched.
      expect(outcome.created.first.id, isNot('old'));
    });

    test('replaceExisting moves the linked reminder instead of duplicating',
        () {
      final outcome = _apply(
        planWithSeries(repeat: RecurrenceRule.daily(), date: _tomorrow),
        mode: RoutineApplyMode.replaceExisting,
      );
      expect(outcome.created.map((r) => r.title), ['Vitamin', 'Su iç']);
      final updated = outcome.updated.single;
      expect(updated.id, 'old');
      expect(updated.remindAt, DateTime(2026, 9, 27, 7, 0));
      expect(updated.recurrence, RecurrenceRule.daily());
      expect(updated.priority, ReminderPriority.medium);
      expect(updated.isDone, isFalse);
      // The user's own fields survive an update.
      expect(updated.note, 'kendi notum');
      expect(updated.pinned, isTrue);
      expect(updated.routineId, 'morning');
      expect(updated.routineItemId, 'sport');
      expect(outcome.skipped, 0);
    });

    test('replaceExisting leaves an unlinked "similar" match alone', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(),
        date: _today,
        existing: [
          buildReminder(
            id: 'manual',
            title: 'Spor',
            remindAt: DateTime(2026, 9, 26, 19, 0),
            categoryId: ReminderCategoryIds.health,
          ),
        ],
      );
      final outcome = _apply(plan, mode: RoutineApplyMode.replaceExisting);
      expect(outcome.updated, isEmpty);
      expect(outcome.skipped, 1);
      expect(outcome.created.map((r) => r.title), ['Vitamin', 'Su iç']);
    });

    test('nothing to do reports an empty outcome', () {
      final plan = RoutineApplyPlan.from(
        routine: _morning(items: [
          buildRoutineStep(id: 'water', title: 'Su iç'),
        ]),
        date: _today,
        existing: [
          buildReminder(
            id: 'old',
            title: 'Su iç',
            createdAt: _now,
            routineId: 'morning',
            routineItemId: 'water',
          ),
        ],
      );
      final outcome = _apply(plan);
      expect(outcome.isEmpty, isTrue);
      expect(outcome.skipped, 1);
    });
  });
}
