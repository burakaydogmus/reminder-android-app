import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_widgets.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Step 4/4 "Hazır": one-time ember burst, suggestions, "Uygulamaya geç".
class ReadyStep extends StatelessWidget {
  const ReadyStep({
    super.key,
    required this.onCreateMarketList,
    required this.onAddBirthday,
    required this.onPinWidget,
    required this.onEnterApp,
  });

  final VoidCallback onCreateMarketList;
  final VoidCallback onAddBirthday;
  final VoidCallback onPinWidget;
  final VoidCallback onEnterApp;

  @override
  Widget build(BuildContext context) {
    final market =
        CategoryVisuals.colorsOf(context, ReminderCategoryIds.market);
    final birthday = CategoryVisuals.birthdayColorsOf(context);
    return OnboardingStepFrame(
      index: 3,
      footer: [
        OnboardingPrimaryButton(
          key: OnboardingKeys.enterApp,
          label: 'Uygulamaya geç',
          onPressed: onEnterApp,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KorSpacing.s5),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: EmberBurst(),
          ),
          const SizedBox(height: KorSpacing.s7),
          const OnboardingCopy(
            title: 'Hazırsın.',
            body: 'İlk hatırlatıcını ekleyelim mi?',
          ),
          const SizedBox(height: KorSpacing.s7),
          GroupedCard(
            padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
            children: [
              _SuggestionRow(
                key: OnboardingKeys.marketSuggestion,
                icon: CategoryVisuals.iconFor(ReminderCategoryIds.market),
                iconColor: market.fg,
                label: 'Market listesi oluştur',
                onTap: onCreateMarketList,
              ),
              _SuggestionRow(
                key: OnboardingKeys.birthdaySuggestion,
                icon: CategoryVisuals.birthdayIcon,
                iconColor: birthday.fg,
                label: 'Bir doğum günü ekle',
                onTap: onAddBirthday,
              ),
              if (PlatformChrome.isAndroid(context))
                _SuggestionRow(
                  key: OnboardingKeys.widgetSuggestion,
                  icon: Icons.widgets_rounded,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  label: 'Ana ekrana widget ekle',
                  onTap: onPinWidget,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: KorSizes.fab,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KorSpacing.s5,
        ),
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: theme.textTheme.bodyLarge),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 96 px ember: a cookie shape pops in and six sparks fly out once.
/// Reduce Motion shows the settled shape without sparks.
class EmberBurst extends StatefulWidget {
  const EmberBurst({super.key});

  static const double size = 96;

  @override
  State<EmberBurst> createState() => _EmberBurstState();
}

class _EmberBurstState extends State<EmberBurst>
    with SingleTickerProviderStateMixin, OneShotAnimation {
  @override
  Duration get oneShotDuration => const Duration(milliseconds: 1100);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: EmberBurst.size,
        child: CustomPaint(
          painter: _EmberBurstPainter(
            progress: animation,
            ember: scheme.primary,
            onEmber: scheme.onPrimary,
            spark: scheme.primary,
          ),
        ),
      ),
    );
  }
}

class _EmberBurstPainter extends CustomPainter {
  _EmberBurstPainter({
    required this.progress,
    required this.ember,
    required this.onEmber,
    required this.spark,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color ember;
  final Color onEmber;
  final Color spark;

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Sparks: fly out and fade (gone at the end).
    final sparkT = _interval(t, 0.15, 1);
    if (sparkT > 0 && sparkT < 1) {
      final paint = Paint()
        ..color = spark.withValues(alpha: 1 - sparkT)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final travel = Curves.easeOutCubic.transform(sparkT);
      for (var i = 0; i < 6; i++) {
        final angle = -math.pi / 2 + i * math.pi / 3;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final from = center + dir * (radius * (0.55 + 0.35 * travel));
        final to = center + dir * (radius * (0.7 + 0.3 * travel));
        canvas.drawLine(from, to, paint);
      }
    }

    // Cookie pops in (circle → 9 lobes).
    final popT = _interval(t, 0, 0.55);
    final scale = Curves.easeOutBack.transform(popT);
    final shapeRadius = radius * 0.62 * scale;
    if (shapeRadius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: shapeRadius);
    final shape = CookieShapeBorder(
      depth: CookieShapeBorder.defaultDepth * Curves.easeOut.transform(popT),
    );
    canvas.drawPath(shape.getOuterPath(rect), Paint()..color = ember);

    final checkT = _interval(t, 0.4, 0.75);
    if (checkT > 0) {
      final s = shapeRadius;
      final check = Path()
        ..moveTo(center.dx - s * 0.38, center.dy + s * 0.02)
        ..lineTo(center.dx - s * 0.1, center.dy + s * 0.3)
        ..lineTo(center.dx + s * 0.42, center.dy - s * 0.28);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkT),
        Paint()
          ..color = onEmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_EmberBurstPainter old) =>
      old.progress != progress || old.ember != ember || old.onEmber != onEmber;
}
