import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';
import 'package:reminder/ui/reminders/snooze_sheet.dart';
import 'package:reminder/ui/reminders/undo_snack_bar.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

// 13 Sep 2026 is a Sunday.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

const _aliTitle = "Ali'yi kurstan al";
const _bookTitle = 'Kitabı iade et';

List<Reminder> _reminders() => [
      buildReminder(
        id: 'ali',
        title: _aliTitle,
        remindAt: DateTime(2026, 9, 13, 16),
      ),
      buildReminder(id: 'book', title: _bookTitle),
    ];

Future<UiHarness> _pumpShell(
  WidgetTester tester, {
  ThemeData Function()? theme,
}) async {
  final h = await UiHarness.create(reminders: _reminders());
  await tester.pumpWidget(
    theme == null
        ? h.app(home: const HomeShell(clock: _clock))
        : h.app(home: const HomeShell(clock: _clock), theme: theme),
  );
  await tester.pumpAndSettle();
  return h;
}

Reminder? _byId(UiHarness h, String id) =>
    h.cubit.state.reminders.where((r) => r.id == id).firstOrNull;

Finder _card(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byType(ReminderCard),
    );

/// Drags the card by [fraction] of its width (positive = start → end).
/// Touch slop is not part of the swipe offset, so callers keep a margin to
/// the 30 % / 60 % thresholds.
Future<void> _swipe(WidgetTester tester, String title, double fraction) async {
  final card = _card(title);
  final width = tester.getSize(card).width;
  await tester.drag(card, Offset(width * fraction, 0));
  await tester.pumpAndSettle();
}

Future<void> _tapUndo(WidgetTester tester) async {
  await tester.tap(find.text(UndoSnackBar.actionLabel));
  await tester.pumpAndSettle();
}

void _performCustomAction(SemanticsNode node, String label) {
  final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
        (id) => CustomSemanticsAction.getAction(id)!.label == label,
      );
  node.owner!.performAction(node.id, SemanticsAction.customAction, id);
}

SemanticsNode _cardNode(WidgetTester tester, String title) => tester
    .getSemantics(find.bySemanticsLabel(RegExp('^${RegExp.escape(title)},')));

