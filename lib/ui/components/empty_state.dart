import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Shared empty state (§3.3.11): 96 px monochrome ember ribbon, headlineSmall
/// title, one bodyLarge sentence and at most one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KorSpacing.s8,
        vertical: KorSpacing.s7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 96,
              child: CustomPaint(
                painter: _EmberRibbonPainter(
                  rail: scheme.outlineVariant,
                  ember: scheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: KorSpacing.s5),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KorSpacing.s6),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _EmberRibbonPainter extends CustomPainter {
  const _EmberRibbonPainter({required this.rail, required this.ember});

  final Color rail;
  final Color ember;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final railPaint = Paint()
      ..color = rail
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 8), Offset(cx, size.height - 8), railPaint);
    final nodePaint = Paint()
      ..color = rail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, size.height * 0.22), 7, nodePaint);
    canvas.drawCircle(Offset(cx, size.height * 0.78), 7, nodePaint);
    canvas.drawCircle(
      Offset(cx, size.height / 2),
      11,
      Paint()..color = ember,
    );
  }

  @override
  bool shouldRepaint(_EmberRibbonPainter old) =>
      old.rail != rail || old.ember != ember;
}
