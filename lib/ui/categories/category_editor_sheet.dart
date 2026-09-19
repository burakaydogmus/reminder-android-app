import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_palette.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/util/dialog.dart';

/// Keys for tests.
abstract final class CategoryEditorKeys {
  static const name = Key('categoryEditor.name');
  static const save = Key('categoryEditor.save');
  static const delete = Key('categoryEditor.delete');
  static const preview = Key('categoryEditor.preview');
  static Key swatch(KorColorKey key) =>
      Key('categoryEditor.swatch.${key.name}');
  static Key icon(String key) => Key('categoryEditor.icon.$key');
}

/// Opens the category editor sheet (§3.3.6, F4.3) for a new user category
/// or for [existing] (user categories only; built-ins are not editable).
///
/// Saves through [ReminderCubit.saveCategory] and returns the saved
/// category; `null` when dismissed or deleted ("Sil" moves the category's
/// reminders to "Diğer" after a confirmation).
Future<ReminderCategory?> showCategoryEditorSheet(
  BuildContext context, {
  ReminderCategory? existing,
}) {
  assert(existing == null || !existing.isBuiltIn);
  return showModalBottomSheet<ReminderCategory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (_) => CategoryEditorSheet(existing: existing),
  );
}

/// Body of [showCategoryEditorSheet]: live preview, Ad (max 24), Renk (12
/// swatches, 6 columns) and İkon (18 icons, 6 columns), [Sil] · [Kaydet].
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({super.key, this.existing});

  final ReminderCategory? existing;

  /// Colour swatch visual diameter (target cell stays 48).
  static const double swatchSize = 40;

  /// Selected swatch ring width (`onSurface`).
  static const double ringWidth = 3;

  static const int columns = 6;

  /// Default colour of a new category.
  static const KorColorKey defaultColor = KorColorKey.lacivert;

  /// Validation message for [name], `null` when it can be saved: not empty
  /// and no other category with the same folded name (case and Turkish
  /// diacritics ignored, built-ins included).
  static String? validateName(
    String name,
    CategoryCatalog catalog, {
    String? exceptId,
  }) {
    final normalized = ReminderCategory.normalizeName(name);
    if (normalized.isEmpty) return 'Kategoriye bir ad ver';
    if (catalog.byFoldedName(normalized, exceptId: exceptId) != null) {
      return 'Bu adda bir kategori zaten var';
    }
    return null;
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _name;
  late KorColorKey _color;
  late String _icon;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _color = e == null
        ? CategoryEditorSheet.defaultColor
        : CategoryVisuals.colorKeyOf(e);
    _icon = e != null && CategoryIconKeys.all.contains(e.iconKey)
        ? e.iconKey
        : CategoryIconKeys.label;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ReminderCategory _draft() => ReminderCategory(
        id: widget.existing?.id ?? 'draft',
        name: ReminderCategory.normalizeName(_name.text),
        colorKey: _color.storageKey,
        iconKey: _icon,
        position: widget.existing?.position ?? 0,
      );

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final error = CategoryEditorSheet.validateName(
      _name.text,
      cubit.state.categories,
      exceptId: widget.existing?.id,
    );
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    final category = _draft().copyWith(
      id: widget.existing?.id ?? const Uuid().v4(),
    );
    await cubit.saveCategory(category);
    if (!mounted) return;
    Navigator.of(context).pop(cubit.state.categories.byId(category.id));
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final cubit = context.read<ReminderCubit>();
    final count =
        cubit.state.reminders.where((r) => r.categoryId == existing.id).length;
    final confirmed = await showConfirmationDialog(
      context,
      title: '“${existing.name}” silinsin mi?',
      content: count == 0
          ? 'Bu kategoride hatırlatıcı yok.'
          : "Bu kategorideki $count hatırlatıcı Diğer'e taşınacak.",
    );
    if (!confirmed || !mounted) return;
    await cubit.deleteCategory(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          KorSpacing.s5,
          0,
          KorSpacing.s5,
          KorSpacing.s5 + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                isNew ? 'Yeni kategori' : 'Kategoriyi düzenle',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: KorSpacing.s5),
            CategoryPreview(
              key: CategoryEditorKeys.preview,
              category: _draft(),
            ),
            const SizedBox(height: KorSpacing.s5),
            TextField(
              key: CategoryEditorKeys.name,
              controller: _name,
              autofocus: isNew,
              maxLength: ReminderCategory.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _nameError = null),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Ad',
                hintText: 'Örn. Spor salonu',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: KorSpacing.s4),
            const SectionHeader(title: 'Renk', icon: Icons.palette_outlined),
            _Grid(
              children: [
                for (final key in KorColorKey.values)
                  ColorSwatchButton(
                    key: CategoryEditorKeys.swatch(key),
                    colorKey: key,
                    selected: key == _color,
                    onTap: () => setState(() => _color = key),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s5),
            const SectionHeader(title: 'İkon', icon: Icons.category_outlined),
            _Grid(
              children: [
                for (final key in CategoryIconKeys.all)
                  _IconCell(
                    key: CategoryEditorKeys.icon(key),
                    iconKey: key,
                    colors: context.korColors.category(_color),
                    selected: key == _icon,
                    onTap: () => setState(() => _icon = key),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s7),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    key: CategoryEditorKeys.delete,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      minimumSize: const Size(
                        KorSizes.minTouch,
                        KorSizes.minTouch,
                      ),
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Sil'),
                  ),
                const Spacer(),
                FilledButton(
                  key: CategoryEditorKeys.save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      KorSizes.minTouch * 2,
                      KorSizes.minTouch,
                    ),
                  ),
                  onPressed: _save,
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview: the category as a tonal pill (icon `fg`, name
/// `onContainer` on `container`).
class CategoryPreview extends StatelessWidget {
  const CategoryPreview({super.key, required this.category});

  final ReminderCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        context.korColors.category(CategoryVisuals.colorKeyOf(category));
    final name = category.name.isEmpty ? 'Yeni kategori' : category.name;
    return Semantics(
      label: 'Önizleme: $name',
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.container,
            borderRadius: KorRadius.fullAll,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KorSpacing.s5,
              vertical: KorSpacing.s3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CategoryVisuals.iconOf(category), color: colors.fg),
                const SizedBox(width: KorSpacing.s3),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onContainer,
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

/// Rows of [CategoryEditorSheet.columns] 48 dp cells.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const columns = CategoryEditorSheet.columns;
    return Column(
      children: [
        for (var i = 0; i < children.length; i += columns)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var j = i; j < i + columns; j++)
                j < children.length
                    ? children[j]
                    : const SizedBox.square(dimension: KorSizes.minTouch),
            ],
          ),
      ],
    );
  }
}

