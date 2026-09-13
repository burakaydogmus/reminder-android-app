import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Layout of one onboarding step: scrollable content (text scaling up to
/// 200% never overflows) and a footer with page dots and actions.
///
/// The whole step is one semantics container labelled "Adım n / 4".
class OnboardingStepFrame extends StatelessWidget {
  const OnboardingStepFrame({
    super.key,
    required this.index,
    required this.child,
    required this.footer,
  });

  /// Zero-based step index.
  final int index;
  final Widget child;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Adım ${index + 1} / ${OnboardingFlow.stepCount}',
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: KorSpacing.s7,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KorSpacing.s7,
              KorSpacing.s4,
              KorSpacing.s7,
              KorSpacing.s5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageDots(count: OnboardingFlow.stepCount, active: index),
                const SizedBox(height: KorSpacing.s6),
                ...footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator (decorative; the step is announced by the frame).
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.active});

  static const double dotSize = 8;
  static const double activeWidth = 24;

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s2),
              child: Container(
                width: i == active ? activeWidth : dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: i == active ? scheme.primary : scheme.outlineVariant,
                  borderRadius: KorRadius.fullAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width 56 dp pill primary action.
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(KorSizes.fab),
        shape: const StadiumBorder(),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Full-width 48 dp secondary text action.
class OnboardingSecondaryButton extends StatelessWidget {
  const OnboardingSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: KorSpacing.s3),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(KorSizes.minTouch),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Headline + supporting sentence used by every step.
class OnboardingCopy extends StatelessWidget {
  const OnboardingCopy({
    super.key,
    required this.title,
    this.body,
    this.large = true,
  });

  final String title;
  final String? body;

  /// `headlineLarge` (default) or `headlineSmall`.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: large
                ? theme.textTheme.headlineLarge
                : theme.textTheme.headlineSmall,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: KorSpacing.s4),
          Text(
            body!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Runs a one-shot [AnimationController] of [duration] from 0 to 1, or
/// jumps straight to 1 when animations are disabled (Reduce Motion).
mixin OneShotAnimation<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: oneShotDuration,
  );

  Duration get oneShotDuration;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      animation.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      animation.forward();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }
}
