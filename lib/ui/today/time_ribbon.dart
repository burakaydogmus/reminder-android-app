import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/theme/tokens/kor_typography.dart';

/// Keys for tests.
abstract final class TimeRibbonKeys {
  static const nowLine = Key('ribbon.nowLine');
  static const nowPill = Key('ribbon.nowPill');
  static Key gutter(String id) => Key('ribbon.gutter.$id');
}

/// Time ribbon geometry (`kor-screens.json` today.timeline): gutter 56,
/// rail at x = 64, card from x = 80, node 10 px.
abstract final class TimeRibbon {
  static const double gutter = KorSizes.timeGutter;
  static const double railColumn = 24;
  static const double railX = 8; // inside the rail column → x = 64
  static const double railWidth = 2;
  static const double node = 10;
  static const double nowLineMinHeight = 28;
  static const double nowPillHeight = 22;
  static const double compactHeight = 56;

  /// Above this text scale the gutter and rail go away and the time moves
  /// into the card (§3.3.2, §3.6 rule 6).
  static const double singleColumnScale = 1.3;

  /// One-time ŞİMDİ glow (`KorMotion.nowLineGlow`).
  static Duration glowDuration(BuildContext context) =>
      context.korMotion.nowLineGlow;

  static bool singleColumn(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(100) / 100 > singleColumnScale;
}

/// One reminder on the ribbon: time in the gutter, rail node (filled when
/// done), card on the right. Completed items render as a compact 56 h row.
/// The card stays one semantics node; gutter and rail are decorative.
class TimeRibbonRow extends StatelessWidget {
  const TimeRibbonRow({super.key, required this.reminder, required this.now});

  final Reminder reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final at = reminder.remindAt!.toLocal();
    final done = reminder.isDone;
    final single = TimeRibbon.singleColumn(context);
    final category = CategoryVisuals.colorsOf(context, reminder.categoryId);

    final Widget card;
    if (done) {
      card = ReminderCompactCard(
        reminder: reminder,
        now: now,
        subtitle: TextSpan(
          children: [
            if (single)
              TextSpan(
                text: '${KorFormat.time(at)}  ·  ',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            TextSpan(
              text: CategoryVisuals.labelOf(context, reminder.categoryId),
              style: TextStyle(color: category.fg),
            ),
          ],
        ),
      );
    } else {
      card = ReminderCard(
        reminder: reminder,
        now: now,
        timeStyle:
            single ? ReminderTimeStyle.timeOnly : ReminderTimeStyle.hidden,
      );
    }

    if (single) {
      return Padding(
        padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
        child: card,
      );
    }

    // Node centred on the first line of the card.
    final nodeY = (done ? TimeRibbon.compactHeight : 64) / 2;
    return Stack(
      children: [
        PositionedDirectional(
          start: TimeRibbon.gutter,
          top: 0,
          bottom: 0,
          width: TimeRibbon.railColumn,
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _RailPainter(
                rail: scheme.outlineVariant,
                node: category.fg,
                filled: done,
                nodeY: nodeY,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          top: 0,
          width: TimeRibbon.gutter,
          height: nodeY * 2,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: KorSpacing.s3),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    KorFormat.time(at),
                    key: TimeRibbonKeys.gutter(reminder.id),
                    style: KorTypography.timeLabel.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: TimeRibbon.gutter + TimeRibbon.railColumn,
            bottom: KorSpacing.cardGap,
          ),
          child: card,
        ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.rail,
    required this.node,
    required this.filled,
    required this.nodeY,
  });

  final Color rail;
  final Color node;
  final bool filled;
  final double nodeY;

  @override
  void paint(Canvas canvas, Size size) {
    const x = TimeRibbon.railX;
    canvas.drawLine(
      const Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = rail
        ..strokeWidth = TimeRibbon.railWidth,
    );
    final center = Offset(x, math.min(nodeY, size.height / 2));
    const r = TimeRibbon.node / 2;
    if (filled) {
      canvas.drawCircle(center, r, Paint()..color = node);
    } else {
      // Background-coloured hole is not needed: the ring sits on the rail.
      canvas.drawCircle(
        center,
        r - 1,
        Paint()
          ..color = node
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.rail != rail ||
      old.node != node ||
      old.filled != filled ||
      old.nodeY != nodeY;
}

/// ŞİMDİ line: 2 px `nowLine` from the gutter to the edge with a `primary`
/// time pill. Placed by the caller between ribbon rows; the shell's minute
/// tick moves it without animation. With [playGlow] and motion allowed it
/// glows once for `KorMotion.nowLineGlow` (1.2 s, §3.5 nowLine); never with
/// Reduce Motion.
class NowLine extends StatefulWidget {
  const NowLine({super.key, required this.now, this.playGlow = false});

  final DateTime now;
  final bool playGlow;

  @override
  State<NowLine> createState() => _NowLineState();
}

class _NowLineState extends State<NowLine> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.playGlow && !MediaQuery.disableAnimationsOf(context)) {
      _glow
        ..duration = TimeRibbon.glowDuration(context)
        ..forward();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lineColor = context.korColors.nowLine;
    final single = TimeRibbon.singleColumn(context);
    final time = KorFormat.time(widget.now);

    return Semantics(
      container: true,
      label: context.l10n.todayNowSpoken(
        KorFormat.spokenTime(widget.now, context.l10n),
      ),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TimeRibbon.nowLineMinHeight,
          ),
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final double t =
                  _glow.isAnimating ? math.sin(math.pi * _glow.value) : 0.0;
              return Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: single ? 0 : TimeRibbon.gutter,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: lineColor,
                            boxShadow: t > 0
                                ? [
                                    BoxShadow(
                                      color: lineColor.withValues(
                                        alpha: 0.5 * t,
                                      ),
                                      blurRadius: 8 * t,
                                      spreadRadius: t,
                                    ),
                                  ]
                                : null,
                          ),
                          child: const SizedBox(
                            height: TimeRibbon.railWidth,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!single)
                    PositionedDirectional(
                      start: TimeRibbon.gutter +
                          TimeRibbon.railX -
                          TimeRibbon.node / 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: lineColor,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            dimension: TimeRibbon.node,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: KorSpacing.s2,
                    ),
                    child: ConstrainedBox(
                      key: TimeRibbonKeys.nowPill,
                      constraints: const BoxConstraints(
                        minHeight: TimeRibbon.nowPillHeight,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: KorRadius.fullAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KorSpacing.s3,
                            vertical: KorSpacing.s1,
                          ),
                          child: Text(
                            time,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
