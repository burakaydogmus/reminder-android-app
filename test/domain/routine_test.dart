import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/routine.dart';
import 'package:reminder/domain/model/subtask.dart';

import '../helpers/factories.dart';

void main() {
  group('RoutineTime', () {
    test('formats and parses HH:MM', () {
      expect(const RoutineTime(7, 5).storage, '07:05');
      expect(const RoutineTime(23, 59).storage, '23:59');
      expect(RoutineTime.tryParse('07:05'), const RoutineTime(7, 5));
      expect(RoutineTime.tryParse('7:05'), const RoutineTime(7, 5));
      expect(RoutineTime.tryParse(' 07:05 '), const RoutineTime(7, 5));
    });

    test('rejects broken or out-of-range values', () {
      expect(RoutineTime.tryParse(null), isNull);
      expect(RoutineTime.tryParse(700), isNull);
      expect(RoutineTime.tryParse('7'), isNull);
      expect(RoutineTime.tryParse('07:5'), isNull);
      expect(RoutineTime.tryParse('24:00'), isNull);
      expect(RoutineTime.tryParse('07:60'), isNull);
      expect(RoutineTime.tryParse('sabah'), isNull);
    });

    test('onDate builds a local wall-clock time on that day', () {
      final at = const RoutineTime(7, 30).onDate(DateTime(2026, 9, 26, 22));
      expect(at, DateTime(2026, 9, 26, 7, 30));
      expect(at.isUtc, isFalse);
    });

    test('compares and sorts by minutes of day', () {
      final times = [
        const RoutineTime(9, 0),
        const RoutineTime(7, 30),
        const RoutineTime(7, 5),
      ]..sort();
      expect(times.map((t) => t.storage), ['07:05', '07:30', '09:00']);
      expect(const RoutineTime(7, 30).minutesOfDay, 450);
    });
  });

  group('RoutineItem', () {
    test('keeps template subtasks open, ordered and renumbered', () {
      final item = buildRoutineStep(
        subtasks: [
          const Subtask(id: 'b', title: 'İkinci', isDone: true, position: 5),
          const Subtask(id: 'a', title: 'Birinci', position: 1),
        ],
      );
      expect(item.subtasks.map((s) => s.id), ['a', 'b']);
      expect(item.subtasks.map((s) => s.position), [0, 1]);
      expect(item.subtasks.every((s) => !s.isDone), isTrue);
      expect(item.hasSubtasks, isTrue);
    });

    test('normalizes the priority and reports hasPriority', () {
      expect(buildRoutineStep(priority: 9).priority, ReminderPriority.high);
      expect(buildRoutineStep(priority: -1).priority, ReminderPriority.none);
      expect(buildRoutineStep(priority: 2).hasPriority, isTrue);
      expect(buildRoutineStep().hasPriority, isFalse);
    });

    test('normalizeTitle trims, collapses spaces and clamps the length', () {
      expect(RoutineItem.normalizeTitle('  Spor   salonu '), 'Spor salonu');
      expect(
        RoutineItem.normalizeTitle('a' * (RoutineItem.maxTitleLength + 10)),
        'a' * RoutineItem.maxTitleLength,
      );
    });

    test('round-trips through JSON', () {
      final item = buildRoutineStep(
        id: 'i7',
        title: 'Vitamin',
        time: '07:30',
        categoryId: ReminderCategoryIds.health,
        priority: 2,
        subtasks: buildSubtasks(['D vitamini', 'Omega 3']),
        position: 3,
      );
      final again = RoutineItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );
      expect(again, item);
      expect(again.time, const RoutineTime(7, 30));
      expect(again.subtasks.map((s) => s.title), ['D vitamini', 'Omega 3']);
    });

    test('a timeless step keeps a null time in JSON', () {
      final item = buildRoutineStep(time: null);
      expect(item.toJson()['time'], isNull);
      expect(RoutineItem.fromJson(item.toJson()).time, isNull);
    });

    test('fromJson needs a string id and title', () {
      expect(
        () => RoutineItem.fromJson(const {'title': 'Spor'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RoutineItem.fromJson(const {'id': 'i1', 'title': 7}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson tolerates a broken time, priority and subtasks', () {
      final item = RoutineItem.fromJson(const {
        'id': 'i1',
        'title': 'Spor',
        'time': '25:00',
        'priority': 'high',
        'subtasks': [
          {'id': 's1', 'title': 'Havlu'},
          {'title': 'kimliksiz'},
          'metin',
        ],
      });
      expect(item.time, isNull);
      expect(item.priority, ReminderPriority.none);
      expect(item.subtasks.map((s) => s.id), ['s1']);
      expect(item.categoryId, ReminderCategoryIds.other);
    });

    test('listFromJson skips unreadable items and renumbers the rest', () {
      final items = RoutineItem.listFromJson([
        {'id': 'b', 'title': 'İkinci', 'position': 4},
        {'title': 'kimliksiz'},
        {'id': 'a', 'title': 'Birinci', 'position': 1},
        42,
      ]);
      expect(items.map((i) => i.id), ['a', 'b']);
      expect(items.map((i) => i.position), [0, 1]);
      expect(RoutineItem.listFromJson(null), isEmpty);
    });

    test('copyWith replaces fields and can clear the time', () {
      final item = buildRoutineStep(time: '07:00');
      expect(item.copyWith(title: 'Yeni').title, 'Yeni');
      expect(item.copyWith(title: 'Yeni').time, const RoutineTime(7, 0));
      expect(item.copyWith(time: () => null).time, isNull);
      expect(
        item.copyWith(time: () => const RoutineTime(8, 15)).time,
        const RoutineTime(8, 15),
      );
    });

    test('value equality covers every field', () {
      final a = buildRoutineStep(time: '07:00', subtasks: buildSubtasks(['x']));
      final b = buildRoutineStep(time: '07:00', subtasks: buildSubtasks(['x']));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(title: 'Başka'), isFalse);
      expect(a == a.copyWith(subtasks: buildSubtasks(['y'])), isFalse);
      expect(a == a.copyWith(position: 3), isFalse);
    });
  });

  group('RoutineItemList', () {
    final steps = [
      buildRoutineStep(id: 'a', title: 'Spor'),
      buildRoutineStep(id: 'b', title: 'Vitamin'),
      buildRoutineStep(id: 'c', title: 'Su'),
    ];

    test('normalized sorts by position and renumbers', () {
      final items = RoutineItemList.normalized([
        buildRoutineStep(id: 'c', position: 9),
        buildRoutineStep(id: 'a', position: 2),
        buildRoutineStep(id: 'b', position: 2),
      ]);
      expect(items.map((i) => i.id), ['a', 'b', 'c']);
      expect(items.map((i) => i.position), [0, 1, 2]);
    });

    test('added, updated, replaced and removed keep 0..n-1 positions', () {
      final list = RoutineItemList.inOrder(steps);
      final added = list.added(buildRoutineStep(id: 'd', title: 'Kahve'));
      expect(added.map((i) => i.id), ['a', 'b', 'c', 'd']);
      expect(added.last.position, 3);

      final atFront =
          list.added(buildRoutineStep(id: 'd', title: 'Kahve'), index: 0);
      expect(atFront.map((i) => i.id), ['d', 'a', 'b', 'c']);
      expect(atFront.map((i) => i.position), [0, 1, 2, 3]);

      final updated = list.updated(
        buildRoutineStep(id: 'b', title: 'Vitaminler'),
      );
      expect(updated[1].title, 'Vitaminler');
      expect(updated[1].position, 1);

      // replaced appends an unknown id instead of dropping it.
      expect(
        list
            .replaced(buildRoutineStep(id: 'z', title: 'Yeni'))
            .map((i) => i.id),
        ['a', 'b', 'c', 'z'],
      );

      expect(list.removed('b').map((i) => i.id), ['a', 'c']);
      expect(list.removed('b').map((i) => i.position), [0, 1]);
      expect(list.removed('yok').map((i) => i.id), ['a', 'b', 'c']);
    });

    test('reordered and moved follow onReorderItem semantics', () {
      final list = RoutineItemList.inOrder(steps);
      expect(list.reordered(0, 2).map((i) => i.id), ['b', 'c', 'a']);
      expect(list.reordered(2, 0).map((i) => i.id), ['c', 'a', 'b']);
      expect(list.reordered(9, 0).map((i) => i.id), ['a', 'b', 'c']);
      expect(list.moved('c', -1).map((i) => i.id), ['a', 'c', 'b']);
      expect(list.moved('a', 1).map((i) => i.id), ['b', 'a', 'c']);
      // Clamped at the edges, never thrown.
      expect(list.moved('a', -1).map((i) => i.id), ['a', 'b', 'c']);
      expect(list.moved('yok', 1).map((i) => i.id), ['a', 'b', 'c']);
    });

    test('every helper returns an unmodifiable list', () {
      final list = RoutineItemList.inOrder(steps);
      expect(() => list.add(buildRoutineStep(id: 'x')), throwsUnsupportedError);
    });
  });

  group('Routine', () {
    test('normalizes item order and reports counts', () {
      final routine = buildRoutine(items: [
        buildRoutineStep(id: 'b', title: 'Vitamin', position: 7),
        buildRoutineStep(id: 'a', title: 'Spor', position: 1),
      ]);
      expect(routine.items.map((i) => i.id), ['a', 'b']);
      expect(routine.itemCount, 2);
      expect(routine.isEmpty, isFalse);
      expect(buildRoutine().isEmpty, isTrue);
    });

    test('repeats only with a rule', () {
      expect(buildRoutine().repeats, isFalse);
      expect(buildRoutine(repeat: RecurrenceRule.daily()).repeats, isTrue);
    });

    test('normalizeName trims, collapses spaces and clamps the length', () {
      expect(Routine.normalizeName('  Sabah   rutini '), 'Sabah rutini');
      expect(
        Routine.normalizeName('a' * (Routine.maxNameLength + 5)),
        'a' * Routine.maxNameLength,
      );
    });

    test('round-trips through JSON, repeat rule included', () {
      final routine = buildRoutine(
        repeat: RecurrenceRule.weekly(const [
          DateTime.monday,
          DateTime.wednesday,
        ]),
        items: [
          buildRoutineStep(id: 'a', title: 'Spor', time: '07:00'),
          buildRoutineStep(id: 'b', title: 'Su'),
        ],
      );
      final again = Routine.fromJson(
        jsonDecode(jsonEncode(routine.toJson())) as Map<String, dynamic>,
      );
      expect(again, routine);
      expect(
        again.repeat,
        RecurrenceRule.weekly(const [DateTime.monday, DateTime.wednesday]),
      );
      expect(again.items.map((i) => i.title), ['Spor', 'Su']);
    });

    test('fromJson needs a string id and name', () {
      expect(
        () => Routine.fromJson(const {'name': 'Sabah'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Routine.fromJson(const {'id': 'r1'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson tolerates missing optional fields', () {
      final fallback = DateTime(2026, 9, 26, 12);
      final routine = Routine.fromJson(
        const {'id': 'r1', 'name': 'Sabah'},
        fallbackCreatedAt: fallback,
      );
      expect(routine.colorKey, isNull);
      expect(routine.iconKey, isNull);
      expect(routine.items, isEmpty);
      expect(routine.repeat, RecurrenceRule.none);
      expect(routine.createdAt, fallback);
      expect(routine.position, 0);
    });

    test('copyWith replaces fields and can clear colour and icon', () {
      final routine = buildRoutine();
      expect(routine.copyWith(name: 'Akşam').name, 'Akşam');
      expect(routine.copyWith(colorKey: () => null).colorKey, isNull);
      expect(routine.copyWith(iconKey: () => null).iconKey, isNull);
      expect(
        routine.copyWith(repeat: RecurrenceRule.daily()).repeat,
        RecurrenceRule.daily(),
      );
    });

    test('value equality covers items and the repeat rule', () {
      final a = buildRoutine(items: [buildRoutineStep()]);
      final b = buildRoutine(items: [buildRoutineStep()]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(repeat: RecurrenceRule.daily()), isFalse);
      expect(a == a.copyWith(items: []), isFalse);
      expect(a == a.copyWith(position: 2), isFalse);
    });
  });

  group('RoutineList', () {
    final routines = [
      buildRoutine(id: 'a', name: 'Sabah'),
      buildRoutine(id: 'b', name: 'Akşam', position: 1),
    ];

    test('normalized drops duplicate ids, sorts and renumbers', () {
      final list = RoutineList.normalized([
        buildRoutine(id: 'b', name: 'Akşam', position: 5),
        buildRoutine(id: 'a', name: 'Sabah', position: 2),
        buildRoutine(id: 'a', name: 'Kopya', position: 9),
      ]);
      expect(list.map((r) => r.id), ['a', 'b']);
      expect(list.map((r) => r.name), ['Sabah', 'Akşam']);
      expect(list.map((r) => r.position), [0, 1]);
    });

    test('byId and byFoldedName ignore case and Turkish diacritics', () {
      expect(routines.byId('b')!.name, 'Akşam');
      expect(routines.byId('yok'), isNull);
      expect(routines.byFoldedName('AKSAM')!.id, 'b');
      expect(routines.byFoldedName('akşam', exceptId: 'b'), isNull);
      expect(routines.byFoldedName('  '), isNull);
    });

    test('saved updates in place and appends new routines', () {
      final updated = routines.saved(buildRoutine(id: 'a', name: 'Sabahçı'));
      expect(updated.map((r) => r.name), ['Sabahçı', 'Akşam']);
      final added = routines.saved(buildRoutine(id: 'c', name: 'Hafta sonu'));
      expect(added.map((r) => r.id), ['a', 'b', 'c']);
      expect(added.last.position, 2);
    });

    test('removed and reordered keep 0..n-1 positions', () {
      expect(routines.removed('a').map((r) => r.id), ['b']);
      expect(routines.removed('a').single.position, 0);
      final moved = routines.reordered(1, 0);
      expect(moved.map((r) => r.id), ['b', 'a']);
      expect(moved.map((r) => r.position), [0, 1]);
      expect(routines.reordered(5, 0).map((r) => r.id), ['a', 'b']);
    });
  });

  group('RoutineNames', () {
    test('folds like category names', () {
      expect(
          RoutineNames.fold('Işık Rutini'), CategoryNames.fold('ışık rutini'));
    });
  });
}
