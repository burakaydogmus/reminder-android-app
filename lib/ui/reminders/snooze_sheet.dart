import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/reminders/snooze_options.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class SnoozeSheetKeys {
  static Key option(SnoozeKind kind) => Key('snoozeSheet.${kind.name}');
  static const custom = Key('snoozeSheet.custom');
  static const pastError = Key('snoozeSheet.pastError');
}

/// Ertele sheet (§3.3.4): 2×2 quick options plus "Tarih ve saat seç…".
///
/// Returns the chosen time, or null when dismissed. [now] defaults to the
/// caller's [NowScope] clock.
Future<DateTime?> showSnoozeSheet(
  BuildContext context, {
  required Reminder reminder,
  DateTime Function()? now,
}) {
  final clock = now ?? NowScope.clockOf(context);
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SnoozeSheet(reminder: reminder, clock: clock),
  );
}

class _SnoozeSheet extends StatefulWidget {
  const _SnoozeSheet({required this.reminder, required this.clock});

  final Reminder reminder;
  final DateTime Function() clock;

  @override
  State<_SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends State<_SnoozeSheet> {
  bool _pastError = false;

  static IconData _iconFor(SnoozeKind kind) => switch (kind) {
        SnoozeKind.tenMinutes => Icons.timer_outlined,
        SnoozeKind.oneHour => Icons.hourglass_bottom_rounded,
        SnoozeKind.evening => Icons.nights_stay_outlined,
        SnoozeKind.tomorrowMorning => Icons.wb_sunny_outlined,
      };

  Future<void> _pickCustom() async {
    final now = widget.clock();
    final current = widget.reminder.remindAt?.toLocal();
    final base = current != null && current.isAfter(now) ? current : now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      currentDate: now,
      firstDate: KorFormat.dateOnly(now),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Never shift a past choice silently (F1.8b): keep the sheet open.
    if (!at.isAfter(widget.clock())) {
      setState(() => _pastError = true);
      return;
    }
    Navigator.of(context).pop(at);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = widget.clock();
    final options = SnoozeOptions.from(now);
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget card(SnoozeOption o) => _OptionCard(
          key: SnoozeSheetKeys.option(o.kind),
          icon: _iconFor(o.kind),
          label: o.label,
          time: SnoozeOptions.timeLabel(o.at, now),
          semanticLabel: '${o.label}, '
              '${KorFormat.relativeDay(o.at, now).toLowerCase()} '
              '${KorFormat.spokenTime(o.at)}',
          onTap: () => Navigator.of(context).pop(o.at),
        );

    Widget row(SnoozeOption a, SnoozeOption b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(a)),
              const SizedBox(width: KorSpacing.s3),
              Expanded(child: card(b)),
            ],
          ),
        );

    return SingleChildScrollView(
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
            child: Text('Ertele', style: theme.textTheme.titleLarge),
          ),
          Text(
            widget.reminder.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KorSpacing.s5),
          row(options[0], options[1]),
          const SizedBox(height: KorSpacing.s3),
          row(options[2], options[3]),
          const SizedBox(height: KorSpacing.s3),
          InkWell(
            key: SnoozeSheetKeys.custom,
            borderRadius: KorRadius.mdAll,
            onTap: _pickCustom,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s3),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: scheme.primary),
                    const SizedBox(width: KorSpacing.s4),
                    Expanded(
                      child: Text(
                        'Tarih ve saat seç…',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_pastError)
            Semantics(
              liveRegion: true,
              child: Row(
                key: SnoozeSheetKeys.pastError,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: KorSizes.iconSm,
                    color: scheme.error,
                  ),
                  const SizedBox(width: KorSpacing.s3),
                  Expanded(
                    child: Text(
                      'Bu saat geçti. Daha ileri bir zaman seç.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String time;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: KorRadius.mdAll),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(KorSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: KorSizes.iconSm, color: scheme.tertiary),
                      const SizedBox(width: KorSpacing.s3),
                      Expanded(
                        child: Text(label, style: theme.textTheme.titleSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: KorSpacing.s1),
                  Text(
                    time,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
