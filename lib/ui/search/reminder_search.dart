import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/reminder_sorting.dart';
import 'package:reminder/domain/text_search.dart';

/// Status chips of the search page (Açık / Tamamlanan).
enum SearchStatus { open, completed }

/// One matched reminder with its highlight ranges.
class ReminderMatch {
  const ReminderMatch({
    required this.reminder,
    required this.score,
    required this.titleRanges,
    required this.noteRanges,
  });

  final Reminder reminder;

  /// Lower is better (sum of the best field rank of every token).
  final int score;
  final List<MatchRange> titleRanges;

  /// Ranges in `reminder.note` (untrimmed).
  final List<MatchRange> noteRanges;
}

/// Grouped search results (§3.3.8): "Hatırlatıcılar" (title, category or
/// place) and "Notlarda" (at least one word only found in the note).
class ReminderSearchResults {
  const ReminderSearchResults({
    required this.inReminders,
    required this.inNotes,
  });

  static const empty = ReminderSearchResults(inReminders: [], inNotes: []);

  final List<ReminderMatch> inReminders;
  final List<ReminderMatch> inNotes;

  int get total => inReminders.length + inNotes.length;
  bool get isEmpty => total == 0;
}

/// Pure reminder search.
///
/// - Query is split into words; **every** word must match one of title,
///   note, category label or place label (Turkish-insensitive, see
///   [TextSearch]).
/// - Ranking per word: title word start (0) < title (1) < category / place
///   (2) < note (3); results sort by the summed rank, then by
///   [compareReminders].
/// - [statuses] empty means both; [categoryId] null means every category.
abstract final class ReminderSearch {
  static const int _titleWordStart = 0;
  static const int _title = 1;
  static const int _meta = 2;
  static const int _note = 3;

  static ReminderSearchResults run(
    Iterable<Reminder> reminders,
    String query, {
    Set<SearchStatus> statuses = const {SearchStatus.open},
    String? categoryId,
  }) {
    final tokens = TextSearch.tokens(query);
    if (tokens.isEmpty) return ReminderSearchResults.empty;

    final inReminders = <ReminderMatch>[];
    final inNotes = <ReminderMatch>[];
    for (final r in reminders) {
      if (statuses.isNotEmpty) {
        final status = r.isDone ? SearchStatus.completed : SearchStatus.open;
        if (!statuses.contains(status)) continue;
      }
      if (categoryId != null && r.categoryId != categoryId) continue;

      final title = TextSearch.fold(r.title);
      final note = TextSearch.fold(r.note ?? '');
      final category = TextSearch.fold(r.categoryDisplayLabel);
      final place = TextSearch.fold(r.locationPlaceLabel ?? '');

      var score = 0;
      var noteOnly = false;
      var matched = true;
      for (final t in tokens) {
        final int rank;
        if (title.contains(t)) {
          rank = TextSearch.startsWord(r.title, t) ? _titleWordStart : _title;
        } else if (category.contains(t) || place.contains(t)) {
          rank = _meta;
        } else if (note.contains(t)) {
          rank = _note;
          noteOnly = true;
        } else {
          matched = false;
          break;
        }
        score += rank;
      }
      if (!matched) continue;

      final match = ReminderMatch(
        reminder: r,
        score: score,
        titleRanges: TextSearch.ranges(r.title, tokens),
        noteRanges: TextSearch.ranges(r.note ?? '', tokens),
      );
      (noteOnly ? inNotes : inReminders).add(match);
    }

    int compare(ReminderMatch a, ReminderMatch b) {
      final byScore = a.score.compareTo(b.score);
      return byScore != 0 ? byScore : compareReminders(a.reminder, b.reminder);
    }

    inReminders.sort(compare);
    inNotes.sort(compare);
    return ReminderSearchResults(
      inReminders: List.unmodifiable(inReminders),
      inNotes: List.unmodifiable(inNotes),
    );
  }

  /// One-line note context around the first match: `…geçen ayki fatura…`.
  /// Returns the snippet and the ranges shifted into it.
  static ({String text, List<MatchRange> ranges}) noteContext(
    String note,
    List<MatchRange> ranges, {
    int before = 20,
  }) {
    final flat = note.replaceAll(RegExp(r'\s'), ' ');
    if (ranges.isEmpty) return (text: flat.trim(), ranges: const []);
    final start = ranges.first.start;
    if (start <= before) return (text: flat, ranges: ranges);
    // Start the snippet at a word boundary when one is close.
    var cut = start - before;
    final space = flat.indexOf(' ', cut);
    if (space >= 0 && space < start) cut = space + 1;
    const ellipsis = '…';
    final shift = cut - ellipsis.length;
    return (
      text: '$ellipsis${flat.substring(cut)}',
      ranges: [
        for (final r in ranges)
          if (r.start >= cut) MatchRange(r.start - shift, r.end - shift),
      ],
    );
  }
}
