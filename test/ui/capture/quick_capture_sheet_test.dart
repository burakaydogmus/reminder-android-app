import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/capture/capture_text.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../ui_harness.dart';

// Pazar 13 Eylül 2026, 14:32 (the parser tables' clock).
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

const _openKey = Key('open');

Finder get _field => find.byKey(QuickCaptureKeys.field);

Future<UiHarness> _open(
  WidgetTester tester, {
  ThemeData Function() theme = KorTheme.light,
  List<ReminderCategory> categories = const [],
}) async {
  final h = await UiHarness.create(now: _clock, categories: categories);
  await tester.pumpWidget(
    h.app(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: _openKey,
              onPressed: () => showQuickCaptureSheet(context, now: _clock),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pumpAndSettle();
}

Finder _chip(Key key) => find.byKey(key);

Finder _chipText(Key key, String text) => find.descendant(
      of: find.byKey(key),
      matching: find.text(text),
    );

Future<void> _removeChip(WidgetTester tester, Key key) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(key),
      matching: find.byTooltip('Düz metne çevir'),
    ),
  );
  await tester.pumpAndSettle();
}

CaptureTextController _controller(WidgetTester tester) =>
    tester.widget<TextField>(_field).controller! as CaptureTextController;

/// The field's styled spans as (text, style) pairs.
List<(String, TextStyle?)> _spans(WidgetTester tester) {
  final span = _controller(tester).buildTextSpan(
    context: tester.element(_field),
    withComposing: false,
  );
  return [
    for (final child in span.children ?? const <InlineSpan>[])
      if (child is TextSpan) (child.text ?? '', child.style),
  ];
}

List<Reminder> _reminders(UiHarness h) => h.cubit.state.reminders;

