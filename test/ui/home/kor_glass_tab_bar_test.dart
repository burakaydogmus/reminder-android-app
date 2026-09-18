import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/ui/components/kor_glass_surface.dart';
import 'package:reminder/ui/home/kor_glass_tab_bar.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../ui_harness.dart';
import 'ios_platform.dart';

Finder _tab(String label) => find.descendant(
      of: find.byKey(KorGlassTabBar.capsuleKey),
      matching: find.bySemanticsLabel(label),
    );

class _Host extends StatefulWidget {
  const _Host({
    this.collapsed = false,
    this.prefs = A11yPrefsData.none,
    this.onSearch,
  });

  final bool collapsed;
  final A11yPrefsData prefs;
  final VoidCallback? onSearch;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;
  late bool collapsed = widget.collapsed;
  late final prefs = A11yPrefs(widget.prefs);

  @override
  void dispose() {
    prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Sayfa $index')),
      bottomNavigationBar: A11yPrefsScope(
        prefs: prefs,
        child: KorGlassTabBar(
          selectedIndex: index,
          onSelected: (i) => setState(() => index = i),
          collapsed: collapsed,
          onExpand: () => setState(() => collapsed = false),
          onSearch: widget.onSearch,
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget host, {
  ThemeData Function() theme = KorTheme.light,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme().copyWith(platform: TargetPlatform.iOS),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: host,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (themeName, theme) in korThemes) {
    iosTestWidgets('renders 3 destinations and the search button ($themeName)',
        (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var searches = 0;
      await _pump(tester, _Host(onSearch: () => searches++), theme: theme);

      for (final label in ['Bugün', 'Takvim', 'Listeler']) {
        expect(_tab(label), findsOneWidget);
      }
      expect(find.byKey(KorGlassTabBar.searchKey), findsOneWidget);
      expect(find.byKey(KorGlassSurface.glassKey), findsNWidgets(2));
      expect(find.byKey(KorGlassSurface.solidKey), findsNothing);

      final capsule = tester.getSize(find.byKey(KorGlassTabBar.capsuleKey));
      expect(capsule.height, 62);
      expect(capsule.width, lessThanOrEqualTo(290));
      final search = tester.getSize(
        find.ancestor(
          of: find.byKey(KorGlassTabBar.searchKey),
          matching: find.byType(KorGlassSurface),
        ),
      );
      expect(search, const Size(62, 62));

      await tester.tap(find.bySemanticsLabel('Ara'));
      expect(searches, 1);
      semantics.dispose();
    });
  }

  iosTestWidgets('selecting a tab slides the indicator', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const _Host());
    final indicator = find.byKey(KorGlassTabBar.indicatorKey);
    final start = tester.getRect(indicator);
    expect(
      tester.getSemantics(_tab('Bugün')),
      isSemantics(isSelected: true),
    );

    await tester.tap(_tab('Listeler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getRect(indicator);
    expect(mid.left, greaterThan(start.left));
    expect(mid.left, lessThan(tester.getRect(_tab('Listeler')).left));

    await tester.pumpAndSettle();
    expect(find.text('Sayfa 2'), findsOneWidget);
    expect(
      tester.getRect(indicator).center.dx,
      closeTo(tester.getRect(_tab('Listeler')).center.dx, 1),
    );
    expect(
      tester.getSemantics(_tab('Listeler')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(_tab('Bugün')),
      isSemantics(isSelected: false),
    );
    semantics.dispose();
  });

  iosTestWidgets('Reduce Motion: the indicator jumps without sliding', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const _Host(), disableAnimations: true);

    await tester.tap(_tab('Takvim'));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(KorGlassTabBar.indicatorKey)).center.dx,
      closeTo(tester.getRect(_tab('Takvim')).center.dx, 1),
    );
    semantics.dispose();
  });

  iosTestWidgets('collapsed shows only the selected icon and expands on tap',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const _Host(collapsed: true, onSearch: _noop));

    expect(find.byKey(KorGlassTabBar.collapsedKey), findsOneWidget);
    expect(find.text('Takvim'), findsNothing);
    final capsule = tester.getSize(find.byKey(KorGlassTabBar.capsuleKey));
    expect(capsule.width, lessThan(100));
    expect(capsule.height, greaterThanOrEqualTo(48));
    // Search stays reachable while collapsed.
    expect(find.bySemanticsLabel('Ara'), findsOneWidget);

    await tester.tap(find.byKey(KorGlassTabBar.collapsedKey));
    await tester.pumpAndSettle();
    expect(find.byKey(KorGlassTabBar.collapsedKey), findsNothing);
    expect(_tab('Takvim'), findsOneWidget);
    expect(tester.getSize(find.byKey(KorGlassTabBar.capsuleKey)).height, 62);
    semantics.dispose();
  });

  iosTestWidgets('search button is hidden without a handler', (tester) async {
    await _pump(tester, const _Host());
    expect(find.byKey(KorGlassTabBar.searchKey), findsNothing);
  });

  for (final (name, prefs) in [
    ('Reduce Transparency', const A11yPrefsData(reduceTransparency: true)),
    ('Increase Contrast', const A11yPrefsData(increaseContrast: true)),
    ('Low Power Mode', const A11yPrefsData(lowPower: true)),
  ]) {
    iosTestWidgets('$name: solid surfaceContainerHigh fallback', (
      tester,
    ) async {
      await _pump(tester, _Host(prefs: prefs, onSearch: _noop));

      expect(find.byKey(KorGlassSurface.glassKey), findsNothing);
      final solid = find.byKey(KorGlassSurface.solidKey);
      expect(solid, findsNWidgets(2));
      final context = tester.element(solid.first);
      final scheme = Theme.of(context).colorScheme;
      final decoration =
          tester.widget<Container>(solid.first).decoration! as ShapeDecoration;
      expect(decoration.color, scheme.surfaceContainerHigh);
      expect((decoration.shape as OutlinedBorder).side.width, 1);
    });
  }

  iosTestWidgets('high contrast: solid with a 2px outline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KorTheme.light().copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: const _Host(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final solid = find.byKey(KorGlassSurface.solidKey);
    expect(solid, findsOneWidget);
    final decoration =
        tester.widget<Container>(solid).decoration! as ShapeDecoration;
    final side = (decoration.shape as OutlinedBorder).side;
    expect(side.width, 2);
    expect(side.color, Theme.of(tester.element(solid)).colorScheme.outline);
  });

  iosTestWidgets('prefs change at runtime switches glass to solid', (
    tester,
  ) async {
    await _pump(tester, const _Host());
    expect(find.byKey(KorGlassSurface.glassKey), findsOneWidget);

    final host = tester.state<_HostState>(find.byType(_Host));
    host.prefs.value = const A11yPrefsData(reduceTransparency: true);
    await tester.pumpAndSettle();
    expect(find.byKey(KorGlassSurface.glassKey), findsNothing);
    expect(find.byKey(KorGlassSurface.solidKey), findsOneWidget);
  });

  iosTestWidgets('targets are at least 48pt and labelled', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const _Host(onSearch: _noop));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    final tab = tester.getSemantics(_tab('Takvim'));
    expect(tab.flagsCollection.isButton, isTrue);
    expect(tab.hint, 'Sekme 2 / 3');
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Ara'))
          .flagsCollection
          .isButton,
      isTrue,
    );
    semantics.dispose();
  });

  iosTestWidgets('labels stay on one line at 200% text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KorTheme.light().copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: const _Host(onSearch: _noop),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Listeler'), findsOneWidget);
  });
}

void _noop() {}
