import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Priority and pin visuals (F3.4), shared by [ReminderCard], the compact
/// row, the calendar agenda and the editor.
///
/// Colour is never the only signal (§3.6): priority is written as "!!!" plus
/// "Yüksek", the pin is an icon plus "sabitlendi" in the semantics label.
abstract final class PriorityPinVisuals {
  /// Pin action / toggle label: "Sabitle" or "Sabitlemeyi kaldır".
  static String pinActionLabel(bool pinned, AppLocalizations l10n) =>
      pinned ? l10n.actionUnpin : l10n.actionPin;

  /// "Yok" / "Düşük" / "Orta" / "Yüksek".
  static String label(int priority, AppLocalizations l10n) =>
      switch (ReminderPriority.normalize(priority)) {
        ReminderPriority.low => l10n.priorityLow,
        ReminderPriority.medium => l10n.priorityMedium,
        ReminderPriority.high => l10n.priorityHigh,
        _ => l10n.priorityNone,
      };

  /// Screen-reader text ("Yüksek öncelik"); `null` without priority.
  static String? spoken(int priority, AppLocalizations l10n) {
    final p = ReminderPriority.normalize(priority);
    return p == ReminderPriority.none
        ? null
        : l10n.prioritySpoken(label(p, l10n));
  }

  static IconData pinIcon(bool pinned) =>
      pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined;

  /// Screen-reader parts for a card label: "sabitlendi", "Yüksek öncelik".
  static List<String> spokenParts(Reminder r, AppLocalizations l10n) => [
        if (r.pinned) l10n.reminderSpokenPinned,
        if (spoken(r.priority, l10n) case final p?) p,
      ];

  /// High priority on an open reminder gets the 2.5 px primary ring on its
  /// checkbox (§3.3.2); `null` otherwise.
  static BorderSide? checkboxRing(BuildContext context, Reminder r) {
    if (r.isDone || r.priority != ReminderPriority.high) return null;
    return BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5);
  }

  /// Colour of the "!!!" marker: primary for high (as the ring), otherwise
  /// the muted meta colour.
  static Color markerColor(ColorScheme scheme, int priority) =>
      priority == ReminderPriority.high
          ? scheme.primary
          : scheme.onSurfaceVariant;

  /// "!!! Yüksek" meta span (bold marker + label); empty without priority.
  static List<InlineSpan> metaSpans(
    ColorScheme scheme,
    int priority,
    AppLocalizations l10n,
  ) {
    if (priority == ReminderPriority.none) return const [];
    final color = markerColor(scheme, priority);
    return [
      TextSpan(
        text: ReminderPriority.marker(priority),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      TextSpan(
        text: ' ${label(priority, l10n)}',
        style: TextStyle(color: color),
      ),
    ];
  }

  /// Pin icon in front of a title (a [WidgetSpan]); size follows the title.
  static InlineSpan titlePin(ColorScheme scheme, {double size = 16}) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: KorSpacing.s1),
          child: Icon(
            Icons.push_pin_rounded,
            size: size,
            color: scheme.primary,
          ),
        ),
      );
}
