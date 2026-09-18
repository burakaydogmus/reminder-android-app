import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/haptics_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> _recordHaptics(TestWidgetsFlutterBinding binding) {
  final calls = <String>[];
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

Future<void> _playAll(KorHaptics haptics) async {
  await haptics.complete();
  await haptics.swipeThreshold();
  await haptics.tokenRecognized();
  await haptics.undo();
  await haptics.delete();
  await haptics.reorderPickUp();
  await haptics.reorderDrop();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticsStore', () {
    test('defaults to on', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await HapticsStore().isEnabled(), isTrue);
    });

    test('persists the toggle under haptics_enabled_v1', () async {
      SharedPreferences.setMockInitialValues({});
      final store = HapticsStore();
      await store.setEnabled(false);
      expect(await store.isEnabled(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('haptics_enabled_v1'), isFalse);

      await store.setEnabled(true);
      expect(await HapticsStore().isEnabled(), isTrue);
    });

    test('memory store', () async {
      final store = HapticsStore.memory(enabled: false);
      expect(await store.isEnabled(), isFalse);
      await store.setEnabled(true);
      expect(await store.isEnabled(), isTrue);
    });
  });

  group('HapticsController', () {
    test('loads the stored value and notifies', () async {
      final controller = HapticsController(HapticsStore.memory(enabled: false));
      var notified = 0;
      controller.addListener(() => notified++);
      expect(controller.enabled, isTrue);
      await controller.load();
      expect(controller.enabled, isFalse);
      expect(notified, 1);
      controller.dispose();
    });

    test('a user change wins over a late load', () async {
      final store = HapticsStore.memory(enabled: false);
      final controller = HapticsController(store);
      final loading = controller.load();
      await controller.setEnabled(true);
      await loading;
      expect(controller.enabled, isTrue);
      expect(await store.isEnabled(), isTrue);
      controller.dispose();
    });

    test('keeps the default when the store throws', () async {
      final controller = HapticsController(
        HapticsStore(preferences: () => Future.error(StateError('no prefs'))),
      );
      await controller.load();
      expect(controller.enabled, isTrue);
      controller.dispose();
    });
  });

  group('KorHaptics', () {
    test('maps events to the §3.1 table', () async {
      final calls = _recordHaptics(binding);
      await _playAll(const KorHaptics());
      expect(calls, [
        'HapticFeedbackType.mediumImpact', // complete
        'HapticFeedbackType.selectionClick', // swipe threshold
        'HapticFeedbackType.selectionClick', // token recognised
        'HapticFeedbackType.lightImpact', // undo
        'HapticFeedbackType.heavyImpact', // delete
        'HapticFeedbackType.mediumImpact', // reorder pick-up
        'HapticFeedbackType.lightImpact', // reorder drop
      ]);
    });

    test('disabled: every call is a no-op', () async {
      final calls = _recordHaptics(binding);
      await _playAll(const KorHaptics(enabled: false));
      expect(calls, isEmpty);
    });

    testWidgets('of(context) follows the HapticsScope setting', (tester) async {
      final calls = _recordHaptics(binding);
      final store = HapticsStore.memory();
      late BuildContext inner;
      await tester.pumpWidget(
        HapticsScope(
          store: store,
          child: Builder(
            builder: (context) {
              inner = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      await KorHaptics.of(inner).complete();
      expect(calls, hasLength(1));

      await HapticsScope.maybeOf(inner)!.setEnabled(false);
      await tester.pump();
      expect(KorHaptics.of(inner).enabled, isFalse);
      await KorHaptics.of(inner).complete();
      expect(calls, hasLength(1));
      expect(await store.isEnabled(), isFalse);
    });

    testWidgets('without a scope haptics are on', (tester) async {
      late BuildContext inner;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            inner = context;
            return const SizedBox();
          },
        ),
      );
      expect(KorHaptics.of(inner).enabled, isTrue);
      expect(HapticsScope.maybeOf(inner), isNull);
    });
  });
}
