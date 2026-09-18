import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

final _reminder = buildReminder(
  id: 'market',
  title: 'Market alışverişi',
  remindAt: DateTime(2026, 9, 13, 18, 30),
);

Finder get _editorTitle => find.byKey(ReminderEditorKeys.title);

void main() {
  late NotificationTapRouter router;

  setUp(() => router = NotificationTapRouter());

  Future<UiHarness> pumpShell(
    WidgetTester tester, {
    List reminders = const [],
  }) async {
    final h = await UiHarness.create(reminders: [...reminders.cast()]);
    await tester.pumpWidget(
      h.app(home: HomeShell(clock: _clock, tapRouter: router)),
    );
    return h;
  }

  String editorTitleText(WidgetTester tester) =>
      tester.widget<TextField>(_editorTitle).controller!.text;

  testWidgets('cold start: the launch tap opens the editor after load', (
    tester,
  ) async {
    // Launch details are read before runApp; the state is still empty.
    await router.openFromLaunch(
      () async => const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'reminder:market',
        ),
      ),
    );
    final h = await pumpShell(tester);
    await tester.pumpAndSettle();
    expect(router.pending, isNull, reason: 'taken by the shell');
    expect(_editorTitle, findsNothing);

    when(() => h.repository.loadReminders())
        .thenAnswer((_) async => [_reminder]);
    unawaited(h.cubit.load());
    await tester.pumpAndSettle();

    expect(_editorTitle, findsOneWidget);
    expect(editorTitleText(tester), 'Market alışverişi');
    expect(router.pending, isNull);
  });

  testWidgets('warm start: a tap while running opens the editor', (
    tester,
  ) async {
    await pumpShell(tester, reminders: [_reminder]);
    await tester.pumpAndSettle();

    router.openResponse(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'reminder:market',
      ),
    );
    await tester.pumpAndSettle();

    expect(_editorTitle, findsOneWidget);
    expect(editorTitleText(tester), 'Market alışverişi');
  });

  testWidgets('a birthday payload opens Doğum günleri', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    router.open(const BirthdayPayload('b1'));
    await tester.pumpAndSettle();

    expect(find.byType(BirthdaysPage), findsOneWidget);
  });

  testWidgets('a deleted reminder opens nothing', (tester) async {
    await pumpShell(tester, reminders: [_reminder]);
    await tester.pumpAndSettle();

    router.open(const ReminderPayload('deleted'));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(_editorTitle, findsNothing);
    expect(find.byType(BirthdaysPage), findsNothing);
  });
}
