import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class RecurrenceSheetKeys {
  static const segments = Key('recurrenceSheet.segments');
  static Key weekday(int weekday) => Key('recurrenceSheet.weekday.$weekday');
  static const decrement = Key('recurrenceSheet.interval.decrement');
  static const increment = Key('recurrenceSheet.interval.increment');
  static const intervalLabel = Key('recurrenceSheet.interval.label');
  static const until = Key('recurrenceSheet.until');
  static const clearUntil = Key('recurrenceSheet.until.clear');
  static const preview = Key('recurrenceSheet.preview');
  static const done = Key('recurrenceSheet.done');
  static const cancel = Key('recurrenceSheet.cancel');
}

/// Segments of the Tekrar sheet (§3.3.4). "Özel" is every N ≥ 2 days;
/// Günlük is every day.
enum RecurrenceMode {
  none('Yok'),
  daily('Günlük'),
  weekly('Haftalık'),
  monthly('Aylık'),
  custom('Özel');

  const RecurrenceMode(this.label);

  final String label;

  static RecurrenceMode of(RecurrenceRule rule) => switch (rule.frequency) {
        RecurrenceFrequency.none => none,
        RecurrenceFrequency.daily => rule.interval == 1 ? daily : custom,
        RecurrenceFrequency.weekly => weekly,
        RecurrenceFrequency.monthly => monthly,
      };
}

/// Occurrence labels for the sheet preview and the "Sonraki" snackbar.
abstract final class RecurrenceFormat {
  static const _locale = 'tr_TR';

  /// `Cmt 20 Eyl` (`Cmt 2 Oca 2027` in another year than [now]).
  static String day(DateTime d, DateTime now) => DateFormat(
        d.year == now.year ? 'EEE d MMM' : 'EEE d MMM y',
        _locale,
      ).format(d);

  /// `Sonraki: Cmt 20 Eyl 16:00`.
  static String next(DateTime at, DateTime now) =>
      'Sonraki: ${day(at, now)} ${KorFormat.time(at)}';

  /// `Sonraki 3: Cmt 13 Eyl · Cmt 20 Eyl · Cmt 27 Eyl`.
  static String preview(List<DateTime> dates, DateTime now) => dates.isEmpty
      ? 'Bu kuralla yaklaşan tekrar yok.'
      : 'Sonraki ${dates.length}: ${dates.map((d) => day(d, now)).join(' · ')}';
}

/// Opens the Tekrar sheet. [anchor] is the reminder's date and time (the
/// series start); the preview lists occurrences from it (or from [now] when
/// it is already past). Returns the chosen rule, or `null` when dismissed.
Future<RecurrenceRule?> showRecurrenceSheet(
  BuildContext context, {
  required RecurrenceRule initial,
  required DateTime anchor,
  required DateTime now,
}) {
  return showModalBottomSheet<RecurrenceRule>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RecurrenceSheet(initial: initial, anchor: anchor, now: now),
  );
}

class RecurrenceSheet extends StatefulWidget {
  const RecurrenceSheet({
    super.key,
    required this.initial,
    required this.anchor,
    required this.now,
  });

  final RecurrenceRule initial;
  final DateTime anchor;
  final DateTime now;

  @override
  State<RecurrenceSheet> createState() => _RecurrenceSheetState();
}

