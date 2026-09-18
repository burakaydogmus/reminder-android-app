import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:reminder/ui/theme/haptics_store.dart';

/// Kor haptic vocabulary (`kor-design-proposal.md` §3.1 "Haptik").
///
/// | Event                               | Feedback         |
/// |-------------------------------------|------------------|
/// | Tamamla                             | `mediumImpact`   |
/// | Swipe threshold, token recognised   | `selectionClick` |
/// | Geri al, reorder drop               | `lightImpact`    |
/// | Sil                                 | `heavyImpact`    |
/// | Reorder pick-up                     | `mediumImpact`   |
///
/// Haptics are never the only feedback. Resolve with [KorHaptics.of] so
/// Ayarlar › "Titreşim geri bildirimi" applies: when it is off ([enabled]
/// false) every call is a no-op.
class KorHaptics {
  const KorHaptics({this.enabled = true});

  /// Haptics for [context]: disabled when the nearest [HapticsScope] says
  /// so; enabled without a scope. Does not register a dependency (call it
  /// from event handlers).
  static KorHaptics of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_HapticsInherited>();
    final enabled = scope?.notifier?.enabled ?? HapticsStore.defaultEnabled;
    return enabled ? const KorHaptics() : const KorHaptics(enabled: false);
  }

  final bool enabled;

  Future<void> complete() => _run(HapticFeedback.mediumImpact);
  Future<void> swipeThreshold() => _run(HapticFeedback.selectionClick);
  Future<void> tokenRecognized() => _run(HapticFeedback.selectionClick);
  Future<void> undo() => _run(HapticFeedback.lightImpact);
  Future<void> delete() => _run(HapticFeedback.heavyImpact);
  Future<void> reorderPickUp() => _run(HapticFeedback.mediumImpact);
  Future<void> reorderDrop() => _run(HapticFeedback.lightImpact);

  Future<void> _run(Future<void> Function() feedback) async {
    if (enabled) await feedback();
  }
}

/// The "Titreşim geri bildirimi" setting, loaded from a [HapticsStore].
class HapticsController extends ChangeNotifier {
  HapticsController(this.store);

  final HapticsStore store;

  bool _enabled = HapticsStore.defaultEnabled;
  bool _disposed = false;
  bool _changedByUser = false;

  bool get enabled => _enabled;

  Future<void> load() async {
    bool stored;
    try {
      stored = await store.isEnabled();
    } catch (_) {
      // No preferences (e.g. plugin unavailable): keep the default.
      return;
    }
    if (_disposed || _changedByUser || stored == _enabled) return;
    _enabled = stored;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _changedByUser = true;
    if (enabled != _enabled) {
      _enabled = enabled;
      notifyListeners();
    }
    await store.setEnabled(enabled);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provides the haptics setting to [KorHaptics.of] and Ayarlar. Wired in
/// `App` (inside `MaterialApp.builder`, so every route sees it); widget tests
/// pass a `HapticsStore.memory()`.
class HapticsScope extends StatefulWidget {
  const HapticsScope({super.key, this.store, required this.child});

  /// Defaults to [HapticsStore] over SharedPreferences.
  final HapticsStore? store;
  final Widget child;

  /// The controller, rebuilding [context] when the setting changes; null
  /// without a scope.
  static HapticsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HapticsInherited>()?.notifier;

  @override
  State<HapticsScope> createState() => _HapticsScopeState();
}

class _HapticsScopeState extends State<HapticsScope> {
  late final HapticsController _controller =
      HapticsController(widget.store ?? HapticsStore())..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _HapticsInherited(notifier: _controller, child: widget.child);
}

class _HapticsInherited extends InheritedNotifier<HapticsController> {
  const _HapticsInherited({required super.notifier, required super.child});
}
