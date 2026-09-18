import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';

/// An [IndexedStack] (pages keep their state) whose newly selected page
/// fades through (§3.5 "Nav geçişi"): the outgoing page leaves at once, the
/// incoming one fades in on `effectsSlow` and grows 0.96 → 1. With Reduce
/// Motion there is no scale, only the fade (effects springs never
/// overshoot).
class FadeThroughIndexedStack extends StatefulWidget {
  const FadeThroughIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  /// Starting scale of the incoming page.
  static const double enterScale = 0.96;

  @override
  State<FadeThroughIndexedStack> createState() =>
      _FadeThroughIndexedStackState();
}

class _FadeThroughIndexedStackState extends State<FadeThroughIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter =
      AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(FadeThroughIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) return;
    final spring = context.korMotion.effectsSlow;
    _enter
      ..value = 0
      ..animateWith(SpringSimulation(spring.description, 0, 1, 0))
          .whenComplete(() {
        if (mounted) _enter.value = 1;
      });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stack = IndexedStack(index: widget.index, children: widget.children);
    return AnimatedBuilder(
      animation: _enter,
      child: stack,
      builder: (context, child) {
        final t = _enter.value;
        // Same widget structure in every frame, so the pages keep their
        // state.
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: reduceMotion
                ? 1
                : FadeThroughIndexedStack.enterScale +
                    (1 - FadeThroughIndexedStack.enterScale) * t,
            child: child,
          ),
        );
      },
    );
  }
}
