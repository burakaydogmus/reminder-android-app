import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_widgets.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Step 2/4 "Yazman yeterli": a scripted typing demo. There is no parsing
/// here — the token ranges and the resulting card are fixed (the real
/// Turkish parser is F4.6).
class CaptureDemoStep extends StatelessWidget {
  const CaptureDemoStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepFrame(
      index: 1,
      footer: [
        OnboardingPrimaryButton(
          key: OnboardingKeys.next,
          label: context.l10n.onboardingContinue,
          onPressed: onNext,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KorSpacing.s5),
          const CaptureDemo(),
          const SizedBox(height: KorSpacing.s9),
          OnboardingCopy(
            title: context.l10n.onboardingCaptureTitle,
            body: context.l10n.onboardingCaptureBody,
          ),
        ],
      ),
    );
  }
}

/// Self-typing capture field + parsed preview card.
class CaptureDemo extends StatefulWidget {
  const CaptureDemo({super.key});

  /// The scripted sentence (starts with [whenToken], ends with
  /// [categoryToken]) and its parsed card, in the app language.
  static String sentence(AppLocalizations l10n) => l10n.onboardingDemoSentence;
  static String whenToken(AppLocalizations l10n) => l10n.onboardingDemoWhen;
  static String categoryToken(AppLocalizations l10n) =>
      l10n.onboardingDemoCategory;
  static String cardTitle(AppLocalizations l10n) =>
      l10n.onboardingDemoCardTitle;
  static String cardMeta(AppLocalizations l10n) => l10n.onboardingDemoCardMeta;

  /// Phases of the one-shot animation (fractions of its duration).
  static const typingEnd = 0.6;
  static const highlightStart = 0.62;
  static const highlightEnd = 0.72;
  static const cardStart = 0.76;

  @override
  State<CaptureDemo> createState() => _CaptureDemoState();
}

class _CaptureDemoState extends State<CaptureDemo>
    with SingleTickerProviderStateMixin, OneShotAnimation {
  @override
  Duration get oneShotDuration => const Duration(milliseconds: 3200);

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.onboardingDemoSpoken(
        CaptureDemo.sentence(context.l10n),
        CaptureDemo.cardTitle(context.l10n),
      ),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(context, t),
                const SizedBox(height: KorSpacing.s6),
                if (t >= CaptureDemo.cardStart)
                  Opacity(
                    opacity: Curves.easeOut.transform(
                      _interval(t, CaptureDemo.cardStart, 1),
                    ),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        12 *
                            (1 -
                                Curves.easeOutCubic.transform(
                                  _interval(t, CaptureDemo.cardStart, 1),
                                )),
                      ),
                      child: const _ParsedCard(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _field(BuildContext context, double t) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final elevation = isDark ? KorElevation.dark : KorElevation.light;
    final health =
        CategoryVisuals.colorsOf(context, ReminderCategoryIds.health);

    final l10n = context.l10n;
    final sentence = CaptureDemo.sentence(l10n);
    final typed =
        (sentence.length * _interval(t, 0, CaptureDemo.typingEnd)).round();
    final highlight = _interval(
      t,
      CaptureDemo.highlightStart,
      CaptureDemo.highlightEnd,
    );
    final base = theme.textTheme.bodyLarge!.copyWith(color: scheme.onSurface);

    final whenEnd = CaptureDemo.whenToken(l10n).length;
    final categoryStart =
        sentence.length - CaptureDemo.categoryToken(l10n).length;

    TextSpan span(int start, int end, {Color? bg, Color? fg}) {
      final visibleEnd = typed.clamp(start, end);
      return TextSpan(
        text: sentence.substring(start, visibleEnd),
        style: bg == null || highlight == 0
            ? base
            : base.copyWith(
                backgroundColor: bg.withValues(alpha: highlight),
                color: Color.lerp(base.color, fg, highlight),
              ),
      );
    }

    final typing = typed < sentence.length;
    return Container(
      constraints: const BoxConstraints(minHeight: KorSizes.fab),
      padding: const EdgeInsets.symmetric(
        horizontal: KorSpacing.s5,
        vertical: KorSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: KorRadius.lgAll,
        boxShadow: elevation.level2,
      ),
      child: Row(
        children: [
          Icon(Icons.add_rounded, color: scheme.primary),
          const SizedBox(width: KorSpacing.s4),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  span(
                    0,
                    whenEnd,
                    bg: scheme.primaryContainer,
                    fg: scheme.onPrimaryContainer,
                  ),
                  span(whenEnd, categoryStart),
                  span(
                    categoryStart,
                    sentence.length,
                    bg: health.container,
                    fg: health.fg,
                  ),
                  if (typing)
                    TextSpan(
                      text: '|',
                      style: base.copyWith(color: scheme.primary),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedCard extends StatelessWidget {
  const _ParsedCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(KorSpacing.cardPaddingCompact),
      decoration: korCardDecoration(context),
      child: Row(
        children: [
          const CategoryIconBadge(categoryId: ReminderCategoryIds.health),
          const SizedBox(width: KorSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CaptureDemo.cardTitle(context.l10n),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: KorSpacing.s1),
                Text(
                  CaptureDemo.cardMeta(context.l10n),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
