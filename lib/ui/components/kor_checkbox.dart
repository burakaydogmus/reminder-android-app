import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Returns the commit of a [KorCheckbox] toggle; see [KorCheckbox.onToggle].
typedef KorCheckboxToggle = VoidCallback Function();

/// Complete toggle with the Kor completion sequence (§3.5 "Tamamla"):
///
/// | Time       | Event                                                    |
/// |------------|----------------------------------------------------------|
/// | 0 ms       | `KorHaptics.complete`, press 1 → 0.85 → 1 (spatialFast) |
/// | 0–240 ms   | circle → 9-sided cookie morph, [color] fill from centre |
/// | 120–300 ms | ✓ path drawn                                             |
/// | 300–900 ms | hold: the row stays so a mistaken tap can be noticed     |
/// | 900 ms     | the commit returned by [onToggle] runs                   |
///
/// Tapping again during the hold cancels (the circle comes back, nothing is
/// committed). Un-checking commits at once and plays the fill backwards.
/// With Reduce Motion (`MediaQuery.disableAnimationsOf`) there is no press,
/// morph or drawn check and no hold: the commit runs immediately and the
/// checked state fades in over `KorMotion.reduceMotionFade`.
///
/// The visual is [size] (default 26) inside a 48 dp target; [ring] draws an
/// extra outline around the shape (e.g. a high-priority ring).
class KorCheckbox extends StatefulWidget {
  const KorCheckbox({
    super.key,
    required this.value,
    required this.onToggle,
    required this.color,
    required this.onColor,
    this.size = KorSizes.checkboxVisual,
    this.ring,
    this.semanticLabel,
  });

  /// Whether the item is done.
  final bool value;

  /// Called on tap, before the sequence plays; null disables the toggle.
  ///
  /// Capture everything that needs a [BuildContext] here and return the
  /// commit (the actual toggle). The commit runs when the sequence ends — also
  /// when the checkbox is disposed during the hold — so it must not look up
  /// the context again.
  final KorCheckboxToggle? onToggle;

  /// Outline and fill (category `fg`).
  final Color color;

  /// Check mark on the fill (category `onFg`).
  final Color onColor;

  /// Visual diameter.
  final double size;

  /// Optional outline around the shape, 2 px outside it.
  final BorderSide? ring;

  /// Semantics label; defaults to "Tamamla" / "Geri aç".
  final String? semanticLabel;

  /// Scale at the bottom of the press.
  static const double pressScale = 0.85;

  /// Length of the visual timeline (morph, fill, check).
  static const Duration sequence = Duration(milliseconds: 300);

  /// When the commit runs after the tap.
  static const Duration hold = Duration(milliseconds: 900);

  /// Morph and fill: 0–240 ms of [sequence].
  static const Interval morphInterval = Interval(0, 240 / 300);

  /// Check path: 120–300 ms of [sequence].
  static const Interval checkInterval = Interval(120 / 300, 1);

  /// Gap between the shape and [ring].
  static const double ringGap = 2;

  @override
  State<KorCheckbox> createState() => _KorCheckboxState();
}

