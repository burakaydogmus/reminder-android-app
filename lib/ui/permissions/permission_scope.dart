import 'package:material_ui/material_ui.dart';

import 'package:reminder/services/permission_service.dart';

/// Holds the latest [PermissionSnapshot] and re-checks it when the app comes
/// back to the foreground (e.g. after the user changed a permission in
/// system settings).
class PermissionController extends ChangeNotifier with WidgetsBindingObserver {
  PermissionController(this.service);

  final PermissionService service;

  PermissionSnapshot? _snapshot;
  bool _disposed = false;

  /// `null` until the first check finished.
  PermissionSnapshot? get snapshot => _snapshot;

  Future<PermissionSnapshot> refresh() async {
    final next = await service.check();
    if (!_disposed && next != _snapshot) {
      _snapshot = next;
      notifyListeners();
    }
    return next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provides a [PermissionController] above `MaterialApp` (wired in `main.dart`,
/// replaced by a fake service in widget tests).
class PermissionScope extends StatefulWidget {
  const PermissionScope({
    super.key,
    required this.service,
    required this.child,
  });

  final PermissionService service;
  final Widget child;

  /// Controller that rebuilds [context] when the snapshot changes.
  static PermissionController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_PermissionInherited>();
    assert(scope != null, 'No PermissionScope above this widget');
    return scope!.notifier!;
  }

  /// Controller without registering a dependency (event handlers).
  static PermissionController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_PermissionInherited>();
    assert(scope != null, 'No PermissionScope above this widget');
    return scope!.notifier!;
  }

  @override
  State<PermissionScope> createState() => _PermissionScopeState();
}

class _PermissionScopeState extends State<PermissionScope> {
  late PermissionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PermissionController(widget.service);
    WidgetsBinding.instance.addObserver(_controller);
    _controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_controller);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PermissionInherited(notifier: _controller, child: widget.child);
  }
}

class _PermissionInherited extends InheritedNotifier<PermissionController> {
  const _PermissionInherited({required super.notifier, required super.child});
}
