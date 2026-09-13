import 'package:flutter/services.dart';

/// Kor haptic vocabulary (`kor-design-proposal.md` §3.1 "Haptik").
///
/// Haptics are never the only feedback. When [enabled] is false (Ayarlar ›
/// Titreşim geri bildirimi) every call is a no-op. Wired up in F4.7.
class KorHaptics {
  const KorHaptics({this.enabled = true});

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
