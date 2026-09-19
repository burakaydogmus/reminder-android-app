import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/components/kor_glass_surface.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// iOS floating glass chrome (`kor-design-proposal.md` §3.2, F5.4): a
/// 290×62 [KorGlassSurface] capsule with the three shell destinations (icon +
/// label) and a sliding selected indicator, plus a separate 62 glass search
/// circle ("Ara").
///
/// [collapsed] shrinks the capsule to the selected icon (scrolling content);
/// tapping it calls [onExpand]. The search circle is shown only when
/// [onSearch] is set. A `surface` fade behind the chrome keeps content that
/// scrolls under the glass readable. Glass falls back to solid through
/// [KorGlassSurface] (Reduce Transparency, Increase Contrast, low power).
class KorGlassTabBar extends StatefulWidget {
  const KorGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.collapsed = false,
    this.onExpand,
    this.onSearch,
    this.accessory,
    this.destinations = kShellDestinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool collapsed;
  final VoidCallback? onExpand;
  final VoidCallback? onSearch;

  /// Builds the capture bar (F4.6b) at the given size: full width and
  /// [KorSizes.captureBarHeight] above the capsule, and while [collapsed]
  /// it moves down between the collapsed tab and the search circle
  /// (§3.2 "küçülünce birlikte iniyor"). The outer height stays fixed.
  final Widget Function(BuildContext context, Size size)? accessory;
  final List<KorDestination> destinations;

  static const capsuleKey = ValueKey('KorGlassTabBar.capsule');
  static const indicatorKey = ValueKey('KorGlassTabBar.indicator');
  static const collapsedKey = ValueKey('KorGlassTabBar.collapsed');
  static const searchKey = ValueKey('KorGlassTabBar.search');

  /// Label text scale cap: the capsule height is fixed by design (62), the
  /// full label is always in semantics.
  static const double maxLabelScale = 1.3;

  @override
  State<KorGlassTabBar> createState() => _KorGlassTabBarState();
}