void main() {
  const sentence = 'cuma 18:00 ekmek ve süt al #market !!';

  for (final (themeName, theme) in korThemes) {
    testWidgets('highlights tokens in place ($themeName)', (tester) async {
      await _open(tester, theme: theme);
      await _type(tester, sentence);

      final scheme = Theme.of(tester.element(_field)).colorScheme;
      final market = CategoryVisuals.colorsOf(
        tester.element(_field),
        ReminderCategoryIds.market,
      );
      final spans = {for (final (text, style) in _spans(tester)) text: style};

      expect(spans['cuma']?.backgroundColor, scheme.primaryContainer);
      expect(spans['cuma']?.color, scheme.onPrimaryContainer);
      expect(spans['18:00']?.backgroundColor, scheme.primaryContainer);
      expect(spans['#market']?.backgroundColor, market.container);
      expect(spans['#market']?.color, market.onContainer);
      expect(spans['!!']?.background?.style, PaintingStyle.stroke);
      expect(spans[' ekmek ve süt al ']?.backgroundColor, isNull);
    });
  }

  testWidgets('chips reflect the parsed values', (tester) async {
    await _open(tester);
    await _type(tester, sentence);

    expect(
        _chipText(QuickCaptureKeys.dateChip, '18 Eyl, 18:00'), findsOneWidget);
    expect(_chipText(QuickCaptureKeys.categoryChip, 'Market'), findsOneWidget);
    expect(_chipText(QuickCaptureKeys.priorityChip, '!! Orta'), findsOneWidget);
    expect(
        _chipText(QuickCaptureKeys.recurrenceChip, 'Tekrar'), findsOneWidget);
    expect(_chip(QuickCaptureKeys.splitChip), findsOneWidget);
  });

  testWidgets('"×" turns a token back into plain text', (tester) async {
    final h = await _open(tester);
    await _type(tester, sentence);

    await _removeChip(tester, QuickCaptureKeys.dateChip);
    expect(_chipText(QuickCaptureKeys.dateChip, 'Tarih'), findsOneWidget);
    final texts = [for (final (t, _) in _spans(tester)) t];
    expect(texts.contains('cuma'), isFalse);
    expect(texts, contains('#market'));

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    final saved = _reminders(h).single;
    expect(saved.title, 'Cuma 18:00 ekmek ve süt al');
    expect(saved.remindAt, isNull);
    expect(saved.categoryId, ReminderCategoryIds.market);
    expect(saved.priority, 2);
  });

  testWidgets('↑ saves, clears the field, stays open; undo deletes', (
    tester,
  ) async {
    final h = await _open(tester);
    await _type(tester, sentence);

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();

    final saved = _reminders(h).single;
    expect(saved.title, 'Ekmek ve süt al');
    expect(saved.remindAt, DateTime(2026, 9, 18, 18));
    expect(saved.categoryId, ReminderCategoryIds.market);
    expect(saved.priority, 2);
    expect(saved.subtasks, isEmpty);

    // The sheet stays open with an empty field for the next capture.
    expect(_field, findsOneWidget);
    expect(_controller(tester).text, isEmpty);
    expect(find.text('Eklendi: Ekmek ve süt al'), findsOneWidget);

    await tester.tap(find.byKey(QuickCaptureKeys.undo));
    await tester.pumpAndSettle();
    expect(_reminders(h), isEmpty);
    expect(find.byKey(QuickCaptureKeys.toast), findsNothing);
  });

  testWidgets('the toast goes away after 3 s', (tester) async {
    await _open(tester);
    await _type(tester, 'süt al');
    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(find.byKey(QuickCaptureKeys.toast), findsOneWidget);
    await tester.pump(QuickCaptureSheet.toastDuration);
    await tester.pumpAndSettle();
    expect(find.byKey(QuickCaptureKeys.toast), findsNothing);
  });

  testWidgets('Enter saves and keeps the sheet for the next one', (
    tester,
  ) async {
    final h = await _open(tester);
    await _type(tester, 'yarın 09:00 ilaç al');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await _type(tester, 'her gün 20:00 vitamin iç');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final titles = {for (final r in _reminders(h)) r.title: r};
    expect(titles.keys, containsAll(['İlaç al', 'Vitamin iç']));
    expect(titles['Vitamin iç']!.recurrence, RecurrenceRule.daily());
    expect(titles['Vitamin iç']!.remindAt, DateTime(2026, 9, 13, 20));
    expect(_field, findsOneWidget);
  });

  testWidgets('an empty field does not save', (tester) async {
    final h = await _open(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_reminders(h), isEmpty);
    final save = tester.widget<IconButton>(find.byKey(QuickCaptureKeys.save));
    expect(save.onPressed, isNull);
  });

  testWidgets('a past time warns and blocks saving', (tester) async {
    final h = await _open(tester);
    await _type(tester, "bugün 9'da ilaç iç");

    expect(find.text('Bu saat geçti'), findsOneWidget);
    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h), isEmpty);

    // "Yarın 09:00 mı?" applies the suggestion; now it saves.
    await tester.tap(find.byKey(ReminderScheduleKeys.suggestion));
    await tester.pumpAndSettle();
    expect(find.text('Bu saat geçti'), findsNothing);
    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h).single.remindAt, DateTime(2026, 9, 14, 9));
  });

  testWidgets('"Maddelere böl?" accepted → list title and subtasks', (
    tester,
  ) async {
    final h = await _open(tester);
    await _type(tester, '#market ekmek, süt ve yumurta');
    expect(find.text('Maddelere böl?'), findsOneWidget);

    await tester.ensureVisible(_chip(QuickCaptureKeys.splitChip));
    await tester.tap(_chip(QuickCaptureKeys.splitChip));
    await tester.pumpAndSettle();
    expect(find.text('3 madde'), findsOneWidget);

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    final saved = _reminders(h).single;
    expect(saved.title, 'Market alışverişi');
    expect(
      [for (final s in saved.subtasks) s.title],
      ['Ekmek', 'Süt', 'Yumurta'],
    );
  });

  testWidgets('"Maddelere böl?" declined keeps one title', (tester) async {
    final h = await _open(tester);
    await _type(tester, '#market ekmek, süt ve yumurta');
    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    final saved = _reminders(h).single;
    expect(saved.title, 'Ekmek, süt ve yumurta');
    expect(saved.subtasks, isEmpty);
  });

  testWidgets('an unknown #tag shows the new-category hint', (tester) async {
    final h = await _open(tester);
    await _type(tester, 'koşu #spor');
    expect(find.text('Yeni kategori: #spor'), findsOneWidget);
    expect(_chip(QuickCaptureKeys.categoryChip), findsNothing);

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h).single.categoryId, ReminderCategoryIds.other);
  });

  testWidgets('#tag matches a user category (F4.3)', (tester) async {
    final h = await _open(tester, categories: const [
      ReminderCategory(
        id: 'gym',
        name: 'Spor Salonu',
        colorKey: 'lacivert',
        iconKey: CategoryIconKeys.fitness,
      ),
    ]);
    await _type(tester, 'koşu #spor_salonu');
    expect(find.text('Yeni kategori: #spor_salonu'), findsNothing);
    expect(
      _chipText(QuickCaptureKeys.categoryChip, 'Spor Salonu'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h).single.categoryId, 'gym');
  });

  testWidgets('"Yeni kategori: #tag" creates the category and uses it',
      (tester) async {
    final h = await _open(tester);
    await _type(tester, 'koşu #spor');
    await tester.tap(find.text('Yeni kategori: #spor'));
    await tester.pumpAndSettle();

    // The category editor opens with the tag as the name.
    final nameField = find.byKey(CategoryEditorKeys.name);
    expect(nameField, findsOneWidget);
    expect(tester.widget<TextField>(nameField).controller!.text, 'Spor');
    await tester.ensureVisible(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CategoryEditorKeys.save));
    await tester.pumpAndSettle();

    final created = h.cubit.state.categories.userCategories.single;
    expect(created.name, 'Spor');
    expect(find.text('Yeni kategori: #spor'), findsNothing);
    expect(_chipText(QuickCaptureKeys.categoryChip, 'Spor'), findsOneWidget);

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h).single.categoryId, created.id);
  });

  testWidgets('priority chip opens the picker', (tester) async {
    final h = await _open(tester);
    await _type(tester, 'rapor yaz');
    await tester.tap(_chip(QuickCaptureKeys.priorityChip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yüksek'));
    await tester.pumpAndSettle();
    expect(
        _chipText(QuickCaptureKeys.priorityChip, '!!! Yüksek'), findsOneWidget);

    await tester.tap(find.byKey(QuickCaptureKeys.save));
    await tester.pumpAndSettle();
    expect(_reminders(h).single.priority, 3);
  });

  testWidgets('"Tüm ayrıntılar" opens the editor prefilled', (tester) async {
    final h = await _open(tester);
    await _type(tester, sentence);

    await tester.tap(find.byKey(QuickCaptureKeys.details));
    await tester.pumpAndSettle();

    expect(_field, findsNothing);
    expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
    final title =
        tester.widget<TextField>(find.byKey(ReminderEditorKeys.title));
    expect(title.controller!.text, 'Ekmek ve süt al');
    expect(find.text('18:00'), findsWidgets);
    expect(_reminders(h), isEmpty);

    await tester.ensureVisible(find.byKey(ReminderEditorKeys.save));
    await tester.tap(find.byKey(ReminderEditorKeys.save));
    await tester.pumpAndSettle();
    final saved = _reminders(h).single;
    expect(saved.title, 'Ekmek ve süt al');
    expect(saved.remindAt, DateTime(2026, 9, 18, 18));
    expect(saved.categoryId, ReminderCategoryIds.market);
    expect(saved.priority, 2);
  });

  testWidgets('a new token plays the selection haptic once', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _open(tester);

    await _type(tester, 'süt al');
    expect(calls, isEmpty);
    await _type(tester, 'süt al yarın');
    expect(calls, ['HapticFeedbackType.selectionClick']);
    await _type(tester, 'süt al yarın ');
    expect(calls, hasLength(1));
  });

  testWidgets('opens with a short fade under Reduce Motion', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await UiHarness.create(now: _clock);
    await tester.pumpWidget(
      h.app(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: _openKey,
              onPressed: () => showQuickCaptureSheet(context, now: _clock),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final route = ModalRoute.of(tester.element(_field))!;
    expect(route.animation!.status, AnimationStatus.completed);
  });
}
