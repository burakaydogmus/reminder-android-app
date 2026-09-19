import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/maps/location_picker_page.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_actions.dart';
import 'package:reminder/ui/reminders/subtasks_card.dart';
import 'package:reminder/ui/theme/extensions/kor_colors_ext.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';

/// Keys for tests.
abstract final class ReminderEditorKeys {
  static const title = Key('reminderEditor.title');
  static const save = Key('reminderEditor.save');
  static const recurrence = Key('reminderEditor.recurrence');
  static const pin = Key('reminderEditor.pin');
  static const priority = Key('reminderEditor.priority');
  static Key category(String id) => Key('reminderEditor.category.$id');
  static const newCategory = Key('reminderEditor.newCategory');
}

/// Reminder editor sheet (§3.3.4, reduced to today's data): title first with
/// autofocus, note, category chips, "Ne zaman" and "Nerede" grouped cards.
///
/// [now] is the clock for past-time checks; defaults to the caller's
/// [NowScope] clock (tests pass a fixed one).
Future<void> showReminderEditorSheet(
  BuildContext context, {
  Reminder? existing,
  String? initialCategoryId,
  DateTime? initialRemindAt,
  DateTime Function()? now,
}) {
  final clock = now ?? NowScope.clockOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // F4.7: the editor sheet rises on spatialSlow (fade-length ease with
    // Reduce Motion); it stays a sheet on both platforms (F4.1).
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (ctx) => _ReminderEditorBody(
      existing: existing,
      initialCategoryId: initialCategoryId,
      initialRemindAt: initialRemindAt,
      clock: clock,
    ),
  );
}

class _ReminderEditorBody extends StatefulWidget {
  final Reminder? existing;
  final String? initialCategoryId;
  final DateTime? initialRemindAt;
  final DateTime Function() clock;

  const _ReminderEditorBody({
    this.existing,
    this.initialCategoryId,
    this.initialRemindAt,
    this.clock = DateTime.now,
  });

  @override
  State<_ReminderEditorBody> createState() => _ReminderEditorBodyState();
}

