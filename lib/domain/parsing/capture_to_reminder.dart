/// Maps a quick-capture parse result (F4.6a) to a new [Reminder] (F4.6b).
///
/// The parser stays model-neutral; this file is the only place that turns
/// its [CaptureParseResult] into models (`RecurrenceRule`, priority,
/// category, subtasks). Pure Dart, clock and id generator injected.
library;

import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/model/reminder_priority.dart';
import 'package:reminder/domain/model/subtask.dart';
import 'package:reminder/domain/parsing/capture_parse_result.dart';

/// A reminder built from a capture, plus what the capture UI must show
/// before (or instead of) saving it.
class CaptureDraft {
  const CaptureDraft({
    required this.reminder,
    this.isPast = false,
    this.newCategoryTag,
    this.placeLabel,
  });

  /// The new reminder (not saved).
  final Reminder reminder;

  /// An explicit one-off time that is already behind `now` (`17 eylül 2025`,
  /// `bugün 9'da` after 09:00). Never saved silently: the sheet shows the
  /// F1.8b warning and a "Yarın HH:mm mı?" suggestion (design §3.3.4).
  final bool isPast;

  /// A `#tag` that matched no category (raw, without `#`). The reminder
  /// goes to "Diğer"; the sheet shows an inert "Yeni kategori: #tag" hint
  /// until custom categories (F4.3) can create it.
  final String? newCategoryTag;

  /// `@place` text (without `@`). The model has no place without a
  /// geofence (`locationPlaceLabel` belongs to the location trigger), so the
  /// place is kept in the note (`Yer: ev`) and never registers a geofence.
  final String? placeLabel;
}

abstract final class CaptureToReminder {
  /// Hour used when a capture names a day but no time (`yarın süt al`,
  /// `her gün vitamin`) — the parser's "sabah" hour by default.
  static const int defaultHour = 9;

  /// Builds a new reminder from [result].
  ///
  /// - **Title:** the parser's title; with [acceptSplit] and a
  ///   `splitSuggestion`, [listTitle] of the category and one open subtask
  ///   per item ("Maddelere böl?" accepted).
  /// - **Time:** see [remindAtOf].
  /// - **Recurrence:** [ruleOf]; the first `remindAt` is always an
  ///   occurrence of that rule (see [remindAtOf]).
  /// - **Priority:** 0–3, same scale ([ReminderPriority.normalize]).
  /// - **Category:** the matched built-in id, otherwise "Diğer" (an
  ///   unmatched tag is reported in [CaptureDraft.newCategoryTag]).
  static CaptureDraft map(
    CaptureParseResult result, {
    required DateTime now,
    required String id,
    required String Function() newSubtaskId,
    DateTime? createdAt,
    bool acceptSplit = false,
    int hourForDateOnly = defaultHour,
  }) {
    final categoryId = result.categoryId ?? ReminderCategoryIds.other;
    final tag = result.categoryKey?.trim();
    final newTag =
        result.categoryId == null && tag != null && tag.isNotEmpty ? tag : null;

    final split = acceptSplit && result.splitSuggestion.length >= 2;
    final title = split ? listTitle(categoryId) : result.title.trim();
    final subtasks = split
        ? SubtaskList.inOrder([
            for (var i = 0; i < result.splitSuggestion.length; i++)
              Subtask(
                id: newSubtaskId(),
                title: _capitalized(result.splitSuggestion[i].trim()),
                position: i,
              ),
          ])
        : const <Subtask>[];

    final spec = result.recurrence;
    final rule = spec == null ? RecurrenceRule.none : ruleOf(spec);
    final remindAt = remindAtOf(result, now: now, hour: hourForDateOnly);

    final place = result.placeKey?.trim();
    final placeLabel = place != null && place.isNotEmpty ? place : null;

    final reminder = Reminder(
      id: id,
      title: title,
      note: placeLabel == null ? null : 'Yer: $placeLabel',
      isDone: false,
      createdAt: createdAt ?? now,
      remindAt: remindAt,
      categoryId: categoryId,
      recurrence: remindAt == null ? RecurrenceRule.none : rule,
      subtasks: subtasks,
      priority: ReminderPriority.normalize(result.priority),
    );
    return CaptureDraft(
      reminder: reminder,
      isPast: result.isPast && remindAt != null && rule.isNone,
      newCategoryTag: newTag,
      placeLabel: placeLabel,
    );
  }

