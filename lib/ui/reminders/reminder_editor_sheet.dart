import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/maps/location_picker_page.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/widgets/primary_button.dart';
import 'package:reminder/util/location_permissions.dart';

Future<void> showReminderEditorSheet(
  BuildContext context, {
  Reminder? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ReminderEditorBody(existing: existing),
  );
}

class _ReminderEditorBody extends StatefulWidget {
  final Reminder? existing;

  const _ReminderEditorBody({this.existing});

  @override
  State<_ReminderEditorBody> createState() => _ReminderEditorBodyState();
}

class _ReminderEditorBodyState extends State<_ReminderEditorBody> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _customCategoryCtrl;
  late String _categoryId;
  late bool _schedule;
  DateTime? _date;
  TimeOfDay? _time;

  late bool _locationTrigger;
  double? _locLat;
  double? _locLng;
  late double _locRadius;
  String? _locLabel;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _customCategoryCtrl = TextEditingController(
      text: e?.customCategoryLabel ?? '',
    );
    _categoryId = e?.categoryId ?? ReminderCategoryIds.other;
    _schedule = e?.remindAt != null;
    if (e?.remindAt != null) {
      final dt = e!.remindAt!.toLocal();
      _date = DateTime(dt.year, dt.month, dt.day);
      _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    _locationTrigger = e?.locationTriggerEnabled ?? false;
    _locLat = e?.locationLatitude;
    _locLng = e?.locationLongitude;
    _locRadius = e?.locationRadiusMeters ?? 150;
    _locLabel = e?.locationPlaceLabel;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final base = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime? _combinedRemindAt() {
    if (!_schedule) return null;
    final d = _date;
    final t = _time ?? TimeOfDay.now();
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _openLocationPicker() async {
    final ok = await ensureGeofenceLocationPermission();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Konum hatırlatması için konum izni (ve mümkünse “Her zaman”) gerekli.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          categoryId: _categoryId,
          initialPoint: _locLat != null && _locLng != null
              ? LatLng(_locLat!, _locLng!)
              : null,
          initialRadiusMeters: _locRadius,
          initialLabel: _locLabel,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _locLat = result.point.latitude;
        _locLng = result.point.longitude;
        _locRadius = result.radiusMeters;
        _locLabel = result.label;
      });
    }
  }

  Future<void> _save() async {
    final cubit = context.read<ReminderCubit>();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık boş olamaz.')),
      );
      return;
    }

    if (_categoryId == ReminderCategoryIds.other) {
      final c = _customCategoryCtrl.text.trim();
      if (c.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('“Diğer” için kategori adı yazın.'),
          ),
        );
        return;
      }
    }

    DateTime? remindAt = _combinedRemindAt();
    if (_schedule) {
      if (_date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarih seçin.')),
        );
        return;
      }
      final now = DateTime.now();
      if (remindAt != null && !remindAt.isAfter(now)) {
        remindAt = now.add(const Duration(minutes: 1));
      }
    } else {
      remindAt = null;
    }

    if (_locationTrigger) {
      if (_locLat == null || _locLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Konum hatırlatması açık. Devam etmek için önce «Konum seç» '
              'ekranında konumu kaydedin veya «Konuma gittiğimde hatırlat» '
              'seçeneğini kapatın.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 100),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      final locOk = await ensureGeofenceLocationPermission();
      if (!locOk) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni verilmedi.')),
          );
        }
        return;
      }
    } else {
      _locLat = null;
      _locLng = null;
      _locLabel = null;
    }

    final note = _noteCtrl.text.trim();
    final customCat = _categoryId == ReminderCategoryIds.other
        ? _customCategoryCtrl.text.trim()
        : null;

    final existing = widget.existing;

    final reminder = Reminder(
      id: existing?.id ?? Uuid().v4(), // ignore: prefer_const_constructors
      title: title,
      note: note.isEmpty ? null : note,
      isDone: existing?.isDone ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
      remindAt: remindAt,
      categoryId: _categoryId,
      customCategoryLabel: customCat,
      locationTriggerEnabled: _locationTrigger,
      locationLatitude: _locationTrigger ? _locLat : null,
      locationLongitude: _locationTrigger ? _locLng : null,
      locationRadiusMeters: _locRadius,
      locationPlaceLabel: _locationTrigger ? _locLabel : null,
    );

    if (existing == null) {
      await cubit.addReminder(reminder);
    } else {
      await cubit.updateReminder(reminder);
    }

    if (mounted) Navigator.of(context).pop();
  }

  String _locationSummary() {
    if (_locLat == null || _locLng == null) return 'Haritadan seçilmedi';
    if (_locLabel != null && _locLabel!.isNotEmpty) return _locLabel!;
    return '${_locLat!.toStringAsFixed(5)}, ${_locLng!.toStringAsFixed(5)} · ${_locRadius.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    final dateLabel =
        _date != null ? DateFormat.yMMMd('tr_TR').format(_date!) : 'Tarih seç';
    final timeLabel = _time != null ? _time!.format(context) : 'Saat seç';

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
            Text(
              widget.existing == null ? 'Yeni hatırlatıcı' : 'Düzenle',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kategori',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: ReminderCategoryIds.orderedIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final id = ReminderCategoryIds.orderedIds[i];
                  final selected = _categoryId == id;
                  final color = CategoryVisuals.colorFor(id);
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = id),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            CategoryVisuals.iconFor(id),
                            color: selected ? Colors.white : color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ReminderCategoryIds.defaultLabel(id),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? color
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_categoryId == ReminderCategoryIds.other) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCategoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Özel kategori adı',
                  hintText: 'Örn. Spor salonu',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn. Tuvalet kağıdı al',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zamanla / bildir'),
              subtitle: const Text(
                'Belirli tarih ve saatte bildirim.',
                style: TextStyle(fontSize: 12),
              ),
              value: _schedule,
              onChanged: (v) => setState(() {
                _schedule = v;
                if (v && _date == null) {
                  final n = DateTime.now();
                  _date = DateTime(n.year, n.month, n.day);
                  _time = TimeOfDay.fromDateTime(
                    n.add(const Duration(hours: 1)),
                  );
                }
              }),
            ),
            if (_schedule) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(dateLabel),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(timeLabel),
                onTap: _pickTime,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Konuma gittiğimde hatırlat'),
              subtitle: Text(
                Platform.isAndroid
                    ? 'Seçilen yere yaklaşınca bildirim. Arka planda konum gerekebilir.'
                    : 'Seçilen bölgeye girince bildirim. “Her zaman” konum izni gerekir.',
                style: const TextStyle(fontSize: 12),
              ),
              value: _locationTrigger,
              onChanged: (v) {
                setState(() {
                  _locationTrigger = v;
                  if (!v) {
                    _locLat = null;
                    _locLng = null;
                    _locLabel = null;
                  }
                });
              },
            ),
            if (_locationTrigger) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.map_outlined),
                title: const Text('Konum seç'),
                subtitle: Text(_locationSummary()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openLocationPicker,
              ),
            ],
            const SizedBox(height: 16),
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