class _ReminderEditorBodyState extends State<_ReminderEditorBody> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late String _categoryId;
  late bool _schedule;
  DateTime? _date;
  TimeOfDay? _time;

  /// Tekrar kuralı (F3.1). Tarih değişince "tüm seri" olarak uyarlanır
  /// ([RecurrenceRule.alignedTo]); "yalnızca bu sefer" henüz yok.
  late RecurrenceRule _recurrence;

  /// Existing reminder's time at minute precision; an unchanged overdue time
  /// may still be saved (F1.8b).
  DateTime? _originalRemindAt;

  /// Set when save was blocked by a past time; outlines the section.
  bool _pastTimeBlocked = false;
  final _scheduleSectionKey = GlobalKey();

  late bool _locationTrigger;
  double? _locLat;
  double? _locLng;
  late double _locRadius;
  String? _locLabel;

  String? _titleError;
  String? _locationError;

  /// Maddeler (F3.3); "Kaydet" ile hatırlatıcıyla birlikte kaydedilir.
  late List<Subtask> _subtasks;

  /// Öncelik ve sabitleme (F3.4); "Kaydet" ile kaydedilir.
  late int _priority;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _categoryId =
        e?.categoryId ?? widget.initialCategoryId ?? ReminderCategoryIds.other;
    final remindAt = e != null ? e.remindAt : widget.initialRemindAt;
    _schedule = remindAt != null;
    if (remindAt != null) {
      final dt = remindAt.toLocal();
      _date = DateTime(dt.year, dt.month, dt.day);
      _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
      if (e != null) {
        _originalRemindAt =
            DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      }
    }
    _recurrence = remindAt != null
        ? (e?.recurrence ?? RecurrenceRule.none)
        : RecurrenceRule.none;
    _locationTrigger = e?.locationTriggerEnabled ?? false;
    _locLat = e?.locationLatitude;
    _locLng = e?.locationLongitude;
    _locRadius = e?.locationRadiusMeters ?? 150;
    _locLabel = e?.locationPlaceLabel;
    _subtasks = e?.subtasks ?? const [];
    _priority = e?.priority ?? ReminderPriority.none;
    _pinned = e?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = widget.clock();
    final base = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      currentDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _recurrence = _recurrence.alignedTo(picked);
        _pastTimeBlocked = false;
      });
    }
  }

  /// Default date/time when scheduling is turned on: today, one hour later.
  (DateTime, TimeOfDay) _defaultSchedule() {
    final n = widget.clock();
    return (
      DateTime(n.year, n.month, n.day),
      TimeOfDay.fromDateTime(n.add(const Duration(hours: 1))),
    );
  }

  /// Opens the Tekrar sheet. Tekrar needs a time: without one the sheet
  /// starts from today + one hour, applied only when a rule is chosen.
  Future<void> _openRecurrence() async {
    final (defaultDate, defaultTime) = _defaultSchedule();
    final hasSchedule = _schedule && _date != null;
    final date = hasSchedule ? _date! : defaultDate;
    final time = hasSchedule
        ? (_time ?? TimeOfDay.fromDateTime(widget.clock()))
        : defaultTime;
    final anchor =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final rule = await showRecurrenceSheet(
      context,
      initial: _recurrence,
      anchor: anchor,
      now: widget.clock(),
    );
    if (rule == null || !mounted) return;
    setState(() {
      _recurrence = rule;
      if (rule.isNone) return;
      if (!hasSchedule) {
        _schedule = true;
        _date = date;
        _time = time;
      }
      // A weekly rule whose days exclude the chosen date starts on the first
      // matching day (shown in the sheet preview and the date chip).
      final first = rule.firstOnOrAfter(from: anchor, anchor: anchor);
      if (first != null && !KorFormat.isSameDay(first, anchor)) {
        _date = DateTime(first.year, first.month, first.day);
        _pastTimeBlocked = false;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.fromDateTime(widget.clock()),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _pastTimeBlocked = false;
      });
    }
  }

  DateTime? _combinedRemindAt() {
    if (!_schedule) return null;
    final d = _date;
    final t = _time ?? TimeOfDay.fromDateTime(widget.clock());
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  /// The chosen time when it is in the past, otherwise null.
  DateTime? _pastSelection(DateTime now) {
    final at = _combinedRemindAt();
    if (at == null || !PastTime.isPast(at, now)) return null;
    return at;
  }

  /// An existing reminder's overdue time left untouched: saving keeps it.
  bool _isUnchangedOriginal(DateTime at) =>
      _originalRemindAt != null && at == _originalRemindAt;

  void _applySuggestion(DateTime suggested) {
    setState(() {
      _date = DateTime(suggested.year, suggested.month, suggested.day);
      _time = TimeOfDay(hour: suggested.hour, minute: suggested.minute);
      _pastTimeBlocked = false;
    });
  }

  Future<void> _openLocationPicker() async {
    // Explains and asks once (F1.6); the map opens either way so a place
    // can be picked manually without permission.
    await PermissionFlows.location(context);
    if (!mounted) return;

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
        _locationError = null;
      });
    }
  }

  /// "Tümü tamam — hatırlatıcıyı tamamla?": saves, then completes through
  /// the shared Tamamla action (undo snackbar; recurring reminders advance).
  Future<void> _saveAndComplete() => _save(complete: true);

  /// Items with a title, trimmed, in order.
  List<Subtask> _cleanSubtasks() => SubtaskList.inOrder([
        for (final s in _subtasks)
          if (s.title.trim().isNotEmpty) s.copyWith(title: s.title.trim()),
      ]);

  Future<void> _save({bool complete = false}) async {
    final cubit = context.read<ReminderCubit>();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Başlık boş olamaz.');
      return;
    }

    DateTime? remindAt = _combinedRemindAt();
    if (_schedule) {
      if (_date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarih seçin.')),
        );
        return;
      }
      // Past time: never shift silently (F1.8b). Block with the inline
      // warning, except an existing overdue reminder whose time is unchanged.
      final past = _pastSelection(widget.clock());
      if (past != null) {
        if (_isUnchangedOriginal(past)) {
          remindAt = widget.existing!.remindAt;
        } else {
          setState(() => _pastTimeBlocked = true);
          final sectionContext = _scheduleSectionKey.currentContext;
          if (sectionContext != null) {
            await Scrollable.ensureVisible(
              sectionContext,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
            );
          }
          return;
        }
      }
    } else {
      remindAt = null;
    }

    if (_locationTrigger) {
      if (_locLat == null || _locLng == null) {
        setState(
          () => _locationError =
              'Konum seçilmedi. Bir yer seç ya da «Nerede»yi kapat.',
        );
        return;
      }
      // Missing background location does not block saving; the card shows
      // an inline warning instead (F1.6).
    } else {
      _locLat = null;
      _locLng = null;
      _locLabel = null;
    }

    // Notification pre-permission the first time something is scheduled.
    if ((remindAt != null || _locationTrigger) &&
        cubit.state.settings.notificationsEnabled) {
      await PermissionFlows.beforeScheduling(context);
    }

    final note = _noteCtrl.text.trim();
    final existing = widget.existing;
    // F4.3: the pre-v5 "Diğer + özel ad" label is no longer written; an
    // unchanged category keeps the old value (rollback safety).
    final legacyLabel = existing != null && existing.categoryId == _categoryId
        ? existing.customCategoryLabel
        : null;

    final reminder = Reminder(
      id: existing?.id ?? Uuid().v4(), // ignore: prefer_const_constructors
      title: title,
      note: note.isEmpty ? null : note,
      isDone: existing?.isDone ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
      remindAt: remindAt,
      categoryId: _categoryId,
      customCategoryLabel: legacyLabel,
      locationTriggerEnabled: _locationTrigger,
      locationLatitude: _locationTrigger ? _locLat : null,
      locationLongitude: _locationTrigger ? _locLng : null,
      locationRadiusMeters: _locRadius,
      locationPlaceLabel: _locationTrigger ? _locLabel : null,
      recurrence: remindAt == null ? RecurrenceRule.none : _recurrence,
      subtasks: _cleanSubtasks(),
      priority: _priority,
      pinned: _pinned,
    );

    if (existing == null) {
      await cubit.addReminder(reminder);
    } else {
      await cubit.updateReminder(reminder);
    }

    if (!mounted) return;
    if (complete && !reminder.isDone) {
      unawaited(
          toggleReminderDoneWithUndo(context, reminder, now: widget.clock));
    }
    Navigator.of(context).pop();
  }

  /// "+ Yeni" chip: creates a category and selects it.
  Future<void> _newCategory() async {
    final created = await showCategoryEditorSheet(context);
    if (created == null || !mounted) return;
    setState(() => _categoryId = created.id);
  }

  /// Never shows raw coordinates.
  String _locationSummary() {
    if (_locLat == null || _locLng == null) return 'Konum seç';
    final radius = '${_locRadius.round()} m';
    final label = _locLabel?.trim();
    if (label != null && label.isNotEmpty) return '$label · $radius';
    return 'Seçilen konum · $radius';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final now = widget.clock();
    final pastSelection = _schedule ? _pastSelection(now) : null;
    final mutedBody = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final dateLabel =
        _date != null ? KorFormat.relativeDay(_date!, now) : 'Tarih seç';
    final timeLabel = _time != null
        ? KorFormat.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute))
        : 'Saat seç';

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
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.existing == null
                          ? 'Yeni hatırlatıcı'
                          : 'Hatırlatıcıyı düzenle',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                // 📌 in the top bar (§3.3.4, F3.4); saved with "Kaydet".
                IconButton(
                  key: ReminderEditorKeys.pin,
                  isSelected: _pinned,
                  tooltip: PriorityPinVisuals.pinActionLabel(_pinned),
                  icon: Icon(PriorityPinVisuals.pinIcon(false)),
                  selectedIcon: Icon(
                    PriorityPinVisuals.pinIcon(true),
                    color: scheme.primary,
                  ),
                  onPressed: () => setState(() => _pinned = !_pinned),
                ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            TextField(
              key: ReminderEditorKeys.title,
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.titleMedium,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                labelText: 'Başlık',
                hintText: 'Ne hatırlatayım?',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: KorSpacing.s3),
            TextField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: KorSpacing.s5),
            const SectionHeader(
              title: 'Kategori',
              icon: Icons.label_outline_rounded,
            ),
            // F4.3: every category in the user's order, then "+ Yeni".
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in CategoryVisuals.catalogOf(context).ordered)
                    Padding(
                      padding: const EdgeInsets.only(right: KorSpacing.s3),
                      child: _CategoryChip(
                        key: ReminderEditorKeys.category(c.id),
                        category: c,
                        selected: _categoryId == c.id,
                        onSelected: () => setState(() => _categoryId = c.id),
                      ),
                    ),
                  ActionChip(
                    key: ReminderEditorKeys.newCategory,
                    avatar: const Icon(Icons.add_rounded),
                    label: const Text('Yeni'),
                    tooltip: 'Yeni kategori',
                    onPressed: _newCategory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KorSpacing.s4),
            _PrioritySelector(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: KorSpacing.s5),
            GroupedCard(
              key: _scheduleSectionKey,
              icon: Icons.schedule_rounded,
              title: 'Ne zaman',
              borderColor: _pastTimeBlocked && pastSelection != null
                  ? scheme.error
                  : null,
              headerTrailing: Semantics(
                label: 'Zamanla ve bildir',
                child: Switch.adaptive(
                  value: _schedule,
                  onChanged: (v) => setState(() {
                    _schedule = v;
                    _pastTimeBlocked = false;
                    if (!v) _recurrence = RecurrenceRule.none;
                    if (v && _date == null) {
                      final (date, time) = _defaultSchedule();
                      _date = date;
                      _time = time;
                    }
                  }),
                ),
              ),
              children: [
                if (_schedule) ...[
                  Wrap(
                    spacing: KorSpacing.s3,
                    runSpacing: KorSpacing.s3,
                    children: [
                      ActionChip(
                        key: ReminderScheduleKeys.dateChip,
                        avatar: Icon(
                          Icons.event_rounded,
                          color: pastSelection != null ? scheme.error : null,
                        ),
                        label: Text(dateLabel),
                        labelStyle: pastSelection != null
                            ? theme.textTheme.labelLarge?.copyWith(
                                color: scheme.error,
                              )
                            : null,
                        side: pastSelection != null
                            ? BorderSide(color: scheme.error)
                            : null,
                        tooltip: 'Tarih seç',
                        onPressed: _pickDate,
                      ),
                      ActionChip(
                        key: ReminderScheduleKeys.timeChip,
                        avatar: Icon(
                          Icons.schedule_rounded,
                          color: pastSelection != null ? scheme.error : null,
                        ),
                        label: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        labelStyle: pastSelection != null
                            ? theme.textTheme.labelLarge?.copyWith(
                                color: scheme.error,
                              )
                            : null,
                        side: pastSelection != null
                            ? BorderSide(color: scheme.error)
                            : null,
                        tooltip: 'Saat seç',
                        onPressed: _pickTime,
                      ),
                    ],
                  ),
                  if (pastSelection != null)
                    Padding(
                      padding: const EdgeInsets.only(top: KorSpacing.s3),
                      child: PastTimeHint(
                        suggested: PastTime.suggestion(pastSelection, now),
                        now: now,
                        onApply: () => _applySuggestion(
                          PastTime.suggestion(pastSelection, widget.clock()),
                        ),
                      ),
                    ),
                ] else
                  Text('Seçtiğin tarih ve saatte bildirim.', style: mutedBody),
                Padding(
                  padding: const EdgeInsets.only(top: KorSpacing.s3),
                  child: _RecurrenceRow(
                    summary: _schedule
                        ? _recurrence.summary
                        : RecurrenceRule.none.summary,
                    onTap: _openRecurrence,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            GroupedCard(
              icon: Icons.place_outlined,
              title: 'Nerede',
              borderColor: _locationError != null ? scheme.error : null,
              headerTrailing: Semantics(
                label: 'Konuma gelince hatırlat',
                child: Switch.adaptive(
                  value: _locationTrigger,
                  onChanged: (v) {
                    setState(() {
                      _locationTrigger = v;
                      _locationError = null;
                      if (!v) {
                        _locLat = null;
                        _locLng = null;
                        _locLabel = null;
                      }
                    });
                    if (v) PermissionFlows.location(context);
                  },
                ),
              ),
              children: [
                if (_locationTrigger)
                  InkWell(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(KorSpacing.s4),
                    ),
                    onTap: _openLocationPicker,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined, color: scheme.primary),
                          const SizedBox(width: KorSpacing.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationSummary(),
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  'Bölgeye girince bildirim.',
                                  style: mutedBody,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text('Bir yere varınca hatırlat.', style: mutedBody),
                if (_locationTrigger) const _LocationPermissionWarning(),
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: KorSpacing.s2),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _locationError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KorSpacing.s4),
            SubtasksCard(
              subtasks: _subtasks,
              categoryId: _categoryId,
              onChanged: (next) => setState(() => _subtasks = next),
              onCompleteReminder:
                  (widget.existing?.isDone ?? false) ? null : _saveAndComplete,
            ),
            const SizedBox(height: KorSpacing.s6),
            FilledButton(
              key: ReminderEditorKeys.save,
              onPressed: () => _save(),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "↻ Tekrar · Her Cumartesi ›" row in the "Ne zaman" card (§3.3.4).
class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Tekrar: $summary',
      excludeSemantics: true,
      child: InkWell(
        key: ReminderEditorKeys.recurrence,
        borderRadius: const BorderRadius.all(Radius.circular(KorSpacing.s4)),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KorSizes.minTouch),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: KorSpacing.s4),
              Text('Tekrar', style: theme.textTheme.titleMedium),
              const SizedBox(width: KorSpacing.s4),
              Expanded(
                child: Text(
                  summary,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline warning in "Nerede" when background location is missing (F1.6).
class _LocationPermissionWarning extends StatelessWidget {
  const _LocationPermissionWarning();

  @override
  Widget build(BuildContext context) {
    final state = PermissionScope.of(context).snapshot?.location;
    if (state == null || state == LocationPermissionState.always) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = state == LocationPermissionState.whileInUse
        ? 'Konum izni yalnızca kullanırken açık. Uygulama kapalıyken '
            'bildirim gelmeyebilir.'
        : 'Konum izni yok. Yeri haritadan seçebilirsin ama arka planda '
            'bildirim gelmeyebilir.';
    return Padding(
      padding: const EdgeInsets.only(top: KorSpacing.s3),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
          const SizedBox(width: KorSpacing.s3),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
          TextButton(
            onPressed: () => PermissionFlows.fixLocation(context),
            child: const Text('Düzelt'),
          ),
        ],
      ),
    );
  }
}

/// Category chip; selected → `container` fill, `fg` icon and `onContainer`
/// text (F4.3: `fg` text on `container` fails contrast for light "kor").
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final ReminderCategory category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors =
        context.korColors.category(CategoryVisuals.colorKeyOf(category));
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        CategoryVisuals.iconOf(category),
        color: selected ? colors.fg : scheme.onSurfaceVariant,
      ),
      label: Text(category.name),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? colors.onContainer : scheme.onSurface,
      ),
      selectedColor: colors.container,
      side: BorderSide(
        color: selected ? colors.fg : scheme.outlineVariant,
      ),
    );
  }
}

/// "⚑ Öncelik" + Yok / Düşük / Orta / Yüksek (§3.3.4, F3.4). The segments
/// carry text, so the choice never depends on colour.
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Öncelik', icon: Icons.flag_outlined),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            key: ReminderEditorKeys.priority,
            showSelectedIcon: false,
            segments: [
              for (final p in ReminderPriority.values)
                ButtonSegment(value: p, label: Text(ReminderPriority.label(p))),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}
