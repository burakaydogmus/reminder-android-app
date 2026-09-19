import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassAdaptiveScope;

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/capture/capture_bar.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/components/fade_through_indexed_stack.dart';
import 'package:reminder/ui/home/kor_glass_tab_bar.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/search/search_page.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_elevation.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/today/today_page.dart';

/// App shell (§3.2): Bugün / Takvim / Listeler. Ayarlar opens from the gear
/// in each tab header.
///
/// Android: floating pill navigation + squircle FAB (tap → quick capture,
/// F4.6b). iOS (F5.4): floating [KorGlassTabBar] + separate search circle +
/// the "Ne hatırlatayım?" capture bar above it (no FAB); the tab bar shrinks while
/// content scrolls down and expands on scroll up, at the top, on tab switch
/// and always with VoiceOver. Back from Takvim/Listeler returns to Bugün.
///
/// Notification taps (F3.2) arrive through [tapRouter]: a reminder payload
/// opens its editor (after the first load), a birthday payload opens
/// Listeler › Doğum günleri.
///
/// The iOS search circle opens the same search page as the Bugün/Listeler
/// header button (`openSearch`, F3.6).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.clock = DateTime.now,
    this.tapRouter,
    this.reminderLoadTimeout = const Duration(seconds: 5),
    this.enableGlassScope = true,
    this.a11yPrefs,
  });

  /// Injected for tests; screens read it through [NowScope].
  final DateTime Function() clock;

  /// Notification tap targets; defaults to [NotificationTapRouter.instance].
  final NotificationTapRouter? tapRouter;

  /// How long a tapped reminder is awaited in the cubit state (cold start:
  /// the first `load()` may still be running).
  final Duration reminderLoadTimeout;

  /// iOS: wraps the glass chrome in a `GlassAdaptiveScope` (frame-timing
  /// quality adaptation, drops to solid on slow devices). Tests turn it off.
  final bool enableGlassScope;

  /// iOS accessibility prefs for the glass fallback; defaults to
  /// [A11yPrefs.platform] (native channel), tests pass a fixed value.
  final A11yPrefs? a11yPrefs;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _tick = 0;
  Timer? _ticker;

  /// iOS glass tab bar shrunk by scrolling.
  bool _collapsed = false;
  A11yPrefs? _ownedPrefs;

  A11yPrefs get _a11yPrefs =>
      widget.a11yPrefs ?? (_ownedPrefs ??= A11yPrefs.platform());

  NotificationTapRouter get _router =>
      widget.tapRouter ?? NotificationTapRouter.instance;

  @override
  void initState() {
    super.initState();
    // Moves due reminders from "Bugün" to "Kaçanlar" without data changes.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
    _router.addListener(_openTapTarget);
    // A cold-start tap was queued before the shell existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTapTarget());
  }

  @override
  void dispose() {
    _router.removeListener(_openTapTarget);
    _ticker?.cancel();
    _ownedPrefs?.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _collapsed = false;
    });
  }

  void _setCollapsed(bool collapsed) {
    if (collapsed == _collapsed) return;
    setState(() => _collapsed = collapsed);
  }

  /// iOS shrink-on-scroll: down past [KorGlass.scrollSlop] collapses, up or
  /// reaching the top expands. VoiceOver keeps the tab bar expanded.
  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (notification is! ScrollUpdateNotification ||
        metrics.axis != Axis.vertical) {
      return false;
    }
    if (MediaQuery.accessibleNavigationOf(context)) {
      _setCollapsed(false);
      return false;
    }
    final delta = notification.scrollDelta ?? 0;
    if (metrics.pixels <= metrics.minScrollExtent) {
      _setCollapsed(false);
    } else if (delta > KorGlass.scrollSlop) {
      _setCollapsed(true);
    } else if (delta < -KorGlass.scrollSlop) {
      _setCollapsed(false);
    }
    return false;
  }

  void _openTapTarget() {
    if (!mounted) return;
    final target = _router.take();
    if (target == null) return;
    unawaited(_open(target));
  }

  Future<void> _open(NotificationPayload target) async {
    switch (target) {
      case ReminderPayload(:final reminderId):
        final reminder = await _awaitReminder(reminderId);
        if (!mounted || reminder == null) return;
        await showReminderEditorSheet(
          context,
          existing: reminder,
          now: widget.clock,
        );
      case BirthdayPayload():
        _select(2);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NowScope(
              clock: widget.clock,
              child: const BirthdaysPage(),
            ),
          ),
        );
    }
  }

  /// The reminder with [id] from the cubit state; waits for a state that
  /// contains it (first load) up to [HomeShell.reminderLoadTimeout].
  Future<Reminder?> _awaitReminder(String id) async {
    final cubit = context.read<ReminderCubit>();
    Reminder? find(ReminderState state) {
      for (final r in state.reminders) {
        if (r.id == id) return r;
      }
      return null;
    }

    final current = find(cubit.state);
    if (current != null) return current;

    final found = Completer<Reminder?>();
    final timer = Timer(widget.reminderLoadTimeout, () {
      if (!found.isCompleted) found.complete(null);
    });
    final subscription = cubit.stream.listen((state) {
      final r = find(state);
      if (r != null && !found.isCompleted) found.complete(r);
    });
    try {
      return await found.future;
    } finally {
      timer.cancel();
      // Not awaited: cancelling from inside the delivering listener would
      // delay opening the editor.
      unawaited(subscription.cancel());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cupertino = PlatformChrome.isCupertino(context);

    final pages = NowScope(
      clock: widget.clock,
      tick: _tick,
      child: FadeThroughIndexedStack(
        index: _index,
        children: const [TodayPage(), CalendarPage(), ListsPage()],
      ),
    );
    final body = cupertino
        ? NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: pages,
          )
        : pages;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        // Content scrolls under the floating nav on both platforms.
        extendBody: true,
        body: body,
        bottomNavigationBar: cupertino
            ? _glassChrome(context)
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  KorSpacing.s5,
                  0,
                  KorSpacing.s5,
                  KorSpacing.s4,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Align(
                        // Without a height factor the Align fills the
                        // scaffold's bottom slot (whole screen), which put
                        // the nav mid-screen and floating snackbars off it.
                        heightFactor: 1,
                        alignment: AlignmentDirectional.centerStart,
                        child: KorPillNavigation(
                          selectedIndex: _index,
                          onSelected: _select,
                        ),
                      ),
                    ),
                    const SizedBox(width: KorSpacing.s4),
                    NewItemFab(clock: widget.clock),
                  ],
                ),
              ),
      ),
    );
  }

  /// iOS tab bar + search circle with the a11y prefs (and, outside tests,
  /// the adaptive quality scope) above the glass.
  Widget _glassChrome(BuildContext context) {
    // Under a NowScope so the search page keeps the shell's clock.
    Widget bar = NowScope(
      clock: widget.clock,
      tick: _tick,
      child: Builder(
        builder: (context) => KorGlassTabBar(
          selectedIndex: _index,
          onSelected: _select,
          collapsed: _collapsed && !MediaQuery.accessibleNavigationOf(context),
          onExpand: () => _setCollapsed(false),
          onSearch: () => openSearch(context),
          accessory: (context, size) => CaptureBar(
            width: size.width,
            height: size.height,
            onTap: () => showQuickCaptureSheet(context, now: widget.clock),
            onLongPress: () => showNewItemMenu(context, now: widget.clock),
            semanticsActions:
                newItemSemanticsActions(context, now: widget.clock),
          ),
        ),
      ),
    );
    if (widget.enableGlassScope) bar = GlassAdaptiveScope(child: bar);
    return A11yPrefsScope(prefs: _a11yPrefs, child: bar);
  }
}