List<String> _customActionLabels(SemanticsNode node) => [
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ?? const <int>[])
        CustomSemanticsAction.getAction(id)!.label ?? '',
    ];

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Reminder swipe ($themeName)', () {
      testWidgets('swipe right completes, Geri al restores', (tester) async {
        final h = await _pumpShell(tester, theme: theme);

        await _swipe(tester, _aliTitle, 0.5);
        expect(_byId(h, 'ali')!.isDone, isTrue);
        expect(find.text('“$_aliTitle” tamamlandı'), findsOneWidget);
        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).duration,
          UndoSnackBar.duration,
        );
        // A completed timed card stays on the Bugün ribbon as a compact row.
        expect(
          find.ancestor(
            of: find.text(_aliTitle),
            matching: find.byType(ReminderCompactCard),
          ),
          findsOneWidget,
        );

        await _tapUndo(tester);
        expect(_byId(h, 'ali')!.isDone, isFalse);
        expect(find.text(_aliTitle), findsOneWidget);
      });

      testWidgets('long swipe left deletes, Geri al restores the same item',
          (tester) async {
        final h = await _pumpShell(tester, theme: theme);
        final original = _byId(h, 'ali')!;

        await _swipe(tester, _aliTitle, -0.8);
        expect(_byId(h, 'ali'), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('“$_aliTitle” silindi'), findsOneWidget);

        await _tapUndo(tester);
        final restored = _byId(h, 'ali');
        expect(restored, same(original));
        expect(restored!.toJson(), original.toJson());
        expect(find.text(_aliTitle), findsOneWidget);
        // Persisted again with the same id.
        final saved = verify(() => h.repository.saveReminders(captureAny()))
            .captured
            .last as List<Reminder>;
        expect(saved.map((r) => r.id), contains('ali'));
      });
    });
  }

  group('Reminder swipe → Ertele', () {
    testWidgets('short swipe left opens the sheet; option applies and undoes',
        (tester) async {
      final h = await _pumpShell(tester);

      await _swipe(tester, _aliTitle, -0.45);
      expect(find.text('Tarih ve saat seç…'), findsOneWidget);
      for (final text in [
        '10 dakika',
        '14:42',
        '1 saat',
        '15:32',
        'Bu akşam',
        '20:00',
        'Yarın sabah',
        'Pzt 09:00',
      ]) {
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(text),
          ),
          findsOneWidget,
          reason: text,
        );
      }
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 13, 16));

      await tester.tap(
        find.byKey(SnoozeSheetKeys.option(SnoozeKind.tomorrowMorning)),
      );
      await tester.pumpAndSettle();
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 14, 9));
      expect(find.text("Yarın 09:00'a ertelendi"), findsOneWidget);

      await _tapUndo(tester);
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 13, 16));
    });

    testWidgets('an untimed reminder gets a time', (tester) async {
      final h = await _pumpShell(tester);

      await _swipe(tester, _bookTitle, -0.45);
      await tester.tap(find.byKey(SnoozeSheetKeys.option(SnoozeKind.oneHour)));
      await tester.pumpAndSettle();
      expect(_byId(h, 'book')!.remindAt, DateTime(2026, 9, 13, 15, 32));
      expect(find.text("15:32'ye ertelendi"), findsOneWidget);
    });

    testWidgets('dismissing the sheet changes nothing', (tester) async {
      final h = await _pumpShell(tester);

      await _swipe(tester, _aliTitle, -0.45);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Tarih ve saat seç…'), findsNothing);
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 13, 16));
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Reminder swipe threshold', () {
    testWidgets(
        'crossing 30 % clicks once; release below the threshold does nothing',
        (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      int clicks() => calls
          .where(
            (c) =>
                c.method == 'HapticFeedback.vibrate' &&
                c.arguments == 'HapticFeedbackType.selectionClick',
          )
          .length;

      final h = await _pumpShell(tester);
      final card = _card(_aliTitle);
      final width = tester.getSize(card).width;
      final restX = tester.getTopLeft(find.text(_aliTitle)).dx;

      final gesture = await tester.startGesture(tester.getCenter(card));
      await gesture.moveBy(const Offset(-30, 0)); // touch slop
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(-width * 0.05, 0));
        await tester.pump();
      }
      expect(clicks(), 1);
      expect(find.text('Ertele'), findsOneWidget); // background label

      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(Offset(width * 0.05, 0));
        await tester.pump();
      }
      expect(clicks(), 1);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Tarih ve saat seç…'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 13, 16));
      expect(_byId(h, 'ali')!.isDone, isFalse);
      expect(tester.getTopLeft(find.text(_aliTitle)).dx, restX);
    });

    testWidgets('Reduce Motion: springs back with the short fade tween',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      final h = await _pumpShell(tester);
      final restX = tester.getTopLeft(find.text(_aliTitle)).dx;
      final card = _card(_aliTitle);
      await tester.drag(card, Offset(-tester.getSize(card).width * 0.2, 0));
      await tester.pump(); // starts the tween
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.getTopLeft(find.text(_aliTitle)).dx, restX);
      expect(_byId(h, 'ali')!.isDone, isFalse);
    });
  });

  group('Reminder action alternatives', () {
    testWidgets('semantics custom actions run the same handlers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await _pumpShell(tester);

      final ali = _cardNode(tester, _aliTitle);
      expect(
        _customActionLabels(ali),
        containsAll(['Tamamla', 'Ertele', 'Düzenle', 'Sil']),
      );

      _performCustomAction(ali, 'Ertele');
      await tester.pumpAndSettle();
      expect(find.text('Tarih ve saat seç…'), findsOneWidget);
      await tester.tap(find.byKey(SnoozeSheetKeys.option(SnoozeKind.evening)));
      await tester.pumpAndSettle();
      expect(_byId(h, 'ali')!.remindAt, DateTime(2026, 9, 13, 20));
      expect(find.text("20:00'ye ertelendi"), findsOneWidget);

      _performCustomAction(_cardNode(tester, _aliTitle), 'Tamamla');
      await tester.pumpAndSettle();
      expect(_byId(h, 'ali')!.isDone, isTrue);
      expect(find.text('“$_aliTitle” tamamlandı'), findsOneWidget);
      // A new action replaced the previous snackbar.
      expect(find.byType(SnackBar), findsOneWidget);

      _performCustomAction(_cardNode(tester, _bookTitle), 'Sil');
      await tester.pumpAndSettle();
      expect(_byId(h, 'book'), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('“$_bookTitle” silindi'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('done cards offer Geri aç and no Ertele', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await UiHarness.create(
        reminders: [
          buildReminder(id: 'done', title: 'Vitamin iç', isDone: true)
        ],
      );
      await tester.pumpWidget(
        h.app(
          home: Scaffold(
            body: ReminderCard(
                reminder: h.cubit.state.reminders.single, now: _now),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = _cardNode(tester, 'Vitamin iç');
      expect(_customActionLabels(node), ['Geri aç', 'Düzenle', 'Sil']);
      _performCustomAction(node, 'Geri aç');
      await tester.pumpAndSettle();
      expect(h.cubit.state.reminders.single.isDone, isFalse);
      expect(find.text('“Vitamin iç” geri açıldı'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('long-press menu: Sil deletes without a confirm dialog',
        (tester) async {
      final h = await _pumpShell(tester);

      await tester.longPress(find.text(_aliTitle));
      await tester.pumpAndSettle();
      for (final label in ['Tamamla', 'Ertele', 'Düzenle', 'Sil']) {
        expect(
          find.descendant(
            of: find.byWidgetPredicate((w) => w is PopupMenuItem),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }

      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(_byId(h, 'ali'), isNull);
      expect(find.text('“$_aliTitle” silindi'), findsOneWidget);

      await _tapUndo(tester);
      expect(_byId(h, 'ali'), isNotNull);
    });

    testWidgets('long-press menu: Tamamla and Ertele', (tester) async {
      final h = await _pumpShell(tester);

      await tester.longPress(find.text(_bookTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ertele'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(SnoozeSheetKeys.option(SnoozeKind.tenMinutes)),
      );
      await tester.pumpAndSettle();
      expect(_byId(h, 'book')!.remindAt, DateTime(2026, 9, 13, 14, 42));

      await tester.longPress(find.text(_aliTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamamla'));
      await tester.pumpAndSettle();
      expect(_byId(h, 'ali')!.isDone, isTrue);
    });

    testWidgets(
        'screen reader: undo snackbar lasts 10 s and focus moves to Geri al',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final semantics = tester.ensureSemantics();
      final events = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          events.add(message);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
      );

      final h = await _pumpShell(tester);
      _performCustomAction(_cardNode(tester, _aliTitle), 'Tamamla');
      await tester.pump();
      await tester.pump();
      expect(_byId(h, 'ali')!.isDone, isTrue);

      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        UndoSnackBar.screenReaderDuration,
      );
      final focusEvents = events
          .whereType<Map<Object?, Object?>>()
          .where((e) => e['type'] == 'focus')
          .toList();
      expect(focusEvents, isNotEmpty);
      final focusedId = focusEvents.last['nodeId'];
      final undoNode = tester.getSemantics(
        find
            .descendant(
              of: find.byType(SnackBarAction),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(undoNode.id, focusedId);
      expect(undoNode.getSemanticsData().label, contains('Geri al'));

      // The dismiss timer starts once the entry animation has completed.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 9));
      expect(find.text(UndoSnackBar.actionLabel), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.text(UndoSnackBar.actionLabel), findsNothing);
      semantics.dispose();
    });

    testWidgets('undo snackbar hides after 5 s without a screen reader',
        (tester) async {
      await _pumpShell(tester);
      await _swipe(tester, _aliTitle, 0.5);
      expect(find.text(UndoSnackBar.actionLabel), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text(UndoSnackBar.actionLabel), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(UndoSnackBar.actionLabel), findsNothing);
    });
  });
}
