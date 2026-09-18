import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/domain/reminder_completion.dart';

import '../helpers/factories.dart';

List<String> titles(List<Subtask> items) => [for (final s in items) s.title];
List<int> positions(List<Subtask> items) => [for (final s in items) s.position];

void main() {
  group('Subtask JSON', () {
    test('round trips', () {
      const s = Subtask(id: 'a', title: 'Süt', isDone: true, position: 3);
      expect(Subtask.fromJson(s.toJson()), s);
    });

    test('missing isDone/position default to open/0', () {
      expect(
        Subtask.fromJson({'id': 'a', 'title': 'Süt'}),
        const Subtask(id: 'a', title: 'Süt'),
      );
    });

    test('listFromJson: missing or non-list → empty', () {
      expect(Subtask.listFromJson(null), isEmpty);
      expect(Subtask.listFromJson('x'), isEmpty);
    });

    test('listFromJson skips unreadable items and orders by position', () {
      final list = Subtask.listFromJson([
        {'id': 'b', 'title': 'Ekmek', 'position': 5},
        'bozuk',
        {'id': 'x'},
        {'id': 'a', 'title': 'Süt', 'position': 1, 'isDone': true},
      ]);
      expect(titles(list), ['Süt', 'Ekmek']);
      expect(positions(list), [0, 1]);
      expect(list.first.isDone, isTrue);
    });
  });

  group('Reminder.subtasks', () {
    test('defaults to empty and legacy JSON without the key loads empty', () {
      final json = buildReminder().toJson()..remove('subtasks');
      expect(Reminder.fromJson(json).subtasks, isEmpty);
      expect(buildReminder().hasSubtasks, isFalse);
    });

    test('toJson/fromJson round trip keeps subtasks', () {
      final r = buildReminder(
        subtasks: buildSubtasks(['Süt', 'Ekmek'], done: {1}),
      );
      final back = Reminder.fromJson(r.toJson());
      expect(back.subtasks, r.subtasks);
      expect(back.hasSubtasks, isTrue);
    });

    test('copyWith replaces or keeps subtasks', () {
      final r = buildReminder(subtasks: buildSubtasks(['Süt']));
      expect(r.copyWith(title: 'x').subtasks, r.subtasks);
      expect(r.copyWith(subtasks: const []).subtasks, isEmpty);
    });
  });

  group('SubtaskList helpers', () {
    final items = buildSubtasks(['A', 'B', 'C', 'D'], done: {1});

    test('progress counts', () {
      expect(items.doneCount, 1);
      expect(items.openCount, 3);
      expect(items.progress, 0.25);
      expect(items.allDone, isFalse);
      expect(<Subtask>[].progress, 0);
      expect(<Subtask>[].allDone, isFalse);
      expect(buildSubtasks(['A'], done: {0}).allDone, isTrue);
      expect(titles(items.open), ['A', 'C', 'D']);
      expect(titles(items.done), ['B']);
    });

    test('toggled flips one item or sets it', () {
      expect(items.toggled('s1').first.isDone, isTrue);
      expect(items.toggled('s2')[1].isDone, isFalse);
      expect(items.toggled('s2', done: true)[1].isDone, isTrue);
      expect(items.toggled('nope'), items);
    });

    test('renamed', () {
      expect(titles(items.renamed('s3', 'Çay')), ['A', 'B', 'Çay', 'D']);
    });

    test('added / addedAll renumber positions', () {
      final added = items.added(const Subtask(id: 'n', title: 'E'));
      expect(titles(added), ['A', 'B', 'C', 'D', 'E']);
      expect(positions(added), [0, 1, 2, 3, 4]);
      final inserted =
          items.added(const Subtask(id: 'n', title: 'X'), index: 1);
      expect(titles(inserted), ['A', 'X', 'B', 'C', 'D']);
      final many = items.addedAll(
        const [Subtask(id: 'p', title: 'P'), Subtask(id: 'q', title: 'Q')],
        index: 2,
      );
      expect(titles(many), ['A', 'B', 'P', 'Q', 'C', 'D']);
      expect(positions(many), [0, 1, 2, 3, 4, 5]);
    });

    test('removed renumbers', () {
      final removed = items.removed('s2');
      expect(titles(removed), ['A', 'C', 'D']);
      expect(positions(removed), [0, 1, 2]);
    });

    test('reordered moves to the target index (after removal)', () {
      expect(titles(items.reordered(0, 2)), ['B', 'C', 'A', 'D']);
      expect(titles(items.reordered(3, 0)), ['D', 'A', 'B', 'C']);
      expect(titles(items.reordered(0, 99)), ['B', 'C', 'D', 'A']);
      expect(positions(items.reordered(0, 2)), [0, 1, 2, 3]);
    });

    test('moved up/down, clamped at the ends', () {
      expect(titles(items.moved('s2', -1)), ['B', 'A', 'C', 'D']);
      expect(titles(items.moved('s2', 1)), ['A', 'C', 'B', 'D']);
      expect(titles(items.moved('s1', -1)), ['A', 'B', 'C', 'D']);
      expect(titles(items.moved('s4', 1)), ['A', 'B', 'C', 'D']);
    });

    test('reset clears done flags only', () {
      final reset = buildSubtasks(['A', 'B'], done: {0, 1}).reset;
      expect(reset.every((s) => !s.isDone), isTrue);
      expect(titles(reset), ['A', 'B']);
    });
  });

  group('splitSubtaskText', () {
    test('newlines (also CRLF) and trimming', () {
      expect(
        splitSubtaskText('  Süt \r\nEkmek\n\n  Yumurta (15\'li)  \n'),
        ['Süt', 'Ekmek', "Yumurta (15'li)"],
      );
    });

    test('commas, semicolons and Turkish " ve "', () {
      expect(
        splitSubtaskText('süt, ekmek ve yumurta; peynir'),
        ['süt', 'ekmek', 'yumurta', 'peynir'],
      );
      expect(splitSubtaskText('Domates VE biber'), ['Domates', 'biber']);
    });

    test('"ve" inside a word does not split', () {
      expect(splitSubtaskText('Deve sütü'), ['Deve sütü']);
      expect(splitSubtaskText('vergi ödemesi'), ['vergi ödemesi']);
      expect(splitSubtaskText('Kavanoz ve'), ['Kavanoz ve']);
    });

    test('decimal comma between digits is kept', () {
      expect(splitSubtaskText('Peynir 1,5 kg, zeytin'), [
        'Peynir 1,5 kg',
        'zeytin',
      ]);
    });

    test('strips list bullets and checkboxes', () {
      expect(
        splitSubtaskText('- süt\n* ekmek\n• çay\n1. yumurta\n2) un\n[ ] tuz\n'
            '[x] şeker\n- [ ] pirinç'),
        ['süt', 'ekmek', 'çay', 'yumurta', 'un', 'tuz', 'şeker', 'pirinç'],
      );
      // A number that is part of the title stays.
      expect(splitSubtaskText('3 yumurta'), ['3 yumurta']);
      expect(splitSubtaskText('1.5 L su'), ['1.5 L su']);
    });

    test('empty input and separators only', () {
      expect(splitSubtaskText(''), isEmpty);
      expect(splitSubtaskText(' ,\n ; '), isEmpty);
      expect(splitSubtaskText('Tek madde'), ['Tek madde']);
      expect(looksLikeSubtaskList('Tek madde'), isFalse);
      expect(looksLikeSubtaskList('süt ve ekmek'), isTrue);
    });
  });

  group('splitSubtaskLines', () {
    test('splits on line breaks only, keeps commas and "ve"', () {
      expect(
        splitSubtaskLines('Peynir, beyaz\r\n- Domates ve biber\n\n  Çay  '),
        ['Peynir, beyaz', 'Domates ve biber', 'Çay'],
      );
      expect(splitSubtaskLines('   '), isEmpty);
    });
  });

  test('SubtaskList.inOrder renumbers in the given order', () {
    final items = buildSubtasks(['A', 'B', 'C']);
    final reversed = SubtaskList.inOrder(items.reversed);
    expect(titles(reversed), ['C', 'B', 'A']);
    expect(positions(reversed), [0, 1, 2]);
  });

  group('completeReminder and subtasks', () {
    final now = DateTime(2026, 9, 13, 12);

    test('recurring: advancing resets subtasks to open', () {
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.daily(),
        subtasks: buildSubtasks(['Süt', 'Ekmek'], done: {0, 1}),
      );
      final next = completeReminder(r, now);
      expect(next.remindAt, DateTime(2026, 9, 14, 18));
      expect(next.subtasks.every((s) => !s.isDone), isTrue);
      expect(titles(next.subtasks), ['Süt', 'Ekmek']);
    });

    test('one-off: completing does not touch subtasks', () {
      final subtasks = buildSubtasks(['Süt', 'Ekmek'], done: {0});
      final r = buildReminder(subtasks: subtasks);
      final done = completeReminder(r, now);
      expect(done.isDone, isTrue);
      expect(done.subtasks, subtasks);
    });

    test('finished series is marked done, subtasks kept', () {
      final subtasks = buildSubtasks(['Süt'], done: {0});
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 13, 18),
        recurrence: RecurrenceRule.daily(until: DateTime(2026, 9, 13)),
        subtasks: subtasks,
      );
      final done = completeReminder(r, now);
      expect(done.isDone, isTrue);
      expect(done.subtasks, subtasks);
    });

    test('all subtasks done does not complete the reminder', () {
      final r = buildReminder(subtasks: buildSubtasks(['Süt'], done: {0}));
      expect(r.isDone, isFalse);
      expect(r.subtasks.allDone, isTrue);
    });
  });
}
