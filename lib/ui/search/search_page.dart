import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/text_search.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/common/kor_format.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/empty_state.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/components/reminder_compact_card.dart';
import 'package:reminder/ui/reminders/category_visuals.dart';
import 'package:reminder/ui/search/recent_search_store.dart';
import 'package:reminder/ui/search/reminder_search.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class SearchPageKeys {
  static const field = Key('search.field');
  static const openChip = Key('search.chip.open');
  static const completedChip = Key('search.chip.completed');
  static const categoryChip = Key('search.chip.category');
  static const resultCount = Key('search.resultCount');
  static const clearRecent = Key('search.clearRecent');
}

/// Opens the full-screen search, keeping the caller's clock.
Future<void> openSearch(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NowScope.carry(context, const SearchPage()),
    ),
  );
}

/// 48 dp "Ara" header button (Bugün, Listeler, smart lists).
///
/// On iOS the shell's glass tab bar already has an "Ara" circle, so the
/// button hides itself on the shell's route (the first route: Bugün,
/// Listeler headers) and only shows on pushed pages, which cover the tab bar.
/// Android always shows it.
class SearchIconButton extends StatelessWidget {
  const SearchIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformChrome.isCupertino(context) &&
        (ModalRoute.of(context)?.isFirst ?? true)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: context.l10n.searchTooltip,
      onPressed: () => openSearch(context),
      icon: const Icon(Icons.search_rounded),
    );
  }
}

