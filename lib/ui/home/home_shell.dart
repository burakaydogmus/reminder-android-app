import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/calendar/calendar_page.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/lists/lists_page.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/ui/today/today_page.dart';

/// App shell (§3.2): Bugün / Takvim / Listeler. Ayarlar opens from the gear
/// in each tab header.
///
/// Android: floating pill navigation + squircle FAB. iOS: plain bottom tab
/// bar + FAB. Back from Takvim/Listeler returns to Bugün.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.clock = DateTime.now});

  /// Injected for tests; screens read it through [NowScope].
  final DateTime Function() clock;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _tick = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Moves due reminders from "Bugün" to "Kaçanlar" without data changes.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
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
