import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/services/notification_payload.dart';

void main() {
  group('NotificationPayload', () {
    test('encodes reminders and birthdays with a namespace', () {
      expect(const ReminderPayload('abc').encode(), 'reminder:abc');
      expect(const BirthdayPayload('b1').encode(), 'birthday:b1');
    });

    test('parse is the inverse of encode', () {
      for (final payload in const <NotificationPayload>[
        ReminderPayload('3f2a-uuid'),
        BirthdayPayload('b1'),
      ]) {
        expect(NotificationPayload.parse(payload.encode()), payload);
      }
    });

    test('a raw id (geofence payload before F3.2) is a reminder', () {
      expect(NotificationPayload.parse('abc'), const ReminderPayload('abc'));
    });

    test('empty or id-less payloads are null', () {
      for (final raw in [null, '', 'reminder:', 'birthday:']) {
        expect(NotificationPayload.parse(raw), isNull, reason: '$raw');
      }
    });

    test('reminder and birthday payloads with the same id differ', () {
      expect(
        NotificationPayload.parse('birthday:x'),
        isNot(NotificationPayload.parse('reminder:x')),
      );
    });
  });
}
