import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';

const _rect = Rect.fromLTWH(0, 0, 100, 100);
const _center = Offset(50, 50);

/// Point at polar [theta] (0 = up, clockwise) and [radius] from the centre.
Offset _polar(double theta, double radius) =>
    _center + Offset(math.sin(theta) * radius, -math.cos(theta) * radius);

/// Angle of the first notch of a 9-lobed cookie.
const _notch = math.pi / 9;

void main() {
  group('CookieShapeBorder', () {
    test('ShapeBorder.lerp from a circle: circle at 0, cookie at 1', () {
      const circle = CircleBorder();
      const cookie = CookieShapeBorder();

      final start = ShapeBorder.lerp(circle, cookie, 0)! as CookieShapeBorder;
      final end = ShapeBorder.lerp(circle, cookie, 1)! as CookieShapeBorder;
      expect(start.depth, 0);
      expect(end.depth, CookieShapeBorder.defaultDepth);
      expect(end.lobes, 9);

      // t = 0 is exactly the circle: a notch point just inside the radius
      // is inside, just outside is not.
      final startPath = start.getOuterPath(_rect);
      expect(startPath.contains(_polar(_notch, 49.5)), isTrue);
      expect(startPath.contains(_polar(_notch, 50.5)), isFalse);

      // t = 1 is the cookie: notches sink by depth, crests touch the rect.
      final endPath = end.getOuterPath(_rect);
      const notchRadius = 50 * (1 - CookieShapeBorder.defaultDepth);
      expect(endPath.contains(_polar(_notch, notchRadius - 1)), isTrue);
      expect(endPath.contains(_polar(_notch, notchRadius + 1)), isFalse);
      expect(endPath.contains(_polar(0, 49)), isTrue);
      expect(endPath.getBounds().top, closeTo(0, 0.01));
    });

    test('lerp back to a circle and between cookies', () {
      const cookie = CookieShapeBorder();
      final back = ShapeBorder.lerp(cookie, const CircleBorder(), 1)!
          as CookieShapeBorder;
      expect(back.depth, 0);

      final half = ShapeBorder.lerp(
        const CookieShapeBorder.circle(),
        cookie,
        0.5,
      )! as CookieShapeBorder;
      expect(half.depth, closeTo(CookieShapeBorder.defaultDepth / 2, 1e-9));
    });

    test('has 9 crests and 9 notches', () {
      const cookie = CookieShapeBorder();
      for (var i = 0; i < 9; i++) {
        final crest = 2 * math.pi * i / 9;
        expect(cookie.radiusFactor(crest), closeTo(1, 1e-9));
        expect(
          cookie.radiusFactor(crest + _notch),
          closeTo(1 - CookieShapeBorder.defaultDepth, 1e-9),
        );
      }
      // Lobes are broader than notches: halfway to a notch the edge has
      // sunk by less than half the depth.
      expect(
        cookie.radiusFactor(_notch / 2),
        greaterThan(1 - CookieShapeBorder.defaultDepth / 2),
      );
    });

    test('paints its side along the outline', () {
      const cookie = CookieShapeBorder(
        side: BorderSide(color: Color(0xFF000000), width: 2),
      );
      expect(cookie.dimensions, const EdgeInsets.all(2));
      expect(
        cookie.scale(2),
        const CookieShapeBorder(
          side: BorderSide(color: Color(0xFF000000), width: 4),
        ),
      );
    });
  });
}
