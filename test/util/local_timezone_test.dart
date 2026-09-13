import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:reminder/util/local_timezone.dart';

void main() {
  test('sets tz.local to the platform zone', () async {
    await configureLocalTimezone(
        localIdentifier: () async => 'Europe/Istanbul');

    expect(tz.local.name, 'Europe/Istanbul');
  });

  test('falls back to Etc/UTC when the platform call fails', () async {
    await configureLocalTimezone(
      localIdentifier: () async => throw Exception('no channel'),
    );

    expect(tz.local.name, kFallbackTimezone);
    expect(tz.TZDateTime.now(tz.local).timeZoneOffset, Duration.zero);
  });

  test('falls back to Etc/UTC for an unknown zone identifier', () async {
    await configureLocalTimezone(localIdentifier: () async => 'Mars/Olympus');

    expect(tz.local.name, kFallbackTimezone);
  });
}
