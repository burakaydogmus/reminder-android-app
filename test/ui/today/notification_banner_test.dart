import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/today/today_page.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

final _banner = find.byKey(TodayPageKeys.notificationBanner);

void main() {
  for (final (themeName, theme) in korThemes) {
    group('Bugün notification banner ($themeName)', () {
      testWidgets('shown when denied and a reminder is timed', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(remindAt: _now.add(const Duration(hours: 2))),
          ],
        );
        h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
          notifications: NotificationPermissionState.denied,
        );
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();

        expect(_banner, findsOneWidget);
        expect(find.text('Bildirimler kapalı'), findsOneWidget);
        expect(
            find.text('Hatırlatmalar zamanında gelmeyecek.'), findsOneWidget);

        await tester.tap(find.text('Ayarları aç'));
        await tester.pumpAndSettle();
        expect(h.permissions.calls, ['openNotificationSettings']);
      });

      testWidgets('hidden when notifications are granted', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(remindAt: _now.add(const Duration(hours: 2))),
          ],
        );
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();
        expect(_banner, findsNothing);
      });

      testWidgets('hidden without timed reminders', (tester) async {
        final h = await UiHarness.create(
          reminders: [
            buildReminder(id: 'untimed'),
            buildReminder(
              id: 'done',
              isDone: true,
              remindAt: _now.add(const Duration(hours: 1)),
            ),
          ],
        );
        h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
          notifications: NotificationPermissionState.denied,
        );
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();
        expect(_banner, findsNothing);
      });

      testWidgets('never asked: shown for birthdays, "İzin ver" requests',
          (tester) async {
        final h = await UiHarness.create(birthdays: [buildBirthday()]);
        h.permissions.snapshot = PermissionSnapshot.allGranted.copyWith(
          notifications: NotificationPermissionState.notRequested,
        );
        await tester.pumpWidget(
          h.app(home: const HomeShell(clock: _clock), theme: theme),
        );
        await tester.pumpAndSettle();
        expect(_banner, findsOneWidget);
        expect(
          find.descendant(of: _banner, matching: find.text('Ayarları aç')),
          findsNothing,
        );

        await tester.tap(
          find.descendant(of: _banner, matching: find.text('İzin ver')),
        );
        await tester.pumpAndSettle();
        expect(h.permissions.calls, ['requestNotifications']);
        // The fake grants it: the banner goes away.
        expect(_banner, findsNothing);
      });
    });
  }
}
