import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/services/notification_payload.dart';
import 'package:reminder/services/notification_tap_router.dart';
import 'package:reminder/ui/birthdays/birthdays_page.dart';
import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/today/today_page.dart';

/// App shell (§3.2): Bugün / Takvim / Listeler. Ayarlar opens from the gear
/// in each tab header.
///
/// Android: floating pill navigation + squircle FAB. iOS: plain bottom tab
/// bar + FAB. Back from Takvim/Listeler returns to Bugün.
///
/// Notification taps (F3.2) arrive through [tapRouter]: a reminder payload
/// opens its editor (after the first load), a birthday payload opens
/// Listeler › Doğum günleri.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.clock = DateTime.now,
    this.tapRouter,
    this.reminderLoadTimeout = const Duration(seconds: 5),
  });

  /// Injected for tests; screens read it through [NowScope].
  final DateTime Function() clock;

  /// Notification tap targets; defaults to [NotificationTapRouter.instance].
  final NotificationTapRouter? tapRouter;

  /// How long a tapped reminder is awaited in the cubit state (cold start:
  /// the first `load()` may still be running).
  final Duration reminderLoadTimeout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _tick = 0;
  Timer? _ticker;

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
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
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

    final body = NowScope(
      clock: widget.clock,
      tick: _tick,
      child: IndexedStack(
        index: _index,
        children: const [TodayPage(), CalendarPage(), ListsPage()],
      ),
    );

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        extendBody: !cupertino,
        body: body,
        floatingActionButton: cupertino ? const NewItemFab() : null,
        bottomNavigationBar: cupertino
            ? KorTabBar(selectedIndex: _index, onSelected: _select)
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
                    const NewItemFab(),
                  ],
                ),
              ),
      ),
    );
  }
}