/// Arama (§3.3.8): autofocus pill field, Açık / Tamamlanan / Kategori
/// filters, grouped results with highlighted matches, recent searches and
/// empty / no-result states. Matching is Turkish-insensitive
/// ([ReminderSearch], [TextSearch]).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.store = const RecentSearchStore()});

  final RecentSearchStore store;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final Set<SearchStatus> _statuses = {SearchStatus.open};
  String? _categoryId;
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    unawaited(_loadRecent());
  }

  Future<void> _loadRecent() async {
    final list = await widget.store.load();
    if (mounted) setState(() => _recent = list);
  }

  Future<void> _remember() async {
    final q = _controller.text;
    if (q.trim().isEmpty) return;
    final list = await widget.store.add(q);
    if (mounted) setState(() => _recent = list);
  }

  Future<void> _clearRecent() async {
    await widget.store.clear();
    if (mounted) setState(() => _recent = const []);
  }

  void _setQuery(String q) {
    _controller.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    unawaited(_remember());
  }

  void _toggleStatus(SearchStatus status, bool selected) {
    setState(() {
      if (selected) {
        _statuses.add(status);
      } else {
        _statuses.remove(status);
      }
    });
  }

  Future<void> _pickCategory() async {
    // F4.3: every category in the user's order.
    final categories = context.read<ReminderCubit>().state.categories;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: Text(context.l10n.searchAllCategories),
              selected: _categoryId == null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final c in categories.ordered)
              ListTile(
                leading: CategoryBadge(category: c, size: 32),
                title: Text(CategoryVisuals.nameOf(c, context.l10n)),
                selected: _categoryId == c.id,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _categoryId = picked.isEmpty ? null : picked);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = NowScope.now(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KorSpacing.screenEdge,
                KorSpacing.s3,
                KorSpacing.screenEdge,
                0,
              ),
              child: _field(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KorSpacing.screenEdge,
                vertical: KorSpacing.s3,
              ),
              child: _chips(context),
            ),
            Expanded(
              child: BlocBuilder<ReminderCubit, ReminderState>(
                builder: (context, state) => _body(context, state, now),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: KorRadius.fullAll,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KorSizes.fab),
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.actionBack,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: TextField(
                key: SearchPageKeys.field,
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _remember(),
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: KorSpacing.s4,
                  ),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                tooltip: context.l10n.actionClear,
                onPressed: () {
                  _controller.clear();
                  _focus.requestFocus();
                },
                icon: const Icon(Icons.close_rounded),
              )
            else
              const SizedBox(width: KorSpacing.s3),
          ],
        ),
      ),
    );
  }

  Widget _chips(BuildContext context) {
    final categoryLabel = _categoryId == null
        ? context.l10n.searchCategoryChip
        : CategoryVisuals.labelOf(context, _categoryId!);
    return Wrap(
      spacing: KorSpacing.s3,
      runSpacing: KorSpacing.s3,
      children: [
        FilterChip(
          key: SearchPageKeys.openChip,
          label: Text(context.l10n.searchOpenChip),
          selected: _statuses.contains(SearchStatus.open),
          onSelected: (v) => _toggleStatus(SearchStatus.open, v),
        ),
        FilterChip(
          key: SearchPageKeys.completedChip,
          label: Text(context.l10n.searchCompletedChip),
          selected: _statuses.contains(SearchStatus.completed),
          onSelected: (v) => _toggleStatus(SearchStatus.completed, v),
        ),
        Semantics(
          hint: context.l10n.searchPickCategory,
          child: FilterChip(
            key: SearchPageKeys.categoryChip,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(categoryLabel),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
            selected: _categoryId != null,
            showCheckmark: false,
            onSelected: (_) => _pickCategory(),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, ReminderState state, DateTime now) {
    final query = _controller.text.trim();
    final bottom = MediaQuery.paddingOf(context).bottom + KorSpacing.s7;

    if (query.isEmpty) {
      if (_recent.isEmpty) {
        return ListView(
          padding: EdgeInsets.only(bottom: bottom),
          children: [
            EmptyState(
              title: context.l10n.searchEmptyTitle,
              body: context.l10n.searchEmptyBody,
            ),
          ],
        );
      }
      return ListView(
        padding: EdgeInsets.fromLTRB(
          KorSpacing.screenEdge,
          0,
          KorSpacing.screenEdge,
          bottom,
        ),
        children: [
          SectionHeader(
            title: context.l10n.searchRecent,
            icon: Icons.history_rounded,
            trailing: TextButton(
              key: SearchPageKeys.clearRecent,
              onPressed: _clearRecent,
              child: Text(context.l10n.actionClear),
            ),
          ),
          for (final q in _recent)
            Semantics(
              button: true,
              label: context.l10n.searchRecentSpoken(q),
              excludeSemantics: true,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(q),
                onTap: () => _setQuery(q),
              ),
            ),
        ],
      );
    }

    final results = ReminderSearch.run(
      state.reminders,
      query,
      statuses: _statuses,
      categoryId: _categoryId,
      categories: state.categories,
      l10n: context.l10n,
    );

    if (results.isEmpty) {
      final canWiden =
          _statuses.isNotEmpty && !_statuses.contains(SearchStatus.completed);
      return ListView(
        padding: EdgeInsets.only(bottom: bottom),
        children: [
          Semantics(
            liveRegion: true,
            child: EmptyState(
              title: context.l10n.searchNoResults(query),
              body: canWiden
                  ? context.l10n.searchNoResultsWiden
                  : context.l10n.searchNoResultsBody,
              actionLabel: canWiden ? context.l10n.searchInCompleted : null,
              onAction: canWiden
                  ? () => _toggleStatus(SearchStatus.completed, true)
                  : null,
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        KorSpacing.screenEdge,
        0,
        KorSpacing.screenEdge,
        bottom,
      ),
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.searchResultCount(results.total),
            key: SearchPageKeys.resultCount,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        ..._group(
          context,
          context.l10n.searchGroupReminders,
          results.inReminders,
          now,
        ),
        ..._group(context, context.l10n.searchGroupNotes, results.inNotes, now),
      ],
    );
  }

  List<Widget> _group(
    BuildContext context,
    String title,
    List<ReminderMatch> matches,
    DateTime now,
  ) {
    if (matches.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: KorSpacing.s3),
        child: SectionHeader(
          title: context.l10n.searchGroupHeader(title, matches.length),
        ),
      ),
      for (final m in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: KorSpacing.cardGap),
          child: SearchResultCard(
            key: ValueKey(m.reminder.id),
            match: m,
            now: now,
            onOpen: () => unawaited(_remember()),
          ),
        ),
    ];
  }
}

/// A search result: highlighted title, meta (category · time) and a
/// one-line note context when the note matched.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.match,
    required this.now,
    this.onOpen,
  });

  final ReminderMatch match;
  final DateTime now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = match.reminder;
    final category = CategoryVisuals.colorsOf(context, r.categoryId);
    final highlight = TextStyle(
      fontWeight: FontWeight.w700,
      color: scheme.onPrimaryContainer,
      backgroundColor: scheme.primaryContainer,
    );
    final note = r.note;
    final context_ = note != null && match.noteRanges.isNotEmpty
        ? ReminderSearch.noteContext(note, match.noteRanges)
        : null;

    return ReminderCompactCard(
      reminder: r,
      now: now,
      minHeight: 64,
      onOpen: onOpen,
      title: highlightSpan(r.title, match.titleRanges, highlight),
      subtitle: TextSpan(
        children: [
          TextSpan(
            text: CategoryVisuals.labelOf(context, r.categoryId),
            style: TextStyle(color: category.fg),
          ),
          TextSpan(text: '  ·  ${_when(r, context.l10n)}'),
        ],
      ),
      detail: context_ == null
          ? null
          : highlightSpan(context_.text, context_.ranges, highlight),
    );
  }

  String _when(Reminder r, AppLocalizations l10n) {
    final at = r.remindAt?.toLocal();
    if (at == null) return l10n.searchUntimed;
    final overdue = !r.isDone && at.isBefore(now);
    return overdue
        ? l10n.searchOverdueWhen(KorFormat.when(at, now, l10n))
        : KorFormat.when(at, now, l10n);
  }
}

/// [text] with [ranges] drawn in [highlight].
TextSpan highlightSpan(
  String text,
  List<MatchRange> ranges,
  TextStyle highlight,
) {
  if (ranges.isEmpty) return TextSpan(text: text);
  final spans = <TextSpan>[];
  var i = 0;
  for (final r in ranges) {
    if (r.start >= text.length) break;
    final end = r.end.clamp(0, text.length);
    if (r.start > i) spans.add(TextSpan(text: text.substring(i, r.start)));
    spans.add(TextSpan(text: text.substring(r.start, end), style: highlight));
    i = end;
  }
  if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
  return TextSpan(children: spans);
}
