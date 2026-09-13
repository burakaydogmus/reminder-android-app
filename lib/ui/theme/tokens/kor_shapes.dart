import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

/// Kor corner radii (`kor-design-proposal.md` §3.1 "Şekil").
abstract final class KorRadius {
  /// Inline token.
  static const double xs = 6;

  /// Chip.
  static const double sm = 10;

  /// Input, snackbar, map preview.
  static const double md = 16;

  /// Reminder card.
  static const double card = 20;

  /// Grouped card, FAB squircle.
  static const double lg = 24;

  /// Hero card, sheet top corners.
  static const double xl = 32;

  /// Nav, capture bar, pill.
  static const double full = 999;

  static const double sheetTop = xl;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(sheetTop));
}

/// The single expressive shape: a 9-lobed "cookie" used by the checked state
/// of `CheckboxMorph` (F4.7).
///
/// [depth] is the lobe depth as a fraction of the radius; `0` is a circle, so
/// animating [depth] from 0 to [defaultDepth] morphs circle → cookie via
/// [lerp]. Minimal implementation; F4.7 may refine the curve.
class CookieShapeBorder extends ShapeBorder {
  const CookieShapeBorder({
    this.lobes = 9,
    this.depth = defaultDepth,
    this.side = BorderSide.none,
  })  : assert(lobes >= 3),
        assert(depth >= 0 && depth < 1);

  static const double defaultDepth = 0.08;

  final int lobes;
  final double depth;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  Path _path(Rect rect) {
    final center = rect.center;
    final radius = rect.shortestSide / 2;
    const steps = 180;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final theta = 2 * math.pi * i / steps;
      // Lobes point outward; valleys sink by `depth * radius`.
      final r = radius * (1 - depth * (1 - math.cos(lobes * theta)) / 2);
      final angle = theta - math.pi / 2;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(side.strokeInset / 2)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) =>
      CookieShapeBorder(lobes: lobes, depth: depth, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CookieShapeBorder && a.lobes == lobes) {
      return CookieShapeBorder(
        lobes: lobes,
        depth: lerpDouble(a.depth, depth, t)!,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    if (a is CircleBorder) {
      return CookieShapeBorder(
        lobes: lobes,
        depth: depth * t,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CookieShapeBorder && b.lobes == lobes) {
      return CookieShapeBorder(
        lobes: lobes,
        depth: lerpDouble(depth, b.depth, t)!,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    if (b is CircleBorder) {
      return CookieShapeBorder(
        lobes: lobes,
        depth: depth * (1 - t),
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is CookieShapeBorder &&
      other.lobes == lobes &&
      other.depth == depth &&
      other.side == side;

  @override
  int get hashCode => Object.hash(lobes, depth, side);
}
