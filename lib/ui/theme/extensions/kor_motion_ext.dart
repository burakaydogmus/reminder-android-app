import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

/// Spring token as plain data (damping ratio + stiffness, mass 1).
///
/// Values are androidx `ExpressiveMotionTokens`, driven with Flutter's own
/// [SpringSimulation] (no motion package). APIs that only take a duration and
/// a curve (sheets, implicit animations) use [settleDuration] + [curve].
@immutable
class KorSpring {
  const KorSpring({
    required this.dampingRatio,
    required this.stiffness,
    required this.spatial,
  });

  final double dampingRatio;
  final double stiffness;

  /// Spatial springs move things (may overshoot); effects springs change
  /// colour/opacity and are always critically damped.
  final bool spatial;

  /// A [SpringDescription] for [SpringSimulation].
  SpringDescription get description => SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: dampingRatio,
      );

  /// A spring from 0 to 1 at rest.
  SpringSimulation simulation() => SpringSimulation(
        description,
        0,
        1,
        0,
        tolerance: _settleTolerance,
      );

  static const _settleTolerance = Tolerance(distance: 0.005, velocity: 0.05);
  static final Map<KorSpring, Duration> _settleCache = {};

  /// Time the 0 → 1 spring needs to come to rest (within 0.5 %).
  Duration get settleDuration => _settleCache.putIfAbsent(this, () {
        final sim = simulation();
        var ms = 1;
        while (ms < 5000 && !sim.isDone(ms / 1000)) {
          ms++;
        }
        return Duration(milliseconds: ms);
      });

  /// The 0 → 1 spring as a [Curve] over [settleDuration]. With
  /// [clampOvershoot] the bounce is cut at 1 (for layouts that must not
  /// travel past their end, e.g. a sheet's bottom edge).
  Curve curve({bool clampOvershoot = false}) =>
      _SpringCurve(this, clampOvershoot: clampOvershoot);

  @override
  bool operator ==(Object other) =>
      other is KorSpring &&
      other.dampingRatio == dampingRatio &&
      other.stiffness == stiffness &&
      other.spatial == spatial;

  @override
  int get hashCode => Object.hash(dampingRatio, stiffness, spatial);
}

class _SpringCurve extends Curve {
  _SpringCurve(this.spring, {required this.clampOvershoot});

  final KorSpring spring;
  final bool clampOvershoot;
  late final SpringSimulation _sim = spring.simulation();
  late final double _seconds = spring.settleDuration.inMicroseconds / 1e6;

  @override
  double transformInternal(double t) {
    final x = _sim.x(t * _seconds);
    return clampOvershoot ? math.min(x, 1) : x;
  }
}

/// Result of resolving a [KorSpring] against accessibility settings.
@immutable
class KorMotionSpec {
  const KorMotionSpec.spring(SpringDescription this.spring)
      : duration = null,
        curve = null;

  const KorMotionSpec.tween(Duration this.duration, Curve this.curve)
      : spring = null;

  /// Non-null when a spring should be used.
  final SpringDescription? spring;

  /// Non-null when a fixed-duration tween (fade) should be used instead.
  final Duration? duration;
  final Curve? curve;

  bool get usesSpring => spring != null;
}

/// Kor motion tokens (`kor-design-proposal.md` §3.1 "Hareket").
///
/// Read with `Theme.of(context).extension<KorMotion>()!` or `context.korMotion`.
@immutable
class KorMotion extends ThemeExtension<KorMotion> {
  const KorMotion({
    this.spatialFast = const KorSpring(
      dampingRatio: 0.6,
      stiffness: 800,
      spatial: true,
    ),
    this.spatialDefault = const KorSpring(
      dampingRatio: 0.8,
      stiffness: 380,
      spatial: true,
    ),
    this.spatialSlow = const KorSpring(
      dampingRatio: 0.8,
      stiffness: 200,
      spatial: true,
    ),
    this.effectsFast = const KorSpring(
      dampingRatio: 1,
      stiffness: 3800,
      spatial: false,
    ),
    this.effectsDefault = const KorSpring(
      dampingRatio: 1,
      stiffness: 1600,
      spatial: false,
    ),
    this.effectsSlow = const KorSpring(
      dampingRatio: 1,
      stiffness: 800,
      spatial: false,
    ),
    this.short = const Duration(milliseconds: 120),
    this.medium = const Duration(milliseconds: 240),
    this.long = const Duration(milliseconds: 400),
    this.reduceMotionFade = const Duration(milliseconds: 150),
    this.fallbackCurve = Curves.easeOutCubic,
    this.nowLineGlow = const Duration(milliseconds: 1200),
  });