class _KorGlassTabBarState extends State<KorGlassTabBar>
    with SingleTickerProviderStateMixin {
  /// Indicator position in destination units (0 = first destination).
  late final AnimationController _indicator = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );

  @override
  void didUpdateWidget(KorGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _slideTo();
  }

  void _slideTo() {
    final target = widget.selectedIndex.toDouble();
    final motion = context.korMotion;
    final spec = motion.resolveOf(context, motion.spatialDefault);
    final spring = spec.spring;
    if (spring == null) {
      // Reduce Motion: no slide, the indicator jumps.
      _indicator.value = target;
      return;
    }
    _indicator.animateWith(
      SpringSimulation(spring, _indicator.value, target, _indicator.velocity),
    );
  }

  @override
  void dispose() {
    _indicator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = context.korMotion;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : motion.medium;
    final curve = motion.fallbackCurve;
    final collapsed = widget.collapsed;
    final search = widget.onSearch;

    return Stack(
      children: [
        // Edge fade: content under the floating glass stays readable.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0),
                    scheme.surface.withValues(alpha: KorGlass.edgeFadeOpacity),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            KorSpacing.s5,
            KorSpacing.s3,
            KorSpacing.s5,
            KorSpacing.s3,
          ),
          // Fixed outer height: collapsing never changes the scaffold's
          // bottom inset, so the body does not relayout while scrolling.
          child: _withAccessory(
            context,
            hasSearch: search != null,
            duration: duration,
            curve: curve,
            tabs: SizedBox(
              height: KorGlass.tabBarHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final searchSpace = search == null
                      ? 0.0
                      : KorGlass.searchSize + KorSpacing.s3;
                  final expandedWidth = math.min(
                    KorGlass.tabBarWidth,
                    constraints.maxWidth - searchSpace,
                  );
                  final capsule = collapsed
                      ? const Size(
                          KorGlass.tabBarCollapsedWidth,
                          KorGlass.collapsedHeight,
                        )
                      : Size(expandedWidth, KorGlass.tabBarHeight);
                  final circle = collapsed
                      ? KorGlass.collapsedHeight
                      : KorGlass.searchSize;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<Size?>(
                        tween: SizeTween(end: capsule),
                        duration: duration,
                        curve: curve,
                        builder: (context, size, child) => KorGlassSurface(
                          key: KorGlassTabBar.capsuleKey,
                          width: size!.width,
                          height: size.height,
                          child: _Clipped(size: capsule, child: child!),
                        ),
                        child: collapsed
                            ? _CollapsedTab(
                                destination:
                                    widget.destinations[widget.selectedIndex],
                                onTap: widget.onExpand,
                              )
                            : _Tabs(
                                destinations: widget.destinations,
                                selectedIndex: widget.selectedIndex,
                                indicator: _indicator,
                                onSelected: widget.onSelected,
                              ),
                      ),
                      const Spacer(),
                      if (search != null)
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: circle),
                          duration: duration,
                          curve: curve,
                          builder: (context, side, child) => KorGlassSurface(
                            shape: KorGlassShape.circle,
                            width: side,
                            height: side,
                            child: child!,
                          ),
                          child: _SearchButton(onTap: search),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// [tabs] alone, or with the [KorGlassTabBar.accessory] above it in a
  /// fixed-height stack; collapsing moves the accessory down between the
  /// collapsed tab and the search circle.
  Widget _withAccessory(
    BuildContext context, {
    required Widget tabs,
    required bool hasSearch,
    required Duration duration,
    required Curve curve,
  }) {
    final accessory = widget.accessory;
    if (accessory == null) return tabs;
    final collapsed = widget.collapsed;
    const height =
        KorSizes.captureBarHeight + KorSpacing.s3 + KorGlass.tabBarHeight;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: KorGlass.tabBarHeight,
            child: tabs,
          ),
          AnimatedPositionedDirectional(
            duration: duration,
            curve: curve,
            start:
                collapsed ? KorGlass.tabBarCollapsedWidth + KorSpacing.s3 : 0,
            end: collapsed && hasSearch
                ? KorGlass.collapsedHeight + KorSpacing.s3
                : 0,
            top: collapsed ? height - KorGlass.collapsedHeight : 0,
            height: collapsed
                ? KorGlass.collapsedHeight
                : KorSizes.captureBarHeight,
            child: LayoutBuilder(
              builder: (context, constraints) => accessory(
                context,
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays [child] out at its final [size] and clips it to the animating
/// surface, so content never overflows mid-animation.
class _Clipped extends StatelessWidget {
  const _Clipped({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        minWidth: size.width,
        maxWidth: size.width,
        minHeight: size.height,
        maxHeight: size.height,
        child: child,
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.destinations,
    required this.selectedIndex,
    required this.indicator,
    required this.onSelected,
  });

  final List<KorDestination> destinations;
  final int selectedIndex;
  final Animation<double> indicator;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = destinations.length;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.all(KorSpacing.s2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / count;
            final rtl = Directionality.of(context) == TextDirection.rtl;
            return Stack(
              children: [
                AnimatedBuilder(
                  animation: indicator,
                  builder: (context, child) {
                    final offset = indicator.value * itemWidth;
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: rtl ? null : offset,
                      right: rtl ? offset : null,
                      width: itemWidth,
                      child: child!,
                    );
                  },
                  child: DecoratedBox(
                    key: KorGlassTabBar.indicatorKey,
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: scheme.primaryContainer,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: _TabItem(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          index: i,
                          count: count,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.destination,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final KorDestination destination;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label(context.l10n),
      hint: context.l10n.navTabHint(index + 1, count),
      excludeSemantics: true,
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: KorSizes.minTouch,
            minHeight: KorSizes.minTouch,
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: KorGlassTabBar.maxLabelScale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: fg,
                ),
                Text(
                  destination.label(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedTab extends StatelessWidget {
  const _CollapsedTab({required this.destination, required this.onTap});

  final KorDestination destination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: KorGlassTabBar.collapsedKey,
      button: true,
      selected: true,
      label: destination.label(context.l10n),
      hint: context.l10n.navShowTabs,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Center(
          child: Icon(destination.selectedIcon, color: scheme.primary),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: KorGlassTabBar.searchKey,
      button: true,
      label: context.l10n.searchTooltip,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Center(
          child: Icon(Icons.search_rounded, color: scheme.onSurface),
        ),
      ),
    );
  }
}