  /// `RecurrenceSpec` → `RecurrenceRule` (CLAUDE.md › Quick-capture
  /// parser): daily → `daily()`, everyNDays → `daily(interval: n)`, weekly →
  /// `weekly(days, interval:)`, monthly → `monthly(dayOfMonth:)`.
  static RecurrenceRule ruleOf(RecurrenceSpec spec) => switch (spec.kind) {
        RecurrenceKind.daily => RecurrenceRule.daily(interval: spec.interval),
        RecurrenceKind.everyNDays =>
          RecurrenceRule.daily(interval: spec.interval),
        RecurrenceKind.weekly =>
          RecurrenceRule.weekly(spec.weekdays, interval: spec.interval),
        RecurrenceKind.monthly => spec.dayOfMonth == null
            ? RecurrenceRule.none
            : RecurrenceRule.monthly(
                dayOfMonth: spec.dayOfMonth!,
                interval: spec.interval,
              ),
      };

  /// The reminder time for [result]:
  ///
  /// - no date/time → `null` (untimed, "Bugün bir ara");
  /// - an explicit time → the parser's `dateTime`;
  /// - a day without a time → that day at [hour]; **today** without a time
  ///   stays untimed (a one-off "bugün …" lands in "Bugün bir ara" instead
  ///   of a morning that may have passed);
  /// - a repeat → the first occurrence of [ruleOf] at or after [now], at the
  ///   parser's time (or [hour]). The parser skips months without the
  ///   day (`her ayın 31'i` in September → 31 Ekim) while `RecurrenceRule`
  ///   clamps them (→ 30 Eylül); the rule wins, so the stored series and its
  ///   first `remindAt` agree.
  static DateTime? remindAtOf(
    CaptureParseResult result, {
    required DateTime now,
    int hour = defaultHour,
  }) {
    final parsed = result.dateTime;
    if (parsed == null) return null;
    final spec = result.recurrence;
    final base = result.hasExplicitTime
        ? parsed
        : DateTime(parsed.year, parsed.month, parsed.day, hour);

    if (spec == null) {
      if (result.hasExplicitTime) return parsed;
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      if (day == today) return null;
      return base;
    }

    final rule = ruleOf(spec);
    if (rule.isNone) return base;
    // The parser's first day is an occurrence of the rule; an untimed one
    // may be today with [hour] already behind now.
    var first = base.isAfter(now)
        ? rule.firstOnOrAfter(from: base, anchor: base) ?? base
        : rule.nextOccurrence(after: now, anchor: base) ?? base;

    final dom = rule.dayOfMonth;
    if (rule.frequency == RecurrenceFrequency.monthly && dom != null) {
      // Month-end clamp: the rule may fire earlier, in a short month the
      // parser skipped.
      final monthStart = DateTime(
        now.year,
        now.month,
        1,
        base.hour,
        base.minute,
      );
      final clamped = rule.nextOccurrence(after: now, anchor: monthStart);
      if (clamped != null && clamped.day != dom && clamped.isBefore(first)) {
        first = clamped;
      }
    }
    return first;
  }

  /// Title of an accepted "Maddelere böl?" list (design §3.3.3):
  /// "Market alışverişi" for Market, "`<Kategori>` listesi" otherwise.
  static String listTitle(String categoryId) =>
      categoryId == ReminderCategoryIds.market
          ? 'Market alışverişi'
          : '${ReminderCategoryIds.defaultLabel(categoryId)} listesi';

  static String _capitalized(String text) {
    if (text.isEmpty) return text;
    final first = text[0];
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${text.substring(1)}';
  }
}
