import 'package:material_ui/material_ui.dart';
import 'package:flutter/physics.dart';

/// Spring token as plain data (damping ratio + stiffness, mass 1).
///
/// Values are androidx `ExpressiveMotionTokens`; kept package-free so F4.7 can
/// map them onto `motor` later.
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

  @override
  bool operator ==(Object other) =>
      other is KorSpring &&
      other.dampingRatio == dampingRatio &&
      other.stiffness == stiffness &&
      other.spatial == spatial;

  @override
  int get hashCode => Object.hash(dampingRatio, stiffness, spatial);
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
