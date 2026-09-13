import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

Widget _opener({
  Reminder? existing,
  DateTime? initialRemindAt,
  DateTime Function()? now,
}) =>
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showReminderEditorSheet(
              context,
              existing: existing,
              initialRemindAt: initialRemindAt,
              now: now,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

/// Fixed clock for past-time tests: Sunday 13 September 2026, 18:00.
final _now = DateTime(2026, 9, 13, 18);
DateTime _clock() => _now;

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
  await tester.tap(find.byKey(ReminderEditorKeys.save));
  await tester.pumpAndSettle();
}

Future<void> _pickDay(WidgetTester tester, String day) async {
  await tester.ensureVisible(find.byKey(ReminderScheduleKeys.dateChip));
  await tester.tap(find.byKey(ReminderScheduleKeys.dateChip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.pumpAndSettle();
  final ok = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  ).okButtonLabel;
  await tester.tap(find.text(ok));
  await tester.pumpAndSettle();
}

Color? _chipBorder(WidgetTester tester, Key key) =>
    tester.widget<ActionChip>(find.byKey(key)).side?.color;

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Reminder editor past time ($themeName)', () {
      testWidgets('picking an earlier day shows the error and a suggestion',
          (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            home: _opener(
              initialRemindAt: DateTime(2026, 9, 13, 19),
              now: _clock,
            ),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byKey(ReminderScheduleKeys.pastWarning), findsNothing);

        await _pickDay(tester, '12');

        final scheme = Theme.of(
          tester.element(find.byKey(ReminderScheduleKeys.dateChip)),
        ).colorScheme;
        expect(find.text('Dün'), findsOneWidget);
        expect(find.text('Bu saat geçti'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        expect(
            _chipBorder(tester, ReminderScheduleKeys.dateChip), scheme.error);
        expect(
            _chipBorder(tester, ReminderScheduleKeys.timeChip), scheme.error);
        // Earlier day, 19:00 still ahead today → today.
        expect(find.text('Bugün 19:00 mı?'), findsOneWidget);
      });

      testWidgets('suggestion applies the same time tomorrow and saves it',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            home: _opener(
              initialRemindAt: DateTime(2026, 9, 13, 17, 30),
              now: _clock,
            ),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Bu saat geçti'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Yarın saat 17:30 olarak ayarla'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byKey(ReminderScheduleKeys.suggestion));
        await tester.tap(find.text('Yarın 17:30 mı?'));
        await tester.pumpAndSettle();

        expect(find.byKey(ReminderScheduleKeys.pastWarning), findsNothing);
        expect(find.text('Yarın'), findsOneWidget);
        expect(_chipBorder(tester, ReminderScheduleKeys.dateChip), isNull);

        await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Koşu');
        await _tapSave(tester);

        expect(
          h.cubit.state.reminders.single.remindAt,
          DateTime(2026, 9, 14, 17, 30),
        );
        semantics.dispose();
      });

      testWidgets('save is blocked for a new reminder with a past time',
          (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            home: _opener(
              initialRemindAt: DateTime(2026, 9, 13, 9),
              now: _clock,
            ),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Fatura');
        await _tapSave(tester);

        expect(h.cubit.state.reminders, isEmpty);
        expect(find.byKey(ReminderEditorKeys.title), findsOneWidget);
        expect(find.text('Bu saat geçti'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        final card = tester.widget<GroupedCard>(
          find.widgetWithText(GroupedCard, 'Ne zaman'),
        );
        final scheme = Theme.of(
          tester.element(find.byKey(ReminderEditorKeys.title)),
        ).colorScheme;
        expect(card.borderColor, scheme.error);
        // The warning is on screen, not scrolled away.
        expect(
          tester.getRect(find.byKey(ReminderScheduleKeys.pastWarning)).top,
          greaterThanOrEqualTo(0),
        );
      });

      testWidgets('existing overdue reminder saves its unchanged time',
          (tester) async {
        final original = DateTime(2026, 9, 12, 9, 0, 42);
        final existing = buildReminder(
          id: 'overdue',
          title: 'Eczane',
          remindAt: original,
        );
        final h = await UiHarness.create(reminders: [existing]);
        await tester.pumpWidget(
          h.app(
            home: _opener(existing: existing, now: _clock),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Overdue time is flagged on open, but does not block saving.
        expect(find.text('Bu saat geçti'), findsOneWidget);
        expect(find.text('Yarın 09:00 mı?'), findsOneWidget);

        await tester.enterText(
          find.byKey(ReminderEditorKeys.title),
          'Eczaneye uğra',
        );
        await _tapSave(tester);

        final saved = h.cubit.state.reminders.single;
        expect(saved.title, 'Eczaneye uğra');
        expect(saved.remindAt, original);
        expect(find.byKey(ReminderEditorKeys.title), findsNothing);
      });

      testWidgets(
          'existing overdue reminder moved to another past day is '
          'blocked', (tester) async {
        final existing = buildReminder(
          id: 'overdue',
          remindAt: DateTime(2026, 9, 12, 9),
        );
        final h = await UiHarness.create(reminders: [existing]);
        await tester.pumpWidget(
          h.app(
            home: _opener(existing: existing, now: _clock),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await _pickDay(tester, '11');
        await _tapSave(tester);

        expect(
          h.cubit.state.reminders.single.remindAt,
          DateTime(2026, 9, 12, 9),
        );
        expect(find.byKey(ReminderEditorKeys.title), findsOneWidget);
        expect(find.text('Bu saat geçti'), findsOneWidget);
      });

      testWidgets('future time saves unchanged without a warning',
          (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            home: _opener(
              initialRemindAt: DateTime(2026, 9, 13, 20, 15),
              now: _clock,
            ),
            theme: theme,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byKey(ReminderScheduleKeys.pastWarning), findsNothing);
        expect(_chipBorder(tester, ReminderScheduleKeys.timeChip), isNull);

        await tester.enterText(find.byKey(ReminderEditorKeys.title), 'Film');
        await _tapSave(tester);

        expect(
          h.cubit.state.reminders.single.remindAt,
          DateTime(2026, 9, 13, 20, 15),
        );
      });
    });

    group('Reminder editor ($themeName)', () {
      testWidgets('title comes first and is focused', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final title = find.byKey(ReminderEditorKeys.title);
        expect(title, findsOneWidget);
        expect(tester.widget<TextField>(title).autofocus, isTrue);
        final editable = tester.widget<EditableText>(
          find.descendant(of: title, matching: find.byType(EditableText)),
        );
        expect(editable.focusNode.hasFocus, isTrue);

        final marketChip = find.widgetWithText(FilterChip, 'Market');
        expect(
          tester.getTopLeft(title).dy,
          lessThan(tester.getTopLeft(marketChip).dy),
        );
      });

      testWidgets('"Diğer" saves without a custom name', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(ReminderEditorKeys.title),
          'Kitabı iade et',
        );
        await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
        await tester.tap(find.byKey(ReminderEditorKeys.save));
        await tester.pumpAndSettle();

        final saved = h.cubit.state.reminders.single;
        expect(saved.title, 'Kitabı iade et');
        expect(saved.categoryId, ReminderCategoryIds.other);
        expect(saved.customCategoryLabel, isNull);
        expect(saved.categoryDisplayLabel, 'Diğer');
        verify(() => h.repository.saveReminders(any())).called(1);
        expect(find.byKey(ReminderEditorKeys.title), findsNothing);
      });

      testWidgets('empty title shows an inline error', (tester) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(h.app(home: _opener(), theme: theme));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
        await tester.tap(find.byKey(ReminderEditorKeys.save));
        await tester.pumpAndSettle();

        expect(find.text('Başlık boş olamaz.'), findsOneWidget);
        expect(h.cubit.state.reminders, isEmpty);
      });
    });
  }

  testWidgets('location summary never shows coordinates', (tester) async {
    final h = await UiHarness.create();
    final existing = Reminder(
      id: 'loc',
      title: 'Market',
      isDone: false,
      createdAt: DateTime(2026, 9, 1),
      categoryId: ReminderCategoryIds.market,
      locationTriggerEnabled: true,
      locationLatitude: 41.0082,
      locationLongitude: 28.9784,
    );
    await tester.pumpWidget(h.app(home: _opener(existing: existing)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Seçilen konum · 150 m'), findsOneWidget);
    expect(find.textContaining('41.0'), findsNothing);
  });
}
