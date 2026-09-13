import 'package:material_ui/material_ui.dart';

/// The single place that decides Android vs iOS chrome (nav, sheets,
/// switches). Reads `Theme.of(context).platform`, so tests can override it
/// through the theme.
abstract final class PlatformChrome {
  static bool isCupertino(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  /// Android-only features (home screen widget pinning).
  static bool isAndroid(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.android;
}
