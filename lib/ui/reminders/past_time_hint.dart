import 'package:material_ui/material_ui.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests of the editor's "Ne zaman" section.
abstract final class ReminderScheduleKeys {
  static const dateChip = Key('reminderEditor.schedule.date');
  static const timeChip = Key('reminderEditor.schedule.time');
  static const pastWarning = Key('reminderEditor.schedule.pastWarning');
  static const suggestion = Key('reminderEditor.schedule.suggestion');
}

/// Past-time rules for the reminder editor (F1.8b). Pure functions of their
/// inputs so tests can pass a fixed clock.
abstract final class PastTime {
  /// Whether [at] is not in the future. Minute precision: a reminder at the
  /// current minute has already passed.
  static bool isPast(DateTime at, DateTime now) => !at.isAfter(now);

  /// The nearest future moment with the same clock time as [chosen]: today at
  /// that time if it is still ahead of [now], otherwise tomorrow.
  static DateTime suggestion(DateTime chosen, DateTime now) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      chosen.hour,
      chosen.minute,
    );
    if (today.isAfter(now)) return today;
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      chosen.hour,
      chosen.minute,
    );
  }

  /// `Yarın 18:30 mı?` / `Bugün 18:30 mı?`
  static String suggestionLabel(
    DateTime suggested,
    DateTime now,
    AppLocalizations l10n,
  ) =>
      l10n.pastTimeSuggestion(
        l10n.dayAndTime(
          KorFormat.relativeDay(suggested, now, l10n),
          KorFormat.time(suggested),
        ),
      );

  /// Screen reader label: `Yarın saat 18:30 olarak ayarla`.
  static String suggestionSemantics(
    DateTime suggested,
    DateTime now,
    AppLocalizations l10n,
  ) =>
      l10n.pastTimeSuggestionSpoken(
        KorFormat.spokenWhen(suggested, now, l10n),
      );
}

/// Inline warning under the date/time chips: error icon + "Bu saat geçti"
/// text (never colour alone) and a suggestion chip that applies the nearest
/// future time.
class PastTimeHint extends StatelessWidget {
  const PastTimeHint({
    super.key,
    required this.suggested,
    required this.now,
    required this.onApply,
  });

  final DateTime suggested;
  final DateTime now;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          key: ReminderScheduleKeys.pastWarning,
          liveRegion: true,
          container: true,
          label: l10n.pastTimeErrorSpoken,
          excludeSemantics: true,
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error),
              const SizedBox(width: KorSpacing.s2),
              Flexible(
                child: Text(
                  l10n.pastTimeError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KorSpacing.s2),
        Semantics(
          button: true,
          label: PastTime.suggestionSemantics(suggested, now, l10n),
          excludeSemantics: true,
          child: ActionChip(
            key: ReminderScheduleKeys.suggestion,
            avatar: const Icon(Icons.update_rounded),
            label: Text(PastTime.suggestionLabel(suggested, now, l10n)),
            onPressed: onApply,
          ),
        ),
      ],
    );
  }
}
