import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/ui/today/today_sections.dart';

import '../../helpers/factories.dart';

void main() {
  final now = DateTime(2026, 9, 13, 14, 32);

  final reminders = [
    buildReminder(id: 'tomorrow', remindAt: DateTime(2026, 9, 14, 9, 30)),
    buildReminder(id: 'today-20', remindAt: DateTime(2026, 9, 13, 20)),
    buildReminder(id: 'overdue-yesterday', remindAt: DateTime(2026, 9, 12, 18)),
    buildReminder(id: 'today-16', remindAt: DateTime(2026, 9, 13, 16)),
    buildReminder(id: 'overdue-morning', remindAt: DateTime(2026, 9, 13, 9)),
    buildReminder(id: 'untimed-old', createdAt: DateTime(2026, 9, 1)),
    buildReminder(id: 'untimed-new', createdAt: DateTime(2026, 9, 10)),
    buildReminder(
      id: 'done-today',
      isDone: true,
      remindAt: DateTime(2026, 9, 13, 11, 30),
    ),
    buildReminder(id: 'done-untimed', isDone: true),
    buildReminder(
      id: 'done-yesterday',
      isDone: true,
      remindAt: DateTime(2026, 9, 12, 8),
    ),
  ];

  final birthdays = [
    buildBirthday(id: 'b-next-week', date: DateTime(1999, 9, 21)),
    buildBirthday(id: 'b-tomorrow', date: DateTime(1996, 9, 14)),
    buildBirthday(id: 'b-today', date: DateTime(1990, 9, 13), notifyHour: 9),
    buildBirthday(id: 'b-yesterday', date: DateTime(1990, 9, 12)),
  ];

  List<String> ids(Iterable<dynamic> items) =>
      [for (final r in items) r.id as String];

  final sections = TodaySections.from(
    reminders: reminders,
    birthdays: birthdays,
    now: now,
  );

  test('overdue: not done and before now, oldest first', () {
    expect(ids(sections.overdue), ['overdue-yesterday', 'overdue-morning']);
  });

  test('today: not done, later today, sorted by time; later days excluded', () {
    expect(ids(sections.today), ['today-16', 'today-20']);
    expect(
      [
        ...sections.overdue,
        ...sections.today,
        ...sections.untimed,
        ...sections.completed,
      ].map((r) => r.id),
      isNot(contains('tomorrow')),
    );
  });

  test('untimed: not done without time, newest first', () {
    expect(ids(sections.untimed), ['untimed-new', 'untimed-old']);
  });

  test('completed: done today or untimed', () {
    expect(ids(sections.completed), ['done-today', 'done-untimed']);
  });

  test('summary, progress and birthdays for today/tomorrow', () {
    expect(sections.summary, '4 açık · 2 gecikmiş · 2 tamam');
    expect(sections.progress, closeTo(2 / 8, 1e-9));
    expect(sections.isEmpty, isFalse);
    expect(sections.allDone, isFalse);
    expect(
      [for (final o in sections.birthdays) o.birthday.id],
      ['b-today', 'b-tomorrow'],
    );
    expect(sections.birthdays.last.age, 30);
  });

  test('completed split into timed (ribbon) and untimed', () {
    expect(ids(sections.completedTimed), ['done-today']);
    expect(ids(sections.completedUntimed), ['done-untimed']);
  });

  test('timeline: chronological with the now marker before later items', () {
    String label(TimelineEntry e) => switch (e) {
          TimelineNow() => 'NOW',
          TimelineReminder(:final reminder) => reminder.id,
        };
    expect(
      sections.timeline(now: now).map(label),
      ['done-today', 'NOW', 'today-16', 'today-20'],
    );
    expect(
      sections.timeline(now: now, includeCompleted: false).map(label),
      ['NOW', 'today-16', 'today-20'],
    );

    final late = TodaySections.from(
      reminders: [
        buildReminder(
          id: 'done-morning',
          isDone: true,
          remindAt: DateTime(2026, 9, 13, 8),
        ),
        buildReminder(
          id: 'done-at-now',
          isDone: true,
          remindAt: DateTime(2026, 9, 13, 22),
        ),
      ],
      birthdays: const [],
      now: DateTime(2026, 9, 13, 22),
    );
    // Items due exactly at now come before the marker; marker is last.
    expect(
      late.timeline(now: DateTime(2026, 9, 13, 22)).map(label),
      ['done-morning', 'done-at-now', 'NOW'],
    );
  });

  test('tomorrowAtSameTime keeps the wall-clock time, across months', () {
    expect(
      TodaySections.tomorrowAtSameTime(DateTime(2026, 9, 10, 18, 5), now),
      DateTime(2026, 9, 14, 18, 5),
    );
    expect(
      TodaySections.tomorrowAtSameTime(
        DateTime(2026, 9, 29, 7),
        DateTime(2026, 9, 30, 12),
      ),
      DateTime(2026, 10, 1, 7),
    );
  });

  test('empty and all-done states', () {
    final empty = TodaySections.from(
      reminders: const [],
      birthdays: const [],
      now: now,
    );
    expect(empty.isEmpty, isTrue);
    expect(empty.progress, 0);

    final allDone = TodaySections.from(
      reminders: [buildReminder(id: 'd', isDone: true)],
      birthdays: const [],
      now: now,
    );
    expect(allDone.allDone, isTrue);
    expect(allDone.progress, 1);
  });
}
