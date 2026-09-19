import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/components/kor_glass_surface.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// iOS "Ne hatırlatayım?" capture bar (§3.2, §3.3.2 `CaptureBar`, F4.6b): a
/// glass capsule above the tab bar that opens the quick-capture sheet.
/// Long-press opens the new-item menu (the iOS replacement of the Android
/// FAB's menu); its items are also semantics actions.
class CaptureBar extends StatelessWidget {
  const CaptureBar({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
    this.onLongPress,
    this.semanticsActions = const {},
  });

  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Map<CustomSemanticsAction, VoidCallback> semanticsActions;

  static const barKey = ValueKey('CaptureBar');

  /// Same cap as the tab labels (`KorGlassTabBar.maxLabelScale`).
  static const double maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      key: barKey,
      button: true,
      label: context.l10n.captureBarLabel,
      hint: context.l10n.captureBarHint,
      onTap: onTap,
      onLongPress: onLongPress,
      customSemanticsActions: semanticsActions,
      excludeSemantics: true,
      child: KorGlassSurface(
        width: width,
        height: height,
        child: InkWell(
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s4),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: scheme.primary),
                const SizedBox(width: KorSpacing.s3),
                Expanded(
                  // Fixed bar height (design 52): the full text is in the
                  // semantics hint, the visible one clamps like tab labels.
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: maxTextScale,
                    child: Text(
                      context.l10n.captureFieldHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