  /// Checkbox morph, press, chip "pop".
  final KorSpring spatialFast;

  /// Card move, swipe return, nav indicator, reorder.
  final KorSpring spatialDefault;

  /// Sheet open, capture → editor expansion.
  final KorSpring spatialSlow;

  /// Small colour/opacity changes.
  final KorSpring effectsFast;

  /// Fade, tint.
  final KorSpring effectsDefault;

  /// Screen crossfade.
  final KorSpring effectsSlow;

  /// Duration fallbacks where a spring cannot be used.
  final Duration short;
  final Duration medium;
  final Duration long;

  /// Replacement for spatial springs when Reduce Motion is on.
  final Duration reduceMotionFade;
  final Curve fallbackCurve;

  /// One-time ŞİMDİ line glow when Bugün opens (§3.5); none with Reduce
  /// Motion.
  final Duration nowLineGlow;

  static const standard = KorMotion();

  /// Resolves [token]: with [reduceMotion], spatial springs become a
  /// [reduceMotionFade] fade; effects springs stay (they never overshoot).
  KorMotionSpec resolve(KorSpring token, {required bool reduceMotion}) {
    if (reduceMotion && token.spatial) {
      return KorMotionSpec.tween(reduceMotionFade, fallbackCurve);
    }
    return KorMotionSpec.spring(token.description);
  }

  /// [resolve] using `MediaQuery.disableAnimationsOf(context)`.
  KorMotionSpec resolveOf(BuildContext context, KorSpring token) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return resolve(token, reduceMotion: reduceMotion);
  }

  /// Fixed [duration] or [reduceMotionFade] when Reduce Motion is on.
  Duration durationOf(BuildContext context, Duration duration) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduceMotion ? reduceMotionFade : duration;
  }

  /// Sheet entrance on [spatialSlow] (settle time + spring curve, overshoot
  /// clamped so the sheet never lifts off the bottom edge); a
  /// [reduceMotionFade]-long ease with Reduce Motion. Pass to
  /// `showModalBottomSheet(sheetAnimationStyle: ...)`.
  AnimationStyle sheetStyleOf(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      return AnimationStyle(
        duration: reduceMotionFade,
        reverseDuration: reduceMotionFade,
        curve: fallbackCurve,
      );
    }
    return AnimationStyle(
      duration: spatialSlow.settleDuration,
      reverseDuration: medium,
      curve: spatialSlow.curve(clampOvershoot: true),
    );
  }

  @override
  KorMotion copyWith({
    KorSpring? spatialFast,
    KorSpring? spatialDefault,
    KorSpring? spatialSlow,
    KorSpring? effectsFast,
    KorSpring? effectsDefault,
    KorSpring? effectsSlow,
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? reduceMotionFade,
    Curve? fallbackCurve,
    Duration? nowLineGlow,
  }) {
    return KorMotion(
      spatialFast: spatialFast ?? this.spatialFast,
      spatialDefault: spatialDefault ?? this.spatialDefault,
      spatialSlow: spatialSlow ?? this.spatialSlow,
      effectsFast: effectsFast ?? this.effectsFast,
      effectsDefault: effectsDefault ?? this.effectsDefault,
      effectsSlow: effectsSlow ?? this.effectsSlow,
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      reduceMotionFade: reduceMotionFade ?? this.reduceMotionFade,
      fallbackCurve: fallbackCurve ?? this.fallbackCurve,
      nowLineGlow: nowLineGlow ?? this.nowLineGlow,
    );
  }

  /// Motion tokens are not interpolable; switches at the midpoint.
  @override
  KorMotion lerp(covariant ThemeExtension<KorMotion>? other, double t) {
    if (other is! KorMotion) return this;
    return t < 0.5 ? this : other;
  }
}

extension KorMotionContext on BuildContext {
  /// The [KorMotion] of the nearest theme. Requires a theme built by
  /// `KorTheme`.
  KorMotion get korMotion => Theme.of(this).extension<KorMotion>()!;
}