/// One colour swatch: a 40 px `fg` circle in a 48 dp target; selected →
/// 3 px `onSurface` ring + ✓ (never colour alone). Spoken as the colour
/// name with the selected state ("Lacivert, seçili").
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.colorKey,
    required this.selected,
    required this.onTap,
  });

  final KorColorKey colorKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.korColors.category(colorKey);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: CategoryColorNames.of(colorKey),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: KorSizes.minTouch / 2,
        child: SizedBox.square(
          dimension: KorSizes.minTouch,
          child: Center(
            child: Container(
              width: CategoryEditorSheet.swatchSize,
              height: CategoryEditorSheet.swatchSize,
              decoration: BoxDecoration(
                color: colors.fg,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: scheme.onSurface,
                        width: CategoryEditorSheet.ringWidth,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : null,
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: KorSizes.iconSm,
                      color: colors.onFg,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// One icon choice in a 48 dp cell; selected → tonal circle, `fg` icon and a
/// 2 px `fg` ring.
class _IconCell extends StatelessWidget {
  const _IconCell({
    super.key,
    required this.iconKey,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final CategoryColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: CategoryIcons.spokenNames[iconKey],
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: KorSizes.minTouch / 2,
        child: Container(
          width: KorSizes.minTouch,
          height: KorSizes.minTouch,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.container : null,
            border: selected ? Border.all(color: colors.fg, width: 2) : null,
          ),
          child: Icon(
            CategoryIcons.of(iconKey),
            color: selected ? colors.fg : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
