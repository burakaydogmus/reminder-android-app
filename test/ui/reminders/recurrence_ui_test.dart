import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/undo_snack_bar.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

/// Saturday 19 September 2026, 16:00.
final _saturday = DateTime(2026, 9, 19, 16);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _segment(RecurrenceMode mode) => find.descendant(
      of: find.byKey(RecurrenceSheetKeys.segments),
      matching: find.text(mode.label),
    );

String _previewText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(RecurrenceSheetKeys.preview)).data!;

String _intervalText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(RecurrenceSheetKeys.intervalLabel)).data!;

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('RecurrenceFormat', () {
    test('occurrence labels', () {
      expect(RecurrenceFormat.day(_saturday, _now), 'Cmt 19 Eyl');
      expect(
        RecurrenceFormat.day(DateTime(2027, 1, 2), _now),
        'Cmt 2 Oca 2027',
      );
      expect(
        RecurrenceFormat.next(DateTime(2026, 9, 20, 16), _now),
        'Sonraki: Paz 20 Eyl 16:00',
      );
      expect(
        RecurrenceFormat.preview(
          [DateTime(2026, 9, 13), DateTime(2026, 9, 20)],
          _now,
        ),
        'Sonraki 2: Paz 13 Eyl · Paz 20 Eyl',
      );
    });
  });

  group('Tekrar sheet', () {
    late RecurrenceRule? result;
    late bool closed;

    Future<void> openSheet(
      WidgetTester tester, {
      RecurrenceRule initial = RecurrenceRule.none,
      DateTime? anchor,
      ThemeData Function() theme = KorTheme.light,
    }) async {
      result = null;
      closed = false;
      final h = await UiHarness.create();
      await tester.pumpWidget(
        h.app(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showRecurrenceSheet(
                      context,
                      initial: initial,
                      anchor: anchor ?? _saturday,
                      now: _now,
                    );
                    closed = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    for (final (themeName, theme) in korThemes) {
      testWidgets('Haftalık starts on the anchor weekday ($themeName)',
          (tester) async {
        await openSheet(tester, theme: theme);
        expect(find.byKey(RecurrenceSheetKeys.preview), findsNothing);

        await _tap(tester, _segment(RecurrenceMode.weekly));
        expect(
          _previewText(tester),
          'Sonraki 3: Cmt 19 Eyl · Cmt 26 Eyl · Cmt 3 Eki',
        );
        expect(_intervalText(tester), 'Her hafta');
        expect(find.text('Hiçbir zaman'), findsOneWidget);

        await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
        expect(closed, isTrue);
        expect(result, RecurrenceRule.weekly([DateTime.saturday]));
      });
    }

    testWidgets('weekday buttons and the stepper build "2 haftada bir"',
        (tester) async {
      await openSheet(tester);
      await _tap(tester, _segment(RecurrenceMode.weekly));

      // The only selected day cannot be removed.
      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(6)));
      expect(_previewText(tester), startsWith('Sonraki 3: Cmt 19 Eyl'));

      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(1)));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(3)));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(6)));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.increment));
      expect(_intervalText(tester), '2 haftada bir');
      // Series starts in the anchor week: Mon/Wed before Saturday 19 are
      // skipped, so the next ones are two weeks later.
      expect(
        _previewText(tester),
        'Sonraki 3: Pzt 28 Eyl · Çar 30 Eyl · Pzt 12 Eki',
      );

      final size = tester.getSize(find.byKey(RecurrenceSheetKeys.weekday(1)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
      expect(
        result,
        RecurrenceRule.weekly(
          [DateTime.monday, DateTime.wednesday],
          interval: 2,
        ),
      );
    });

    testWidgets('Özel is every N ≥ 2 days', (tester) async {
      await openSheet(tester);
      await _tap(tester, _segment(RecurrenceMode.custom));
      expect(_intervalText(tester), '2 günde bir');
      expect(
        tester
            .widget<IconButton>(find.byKey(RecurrenceSheetKeys.decrement))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byKey(RecurrenceSheetKeys.increment));
      expect(_intervalText(tester), '3 günde bir');
      expect(
        _previewText(tester),
        'Sonraki 3: Cmt 19 Eyl · Sal 22 Eyl · Cum 25 Eyl',
      );

      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
      expect(result, RecurrenceRule.daily(interval: 3));
    });

    testWidgets('Aylık on the 31st explains short months', (tester) async {
      await openSheet(tester, anchor: DateTime(2026, 10, 31, 9));
      await _tap(tester, _segment(RecurrenceMode.monthly));
      expect(
        find.text("Ayın 31'i; kısa aylarda ayın son günü."),
        findsOneWidget,
      );
      expect(
        _previewText(tester),
        'Sonraki 3: Cmt 31 Eki · Pzt 30 Kas · Per 31 Ara',
      );
      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
      expect(result, RecurrenceRule.monthly(dayOfMonth: 31));
    });

    testWidgets('an existing rule opens on its segment; Bitiş can be cleared',
        (tester) async {
      await openSheet(
        tester,
        initial: RecurrenceRule.daily(until: DateTime(2026, 12, 31)),
      );
      expect(find.text('31 Aralık'), findsOneWidget);
      expect(
          _previewText(tester),
          'Sonraki 3: Cmt 19 Eyl · Paz 20 Eyl · '
          'Pzt 21 Eyl');

      await _tap(tester, find.byKey(RecurrenceSheetKeys.clearUntil));
      expect(find.text('Hiçbir zaman'), findsOneWidget);
      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
      expect(result, RecurrenceRule.daily());
    });

    testWidgets('Yok returns none, Vazgeç returns null', (tester) async {
      await openSheet(tester, initial: RecurrenceRule.daily());
      await _tap(tester, _segment(RecurrenceMode.none));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));
      expect(result, RecurrenceRule.none);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(RecurrenceSheetKeys.cancel));
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  group('Reminder editor Tekrar row', () {
    Future<UiHarness> openEditor(
      WidgetTester tester, {
      Reminder? existing,
    }) async {
      final h = await UiHarness.create(
        reminders: [if (existing != null) existing],
      );
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showReminderEditorSheet(
                    context,
                    existing: existing,
                    now: _clock,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return h;
    }

    String rowSummary(WidgetTester tester) {
      final row = find.byKey(ReminderEditorKeys.recurrence);
      return tester
          .widget<Text>(
            find.descendant(of: row, matching: find.byType(Text)).at(1),
          )
          .data!;
    }

    Future<void> save(WidgetTester tester) =>
        _tap(tester, find.byKey(ReminderEditorKeys.save));

    testWidgets('choosing a rule without a time schedules today + 1 hour',
        (tester) async {
      final h = await openEditor(tester);
      await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Su iç');
      expect(rowSummary(tester), 'Tekrar yok');

      await _tap(tester, find.byKey(ReminderEditorKeys.recurrence));
      expect(
        find.text('Sonraki 3: Paz 13 Eyl · Pzt 14 Eyl · Sal 15 Eyl'),
        findsNothing,
        reason: 'preview only after choosing a rule',
      );
      await _tap(tester, _segment(RecurrenceMode.daily));
      expect(
        _previewText(tester),
        'Sonraki 3: Paz 13 Eyl · Pzt 14 Eyl · Sal 15 Eyl',
      );
      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));

      expect(rowSummary(tester), 'Her gün');
      expect(find.byKey(ReminderScheduleKeys.timeChip), findsOneWidget);
      await save(tester);

      final saved = h.cubit.state.reminders.single;
      expect(saved.recurrence, RecurrenceRule.daily());
      expect(saved.remindAt, DateTime(2026, 9, 13, 15, 32));
      expect(saved.isDone, isFalse);
    });

    testWidgets('dismissing the sheet leaves scheduling off', (tester) async {
      await openEditor(tester);
      await _tap(tester, find.byKey(ReminderEditorKeys.recurrence));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.cancel));
      expect(find.byKey(ReminderScheduleKeys.timeChip), findsNothing);
      expect(rowSummary(tester), 'Tekrar yok');
    });

    testWidgets('a weekly rule moves the date to its first chosen day',
        (tester) async {
      final h = await openEditor(
        tester,
        existing: buildReminder(id: 'r', remindAt: DateTime(2026, 9, 20, 9)),
      );
      await _tap(tester, find.byKey(ReminderEditorKeys.recurrence));
      await _tap(tester, _segment(RecurrenceMode.weekly));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(1)));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.weekday(7)));
      await _tap(tester, find.byKey(RecurrenceSheetKeys.done));

      expect(rowSummary(tester), 'Her Pazartesi');
      expect(find.text('21 Eyl'), findsOneWidget);
      await save(tester);
      final saved = h.cubit.state.reminders.single;
      expect(saved.remindAt, DateTime(2026, 9, 21, 9));
      expect(saved.recurrence, RecurrenceRule.weekly([DateTime.monday]));
    });

    testWidgets('changing the date moves the whole series (tüm seri)',
        (tester) async {
      final h = await openEditor(
        tester,
        existing: buildReminder(
          id: 'r',
          remindAt: _saturday,
          recurrence: RecurrenceRule.weekly([DateTime.saturday]),
        ),
      );
      expect(rowSummary(tester), 'Her Cumartesi');

      await _tap(tester, find.byKey(ReminderScheduleKeys.dateChip));
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      final ok = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      ).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();

      expect(rowSummary(tester), 'Her Pazar');
      await save(tester);
      final saved = h.cubit.state.reminders.single;
      expect(saved.remindAt, DateTime(2026, 9, 20, 16));
      expect(saved.recurrence, RecurrenceRule.weekly([DateTime.sunday]));
    });

    testWidgets('turning scheduling off removes the rule', (tester) async {
      final h = await openEditor(
        tester,
        existing: buildReminder(
          id: 'r',
          remindAt: _saturday,
          recurrence: RecurrenceRule.daily(),
        ),
      );
      await _tap(
        tester,
        find.bySemanticsLabel('Zamanla ve bildir'),
      );
      expect(rowSummary(tester), 'Tekrar yok');
      await save(tester);
      final saved = h.cubit.state.reminders.single;
      expect(saved.remindAt, isNull);
      expect(saved.recurrence, RecurrenceRule.none);
    });
  });

  group('Recurring reminder card', () {
    final recurring = buildReminder(
      id: 'gym',
      title: 'Spor',
      remindAt: DateTime(2026, 9, 13, 16),
      recurrence: RecurrenceRule.daily(),
    );

    Finder card() => find.ancestor(
          of: find.text('Spor'),
          matching: find.byType(ReminderCard),
        );

    Future<UiHarness> pumpShell(WidgetTester tester) async {
      final h = await UiHarness.create(reminders: [recurring]);
      await tester.pumpWidget(h.app(home: const HomeShell(clock: _clock)));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('meta line shows the repeat icon and summary', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester);
      expect(
        find.descendant(
          of: card(),
          matching: find.textContaining('Her gün', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: card(), matching: find.byIcon(Icons.repeat_rounded)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('tekrar: Her gün')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('completing shows "Sonraki" and Geri al restores the time',
        (tester) async {
      final h = await pumpShell(tester);
      // The cubit uses the real clock; the rule decides the next occurrence.
      final expected = completeReminder(recurring, DateTime.now()).remindAt!;

      final topLeft = tester.getTopLeft(card());
      final height = tester.getSize(card()).height;
      await tester.tapAt(topLeft + Offset(28, height / 2));
      await tester.pumpAndSettle();

      final updated = h.cubit.state.reminders.single;
      expect(updated.isDone, isFalse);
      expect(updated.remindAt, expected);
      expect(find.text(RecurrenceFormat.next(expected, _now)), findsOneWidget);

      await tester.tap(find.text(UndoSnackBar.actionLabel));
      await tester.pumpAndSettle();
      final restored = h.cubit.state.reminders.single;
      expect(restored.isDone, isFalse);
      expect(restored.remindAt, DateTime(2026, 9, 13, 16));
    });
  });
}
