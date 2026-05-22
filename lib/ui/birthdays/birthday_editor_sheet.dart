import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/ui/widgets/primary_button.dart';

const Color kBirthdayAccent = Color(0xFFEC407A); // pembe

Future<void> showBirthdayEditorSheet(
  BuildContext context, {
  Birthday? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
  late TimeOfDay _notifyTime;
  late Set<int> _offsets;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _date = e?.date;
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
    final base = _date ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Doğum tarihi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime,
      helpText: 'Bildirim saati',
    );
    if (picked != null) setState(() => _notifyTime = picked);
  }

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim boş olamaz.')),
      );
      return;
    }
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarih seçin.')),
      );
      return;
    }
    if (_offsets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir hatırlatma zamanı seçin.'),
        ),
      );
      return;
    }

    final note = _noteCtrl.text.trim();
    final existing = widget.existing;

    final offsetsSorted = _offsets.toList()..sort();

    final birthday = Birthday(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      note: note.isEmpty ? null : note,
      date: _date!,
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
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('"${existing.name}" doğum günü hatırlatması silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ReminderCubit>().deleteBirthday(existing.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    final dateLabel = _date != null
        ? DateFormat.yMMMd('tr_TR').format(_date!)
        : 'Tarih seç';
    final timeLabel = _notifyTime.format(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + bottom + viewInsets,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kBirthdayAccent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cake_rounded,
                    color: kBirthdayAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Yeni doğum günü'
                        : 'Doğum günü düzenle',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'İsim',
                hintText: 'Örn. Ayşe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Örn. Hediye fikri',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: dateLabel,
                    placeholder: _date == null,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_rounded,
                    label: timeLabel,
                    placeholder: false,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Hatırlatma zamanı',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Birden fazla seçim yapabilirsin.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in BirthdayAdvanceOffset.presets)
                  _OffsetChip(
                    label: preset.label,
                    selected: _offsets.contains(preset.minutes),
                    onTap: () {
                      setState(() {
                        if (_offsets.contains(preset.minutes)) {
                          _offsets.remove(preset.minutes);
                        } else {
                          _offsets.add(preset.minutes);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: _save,
              title: 'Kaydet',
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool placeholder;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = placeholder
        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
        : theme.colorScheme.onSurface;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: kBirthdayAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffsetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OffsetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = kBirthdayAccent;
    final bg = selected ? color : color.withValues(alpha: 0.12);
    final fg = selected ? Colors.white : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
