import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/parsing/capture_to_reminder.dart';
import 'package:reminder/domain/parsing/category_aliases.dart';
import 'package:reminder/domain/parsing/turkish_capture_parser.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/capture/capture_text.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/common/recurrence_text.dart';
import 'package:reminder/ui/permissions/permission_flows.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/reminders/past_time_hint.dart';
import 'package:reminder/ui/reminders/priority_pin_visuals.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/extensions/kor_motion_ext.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class QuickCaptureKeys {
  static const field = Key('quickCapture.field');
  static const save = Key('quickCapture.save');
  static const details = Key('quickCapture.details');
  static const dateChip = Key('quickCapture.chip.date');
  static const recurrenceChip = Key('quickCapture.chip.recurrence');
  static const categoryChip = Key('quickCapture.chip.category');
  static const newCategoryChip = Key('quickCapture.chip.newCategory');
  static const priorityChip = Key('quickCapture.chip.priority');
  static const placeChip = Key('quickCapture.chip.place');
  static const splitChip = Key('quickCapture.chip.split');
  static const toast = Key('quickCapture.toast');
  static const undo = Key('quickCapture.undo');
}

/// Opens the quick-capture sheet (§3.3.3, F4.6b): type a sentence, the
/// Turkish parser (F4.6a) highlights what it understood, Enter or ↑ saves
/// and the sheet stays open for the next one. "Tüm ayrıntılar" closes it
/// and opens the full editor prefilled with the draft.
///
/// [now] is the clock (default: the caller's [NowScope]). [initialText]
/// prefills the field, cursor at the end (F5.3 "Market listesi" → `#market `).
Future<void> showQuickCaptureSheet(
  BuildContext context, {
  DateTime Function()? now,
  String initialText = '',
}) async {
  final clock = now ?? NowScope.clockOf(context);
  final draft = await showModalBottomSheet<Reminder>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Rises on spatialSlow; a 150 ms fade-length ease with Reduce Motion.
    sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
    builder: (_) => QuickCaptureSheet(clock: clock, initialText: initialText),
  );
  if (draft == null || !context.mounted) return;
  await showReminderEditorSheet(context, draft: draft, now: clock);
}

/// The sheet body; pops with a draft [Reminder] for "Tüm ayrıntılar".
class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({
    super.key,
    this.clock = DateTime.now,
    this.initialText = '',
  });

  final DateTime Function() clock;

  /// Text the field starts with (parsed on the first frame).
  final String initialText;

  /// How long the "Eklendi" toast stays (design: 3 s); longer with a
  /// screen reader.
  static const toastDuration = Duration(seconds: 3);
  static const toastScreenReaderDuration = Duration(seconds: 10);

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

/// A value picked on a chip instead of the typed one; `null` fields keep
/// the parsed value.
class _Overrides {
  bool remindAtSet = false;
  DateTime? remindAt;
  RecurrenceRule? recurrence;
  String? categoryId;
  int? priority;

  void clear() {
    remindAtSet = false;
    remindAt = null;
    recurrence = null;
    categoryId = null;
    priority = null;
  }
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  static const _uuid = Uuid();

  final _controller = CaptureTextController();
  final _focus = FocusNode();

  /// Phrases turned back into plain text with "×".
  final Set<String> _suppressed = {};
  final _overrides = _Overrides();
  bool _splitAccepted = false;
  bool _pastBlocked = false;

  late CaptureParseResult _result;
  Set<String> _tokenKeys = const {};

