import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// A top-level destination of the shell.
class KorDestination {
  const KorDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const kShellDestinations = <KorDestination>[
  KorDestination(
    label: 'Bugün',
    icon: Icons.today_outlined,
    selectedIcon: Icons.today_rounded,
  ),
  KorDestination(
    label: 'Takvim',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
  ),
  KorDestination(
    label: 'Listeler',
    icon: Icons.format_list_bulleted_rounded,
    selectedIcon: Icons.view_list_rounded,
  ),
];

/// Android floating pill navigation (`NavBarAndroid`): active item shows
/// icon + label on `primaryContainer`, inactive items are icon-only with the
/// label in semantics.
class KorPillNavigation extends StatelessWidget {
  const KorPillNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.destinations = kShellDestinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<KorDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final elevation = theme.brightness == Brightness.dark
        ? KorElevation.dark
        : KorElevation.light;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: KorSizes.navBarHeight),
        padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: KorRadius.fullAll,
          boxShadow: elevation.level2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < destinations.length; i++)
              Flexible(
                child: _PillNavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  index: i,
                  count: destinations.length,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
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
    final motion = context.korMotion;
    final duration =
        MediaQuery.disableAnimationsOf(context) ? Duration.zero : motion.medium;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      hint: 'Sekme ${index + 1} / $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s1),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(
              minWidth: KorSizes.minTouch,
              minHeight: KorSizes.minTouch,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? KorSpacing.s5 : KorSpacing.s4,
            ),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: selected ? scheme.primaryContainer : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: fg,
                ),
                if (selected) ...[
                  const SizedBox(width: KorSpacing.s3),
                  Flexible(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(color: fg),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NewItemKind { reminder, birthday }

/// 64 px squircle "Yeni hatırlatıcı" FAB; long-press offers
/// Hatırlatıcı / Doğum günü (also exposed as a semantics action).
class NewItemFab extends StatelessWidget {
  const NewItemFab({super.key});

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final rect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final kind = await showMenu<_NewItemKind>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: const [
        PopupMenuItem(
          value: _NewItemKind.reminder,
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded),
              SizedBox(width: KorSpacing.s4),
              Text('Hatırlatıcı'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _NewItemKind.birthday,
          child: Row(
            children: [
              Icon(CategoryVisuals.birthdayIcon),
              SizedBox(width: KorSpacing.s4),
              Text('Doğum günü'),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (kind) {
      case _NewItemKind.reminder:
        await showReminderEditorSheet(context);
      case _NewItemKind.birthday:
        await showBirthdayEditorSheet(context);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Yeni hatırlatıcı',
      hint: 'Uzun basınca hatırlatıcı veya doğum günü seçilir',
      onTap: () => showReminderEditorSheet(context),
      onLongPress: () => _showMenu(context),
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Yeni doğum günü'): () =>
            showBirthdayEditorSheet(context),
      },
      excludeSemantics: true,
      child: GestureDetector(
        onLongPress: () => _showMenu(context),
        child: FloatingActionButton.large(
          heroTag: null,
          onPressed: () => showReminderEditorSheet(context),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}
