import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/calendar_dates.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/birthdays/birthday_groups.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class BirthdayEditorKeys {
  static const name = Key('birthdayEditor.name');
  static const save = Key('birthdayEditor.save');
  static const date = Key('birthdayEditor.date');
  static const yearUnknown = Key('birthdayEditor.yearUnknown');
}

Future<void> showBirthdayEditorSheet(
  BuildContext context, {
  Birthday? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _BirthdayEditorBody(existing: existing),
  );
}

class _BirthdayEditorBody extends StatefulWidget {
  final Birthday? existing;

  const _BirthdayEditorBody({this.existing});

  @override
  State<_BirthdayEditorBody> createState() => _BirthdayEditorBodyState();
}

class _BirthdayEditorBodyState extends State<_BirthdayEditorBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime? _date;

  /// "Yıl bilinmiyor" (F4.4): saved as `Birthday.year == null`, no age.
  late bool _yearUnknown;

  /// True while the year inside [_date] is only a placeholder for the picker
  /// (a stored year-less birthday has no real year to fall back to).
  late bool _placeholderYear;
  late TimeOfDay _notifyTime;
  late Set<int> _offsets;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _yearUnknown = e != null && !e.hasYear;
    _placeholderYear = _yearUnknown;
    _date = e == null
        ? null
        // The picker needs a real year; a leap year keeps 29 Şubat.
        : DateTime(
            e.year ?? _lastLeapYear(DateTime.now().year), e.month, e.day);
    _notifyTime = TimeOfDay(
      hour: e?.notifyHour ?? 9,
      minute: e?.notifyMinute ?? 0,
    );
    _offsets = Set<int>.from(e?.advanceOffsetsMinutes ?? const <int>[0, 1440]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = _date;
    final base = date ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: context.l10n.birthdayDatePickerTitle,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _placeholderYear = false;
      });
    }
  }

  static int _lastLeapYear(int from) {
    var y = from;
    while (!CalendarDates.isLeapYear(y)) {
      y--;
    }
    return y;
  }

  void _setYearUnknown(bool value) {
    setState(() {
      _yearUnknown = value;
      // A stored year-less date has no real year to go back to.
      if (!value && _placeholderYear) {
        _date = null;
        _placeholderYear = false;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime,
      helpText: context.l10n.birthdayTimePickerTitle,
    );
    if (picked != null) setState(() => _notifyTime = picked);
  }

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.birthdayNameEmpty);
      return;
    }
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.editorDateMissing)),
      );
      return;
    }
    if (_offsets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.birthdayOffsetsEmpty)),
      );
      return;
    }

    // Notification pre-permission the first time something is scheduled.
    if (cubit.state.settings.notificationsEnabled) {
      await PermissionFlows.beforeScheduling(context);
    }

    final note = _noteCtrl.text.trim();
    final existing = widget.existing;

    final offsetsSorted = _offsets.toList()..sort();

    final birthday = Birthday(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      note: note.isEmpty ? null : note,
      month: _date!.month,
      day: _date!.day,
      year: _yearUnknown ? null : _date!.year,
      notifyHour: _notifyTime.hour,
      notifyMinute: _notifyTime.minute,
      advanceOffsetsMinutes: offsetsSorted,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (existing == null) {
      await cubit.addBirthday(birthday);
    } else {
      await cubit.updateBirthday(birthday);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final l10n = ctx.l10n;
        return AlertDialog(
          title: Text(l10n.birthdayDeleteTitle),
          content: Text(l10n.birthdayDeleteBody(existing.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      await context.read<ReminderCubit>().deleteBirthday(existing.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CategoryVisuals.birthdayColorsOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    final l10n = context.l10n;
    final date = _date;
    final dateLabel = date == null
        ? l10n.editorDatePick
        : _yearUnknown
            // Format on a leap year so a year-less 29 Şubat stays 29 Şubat.
            ? KorFormat.pattern(
                l10n.dateFormatDayMonth,
                DateTime(2000, date.month, date.day),
                l10n,
              )
            : KorFormat.pattern(l10n.dateFormatDayMonthYear, date, l10n);
    final timeLabel = KorFormat.time(
      DateTime(2000, 1, 1, _notifyTime.hour, _notifyTime.minute),
    );

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
            Row(
              children: [
                IconBadge(
                  icon: CategoryVisuals.birthdayIcon,
                  foreground: colors.fg,
                  background: colors.container,
                  size: 44,
                ),
                const SizedBox(width: KorSpacing.s4),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.existing == null
                          ? l10n.birthdayNew
                          : l10n.birthdayEdit,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: l10n.actionDelete,
                    onPressed: _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            TextField(
              key: BirthdayEditorKeys.name,
              controller: _nameCtrl,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.birthdayNameLabel,
                hintText: l10n.birthdayNameHint,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: KorSpacing.s3),
            TextField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.editorNoteLabel,
                hintText: l10n.birthdayNoteHint,
              ),
            ),
            const SizedBox(height: KorSpacing.s5),
            GroupedCard(
              icon: Icons.event_rounded,
              title: l10n.birthdayDateCard,
              children: [
                Wrap(
                  spacing: KorSpacing.s3,
                  runSpacing: KorSpacing.s3,
                  children: [
                    ActionChip(
                      key: BirthdayEditorKeys.date,
                      avatar: const Icon(Icons.calendar_today_rounded),
                      label: Text(dateLabel),
                      tooltip: l10n.birthdayDatePick,
                      onPressed: _pickDate,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.schedule_rounded),
                      label: Text(
                        timeLabel,
                        // "saat 09:00", not "sıfır dokuz sıfır sıfır".
                        semanticsLabel: l10n.birthdayTimeSpoken(
                          l10n.timeSpoken(timeLabel),
                        ),
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      tooltip: l10n.birthdayTimePick,
                      onPressed: _pickTime,
                    ),
                    FilterChip(
                      key: BirthdayEditorKeys.yearUnknown,
                      label: Text(l10n.birthdayYearUnknown),
                      selected: _yearUnknown,
                      onSelected: _setYearUnknown,
                    ),
                  ],
                ),
                const SizedBox(height: KorSpacing.s3),
                Text(
                  l10n.birthdayYearUnknownHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            GroupedCard(
              icon: Icons.notifications_outlined,
              title: l10n.birthdayWhenCard,
              children: [
                Text(
                  l10n.birthdayWhenHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KorSpacing.s3),
                Wrap(
                  spacing: KorSpacing.s3,
                  runSpacing: KorSpacing.s3,
                  children: [
                    for (final preset in BirthdayAdvanceOffset.presets)
                      FilterChip(
                        label: Text(
                          BirthdayGroups.offsetLabel(preset.minutes, l10n),
                        ),
                        selected: _offsets.contains(preset.minutes),
                        selectedColor: colors.container,
                        checkmarkColor: colors.fg,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: _offsets.contains(preset.minutes)
                              ? colors.fg
                              : scheme.onSurface,
                        ),
                        side: BorderSide(
                          color: _offsets.contains(preset.minutes)
                              ? colors.fg
                              : scheme.outlineVariant,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _offsets.add(preset.minutes);
                            } else {
                              _offsets.remove(preset.minutes);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KorSpacing.s6),
            FilledButton(
              key: BirthdayEditorKeys.save,
              onPressed: _save,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
