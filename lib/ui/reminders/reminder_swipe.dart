import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// What releasing the card at the current offset would do.
enum ReminderSwipeZone { none, complete, snooze, delete }

/// Swipe actions for a reminder card (§3.5 "Swipe"):
///
/// - start → end past [actionThreshold]: Tamamla (Geri aç on done cards),
///   `success` background;
/// - end → start past [actionThreshold]: Ertele, `tertiary` background
///   (only when [onSnooze] is set);
/// - end → start past [deleteThreshold]: Sil, `error` background.
///
/// Crossing a threshold scales the icon 0.8 → 1.0 and plays
/// `selectionClick` once. Releasing below the threshold springs back
/// (`spatialDefault`, a short fade-length tween with Reduce Motion). Every
/// action must also exist in the long-press menu and the card semantics
/// (WCAG 2.5.7); the gesture itself is hidden from assistive technologies.
class ReminderSwipe extends StatefulWidget {
  const ReminderSwipe({
    super.key,
    required this.done,
    required this.onComplete,
    required this.onSnooze,
    required this.onDelete,
    required this.child,
    this.haptics = const KorHaptics(),
  });

  static const double actionThreshold = 0.3;
  static const double deleteThreshold = 0.6;

  final bool done;
  final VoidCallback onComplete;

  /// Null disables the Ertele zone (e.g. done reminders).
  final VoidCallback? onSnooze;
  final VoidCallback onDelete;
  final KorHaptics haptics;
  final Widget child;

  /// Zone for a signed drag [fraction] of the card width (positive =
  /// start → end).
  static ReminderSwipeZone zoneFor(double fraction, {required bool canSnooze}) {
    if (fraction >= actionThreshold) return ReminderSwipeZone.complete;
    if (fraction <= -deleteThreshold) return ReminderSwipeZone.delete;
    if (canSnooze && fraction <= -actionThreshold) {
      return ReminderSwipeZone.snooze;
    }
    return ReminderSwipeZone.none;
  }

  @override
  State<ReminderSwipe> createState() => _ReminderSwipeState();
}

class _ReminderSwipeState extends State<ReminderSwipe>
    with SingleTickerProviderStateMixin {
  /// Offset in logical pixels, positive = start → end.
  late final AnimationController _offset =
      AnimationController.unbounded(vsync: this)..addListener(_handleOffset);

  ReminderSwipeZone _zone = ReminderSwipeZone.none;
  double _width = 0;
  bool _dragging = false;

  bool get _canSnooze => widget.onSnooze != null;

  double get _fraction => _width == 0 ? 0 : _offset.value / _width;

  double get _sign =>
      Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _handleOffset() {
    final zone = ReminderSwipe.zoneFor(_fraction, canSnooze: _canSnooze);
    if (zone == _zone) return;
    if (_dragging && zone != ReminderSwipeZone.none) {
      widget.haptics.swipeThreshold();
    }
    setState(() => _zone = zone);
  }

  void _handleDragStart(DragStartDetails details) {
    _width = context.size?.width ?? 0;
    _dragging = true;
    _offset.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_width == 0) return;
    final next = _offset.value + (details.primaryDelta ?? 0) * _sign;
    _offset.value = next.clamp(-_width, _width);
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragging = false;
    switch (ReminderSwipe.zoneFor(_fraction, canSnooze: _canSnooze)) {
      case ReminderSwipeZone.complete:
        _settle();
        widget.onComplete();
      case ReminderSwipeZone.snooze:
        _settle();
        widget.onSnooze?.call();
      case ReminderSwipeZone.delete:
        _dismiss();
      case ReminderSwipeZone.none:
        _settle();
    }
  }

  void _handleDragCancel() {
    _dragging = false;
    _settle();
  }

  /// Springs back to rest.
  void _settle() {
    if (_offset.value == 0) return;
    final motion = context.korMotion;
    final spec = motion.resolveOf(context, motion.spatialDefault);
    final TickerFuture run;
    if (spec.usesSpring) {
      run = _offset.animateWith(
        SpringSimulation(spec.spring!, _offset.value, 0, 0),
      );
    } else {
      run = _offset.animateTo(0, duration: spec.duration, curve: spec.curve!);
    }
    // A spring stops within its tolerance; snap exactly to rest. A new drag
    // stops the ticker, which never completes this future.
    run.whenComplete(() {
      if (mounted && !_dragging) _offset.value = 0;
    });
  }

  /// Slides the card out, then deletes.
  Future<void> _dismiss() async {
    final motion = context.korMotion;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _offset.animateTo(
        -_width,
        duration: motion.short,
        curve: motion.fallbackCurve,
      );
    }
    if (!mounted) return;
    widget.onDelete();
    // If the card stays (e.g. the delete did not remove it), bring it back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offset.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      child: AnimatedBuilder(
        animation: _offset,
        child: widget.child,
        builder: (context, child) {
          final value = _offset.value;
          return Stack(
            children: [
              if (value != 0)
                Positioned.fill(child: ExcludeSemantics(child: _background())),
              Transform.translate(
                offset: Offset(value * _sign, 0),
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _background() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kor = context.korColors;
    final startSide = _offset.value > 0;
    final snoozeSide =
        !startSide && _canSnooze && _fraction > -ReminderSwipe.deleteThreshold;

    final (Color bg, Color fg, IconData icon, String label) = startSide
        ? (
            kor.success,
            kor.onSuccess,
            widget.done ? Icons.undo_rounded : Icons.check_rounded,
            widget.done ? 'Geri aç' : 'Tamamla',
          )
        : snoozeSide
            ? (
                scheme.tertiary,
                scheme.onTertiary,
                Icons.snooze_rounded,
                'Ertele'
              )
            : (
                scheme.error,
                scheme.onError,
                Icons.delete_outline_rounded,
                'Sil',
              );

    final armed = startSide
        ? _zone == ReminderSwipeZone.complete
        : _zone == ReminderSwipeZone.snooze ||
            _zone == ReminderSwipeZone.delete;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final iconWidget = AnimatedScale(
      scale: armed ? 1.0 : 0.8,
      duration: reduceMotion ? Duration.zero : context.korMotion.short,
      child: Icon(icon, color: fg),
    );
    final text = Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(color: fg),
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: KorRadius.cardAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s6),
        child: Align(
          alignment: startSide
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: startSide
                ? [iconWidget, const SizedBox(width: KorSpacing.s3), text]
                : [text, const SizedBox(width: KorSpacing.s3), iconWidget],
          ),
        ),
      ),
    );
  }
}
