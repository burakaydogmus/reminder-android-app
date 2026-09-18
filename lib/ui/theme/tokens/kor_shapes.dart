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

/// The single expressive shape: the 9-sided "cookie" of a completed
/// checkbox (`KorCheckbox`, F4.7; §3.1 "M3E şekil vurgusu").
///
/// The outline is a polar curve with [lobes] broad, rounded scallops and
/// narrow notches between them (the androidx `Cookie9Sided` silhouette):
/// `r(θ) = R · (1 − depth · v(θ))`, where `v` is 0 at a lobe's crest and 1 at
/// a notch, sharpened by [notchSharpness]. Lobe crests touch the bounding
/// circle, so the shape never grows past its rect; one crest points up.
///
/// [depth] is the notch depth as a fraction of the radius. `0` is exactly a
/// circle, so [lerpFrom] / [lerpTo] a [CircleBorder] (or
/// `ShapeBorder.lerp(CircleBorder(), CookieShapeBorder(), t)`) morph circle →
/// cookie by animating [depth] from 0 to [defaultDepth].
class CookieShapeBorder extends OutlinedBorder {
  const CookieShapeBorder({
    this.lobes = 9,
    this.depth = defaultDepth,
    super.side,
  })  : assert(lobes >= 3),
        assert(depth >= 0 && depth < 1);

  /// A cookie with no notches: renders as a circle.
  const CookieShapeBorder.circle({this.lobes = 9, super.side}) : depth = 0;

  /// Notch depth of the finished cookie.
  static const double defaultDepth = 0.12;

  /// Exponent applied to the notch profile: > 1 widens the lobes and
  /// narrows the notches.
  static const double notchSharpness = 2;

  /// Outline samples per lobe (smooth at checkbox and hero sizes).
  static const int _samplesPerLobe = 24;

  final int lobes;
  final double depth;

  /// Radius factor at polar angle [theta] (0 = up, clockwise); 1 on a crest,
  /// `1 − depth` in a notch.
  double radiusFactor(double theta) {
    final notch = (1 - math.cos(lobes * theta)) / 2;
    return 1 - depth * math.pow(notch, notchSharpness);
  }

  Path _path(Rect rect) {
    final center = rect.center;
    final radius = rect.shortestSide / 2;
    final path = Path();
    if (depth == 0) {
      return path..addOval(Rect.fromCircle(center: center, radius: radius));
    }
    final steps = lobes * _samplesPerLobe;
    for (var i = 0; i < steps; i++) {
      final theta = 2 * math.pi * i / steps;
      final r = radius * radiusFactor(theta);
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
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final inset = side.strokeInset - side.width / 2;
    canvas.drawPath(_path(rect.deflate(inset)), side.toPaint());
  }

  @override
  CookieShapeBorder copyWith({BorderSide? side, int? lobes, double? depth}) =>
      CookieShapeBorder(
        lobes: lobes ?? this.lobes,
        depth: depth ?? this.depth,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) => copyWith(side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CookieShapeBorder && a.lobes == lobes) {
      return copyWith(
        depth: lerpDouble(a.depth, depth, t),
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    if (a is CircleBorder && a.eccentricity == 0) {
      return copyWith(
        depth: depth * t,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CookieShapeBorder && b.lobes == lobes) {
      return copyWith(
        depth: lerpDouble(depth, b.depth, t),
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    if (b is CircleBorder && b.eccentricity == 0) {
      return copyWith(
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

  @override
  String toString() => 'CookieShapeBorder(lobes: $lobes, depth: $depth, $side)';
}
