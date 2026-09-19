import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';

/// Title whose strike-through is **drawn from the start edge to the end
/// edge** when a reminder is completed (§3.5 "Tamamla"), instead of the
/// struck style appearing at once.
///
/// [builder] is called twice with the same layout: once for the open title
/// (`struck: false`) and once for the completed one (`struck: true`, i.e.
/// `TextDecoration.lineThrough` and the muted colour). The struck version is
/// revealed over the open one behind a clip that grows from 0 to the full
/// width, so the line (and the colour change with it) travels across the
/// title. Both calls must return the same text with the same size — only the
/// style may differ — otherwise the two layers do not line up.
///
/// **Motion:** the reveal runs over `KorMotion.effectsDefault`
/// (`settleDuration` ≈ 185 ms with its spring curve), which is the §3.5
/// "120–300 ms" window. It starts when [done] flips, i.e. when the
/// completion is committed (`KorCheckbox.hold`, 900 ms after the tap) and the
/// card is rebuilt — the card does not know about the checkbox's pending
/// sequence. Re-opening a reminder wipes the line back the same way.
///
/// **Reduce Motion** (`MediaQuery.disableAnimationsOf`): no reveal at all,
/// the final state is painted immediately — like the checkbox's morph and
/// check (§3.6 rule 7).
class StrikeThroughTitle extends StatefulWidget {
  const StrikeThroughTitle({
    super.key,
    required this.done,
    required this.builder,
  });

  /// Whether the reminder is completed.
  final bool done;

  /// Builds the title; [struck] decides the completed style.
  final Widget Function(BuildContext context, bool struck) builder;

  @override
  State<StrikeThroughTitle> createState() => _StrikeThroughTitleState();
}

class _StrikeThroughTitleState extends State<StrikeThroughTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.done ? 1 : 0,
  );

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didUpdateWidget(StrikeThroughTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done == oldWidget.done) return;
    final target = widget.done ? 1.0 : 0.0;
    if (_reduceMotion) {
      _controller.value = target;
      return;
    }
    // Isolated widget tests may have no Kor theme; fall back to the tokens.
    final motion =
        (Theme.of(context).extension<KorMotion>() ?? KorMotion.standard)
            .effectsDefault;
    _controller
      ..duration = motion.settleDuration
      ..reverseDuration = motion.settleDuration;
    // The spring curve is applied here (not as a simulation) so the reveal
    // has a definite end: a clip that keeps moving would tear the text.
    if (widget.done) {
      _controller.animateTo(1, curve: motion.curve(clampOvershoot: true));
    } else {
      _controller.animateBack(0, curve: motion.curve(clampOvershoot: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        if (t <= 0) return widget.builder(context, false);
        if (t >= 1) return widget.builder(context, true);
        return Stack(
          children: [
            widget.builder(context, false),
            Positioned.fill(
              child: ClipRect(
                clipper: _EdgeReveal(t, Directionality.of(context)),
                child: widget.builder(context, true),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Reveals [progress] of the width, from the reading start edge.
class _EdgeReveal extends CustomClipper<Rect> {
  const _EdgeReveal(this.progress, this.direction);

  final double progress;
  final TextDirection direction;

  @override
  Rect getClip(Size size) {
    final width = size.width * progress.clamp(0.0, 1.0);
    return direction == TextDirection.rtl
        ? Rect.fromLTWH(size.width - width, 0, width, size.height)
        : Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_EdgeReveal oldClipper) =>
      oldClipper.progress != progress || oldClipper.direction != direction;
}