  Reminder? _added;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _result = CaptureParser.parse('', now: widget.clock());
    final initial = widget.initialText;
    if (initial.isNotEmpty) {
      _controller.value = TextEditingValue(
        text: initial,
        selection: TextSelection.collapsed(offset: initial.length),
      );
      // Parsing reads the theme and the category catalog: after the first
      // build, not in initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reparse(haptics: false);
      });
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _lastParsed = '';

  void _onTextChanged() {
    final text = _controller.text;
    if (text == _lastParsed) return;
    _reparse();
  }

  void _reparse({bool haptics = true}) {
    final text = _controller.text;
    _lastParsed = text;
    // F4.6c: the grammar follows the **app** language (F6.1), not the device.
    final locale = context.l10n.captureLocale;
    final result = CaptureText.parse(
      text,
      now: widget.clock(),
      suppressed: _suppressed,
      // F4.3: `#tag` also matches user categories.
      config: CategoryAliases.configFor(
        CategoryVisuals.readCatalog(context),
        locale: locale,
      ),
      locale: locale,
    );
    final keys = {
      for (final t in result.tokens) '${t.kind.name}:${t.text}',
    };
    if (haptics && keys.difference(_tokenKeys).isNotEmpty) {
      KorHaptics.of(context).tokenRecognized();
    }
    _tokenKeys = keys;
    setState(() {
      _result = result;
      _pastBlocked = false;
      if (result.splitSuggestion.isEmpty) _splitAccepted = false;
    });
    _controller.setTokens(text, result.tokens, _tokenStyle);
  }

  TextStyle _tokenStyle(CaptureToken token) {
    final scheme = Theme.of(context).colorScheme;
    const weight = FontWeight.w600;
    switch (token.kind) {
      case CaptureTokenKind.date:
      case CaptureTokenKind.time:
      case CaptureTokenKind.recurrence:
        return TextStyle(
          fontWeight: weight,
          color: scheme.onPrimaryContainer,
          backgroundColor: scheme.primaryContainer,
        );
      case CaptureTokenKind.category:
        final colors = CategoryVisuals.readColorsOf(
          context,
          _result.categoryId ?? ReminderCategoryIds.other,
        );
        return TextStyle(
          fontWeight: weight,
          color: colors.onContainer,
          backgroundColor: colors.container,
        );
      case CaptureTokenKind.priority:
        // A TextSpan cannot draw a border; a stroked background paints the
        // outline around the "!" run.
        return TextStyle(
          fontWeight: weight,
          color: scheme.primary,
          background: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = scheme.primary,
        );
      case CaptureTokenKind.place:
        return TextStyle(
          fontWeight: weight,
          color: scheme.onSecondaryContainer,
          backgroundColor: scheme.secondaryContainer,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Draft

  CaptureDraft _mapped({String? id}) => CaptureToReminder.map(
        _result,
        now: widget.clock(),
        id: id ?? _uuid.v4(),
        newSubtaskId: _uuid.v4,
        acceptSplit: _splitAccepted,
        texts: _captureTexts(context.l10n),
      );

  /// List titles and the place note in the app language (F6.1; the parser
  /// itself follows the same language since F4.6c).
  CaptureTexts _captureTexts(AppLocalizations l10n) => CaptureTexts(
        listTitle: (id) => id == ReminderCategoryIds.market
            ? l10n.captureListTitleMarket
            : l10n.captureListTitle(
                CategoryVisuals.labelIn(
                  CategoryVisuals.readCatalog(context),
                  id,
                  l10n,
                ),
              ),
        placeNote: l10n.capturePlaceNote,
      );

  /// The reminder that would be saved now: parsed values plus the chip
  /// overrides.
  Reminder _current({String? id}) {
    var r = _mapped(id: id).reminder;
    final o = _overrides;
    if (o.remindAtSet) {
      r = r.copyWith(
        remindAt: () => o.remindAt,
        recurrence: o.remindAt == null ? RecurrenceRule.none : null,
      );
    }
    if (o.recurrence != null) {
      r = r.copyWith(
        recurrence: r.remindAt == null ? RecurrenceRule.none : o.recurrence,
      );
    }
    if (o.categoryId != null) r = r.copyWith(categoryId: o.categoryId);
    if (o.priority != null) r = r.copyWith(priority: o.priority);
    return r;
  }

  /// A one-off time that has passed (F1.8b: warn, never save silently).
  DateTime? _pastTime(Reminder r) {
    final at = r.remindAt;
    if (at == null || !r.recurrence.isNone) return null;
    return PastTime.isPast(at, widget.clock()) ? at : null;
  }

  // ---------------------------------------------------------------------------
  // Actions

  Future<void> _save() async {
    final reminder = _current();
    if (reminder.title.trim().isEmpty) return;
    if (_pastTime(reminder) != null) {
      setState(() => _pastBlocked = true);
      return;
    }
    final cubit = context.read<ReminderCubit>();
    if (reminder.remindAt != null &&
        cubit.state.settings.notificationsEnabled) {
      await PermissionFlows.beforeScheduling(context);
      if (!mounted) return;
    }
    await cubit.addReminder(reminder);
    if (!mounted) return;
    _reset();
    _showAdded(reminder);
    _focus.requestFocus();
  }

  void _reset() {
    _suppressed.clear();
    _overrides.clear();
    _splitAccepted = false;
    _pastBlocked = false;
    _tokenKeys = const {};
    _controller.clear();
  }

  void _showAdded(Reminder reminder) {
    _toastTimer?.cancel();
    final duration = MediaQuery.accessibleNavigationOf(context)
        ? QuickCaptureSheet.toastScreenReaderDuration
        : QuickCaptureSheet.toastDuration;
    setState(() => _added = reminder);
    _toastTimer = Timer(duration, () {
      if (mounted) setState(() => _added = null);
    });
  }

  Future<void> _undoAdded() async {
    final added = _added;
    if (added == null) return;
    _toastTimer?.cancel();
    setState(() => _added = null);
    unawaited(KorHaptics.of(context).undo());
    await context.read<ReminderCubit>().deleteReminder(added.id);
  }

  void _openDetails() {
    Navigator.of(context).pop(_current());
  }

  /// "×": the phrases of [kinds] become plain text and the chip's picked
  /// value is dropped.
  void _suppress(Set<CaptureTokenKind> kinds) {
    for (final t in _result.tokens) {
      if (kinds.contains(t.kind)) _suppressed.add(t.text);
    }
    if (kinds.contains(CaptureTokenKind.date) ||
        kinds.contains(CaptureTokenKind.time)) {
      _overrides
        ..remindAtSet = false
        ..remindAt = null;
    }
    if (kinds.contains(CaptureTokenKind.recurrence)) {
      _overrides.recurrence = null;
    }
    if (kinds.contains(CaptureTokenKind.category)) {
      _overrides.categoryId = null;
      _splitAccepted = false;
    }
    if (kinds.contains(CaptureTokenKind.priority)) _overrides.priority = null;
    _reparse();
  }

  Future<void> _pickDateTime() async {
    final now = widget.clock();
    final current = _current().remindAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      currentDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : const TimeOfDay(hour: CaptureToReminder.defaultHour, minute: 0),
    );
    if (time == null || !mounted) return;
    final at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final rule = _current().recurrence;
    setState(() {
      _overrides
        ..remindAtSet = true
        ..remindAt = at;
      // Moving a series moves all of it (like the editor).
      if (!rule.isNone) _overrides.recurrence = rule.alignedTo(at);
      _pastBlocked = false;
    });
  }

  Future<void> _pickRecurrence() async {
    final now = widget.clock();
    final current = _current();
    final anchor = current.remindAt ?? now.add(const Duration(hours: 1));
    final rule = await showRecurrenceSheet(
      context,
      initial: current.recurrence,
      anchor: anchor,
      now: now,
    );
    if (rule == null || !mounted) return;
    setState(() {
      _overrides.recurrence = rule;
      if (rule.isNone) return;
      final first = rule.firstOnOrAfter(from: anchor, anchor: anchor) ?? anchor;
      _overrides
        ..remindAtSet = true
        ..remindAt = first;
      _pastBlocked = false;
    });
  }

  Future<void> _pickCategory() async {
    final current = _current().categoryId;
    final picked = await _pickFromSheet<String>(
      title: context.l10n.captureCategory,
      selected: current,
      options: [
        for (final c in CategoryVisuals.readCatalog(context).ordered)
          (
            c.id,
            CategoryVisuals.nameOf(c, context.l10n),
            CategoryVisuals.iconOf(c),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _overrides.categoryId = picked);
  }

  /// "Yeni kategori: #tag" (F4.3): creates the category with the tag as
  /// its name; the capture then uses it (the tag matches from now on).
  Future<void> _createCategory(String tag) async {
    // "#spor_salonu" → "Spor salonu" (Turkish capital: i → İ).
    final words = tag.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    final name = words.isEmpty
        ? words
        : KorFormat.upperTr(words.substring(0, 1)) + words.substring(1);
    final created = await showCategoryEditorSheet(context, initialName: name);
    if (created == null || !mounted) return;
    _overrides.categoryId = created.id;
    _reparse();
  }

  Future<void> _pickPriority() async {
    final picked = await _pickFromSheet<int>(
      title: context.l10n.capturePriority,
      selected: _current().priority,
      options: [
        for (final p in ReminderPriority.values)
          (
            p,
            PriorityPinVisuals.label(p, context.l10n),
            Icons.flag_outlined,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _overrides.priority = picked);
  }

  Future<T?> _pickFromSheet<T>({
    required String title,
    required T selected,
    required List<(T, String, IconData)> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      sheetAnimationStyle: context.korMotion.sheetStyleOf(context),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KorSpacing.s5),
              child: Semantics(
                header: true,
                child: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              ),
            ),
            const SizedBox(height: KorSpacing.s2),
            for (final (value, label, icon) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                selected: value == selected,
                trailing:
                    value == selected ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(ctx).pop(value),
              ),
            const SizedBox(height: KorSpacing.s3),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = widget.clock();
    final mapped = _mapped(id: '');
    final reminder = _current(id: '');
    final past = _pastTime(reminder);
    final canSave = reminder.title.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          KorSpacing.s5,
          0,
          KorSpacing.s5,
          KorSpacing.s4 + (viewInsets > 0 ? 0 : bottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_added != null) ...[
              _AddedToast(
                title: _added!.title,
                onUndo: _undoAdded,
              ),
              const SizedBox(height: KorSpacing.s3),
            ],
            TextField(
              key: QuickCaptureKeys.field,
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium,
              // Keeps the keyboard up after Enter (successive captures).
              onEditingComplete: () {},
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: context.l10n.captureFieldHint,
                semanticCounterText: '',
                // F4.6c: examples of what the parser understands, in the
                // app language.
                helperText: context.l10n.captureParserExamples,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: KorSpacing.s3),
            _chipRow(context, reminder, mapped, now),
            if (past != null) ...[
              const SizedBox(height: KorSpacing.s3),
              _PastWarning(
                blocked: _pastBlocked,
                child: PastTimeHint(
                  suggested: PastTime.suggestion(past, now),
                  now: now,
                  onApply: () => setState(() {
                    _overrides
                      ..remindAtSet = true
                      ..remindAt = PastTime.suggestion(past, widget.clock());
                    _pastBlocked = false;
                  }),
                ),
              ),
            ],
            const SizedBox(height: KorSpacing.s3),
            Row(
              children: [
                // Expanded: the label wraps at 200 % text instead of
                // pushing "Kaydet" off the sheet.
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: QuickCaptureKeys.details,
                      onPressed: _openDetails,
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: Text(context.l10n.captureAllDetails),
                    ),
                  ),
                ),
                const SizedBox(width: KorSpacing.s3),
                IconButton.filled(
                  key: QuickCaptureKeys.save,
                  tooltip: context.l10n.actionSave,
                  onPressed: canSave ? _save : null,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(KorSizes.minTouch),
                    shape: const RoundedRectangleBorder(
                      borderRadius: KorRadius.mdAll,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(
    BuildContext context,
    Reminder reminder,
    CaptureDraft mapped,
    DateTime now,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result;
    bool has(CaptureTokenKind kind) => result.tokensOf(kind).isNotEmpty;

    final at = reminder.remindAt;
    final dateRecognized =
        has(CaptureTokenKind.date) || has(CaptureTokenKind.time);
    final dateSet = at != null && (dateRecognized || _overrides.remindAtSet);
    final ruleSet = !reminder.recurrence.isNone;
    final categorySet =
        result.categoryId != null || _overrides.categoryId != null;
    final newTag = _overrides.categoryId == null ? mapped.newCategoryTag : null;
    final prioritySet = reminder.priority != ReminderPriority.none;
    final category = reminder.categoryId;
    final categoryColors = CategoryVisuals.colorsOf(context, category);
    final l10n = context.l10n;

    final chips = <Widget>[
      _CaptureChip(
        key: QuickCaptureKeys.dateChip,
        icon: Icons.event_rounded,
        label: dateSet
            ? l10n.captureDateChipSet(
                KorFormat.relativeDay(at, now, l10n),
                KorFormat.time(at),
              )
            : l10n.captureDateChip,
        semanticsLabel: dateSet
            ? l10n.captureDateSpoken(KorFormat.spokenWhen(at, now, l10n))
            : l10n.captureDateAdd,
        set: dateSet,
        onPressed: _pickDateTime,
        onDeleted: dateSet
            ? () => _suppress({CaptureTokenKind.date, CaptureTokenKind.time})
            : null,
      ),
      _CaptureChip(
        key: QuickCaptureKeys.recurrenceChip,
        icon: Icons.repeat_rounded,
        label: ruleSet
            ? RecurrenceText.summary(reminder.recurrence, l10n)
            : l10n.captureRecurrenceChip,
        semanticsLabel: ruleSet
            ? l10n.captureRecurrenceSpoken(
                RecurrenceText.summary(reminder.recurrence, l10n),
              )
            : l10n.captureRecurrenceAdd,
        set: ruleSet,
        onPressed: _pickRecurrence,
        onDeleted:
            ruleSet ? () => _suppress({CaptureTokenKind.recurrence}) : null,
      ),
      if (newTag != null)
        _CaptureChip(
          key: QuickCaptureKeys.newCategoryChip,
          icon: Icons.new_label_outlined,
          label: l10n.captureNewCategory(newTag),
          semanticsLabel: l10n.captureNewCategorySpoken(newTag),
          set: true,
          onPressed: () => _createCategory(newTag),
          onDeleted: () => _suppress({CaptureTokenKind.category}),
        )
      else
        _CaptureChip(
          key: QuickCaptureKeys.categoryChip,
          icon: CategoryVisuals.iconFor(context, category),
          label: categorySet
              ? CategoryVisuals.labelOf(context, category)
              : l10n.captureCategory,
          semanticsLabel: categorySet
              ? l10n.captureCategorySpoken(
                  CategoryVisuals.labelOf(context, category),
                )
              : l10n.captureCategoryPick,
          set: categorySet,
          background: categorySet ? categoryColors.container : null,
          foreground: categorySet ? categoryColors.onContainer : null,
          iconColor: categorySet ? categoryColors.fg : null,
          onPressed: _pickCategory,
          onDeleted:
              categorySet ? () => _suppress({CaptureTokenKind.category}) : null,
        ),
      _CaptureChip(
        key: QuickCaptureKeys.priorityChip,
        icon: Icons.flag_outlined,
        label: prioritySet
            ? '${ReminderPriority.marker(reminder.priority)} '
                '${PriorityPinVisuals.label(reminder.priority, l10n)}'
            : l10n.capturePriority,
        semanticsLabel: prioritySet
            ? PriorityPinVisuals.spoken(reminder.priority, l10n)!
            : l10n.capturePriorityPick,
        set: prioritySet,
        onPressed: _pickPriority,
        onDeleted:
            prioritySet ? () => _suppress({CaptureTokenKind.priority}) : null,
      ),
      if (mapped.placeLabel != null)
        _CaptureChip(
          key: QuickCaptureKeys.placeChip,
          icon: Icons.place_outlined,
          label: mapped.placeLabel!,
          semanticsLabel: l10n.capturePlaceSpoken(mapped.placeLabel!),
          set: true,
          onPressed: _openDetails,
          onDeleted: () => _suppress({CaptureTokenKind.place}),
        ),
      if (result.splitSuggestion.length >= 2)
        FilterChip(
          key: QuickCaptureKeys.splitChip,
          selected: _splitAccepted,
          showCheckmark: true,
          avatar: _splitAccepted
              ? null
              : Icon(Icons.checklist_rounded, color: scheme.primary),
          label: Text(
            _splitAccepted
                ? l10n.captureSplitCount(result.splitSuggestion.length)
                : l10n.captureSplitAsk,
          ),
          tooltip: _splitAccepted
              ? l10n.captureSplitUndo
              : l10n.captureSplitDo(result.splitSuggestion.length),
          onSelected: (v) => setState(() => _splitAccepted = v),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: KorSpacing.s3),
              child: chip,
            ),
        ],
      ),
    );
  }
}

/// A chip of the capture row: a recognised (or picked) value with "×" to
/// turn the phrase back into text, or an "add" chip that opens the picker.
class _CaptureChip extends StatelessWidget {
  const _CaptureChip({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.set,
    required this.onPressed,
    required this.onDeleted,
    this.background,
    this.foreground,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool set;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final Color? background;
  final Color? foreground;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = foreground ?? (set ? scheme.onSecondaryContainer : null);
    return InputChip(
      avatar: Icon(icon, color: iconColor ?? fg),
      label: Text(label, semanticsLabel: semanticsLabel),
      labelStyle: theme.textTheme.labelLarge?.copyWith(color: fg),
      selected: set,
      showCheckmark: false,
      isEnabled: true,
      selectedColor: background ?? scheme.secondaryContainer,
      side: BorderSide(
        color: set ? (iconColor ?? scheme.secondary) : scheme.outlineVariant,
      ),
      onPressed: onPressed,
      onDeleted: onDeleted,
      deleteIconColor: fg,
      deleteButtonTooltipMessage: context.l10n.captureChipPlainText,
    );
  }
}

/// "Eklendi: <title> · Geri al" above the field (design: 3 s at the top of
/// the sheet; a snackbar would sit under the sheet).
class _AddedToast extends StatelessWidget {
  const _AddedToast({required this.title, required this.onUndo});

  final String title;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      key: QuickCaptureKeys.toast,
      liveRegion: true,
      container: true,
      child: Material(
        color: scheme.inverseSurface,
        borderRadius: KorRadius.mdAll,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: KorSpacing.s4),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: scheme.onInverseSurface),
              const SizedBox(width: KorSpacing.s3),
              Expanded(
                child: Text(
                  context.l10n.captureAdded(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onInverseSurface,
                  ),
                ),
              ),
              TextButton(
                key: QuickCaptureKeys.undo,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.inversePrimary,
                  minimumSize: const Size(
                    KorSizes.minTouch,
                    KorSizes.minTouch,
                  ),
                ),
                onPressed: onUndo,
                child: Text(context.l10n.actionUndo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlines the past-time hint in `error` after a blocked save.
class _PastWarning extends StatelessWidget {
  const _PastWarning({required this.blocked, required this.child});

  final bool blocked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: KorRadius.mdAll,
        border: Border.all(
          color: blocked ? scheme.error : scheme.surface.withValues(alpha: 0),
          width: KorGlass.strokeWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KorSpacing.s2),
        child: child,
      ),
    );
  }
}
