import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/rendering.dart'
    show RenderFlex, RenderObject, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/l10n/app_language.dart';

import '../ui_harness.dart';
import 'debug_shot.dart';

/// One audit configuration: theme × text scale × platform × language.
class A11yVariant {
  const A11yVariant({
    required this.themeName,
    required this.theme,
    required this.textScale,
    required this.platform,
    this.language = AppLanguage.turkish,
  });

  final String themeName;
  final ThemeData Function() theme;
  final double textScale;
  final TargetPlatform platform;

  /// App language (F6.1): pass it to `UiHarness.app(language:)`. English
  /// strings differ in length, so overflow is audited in both.
  final AppLanguage language;

  bool get isIOS => platform == TargetPlatform.iOS;

  String get name => '$themeName, ${textScale}x, ${isIOS ? 'iOS' : 'Android'}'
      '${language == AppLanguage.english ? ', English' : ''}';
}

/// Languages every audit runs in (F6.1).
const auditLanguages = [AppLanguage.turkish, AppLanguage.english];

/// Text scales of §3.6 rule 6 (up to 200 %).
const auditTextScales = [1.0, 2.0];

/// Phone-sized logical surface (390 dp wide, like the §3.3 frames). Taller
/// than a phone so that most of a page is on screen at once; the
/// tap-target guidelines skip nodes touching the view or scroll edges.
const auditSurface = Size(390, 1400);

/// Every theme × [auditTextScales] × [platforms] × [languages] combination.
List<A11yVariant> auditVariants({
  List<TargetPlatform> platforms = const [TargetPlatform.android],
  List<AppLanguage> languages = auditLanguages,
}) =>
    [
      for (final language in languages)
        for (final platform in platforms)
          for (final (themeName, theme) in korThemes)
            for (final scale in auditTextScales)
              A11yVariant(
                themeName: themeName,
                theme: theme,
                textScale: scale,
                platform: platform,
                language: language,
              ),
    ];

/// Declares one widget test per [auditVariants] entry: [pump] builds the
/// screen for the variant (use `variant.theme` and `variant.platform` in
/// `UiHarness.app`), then [expectAccessible] runs the guidelines.
///
/// iOS variants also set `debugDefaultTargetPlatformOverride` (the glass
/// chrome and `Switch.adaptive` read it), reset inside the body.
void a11yAudit(
  String description,
  Future<void> Function(WidgetTester tester, A11yVariant variant) pump, {
  List<TargetPlatform> platforms = const [TargetPlatform.android],
  List<AppLanguage> languages = auditLanguages,
  Size surface = auditSurface,
  bool contrast = true,
}) {
  for (final variant in auditVariants(
    platforms: platforms,
    languages: languages,
  )) {
    testWidgets('$description (${variant.name})', (tester) async {
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = variant.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      if (variant.isIOS) {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      }
      final semantics = tester.ensureSemantics();
      try {
        await pump(tester, variant);
        if (const bool.fromEnvironment('A11Y_SHOTS')) {
          await debugShot(tester, '$description ${variant.name}');
        }
        await expectAccessible(tester, variant, contrast: contrast);
      } finally {
        semantics.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

/// Asserts the §3.6 automated checks on what is on screen now:
///
/// * no exception was thrown while building (RenderFlex overflow included),
/// * `androidTapTargetGuideline` (48×48) or `iOSTapTargetGuideline` (44×44),
/// * `labeledTapTargetGuideline` (every tappable node has a label),
/// * `textContrastGuideline` (≥ 4.5:1, ≥ 3:1 for large text).
///
/// All guidelines are evaluated before failing, so one run lists every issue.
Future<void> expectAccessible(
  WidgetTester tester,
  A11yVariant variant, {
  bool contrast = true,
}) async {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: 'Build/layout error. Overflowing flexes:\n'
        '${overflowingFlexes(tester).join('\n')}',
  );

  final guidelines = <AccessibilityGuideline>[
    variant.isIOS ? iOSTapTargetGuideline : androidTapTargetGuideline,
    labeledTapTargetGuideline,
    if (contrast) textContrastGuideline,
  ];
  final failures = <String>[];
  for (final guideline in guidelines) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) {
      failures.add('${guideline.description}:\n${result.reason}');
    }
  }
  final bareTimes = unspokenTimes(tester);
  if (bareTimes.isNotEmpty) {
    failures.add(
      'Times must be read as "saat 16:00" / "at 16:00" (§3.6 rule 11, '
      'KorFormat.spokenTime):\n${bareTimes.join('\n')}',
    );
  }
  expect(failures, isEmpty, reason: failures.join('\n\n'));
}

final _bareTime = RegExp(r'(?<!saat )(?<!at )(?<![\d:])\d{1,2}:\d{2}(?![\d:])');

/// Semantics labels/values that contain a 24 h time not written as
/// "saat HH:mm" / "at HH:mm" (a screen reader says "on altı sıfır sıfır"
/// otherwise).
List<String> unspokenTimes(WidgetTester tester) {
  final found = <String>[];
  void visit(SemanticsNode node) {
    if (!node.isInvisible && !node.isMergedIntoParent) {
      final data = node.getSemanticsData();
      for (final text in [data.label, data.value]) {
        if (_bareTime.hasMatch(text)) found.add('"$text"');
      }
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return found;
}

/// Render flexes that report an overflow, with the widget that created them.
List<String> overflowingFlexes(WidgetTester tester) {
  final found = <String>[];
  void visit(RenderObject object) {
    if (object is RenderFlex && object.toStringShort().contains('OVERFLOW')) {
      found.add('${object.toStringShort()} <- ${object.debugCreator}');
    }
    object.visitChildren(visit);
  }

  for (final view in tester.binding.renderViews) {
    visit(view);
  }
  return found;
}
