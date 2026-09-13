import 'package:material_ui/material_ui.dart';

/// Provides the clock used by date-dependent screens (Bugün, Takvim, lists).
///
/// Tests inject a fixed clock; [tick] changes (e.g. once a minute) rebuild
/// dependants so sections move from "Bugün" to "Kaçanlar" without data
/// changes.
class NowScope extends InheritedWidget {
  const NowScope({
    super.key,
    required this.clock,
    this.tick = 0,
    required super.child,
  });

  final DateTime Function() clock;
  final int tick;

  static DateTime Function() clockOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NowScope>()?.clock ??
      DateTime.now;

  static DateTime now(BuildContext context) => clockOf(context)();

  /// Wraps a pushed route's page so it keeps the caller's clock (routes are
  /// not below the shell in the tree).
  static Widget carry(BuildContext context, Widget child) =>
      NowScope(clock: clockOf(context), child: child);

  @override
  bool updateShouldNotify(NowScope oldWidget) =>
      oldWidget.tick != tick || oldWidget.clock != clock;
}
