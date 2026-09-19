import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// OSMF tile policy attribution: "flutter_map | © OpenStreetMap
/// contributors" at the bottom left of the map, linking to the copyright
/// page (F6.2b).
///
/// Replaces `SimpleAttributionWidget` for §3.6: the visible box stays small
/// (labelSmall, 3 px padding) but the tap area is at least 48×48 dp, the text
/// wraps at large text scales instead of overflowing, and it keeps clear of
/// [endInset] (the "Konumuma git" button).
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({
    super.key,
    required this.onTap,
    this.endInset = KorSizes.minTouch + KorSpacing.s4 * 2,
  });

  static const source = 'OpenStreetMap contributors';

  final VoidCallback onTap;

  /// Space kept free at the end (the map's corner button).
  final double endInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface);
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: endInset),
          child: Semantics(
            link: true,
            label: '© $source',
            hint: 'Telif hakkı sayfasını açar',
            excludeSemantics: true,
            onTap: onTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: KorSizes.minTouch,
                  minHeight: KorSizes.minTouch,
                ),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ColoredBox(
                    color: scheme.surface.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text('flutter_map | © ', style: style),
                          Text(
                            source,
                            style: style?.copyWith(
                              color: scheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
