import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Phone-sized logical surface (390×844, iPhone 16 frame of §3.3).
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Simulates Reduce Motion / Android animation scale 0.
void useReduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
