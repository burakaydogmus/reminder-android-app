import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';

import '../ui_harness.dart';
import 'a11y_audit.dart';

/// F4.5 audit: the four onboarding steps (§3.3.1) on a phone-sized screen;
/// each step scrolls, so 200 % text must not overflow.
const _phone = Size(390, 844);

void main() {
  for (var step = 0; step < 4; step++) {
    a11yAudit(
      'Onboarding adım ${step + 1}',
      (tester, variant) async {
        final h = await UiHarness.create();
        await tester.pumpWidget(
          h.app(
            theme: variant.theme,
            platform: variant.platform,
            language: variant.language,
            home: OnboardingFlow(
              initialPage: step,
              onSkip: () {},
              onFinish: ([_]) {},
              pinWidget: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
      platforms: const [TargetPlatform.android, TargetPlatform.iOS],
      surface: _phone,
    );
  }
}
