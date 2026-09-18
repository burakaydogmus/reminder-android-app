import 'dart:async';

import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, MissingPluginException, PlatformException;
import 'package:material_ui/material_ui.dart';

/// iOS accessibility settings that [MediaQuery] does not expose
/// (`kor-design-proposal.md` §3.6 rule 8): Reduce Transparency, Increase
/// Contrast ("Darker system colors") and Low Power Mode.
@immutable
class A11yPrefsData {
  const A11yPrefsData({
    this.reduceTransparency = false,
    this.increaseContrast = false,
    this.lowPower = false,
  });

  /// Nothing reported (Android, tests, channel not answered yet).
  static const none = A11yPrefsData();

  factory A11yPrefsData.fromMap(Map<Object?, Object?> map) => A11yPrefsData(
        reduceTransparency: map['reduceTransparency'] == true,
        increaseContrast: map['increaseContrast'] == true,
        lowPower: map['lowPower'] == true,
      );

  /// `UIAccessibility.isReduceTransparencyEnabled`.
  final bool reduceTransparency;

  /// `UIAccessibility.isDarkerSystemColorsEnabled`.
  final bool increaseContrast;

  /// `ProcessInfo.isLowPowerModeEnabled`.
  final bool lowPower;

  /// Glass chrome should render as solid `surfaceContainerHigh`.
  bool get prefersSolid => reduceTransparency || increaseContrast || lowPower;

  @override
  bool operator ==(Object other) =>
      other is A11yPrefsData &&
      other.reduceTransparency == reduceTransparency &&
      other.increaseContrast == increaseContrast &&
      other.lowPower == lowPower;

  @override
  int get hashCode =>
      Object.hash(reduceTransparency, increaseContrast, lowPower);

  @override
  String toString() => 'A11yPrefsData(reduceTransparency: $reduceTransparency, '
      'increaseContrast: $increaseContrast, lowPower: $lowPower)';
}

/// Current [A11yPrefsData]. [A11yPrefs.new] holds a fixed value (tests);
/// [A11yPrefs.platform] reads it from `ios/Runner/AppDelegate.swift` over
/// [channelName] and follows the native change notifications.
///
/// Provide it with [A11yPrefsScope]; read it with [A11yPrefs.of].
class A11yPrefs extends ValueNotifier<A11yPrefsData> {
  A11yPrefs([super.value = A11yPrefsData.none]) : _channel = null;

  A11yPrefs.platform({MethodChannel channel = const MethodChannel(channelName)})
      : _channel = channel,
        super(A11yPrefsData.none) {
    channel.setMethodCallHandler(_handle);
    unawaited(_fetch());
  }

  static const channelName = 'com.burakaydogmus.reminder/a11y_prefs';

  final MethodChannel? _channel;
  bool _disposed = false;

  Future<void> _fetch() async {
    try {
      final map = await _channel!.invokeMapMethod<Object?, Object?>('get');
      if (map != null && !_disposed) value = A11yPrefsData.fromMap(map);
    } on MissingPluginException {
      // Android / tests: no native side, keep [A11yPrefsData.none].
    } on PlatformException {
      // Keep the last known value.
    }
  }

  Future<Object?> _handle(MethodCall call) async {
    final args = call.arguments;
    if (call.method == 'changed' && args is Map && !_disposed) {
      value = A11yPrefsData.fromMap(args);
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  /// The nearest scope's value, or [A11yPrefsData.none] without a scope.
  static A11yPrefsData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<A11yPrefsScope>()
          ?.notifier
          ?.value ??
      A11yPrefsData.none;
}

/// Makes [A11yPrefs] available to [A11yPrefs.of] and rebuilds dependents on
/// change.
class A11yPrefsScope extends InheritedNotifier<A11yPrefs> {
  const A11yPrefsScope({
    super.key,
    required A11yPrefs prefs,
    required super.child,
  }) : super(notifier: prefs);
}
