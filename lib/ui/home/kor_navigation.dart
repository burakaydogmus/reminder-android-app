import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
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

  /// Tab name in the app language.
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final IconData selectedIcon;
}

String _todayLabel(AppLocalizations l10n) => l10n.todayTitle;
String _calendarLabel(AppLocalizations l10n) => l10n.calendarTitle;
String _listsLabel(AppLocalizations l10n) => l10n.listsTitle;

const kShellDestinations = <KorDestination>[
  KorDestination(
    label: _todayLabel,
    icon: Icons.today_outlined,
    selectedIcon: Icons.today_rounded,
  ),
  KorDestination(
    label: _calendarLabel,
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
  ),
  KorDestination(
    label: _listsLabel,
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
    Widget item(int i) => _PillNavItem(
          destination: destinations[i],
          selected: i == selectedIndex,
          index: i,
          count: destinations.length,
          onTap: () => onSelected(i),
        );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // The pill floats over the list: a tap on it between items must not
      // reach the card underneath.
      child: Listener(
        behavior: HitTestBehavior.opaque,
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
              // Only the selected item (icon + label) shrinks; equal shares
              // cut its label to "B…" on a 390 dp phone (F4.5 audit).
              for (var i = 0; i < destinations.length; i++)
                if (i == selectedIndex) Flexible(child: item(i)) else item(i),
            ],
          ),
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
      label: destination.label(context.l10n),
      hint: context.l10n.navTabHint(index + 1, count),
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
                      destination.label(context.l10n),
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

enum _NewItemKind { quick, reminder, birthday }

/// The "new item" menu (long-press on the Android FAB and the iOS capture
/// bar, §3.2): Hızlı ekle / Hatırlatıcı (full editor) / Doğum günü, anchored
/// to [context]'s render box.
Future<void> showNewItemMenu(
  BuildContext context, {
  DateTime Function()? now,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  final rect = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  final l10n = context.l10n;
  final kind = await showMenu<_NewItemKind>(
    context: context,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    items: [
      PopupMenuItem(
        value: _NewItemKind.quick,
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded),
            const SizedBox(width: KorSpacing.s4),
            Text(l10n.newItemQuick),
          ],
        ),
      ),
      PopupMenuItem(
        value: _NewItemKind.reminder,
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded),
            const SizedBox(width: KorSpacing.s4),
            Text(l10n.newItemReminder),
          ],
        ),
      ),
      PopupMenuItem(
        value: _NewItemKind.birthday,
        child: Row(
          children: [
            const Icon(CategoryVisuals.birthdayIcon),
            const SizedBox(width: KorSpacing.s4),
            Text(l10n.newItemBirthday),
          ],
        ),
      ),
    ],
  );
  if (!context.mounted) return;
  switch (kind) {
    case _NewItemKind.quick:
      await showQuickCaptureSheet(context, now: now);
    case _NewItemKind.reminder:
      await showReminderEditorSheet(context, now: now);
    case _NewItemKind.birthday:
      await showBirthdayEditorSheet(context);
    case null:
      break;
  }
}

/// Semantics actions shared by the FAB and the iOS capture bar (the
/// long-press menu's other items for screen readers).
Map<CustomSemanticsAction, VoidCallback> newItemSemanticsActions(
  BuildContext context, {
  DateTime Function()? now,
}) =>
    {
      CustomSemanticsAction(label: context.l10n.newItemDetailedReminder): () =>
          showReminderEditorSheet(context, now: now),
      CustomSemanticsAction(label: context.l10n.birthdayNew): () =>
          showBirthdayEditorSheet(context),
    };

/// 64 px squircle "Yeni hatırlatıcı" FAB (Android): tap opens the quick
/// capture sheet (F4.6b); long-press offers Hızlı ekle / Hatırlatıcı /
/// Doğum günü (also exposed as semantics actions).
class NewItemFab extends StatelessWidget {
  const NewItemFab({super.key, this.clock});

  /// Clock for the sheets; defaults to the caller's `NowScope`.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    void capture() => showQuickCaptureSheet(context, now: clock);
    void menu() => showNewItemMenu(context, now: clock);
    return Semantics(
      button: true,
      label: context.l10n.editorNewTitle,
      hint: context.l10n.newItemFabHint,
      onTap: capture,
      onLongPress: menu,
      customSemanticsActions: newItemSemanticsActions(context, now: clock),
      excludeSemantics: true,
      child: GestureDetector(
        onLongPress: menu,
        child: FloatingActionButton.large(
          heroTag: null,
          onPressed: capture,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}
