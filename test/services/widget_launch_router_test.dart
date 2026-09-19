import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/widget_launch_router.dart';

void main() {
  group('WidgetLaunchTarget.parse', () {
    test('known addresses', () {
      expect(
        WidgetLaunchTarget.parse(Uri.parse('reminderwidget://new')),
        const NewReminderTarget(),
      );
      expect(
        WidgetLaunchTarget.parse(Uri.parse('reminderwidget://open?id=a%20b')),
        const OpenReminderTarget('a b'),
      );
      expect(
        WidgetLaunchTarget.parse(Uri.parse('reminderwidget://birthday?id=b1')),
        const OpenBirthdayTarget('b1'),
      );
      expect(
        WidgetLaunchTarget.parse(Uri.parse('reminderwidget://permissions')),
        const PermissionsTarget(),
      );
    });

    test('unknown, incomplete or foreign addresses are ignored', () {
      for (final uri in [
        null,
        Uri.parse('reminderwidget://toggle?id=r1'),
        Uri.parse('reminderwidget://open'),
        Uri.parse('reminderwidget://open?id='),
        Uri.parse('reminderwidget://birthday'),
        Uri.parse('reminderwidget://other'),
        Uri.parse('homewidget://new'),
        Uri.parse('https://example.com/new'),
      ]) {
        expect(WidgetLaunchTarget.parse(uri), isNull, reason: '$uri');
      }
    });
  });

  group('WidgetLaunchRouter', () {
    late WidgetLaunchRouter router;

    setUp(() => router = WidgetLaunchRouter());
    tearDown(() => router.dispose());

    test('open keeps the latest target until taken, then clears', () {
      var notified = 0;
      router.addListener(() => notified++);

      router.open(Uri.parse('reminderwidget://open?id=r1'));
      router.open(Uri.parse('reminderwidget://new'));
      expect(notified, 2);
      expect(router.pending, const NewReminderTarget());

      expect(router.take(), const NewReminderTarget());
      expect(router.pending, isNull);
      expect(router.take(), isNull);
    });

    test('an unknown address neither replaces nor notifies', () {
      var notified = 0;
      router.open(Uri.parse('reminderwidget://permissions'));
      router.addListener(() => notified++);

      router.open(Uri.parse('reminderwidget://toggle?id=r1'));
      router.open(null);

      expect(notified, 0);
      expect(router.pending, const PermissionsTarget());
    });

    test('attach queues the cold-start target and follows clicks', () async {
      final clicks = StreamController<Uri?>();
      await router.attach(
        initialLaunch: () async => Uri.parse('reminderwidget://birthday?id=b1'),
        clicks: clicks.stream,
      );
      // Nothing takes it until HomeShell exists (after onboarding).
      expect(router.pending, const OpenBirthdayTarget('b1'));
      expect(router.take(), const OpenBirthdayTarget('b1'));

      clicks.add(Uri.parse('reminderwidget://open?id=r9'));
      await Future<void>.delayed(Duration.zero);
      expect(router.take(), const OpenReminderTarget('r9'));

      await clicks.close();
    });

    test('a normal launch (no widget uri) queues nothing', () async {
      await router.attach(
        initialLaunch: () async => null,
        clicks: const Stream.empty(),
      );
      expect(router.pending, isNull);
    });

    test('a failing launch channel is treated as a normal launch', () async {
      await router.attach(
        initialLaunch: () async => throw StateError('no channel'),
        clicks: Stream<Uri?>.error(StateError('no channel')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(router.pending, isNull);
    });
  });
}
