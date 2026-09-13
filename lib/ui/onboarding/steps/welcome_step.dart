import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/onboarding/onboarding_flow.dart';
import 'package:reminder/ui/onboarding/onboarding_widgets.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Step 1/4 "Karşılama": time ribbon illustration, headline and "Başla".
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepFrame(
      index: 0,
      footer: [
        OnboardingPrimaryButton(
          key: OnboardingKeys.start,
          label: 'Başla',
          onPressed: onStart,
        ),
      ],
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: KorSpacing.s5),
          TimeRibbonIllustration(),
          SizedBox(height: KorSpacing.s8),
          OnboardingCopy(
            title: 'Aklında kalmasın.',
            body: 'Yaz, zamanını ya da yerini söyle; gerisini Hatırlatıcı '
                'takip etsin.',
          ),
        ],
      ),
    );
  }
}

/// Decorative vertical time ribbon: three nodes settle in one after another
/// and the "şimdi" line glows once. Reduce Motion shows the final frame.
class TimeRibbonIllustration extends StatefulWidget {
  const TimeRibbonIllustration({super.key});

  static const double height = 260;

  @override
  State<TimeRibbonIllustration> createState() => _TimeRibbonIllustrationState();
}

class _TimeRibbonIllustrationState extends State<TimeRibbonIllustration>
    with SingleTickerProviderStateMixin, OneShotAnimation {
  @override
  Duration get oneShotDuration => const Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kor = context.korColors;
    final isDark = theme.brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SizedBox(
            height: TimeRibbonIllustration.height,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimeRibbonPainter(
                progress: animation,
                rail: scheme.outlineVariant,
                card: isDark ? scheme.surfaceContainer : scheme.surface,
                cardLine: scheme.outlineVariant,
                nowLine: kor.nowLine,
                pill: scheme.primary,
                onPill: scheme.onPrimary,
                done: kor.category(KorColorKey.market).fg,
                onDone: kor.category(KorColorKey.market).onFg,
                upcoming: kor.category(KorColorKey.saglik).fg,
                label: scheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelMedium!,
                pillStyle: theme.textTheme.labelSmall!,
                pillText: KorFormat.upperTr('şimdi'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRibbonPainter extends CustomPainter {
  _TimeRibbonPainter({
    required this.progress,
    required this.rail,
    required this.card,
    required this.cardLine,
    required this.nowLine,
    required this.pill,
    required this.onPill,
    required this.done,
    required this.onDone,
    required this.upcoming,
    required this.label,
    required this.labelStyle,
    required this.pillStyle,
    required this.pillText,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color rail;
  final Color card;
  final Color cardLine;
  final Color nowLine;
  final Color pill;
  final Color onPill;
  final Color done;
  final Color onDone;
  final Color upcoming;
  final Color label;
  final TextStyle labelStyle;
  final TextStyle pillStyle;
  final String pillText;

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset anchor, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? anchor.dx - painter.width : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
    painter.dispose();
  }

  void _cardAt(Canvas canvas, double left, double right, double y, double a) {
    final rect = RRect.fromLTRBR(
      left,
      y - 22,
      right,
      y + 22,
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, Paint()..color = card.withValues(alpha: a));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = cardLine.withValues(alpha: a)
        ..style = PaintingStyle.stroke,
    );
    final bar = Paint()
      ..color = cardLine.withValues(alpha: a)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final width = right - left;
    canvas.drawLine(
      Offset(left + 16, y - 6),
      Offset(left + 16 + width * 0.5, y - 6),
      bar,
    );
    canvas.drawLine(
      Offset(left + 16, y + 8),
      Offset(left + 16 + width * 0.28, y + 8),
      bar,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final w = size.width;
    final h = size.height;
    final railX = w * 0.26;
    final cardLeft = railX + 20;
    final cardRight = w - 8;

    // Rail draws in.
    final railT = Curves.easeOutCubic.transform(_interval(t, 0, 0.35));
    final top = h * 0.06;
    canvas.drawLine(
      Offset(railX, top),
      Offset(railX, top + (h * 0.88) * railT),
      Paint()
        ..color = rail
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Node 1: done (09:00).
    final n1 = _interval(t, 0.1, 0.45);
    if (n1 > 0) {
      final e = Curves.easeOutBack.transform(n1);
      final y = h * 0.2 + (1 - e) * 16;
      _text(
        canvas,
        '09:00',
        labelStyle.copyWith(color: label.withValues(alpha: n1)),
        Offset(railX - 14, y),
        alignRight: true,
      );
      canvas.drawCircle(Offset(railX, y), 9 * e, Paint()..color = done);
      final check = Path()
        ..moveTo(railX - 4, y)
        ..lineTo(railX - 1, y + 3)
        ..lineTo(railX + 4, y - 3);
      canvas.drawPath(
        check,
        Paint()
          ..color = onDone.withValues(alpha: n1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      _cardAt(canvas, cardLeft, cardRight, y, n1);
    }

    // Node 2: "şimdi" line with a single glow.
    final n2 = _interval(t, 0.3, 0.6);
    if (n2 > 0) {
      final e = Curves.easeOutBack.transform(n2);
      final y = h * 0.5;
      final lineStart = w * 0.04;
      final glow = math.sin(math.pi * _interval(t, 0.6, 1.0));
      if (glow > 0) {
        canvas.drawLine(
          Offset(lineStart, y),
          Offset(lineStart + (cardRight - lineStart) * n2, y),
          Paint()
            ..color = nowLine.withValues(alpha: 0.45 * glow)
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawLine(
        Offset(lineStart, y),
        Offset(lineStart + (cardRight - lineStart) * n2, y),
        Paint()
          ..color = nowLine
          ..strokeWidth = 2,
      );
      canvas.drawCircle(Offset(railX, y), 7 * e, Paint()..color = nowLine);

      final pillPainter = TextPainter(
        text:
            TextSpan(text: pillText, style: pillStyle.copyWith(color: onPill)),
        textDirection: TextDirection.ltr,
      )..layout();
      final pillRect = RRect.fromLTRBR(
        lineStart,
        y - 11,
        lineStart + pillPainter.width + 16,
        y + 11,
        const Radius.circular(11),
      );
      canvas.drawRRect(pillRect, Paint()..color = pill.withValues(alpha: n2));
      pillPainter.paint(
        canvas,
        Offset(lineStart + 8, y - pillPainter.height / 2),
      );
      pillPainter.dispose();
    }

    // Node 3: upcoming (18:30).
    final n3 = _interval(t, 0.45, 0.8);
    if (n3 > 0) {
      final e = Curves.easeOutBack.transform(n3);
      final y = h * 0.8 + (1 - e) * 16;
      _text(
        canvas,
        '18:30',
        labelStyle.copyWith(color: label.withValues(alpha: n3)),
        Offset(railX - 14, y),
        alignRight: true,
      );
      canvas.drawCircle(
        Offset(railX, y),
        8 * e,
        Paint()
          ..color = upcoming
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      _cardAt(canvas, cardLeft, cardRight, y, n3);
    }
  }

  @override
  bool shouldRepaint(_TimeRibbonPainter old) =>
      old.progress != progress ||
      old.rail != rail ||
      old.card != card ||
      old.nowLine != nowLine ||
      old.done != done ||
      old.upcoming != upcoming ||
      old.labelStyle != labelStyle;
}