class _KorCheckboxState extends State<KorCheckbox>
    with TickerProviderStateMixin {
  /// 0 = unchecked, 1 = checked; runs over [KorCheckbox.sequence].
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: KorCheckbox.sequence,
    value: widget.value ? 1 : 0,
  );

  late final AnimationController _scale =
      AnimationController.unbounded(vsync: this, value: 1);

  Timer? _hold;
  VoidCallback? _commit;

  /// Set after a commit: the next widget update carries the new value.
  bool _awaitingValue = false;

  /// Paint as a cross-fade instead of the morph (Reduce Motion).
  bool _fadeOnly = false;

  bool get _pending => _hold != null;

  @override
  void didUpdateWidget(KorCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pending) return;
    if (_awaitingValue || widget.value != oldWidget.value) {
      _awaitingValue = false;
      _animateTo(widget.value);
    }
  }

  @override
  void dispose() {
    // A pending completion still happens when the row goes away.
    if (_pending) {
      _hold!.cancel();
      _hold = null;
      _commit?.call();
    }
    _progress.dispose();
    _scale.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _animateTo(bool checked) {
    final target = checked ? 1.0 : 0.0;
    if (_progress.value == target) return;
    final motion = context.korMotion;
    _fadeOnly = _reduceMotion;
    _progress.animateTo(
      target,
      duration: _fadeOnly
          ? motion.reduceMotionFade
          : (checked ? KorCheckbox.sequence : motion.medium),
      curve: Curves.linear,
    );
  }

  void _handleTap() {
    final onToggle = widget.onToggle;
    if (onToggle == null) return;
    if (_pending) {
      _cancel();
      return;
    }
    final commit = onToggle();
    if (widget.value) {
      // Geri aç: no hold, no haptic.
      _awaitingValue = true;
      commit();
      return;
    }
    unawaited(KorHaptics.of(context).complete());
    if (_reduceMotion) {
      _fadeOnly = true;
      _progress.animateTo(
        1,
        duration: context.korMotion.reduceMotionFade,
        curve: Curves.linear,
      );
      _awaitingValue = true;
      commit();
      return;
    }
    _fadeOnly = false;
    _press();
    _progress.forward(from: 0);
    _commit = commit;
    _hold = Timer(KorCheckbox.hold, _runCommit);
    setState(() {});
  }

  /// 1 → 0.85 → 1 on spatialFast: a spring at rest kicked downwards.
  void _press() {
    final spring = context.korMotion.spatialFast;
    final description = spring.description;
    // Peak displacement of an underdamped spring started at rest with
    // velocity v0 is v0 · k(ζ, ω); solve for the 0.15 dip.
    final omega = math.sqrt(description.stiffness / description.mass);
    final zeta = spring.dampingRatio;
    final omegaD = omega * math.sqrt(1 - zeta * zeta);
    final tPeak = math.atan2(omegaD, zeta * omega) / omegaD;
    final peakPerVelocity =
        math.exp(-zeta * omega * tPeak) * math.sin(omegaD * tPeak) / omegaD;
    final velocity = -(1 - KorCheckbox.pressScale) / peakPerVelocity;
    _scale.animateWith(SpringSimulation(description, 1, 1, velocity));
  }

  void _runCommit() {
    final commit = _commit;
    _hold = null;
    _commit = null;
    _awaitingValue = true;
    if (mounted) setState(() {});
    commit?.call();
  }

  void _cancel() {
    _hold?.cancel();
    _hold = null;
    _commit = null;
    _scale
      ..stop()
      ..value = 1;
    _animateTo(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final checked = widget.value || _pending;
    return Semantics(
      container: true,
      button: true,
      checked: checked,
      enabled: widget.onToggle != null,
      label: widget.semanticLabel ??
          (widget.value
              ? context.l10n.actionReopen
              : context.l10n.actionComplete),
      excludeSemantics: true,
      onTap: widget.onToggle == null ? null : _handleTap,
      child: InkResponse(
        onTap: widget.onToggle == null ? null : _handleTap,
        radius: KorSizes.minTouch / 2,
        child: SizedBox.square(
          dimension: KorSizes.minTouch,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_progress, _scale]),
              builder: (context, _) => Transform.scale(
                scale: _scale.value,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: KorCheckboxPainter(
                    progress: _progress.value,
                    fadeOnly: _fadeOnly,
                    color: widget.color,
                    onColor: widget.onColor,
                    ring: widget.ring,
                    morphCurve: context.korMotion.spatialFast.curve(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a [KorCheckbox] at a point of its timeline ([progress] 0..1 over
/// [KorCheckbox.sequence]).
class KorCheckboxPainter extends CustomPainter {
  KorCheckboxPainter({
    required this.progress,
    required this.fadeOnly,
    required this.color,
    required this.onColor,
    required this.morphCurve,
    this.ring,
  });

  final double progress;
  final bool fadeOnly;
  final Color color;
  final Color onColor;
  final BorderSide? ring;
  final Curve morphCurve;

  static const double _strokeWidth = 2;

  /// Shape depth at [progress]: spatialFast (may overshoot slightly).
  double morphAt(double progress) {
    if (fadeOnly) return progress > 0 ? 1 : 0;
    final t = KorCheckbox.morphInterval.transform(progress);
    return morphCurve.transform(t).clamp(0.0, 1.2);
  }

  double fillAt(double progress) {
    if (fadeOnly) return progress > 0 ? 1 : 0;
    return Curves.easeOutCubic
        .transform(KorCheckbox.morphInterval.transform(progress));
  }

  double checkAt(double progress) {
    if (fadeOnly) return progress > 0 ? 1 : 0;
    return Curves.easeOutCubic
        .transform(KorCheckbox.checkInterval.transform(progress));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Reduce Motion: the unchecked circle under a fading, finished cookie.
    if (fadeOnly) {
      _paintState(canvas, rect, morph: 0, fill: 0, check: 0, opacity: 1);
      if (progress > 0) {
        _paintState(
          canvas,
          rect,
          morph: 1,
          fill: 1,
          check: 1,
          opacity: progress,
        );
      }
      return;
    }
    _paintState(
      canvas,
      rect,
      morph: morphAt(progress),
      fill: fillAt(progress),
      check: checkAt(progress),
      opacity: 1,
    );
  }

  void _paintState(
    Canvas canvas,
    Rect rect, {
    required double morph,
    required double fill,
    required double check,
    required double opacity,
  }) {
    final alpha = color.a * opacity;
    final shape = CookieShapeBorder(
      depth: CookieShapeBorder.defaultDepth * morph,
    );
    final outline = shape.getOuterPath(rect);

    final ring = this.ring;
    if (ring != null && ring.style != BorderStyle.none) {
      final ringRect = rect.inflate(KorCheckbox.ringGap + ring.width / 2);
      canvas.drawPath(
        shape.getOuterPath(ringRect),
        ring.toPaint()
          ..color = ring.color.withValues(alpha: ring.color.a * opacity),
      );
    }

    if (fill > 0) {
      canvas.save();
      canvas.clipPath(outline);
      canvas.drawCircle(
        rect.center,
        rect.shortestSide / 2 * fill,
        Paint()..color = color.withValues(alpha: alpha),
      );
      canvas.restore();
    }

    canvas.drawPath(
      shape.getOuterPath(rect.deflate(_strokeWidth / 2)),
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );

    if (check > 0) {
      final s = rect.shortestSide / 2;
      final c = rect.center;
      final path = Path()
        ..moveTo(c.dx - s * 0.42, c.dy + s * 0.02)
        ..lineTo(c.dx - s * 0.12, c.dy + s * 0.32)
        ..lineTo(c.dx + s * 0.44, c.dy - s * 0.3);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * check),
        Paint()
          ..color = onColor.withValues(alpha: onColor.a * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, s * 0.2)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(KorCheckboxPainter old) =>
      old.progress != progress ||
      old.fadeOnly != fadeOnly ||
      old.color != color ||
      old.onColor != onColor ||
      old.ring != ring;
}
