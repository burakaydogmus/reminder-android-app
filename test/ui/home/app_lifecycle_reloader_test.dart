import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/home/widget_change_signal.dart';
import 'package:reminder/ui/home/app_lifecycle_reloader.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

final _start = DateTime(2026, 9, 13, 14, 32);

/// Moves the app to the background (resumed → inactive → hidden → paused).
Future<void> _background(WidgetTester tester) async {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

/// Brings the app back (paused → hidden → inactive → resumed).
Future<void> _foreground(WidgetTester tester) async {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pumpAndSettle();
}

void main() {
  late UiHarness h;
  late DateTime now;
  late int refreshes;
  late List<String> steps;
  late List<Reminder> stored;

  final open = buildReminder(id: 'a', title: 'Kitabı iade et');

  setUp(() async {
    now = _start;
    refreshes = 0;
    steps = [];
    stored = [open];
    h = await UiHarness.create(reminders: [open]);
    // Storage as the widget isolate leaves it; `load()` reads it.
    when(() => h.repository.loadReminders()).thenAnswer((_) async {
      steps.add('load');
      return [...stored];
    });
    clearInteractions(h.repository);
  });

  Widget reloader({required Widget child, bool listen = false}) {
    return AppStateReloader(
      clock: () => now,
      refreshStorage: () async {
        refreshes++;
        steps.add('refreshStorage');
      },
      // F5.2: the iOS widget's completion queue is applied before `load`.
      applyWidgetCompletions: () async => steps.add('applyWidgetCompletions'),
      listenToWidgetChanges: listen,
      child: child,
    );
  }

  Future<void> pumpShell(WidgetTester tester, {bool listen = false}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      h.app(
        home: reloader(
          listen: listen,
          child: HomeShell(clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('startup does not load again', (tester) async {
    await pumpShell(tester);
    // The platform may report resumed right after launch.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verifyNever(() => h.repository.loadReminders());
    expect(refreshes, 0);
  });

  testWidgets('returning from the background reloads from storage', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.text('Kitabı iade et'), findsOneWidget);

    await _background(tester);
    // The widget completes the reminder while the app is in the background.
    stored = [open.copyWith(isDone: true)];
    now = now.add(const Duration(minutes: 5));
    await _foreground(tester);

    expect(refreshes, 1);
    verify(() => h.repository.loadReminders()).called(1);
    expect(h.cubit.state.reminders.single.isDone, isTrue);
  });

  testWidgets(
      'pending iOS widget completions are applied before the cubit loads', (
    tester,
  ) async {
    await pumpShell(tester);

    await _background(tester);
    now = now.add(const Duration(minutes: 5));
    await _foreground(tester);

    // F5.2: applying after `load` would let the stale in-memory state
    // overwrite the completion on the next in-app save (same reason as F1.3).
    expect(steps, ['refreshStorage', 'applyWidgetCompletions', 'load']);
  });

  testWidgets('resume within the throttle window is ignored', (tester) async {
    await pumpShell(tester);

    now = now.add(const Duration(milliseconds: 500));
    await _background(tester);
    await _foreground(tester);
    verifyNever(() => h.repository.loadReminders());

    now = now.add(const Duration(seconds: 2));
    await _background(tester);
    await _foreground(tester);
    verify(() => h.repository.loadReminders()).called(1);

    now = now.add(const Duration(milliseconds: 300));
    await _background(tester);
    await _foreground(tester);
    verifyNever(() => h.repository.loadReminders());
    expect(refreshes, 1);
  });

  testWidgets('inactive → resumed without hiding does not reload', (
    tester,
  ) async {
    await pumpShell(tester);
    now = now.add(const Duration(minutes: 1));

    // Notification shade or a permission dialog.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verifyNever(() => h.repository.loadReminders());
  });

  testWidgets('a widget change signal reloads while in the foreground', (
    tester,
  ) async {
    await pumpShell(tester, listen: true);

    stored = [open.copyWith(isDone: true)];
    notifyAppOfWidgetChange();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(refreshes, 1);
    verify(() => h.repository.loadReminders()).called(1);
    expect(h.cubit.state.reminders.single.isDone, isTrue);
  });

  testWidgets('reload keeps unsaved editor input', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      h.app(
        home: reloader(
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () =>
                      showReminderEditorSheet(context, existing: open),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(ReminderEditorKeys.title),
      'Kitabı yarın iade et',
    );

    await _background(tester);
    stored = [open.copyWith(isDone: true)];
    now = now.add(const Duration(minutes: 5));
    await _foreground(tester);

    verify(() => h.repository.loadReminders()).called(1);
    expect(h.cubit.state.reminders.single.isDone, isTrue);
    expect(find.byKey(ReminderEditorKeys.title), findsOneWidget);
    expect(find.text('Kitabı yarın iade et'), findsOneWidget);
  });
}
