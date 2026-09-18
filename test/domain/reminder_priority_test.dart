import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_priority.dart';

import '../helpers/factories.dart';

void main() {
  group('ReminderPriority', () {
    test('uses the capture parser scale 0–3', () {
      expect(ReminderPriority.values, [0, 1, 2, 3]);
      expect(ReminderPriority.none, 0);
      expect(ReminderPriority.high, 3);
    });

    test('normalize clamps out-of-range and missing values', () {
      expect(ReminderPriority.normalize(null), 0);
      expect(ReminderPriority.normalize(-2), 0);
      expect(ReminderPriority.normalize(2), 2);
      expect(ReminderPriority.normalize(9), 3);
    });

    test('labels, markers and spoken text', () {
      expect(
        ReminderPriority.values.map(ReminderPriority.label),
        ['Yok', 'Düşük', 'Orta', 'Yüksek'],
      );
      expect(
        ReminderPriority.values.map(ReminderPriority.marker),
        ['', '!', '!!', '!!!'],
      );
      expect(
        ReminderPriority.values.map(ReminderPriority.spoken),
        [null, 'Düşük öncelik', 'Orta öncelik', 'Yüksek öncelik'],
      );
    });
  });

  group('Reminder priority and pinned (F3.4)', () {
    test('default to no priority and not pinned', () {
      final r = buildReminder();
      expect(r.priority, ReminderPriority.none);
      expect(r.pinned, isFalse);
      expect(r.hasPriority, isFalse);
    });

    test('JSON round trip keeps both fields', () {
      final r = buildReminder(priority: 2, pinned: true);
      final json = r.toJson();
      expect(json['priority'], 2);
      expect(json['pinned'], true);
      final again = Reminder.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(again.priority, 2);
      expect(again.pinned, isTrue);
      expect(again.hasPriority, isTrue);
    });

    test('legacy JSON without the keys loads with the defaults', () {
      final json = buildReminder(priority: 3, pinned: true).toJson()
        ..remove('priority')
        ..remove('pinned');
      final loaded = Reminder.fromJson(json);
      expect(loaded.priority, 0);
      expect(loaded.pinned, isFalse);
    });

    test('bad values fall back instead of failing the item', () {
      final json = buildReminder().toJson()
        ..['priority'] = 'yüksek'
        ..['pinned'] = 'evet';
      final loaded = Reminder.fromJson(json);
      expect(loaded.priority, 0);
      expect(loaded.pinned, isFalse);

      final clamped = Reminder.fromJson(
        buildReminder().toJson()..['priority'] = 7.0,
      );
      expect(clamped.priority, ReminderPriority.high);
    });

    test('copyWith keeps or replaces them', () {
      final r = buildReminder(priority: 1, pinned: true);
      expect(r.copyWith(title: 'x').priority, 1);
      expect(r.copyWith(title: 'x').pinned, isTrue);
      final changed = r.copyWith(priority: 3, pinned: false);
      expect(changed.priority, 3);
      expect(changed.pinned, isFalse);
    });
  });
}
