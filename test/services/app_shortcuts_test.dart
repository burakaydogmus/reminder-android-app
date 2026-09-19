import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:reminder/services/app_shortcuts.dart';
import 'package:reminder/services/widget_launch_router.dart';

/// Records what the router publishes; [launchType] simulates a shortcut that
/// started the app (the plugin reports it while initializing).
class _FakeQuickActions implements QuickActionsPlatform {
  _FakeQuickActions({this.launchType, this.error});

  final String? launchType;
  final Object? error;
  void Function(String type)? handler;
  List<ShortcutItem>? items;

  @override
  Future<void> initialize(void Function(String type) handler) async {
    if (error != null) throw error!;
    this.handler = handler;
    if (launchType != null) handler(launchType!);
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    this.items = items;
  }
}

void main() {
  group('AppShortcut', () {
    test('types, Turkish titles and icons are the persisted contract', () {
      expect(
        [
          for (final s in AppShortcut.values) (s.type, s.title, s.icon),
        ],
        [
          ('new_reminder', 'Yeni hatırlatıcı', 'shortcut_new_reminder'),
          ('market_list', 'Market listesi', 'shortcut_market_list'),
          ('today', 'Bugün', 'shortcut_today'),
          ('new_birthday', 'Yeni doğum günü', 'shortcut_new_birthday'),
        ],
      );
    });

    test('each shortcut maps to its launch target', () {
      expect(AppShortcut.newReminder.target, const NewReminderTarget());
      expect(
        AppShortcut.marketList.target,
        const NewReminderTarget(initialText: '#market '),
      );
      expect(AppShortcut.today.target, const TodayTarget());
      expect(AppShortcut.newBirthday.target, const NewBirthdayTarget());
    });

    test('fromType finds known types only', () {
      for (final s in AppShortcut.values) {
        expect(AppShortcut.fromType(s.type), s);
      }
      expect(AppShortcut.fromType('action_main'), isNull);
      expect(AppShortcut.fromType(''), isNull);
      expect(AppShortcut.fromType(null), isNull);
    });
  });

  group('ShortcutRouter', () {
    late WidgetLaunchRouter launchRouter;
    late ShortcutRouter router;

    setUp(() {
      launchRouter = WidgetLaunchRouter();
      router = ShortcutRouter(router: launchRouter);
    });
    tearDown(() => launchRouter.dispose());

    test('handle queues each type as its target until taken', () {
      var notified = 0;
      launchRouter.addListener(() => notified++);

      for (final s in AppShortcut.values) {
        router.handle(s.type);
        expect(launchRouter.pending, s.target, reason: s.type);
        expect(launchRouter.take(), s.target);
        expect(launchRouter.pending, isNull);
      }
      expect(notified, AppShortcut.values.length);
    });

    test('unknown types are ignored', () {
      var notified = 0;
      launchRouter.addListener(() => notified++);

      router.handle('something_else');

      expect(launchRouter.pending, isNull);
      expect(notified, 0);
    });

    test('attach publishes the four shortcuts in order', () async {
      final platform = _FakeQuickActions();

      await router.attach(platform);

      expect(
        [
          for (final item in platform.items!)
            (item.type, item.localizedTitle, item.icon),
        ],
        [for (final s in AppShortcut.values) (s.type, s.title, s.icon)],
      );
      expect(launchRouter.pending, isNull);

      // Warm start: a later tap arrives through the registered handler.
      platform.handler!('today');
      expect(launchRouter.pending, const TodayTarget());
    });

    test('cold start: the launching shortcut is queued', () async {
      await router.attach(_FakeQuickActions(launchType: 'market_list'));

      expect(
        launchRouter.pending,
        const NewReminderTarget(initialText: '#market '),
      );
    });

    test('a plugin failure does not break startup', () async {
      await expectLater(
        router.attach(
          _FakeQuickActions(error: MissingPluginException('no plugin')),
        ),
        completes,
      );
      expect(launchRouter.pending, isNull);
    });
  });
}
