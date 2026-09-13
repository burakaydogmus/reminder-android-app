import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Fallback zone when the platform zone cannot be resolved.
const String kFallbackTimezone = 'Etc/UTC';

/// Loads the timezone database and sets `tz.local` to the device zone.
///
/// Falls back to [kFallbackTimezone] when the platform call fails or returns
/// an identifier the database does not know. [localIdentifier] is injectable
/// for tests; it defaults to the `flutter_timezone` platform call.
Future<void> configureLocalTimezone({
  Future<String> Function()? localIdentifier,
}) async {
  tzdata.initializeTimeZones();
  try {
    final identifier = await (localIdentifier ?? _platformIdentifier)();
    tz.setLocalLocation(tz.getLocation(identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation(kFallbackTimezone));
  }
}

Future<String> _platformIdentifier() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;
