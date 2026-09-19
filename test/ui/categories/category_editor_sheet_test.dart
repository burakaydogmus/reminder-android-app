import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/kor_theme.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';

/// Category editor sheet (§3.3.6, F4.3).
void main() {
  final gym = buildCategory(id: 'gym', name: 'Spor', colorKey: 'lacivert');

  Future<UiHarness> open(
    WidgetTester tester, {
    ReminderCategory? existing,
    List<ReminderCategory> categories = const [],
    List reminders = const [],
    ThemeData Function() theme = KorTheme.light,
  }) async {
    final h = await UiHarness.create(
      categories: categories,
      reminders: [...reminders],
    );
    await tester.pumpWidget(h.app(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () =>
                  showCategoryEditorSheet(context, existing: existing),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('new category: name, colour and icon are saved', (tester) async {
    final h = await open(tester);
    expect(find.text('Yeni kategori'), findsWidgets);

    await tester.enterText(
        find.byKey(CategoryEditorKeys.name), ' Spor  salonu ');
    await tapKey(tester, CategoryEditorKeys.swatch(KorColorKey.kiremit));
    await tapKey(tester, CategoryEditorKeys.icon(CategoryIconKeys.fitness));
    await tapKey(tester, CategoryEditorKeys.save);

    final saved = h.cubit.state.categories.userCategories.single;
    expect(saved.name, 'Spor salonu');
    expect(saved.colorKey, 'kiremit');
    expect(saved.iconKey, CategoryIconKeys.fitness);
    expect(h.cubit.state.categories.ordered.last.id, saved.id);
    expect(find.byType(CategoryEditorSheet), findsNothing);
  });

  testWidgets('empty and duplicate names are refused inline', (tester) async {
    final h = await open(tester, categories: [gym]);

    await tapKey(tester, CategoryEditorKeys.save);
    expect(find.text('Kategoriye bir ad ver'), findsOneWidget);

    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'SPOR');
    await tapKey(tester, CategoryEditorKeys.save);
    expect(find.text('Bu adda bir kategori zaten var'), findsOneWidget);

    // Built-in names count too (Turkish folding: "saglik" = "Sağlık").
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'saglik');
    await tester.pump();
    expect(find.text('Bu adda bir kategori zaten var'), findsNothing);
    await tapKey(tester, CategoryEditorKeys.save);
    expect(find.text('Bu adda bir kategori zaten var'), findsOneWidget);

    expect(h.cubit.state.categories.userCategories, [gym]);
    expect(find.byType(CategoryEditorSheet), findsOneWidget);
  });

  test('validateName', () {
    final catalog = CategoryCatalog([gym]);
    expect(CategoryEditorSheet.validateName('  ', catalog, AppL10n.turkish),
        isNotNull);
    expect(CategoryEditorSheet.validateName('spor', catalog, AppL10n.turkish),
        isNotNull);
    expect(
      CategoryEditorSheet.validateName('spor', catalog, AppL10n.turkish,
          exceptId: 'gym'),
      isNull,
    );
    expect(CategoryEditorSheet.validateName('Yoga', catalog, AppL10n.turkish),
        isNull);
  });

  testWidgets('name is capped at 24 characters', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'a' * 30);
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(CategoryEditorKeys.name));
    expect(field.maxLength, ReminderCategory.maxNameLength);
    expect(field.controller!.text.length, ReminderCategory.maxNameLength);
  });

  testWidgets('swatches: 12 colours in 48 dp targets with spoken names',
      (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, existing: gym, categories: [gym]);

    for (final key in KorColorKey.values) {
      final swatch = find.byKey(CategoryEditorKeys.swatch(key));
      expect(swatch, findsOneWidget);
      expect(tester.getSize(swatch), const Size.square(48));
    }
    final selected =
        find.byKey(CategoryEditorKeys.swatch(KorColorKey.lacivert));
    expect(
      tester.getSemantics(selected),
      isSemantics(
        label: 'Lacivert',
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester
          .getSemantics(find.byKey(CategoryEditorKeys.swatch(KorColorKey.kor))),
      isSemantics(label: 'Kor', isButton: true, isSelected: false),
    );
    // Selected: ✓ in addition to the ring (never colour alone).
    expect(
      find.descendant(of: selected, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    final ring = tester
        .widgetList<Container>(
          find.descendant(of: selected, matching: find.byType(Container)),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .single;
    final scheme = Theme.of(tester.element(selected)).colorScheme;
    expect((ring.border! as Border).top.width, 3);
    expect((ring.border! as Border).top.color, scheme.onSurface);

    await tester.tap(find.byKey(CategoryEditorKeys.swatch(KorColorKey.kor)));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(CategoryEditorKeys.swatch(KorColorKey.kor))),
      isSemantics(label: 'Kor', isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('18 icons with spoken names', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, existing: gym, categories: [gym]);
    for (final key in CategoryIconKeys.all) {
      expect(find.byKey(CategoryEditorKeys.icon(key)), findsOneWidget);
    }
    expect(
      tester.getSemantics(
          find.byKey(CategoryEditorKeys.icon(CategoryIconKeys.fitness))),
      isSemantics(label: 'Spor', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  for (final (name, theme) in korThemes) {
    testWidgets('live preview: name in onContainer, icon in fg ($name)',
        (tester) async {
      await open(tester, theme: theme);
      await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Bahçe');
      await tapKey(tester, CategoryEditorKeys.swatch(KorColorKey.kor));
      await tapKey(tester, CategoryEditorKeys.icon(CategoryIconKeys.flower));

      final preview = find.byKey(CategoryEditorKeys.preview);
      final colors =
          tester.element(preview).korColors.category(KorColorKey.kor);
      final text = tester.widget<Text>(
        find.descendant(of: preview, matching: find.text('Bahçe')),
      );
      expect(text.style?.color, colors.onContainer);
      final icon = tester.widget<Icon>(
        find.descendant(of: preview, matching: find.byType(Icon)),
      );
      expect(icon.icon, CategoryIcons.of(CategoryIconKeys.flower));
      expect(icon.color, colors.fg);
      if (name == 'light') {
        // Kor is the key whose fg fails on its container (F4.3 note).
        expect(colors.onContainer, isNot(colors.fg));
      }
    });
  }

  testWidgets('editing keeps the id and position', (tester) async {
    final other = buildCategory(id: 'yoga', name: 'Yoga', position: 7);
    final h = await open(tester, existing: gym, categories: [gym, other]);
    expect(find.text('Kategoriyi düzenle'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(CategoryEditorKeys.name))
          .controller!
          .text,
      'Spor',
    );
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Fitness');
    await tapKey(tester, CategoryEditorKeys.save);

    final ids = [for (final c in h.cubit.state.categories.ordered) c.id];
    expect(ids.sublist(6), ['gym', 'yoga']);
    expect(h.cubit.state.categories.labelOf('gym'), 'Fitness');
  });

  testWidgets('Sil confirms with the count and moves reminders to Diğer',
      (tester) async {
    final h = await open(
      tester,
      existing: gym,
      categories: [gym],
      reminders: [
        buildReminder(id: 'a', categoryId: 'gym'),
        buildReminder(id: 'b', categoryId: 'gym', isDone: true),
        buildReminder(id: 'c', categoryId: 'work'),
      ],
    );

    await tapKey(tester, CategoryEditorKeys.delete);
    expect(find.text("Bu kategorideki 2 hatırlatıcı Diğer'e taşınacak."),
        findsOneWidget);

    // Cancel keeps everything.
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(h.cubit.state.categories.contains('gym'), isTrue);

    await tapKey(tester, CategoryEditorKeys.delete);
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    expect(h.cubit.state.categories.contains('gym'), isFalse);
    expect(
      {for (final r in h.cubit.state.reminders) r.id: r.categoryId},
      {'a': 'other', 'b': 'other', 'c': 'work'},
    );
    expect(find.byType(CategoryEditorSheet), findsNothing);
  });

  testWidgets('new categories have no Sil button', (tester) async {
    await open(tester);
    expect(find.byKey(CategoryEditorKeys.delete), findsNothing);
  });

  testWidgets('initialName prefills a new category', (tester) async {
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showCategoryEditorSheet(context, initialName: '  Bahçe  işi '),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(CategoryEditorKeys.name))
          .controller!
          .text,
      'Bahçe işi',
    );
    expect(
      find.descendant(
        of: find.byKey(CategoryEditorKeys.preview),
        matching: find.text('Bahçe işi'),
      ),
      findsOneWidget,
    );
  });

  test('CategoryVisuals keeps swatch names for every key', () {
    for (final key in KorColorKey.values) {
      expect(CategoryColorNames.of(key, AppL10n.turkish), isNotEmpty);
    }
  });

  testWidgets('semantics: the preview is one node', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await tester.enterText(find.byKey(CategoryEditorKeys.name), 'Bahçe');
    await tester.pump();
    expect(
      tester.getSemantics(find.byKey(CategoryEditorKeys.preview)),
      isSemantics(label: 'Önizleme: Bahçe'),
    );
    handle.dispose();
  });
}