class _RecurrenceSheetState extends State<RecurrenceSheet> {
  late RecurrenceMode _mode;
  late Set<int> _weekdays;
  late int _weeks;
  late int _months;
  late int _days;
  late int _dayOfMonth;
  DateTime? _until;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _mode = RecurrenceMode.of(r);
    final weekly = r.frequency == RecurrenceFrequency.weekly;
    _weekdays = weekly && r.weekdays.isNotEmpty
        ? {...r.weekdays}
        : {widget.anchor.weekday};
    _weeks = weekly ? r.interval : 1;
    _months = r.frequency == RecurrenceFrequency.monthly ? r.interval : 1;
    _days = _mode == RecurrenceMode.custom ? r.interval : 2;
    _dayOfMonth = r.dayOfMonth ?? widget.anchor.day;
    _until = r.until;
  }

  RecurrenceRule get _rule => switch (_mode) {
        RecurrenceMode.none => RecurrenceRule.none,
        RecurrenceMode.daily => RecurrenceRule.daily(until: _until),
        RecurrenceMode.weekly =>
          RecurrenceRule.weekly(_weekdays, interval: _weeks, until: _until),
        RecurrenceMode.monthly => RecurrenceRule.monthly(
            dayOfMonth: _dayOfMonth,
            interval: _months,
            until: _until,
          ),
        RecurrenceMode.custom =>
          RecurrenceRule.daily(interval: _days, until: _until),
      };

  void _toggleWeekday(int weekday) {
    setState(() {
      if (!_weekdays.contains(weekday)) {
        _weekdays.add(weekday);
      } else if (_weekdays.length > 1) {
        // At least one day stays selected.
        _weekdays.remove(weekday);
      }
    });
  }

  Future<void> _pickUntil() async {
    final anchor = widget.anchor;
    final first = DateTime(anchor.year, anchor.month, anchor.day);
    final initial =
        _until ?? DateTime(anchor.year, anchor.month + 1, anchor.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      currentDate: widget.now,
      firstDate: first,
      lastDate: DateTime(anchor.year + 5, 12, 31),
      helpText: 'Bitiş tarihi',
    );
    if (picked != null && mounted) setState(() => _until = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final rule = _rule;
    final anchor = widget.anchor;
    final from = anchor.isBefore(widget.now) ? widget.now : anchor;
    final upcoming = rule.upcoming(from: from, anchor: anchor);

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
            child: Text('Tekrar', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: KorSpacing.s4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<RecurrenceMode>(
              key: RecurrenceSheetKeys.segments,
              showSelectedIcon: false,
              segments: [
                for (final mode in RecurrenceMode.values)
                  ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          if (_mode == RecurrenceMode.weekly) ...[
            const SizedBox(height: KorSpacing.s5),
            Text('Günler', style: theme.textTheme.titleSmall),
            const SizedBox(height: KorSpacing.s3),
            Wrap(
              spacing: KorSpacing.s2,
              runSpacing: KorSpacing.s2,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  _WeekdayButton(
                    key: RecurrenceSheetKeys.weekday(d),
                    weekday: d,
                    selected: _weekdays.contains(d),
                    onTap: () => _toggleWeekday(d),
                  ),
              ],
            ),
          ],
          if (_mode == RecurrenceMode.weekly ||
              _mode == RecurrenceMode.monthly ||
              _mode == RecurrenceMode.custom) ...[
            const SizedBox(height: KorSpacing.s4),
            _IntervalStepper(
              label: switch (_mode) {
                RecurrenceMode.weekly =>
                  _weeks == 1 ? 'Her hafta' : '$_weeks haftada bir',
                RecurrenceMode.monthly =>
                  _months == 1 ? 'Her ay' : '$_months ayda bir',
                _ => '$_days günde bir',
              },
              canDecrement: switch (_mode) {
                RecurrenceMode.weekly => _weeks > 1,
                RecurrenceMode.monthly => _months > 1,
                _ => _days > 2,
              },
              canIncrement: switch (_mode) {
                RecurrenceMode.weekly => _weeks < RecurrenceRule.maxInterval,
                RecurrenceMode.monthly => _months < RecurrenceRule.maxInterval,
                _ => _days < RecurrenceRule.maxInterval,
              },
              onChanged: (delta) => setState(() {
                switch (_mode) {
                  case RecurrenceMode.weekly:
                    _weeks += delta;
                  case RecurrenceMode.monthly:
                    _months += delta;
                  default:
                    _days += delta;
                }
              }),
            ),
          ],
          if (_mode == RecurrenceMode.monthly)
            Text(
              _dayOfMonth > 28
                  ? 'Ayın ${RecurrenceRule.dayOfMonthLabel(_dayOfMonth)}; '
                      'kısa aylarda ayın son günü.'
                  : 'Ayın ${RecurrenceRule.dayOfMonthLabel(_dayOfMonth)}.',
              style: muted,
            ),
          if (_mode != RecurrenceMode.none) ...[
            const SizedBox(height: KorSpacing.s4),
            // Label and chip share a line while they fit; at large text
            // the chip goes under "Bitiş" (§3.6 rule 6).
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: KorSpacing.s2,
              children: [
                Text('Bitiş', style: theme.textTheme.titleMedium),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ActionChip(
                        key: RecurrenceSheetKeys.until,
                        avatar: const Icon(Icons.event_rounded),
                        label: Text(
                          _until == null
                              ? 'Hiçbir zaman'
                              : KorFormat.dayMonth(_until!, widget.now),
                        ),
                        tooltip: 'Bitiş tarihi seç',
                        onPressed: _pickUntil,
                      ),
                    ),
                    if (_until != null)
                      IconButton(
                        key: RecurrenceSheetKeys.clearUntil,
                        tooltip: 'Bitişi kaldır',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _until = null),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            Semantics(
              liveRegion: true,
              child: Text(
                RecurrenceFormat.preview(upcoming, widget.now),
                key: RecurrenceSheetKeys.preview,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: KorSpacing.s6),
          Row(
            children: [
              TextButton(
                key: RecurrenceSheetKeys.cancel,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              const Spacer(),
              FilledButton(
                key: RecurrenceSheetKeys.done,
                onPressed: () => Navigator.of(context).pop(rule),
                child: const Text('Tamam'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 48 dp circular weekday toggle.
class _WeekdayButton extends StatelessWidget {
  const _WeekdayButton({
    super.key,
    required this.weekday,
    required this.selected,
    required this.onTap,
  });

  final int weekday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: RecurrenceRule.weekdayNames[weekday - 1],
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: KorSizes.minTouch,
            child: Center(
              child: Text(
                RecurrenceRule.weekdayShortNames[weekday - 1],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Her [N] …" stepper with 48 dp − / + buttons.
class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({
    required this.label,
    required this.canDecrement,
    required this.canIncrement,
    required this.onChanged,
  });

  final String label;
  final bool canDecrement;
  final bool canIncrement;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.outlined(
          key: RecurrenceSheetKeys.decrement,
          tooltip: 'Azalt',
          icon: const Icon(Icons.remove_rounded),
          onPressed: canDecrement ? () => onChanged(-1) : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              label,
              key: RecurrenceSheetKeys.intervalLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        IconButton.outlined(
          key: RecurrenceSheetKeys.increment,
          tooltip: 'Artır',
          icon: const Icon(Icons.add_rounded),
          onPressed: canIncrement ? () => onChanged(1) : null,
        ),
      ],
    );
  }
}
