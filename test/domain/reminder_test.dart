import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../helpers/factories.dart';

void main() {
  group('Reminder recurrence (F3.1)', () {
    test('round-trips the rule', () {
      final rule = RecurrenceRule.weekly([1, 3], interval: 2);
      final r = buildReminder(
        remindAt: DateTime(2026, 9, 14, 8),
        recurrence: rule,
      );
      final json = r.toJson();
      expect(json['recurrence'], {
        'frequency': 'weekly',
        'interval': 2,
        'weekdays': [1, 3],
      });
      final restored = Reminder.fromJson(json);
      expect(restored.recurrence, rule);
      expect(restored.isRecurring, isTrue);
    });

    test('legacy JSON without the key loads as no recurrence', () {
      final json = buildReminder(remindAt: DateTime(2026, 9, 14, 8)).toJson()
        ..remove('recurrence');
      final restored = Reminder.fromJson(json);
      expect(restored.recurrence, RecurrenceRule.none);
      expect(restored.isRecurring, isFalse);
      expect(buildReminder().toJson()['recurrence'], isNull);
    });

    test('an old backup/prefs reminder without recurrence round-trips', () {
      // Shape written before F3.1 (SharedPreferences and F2.2 backups).
      const legacy = {
        'id': 'old',
        'title': 'Eski',
        'note': null,
        'isDone': false,
        'createdAt': '2026-01-01T12:00:00.000',
        'remindAt': '2026-09-20T09:00:00.000',
        'categoryId': 'other',
        'customCategoryLabel': null,
        'locationTriggerEnabled': false,
        'locationLatitude': null,
        'locationLongitude': null,
        'locationRadiusMeters': 150.0,
        'locationPlaceLabel': null,
      };
      final loaded = Reminder.fromJson(legacy);
      expect(loaded.recurrence, RecurrenceRule.none);

      final encoded = jsonEncode(loaded.toJson());
      final again = Reminder.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(again.recurrence, RecurrenceRule.none);
      expect(again.toJson(), {...legacy, 'recurrence': null});
    });

    test('copyWith keeps or replaces the rule', () {
      final r = buildReminder(recurrence: RecurrenceRule.daily());
      expect(r.copyWith(title: 'x').recurrence, RecurrenceRule.daily());
      expect(
        r.copyWith(recurrence: RecurrenceRule.none).recurrence,
        RecurrenceRule.none,
      );
    });
  });

  group('Reminder JSON', () {
    test('round-trip preserves all fields', () {
      final original = buildReminder(
        id: 'abc-123',
        title: 'Market',
        note: 'Süt, yumurta',
        isDone: true,
        createdAt: DateTime(2026, 3, 1, 10, 30),
        remindAt: DateTime(2026, 3, 2, 18, 45),
        categoryId: ReminderCategoryIds.other,
        customCategoryLabel: 'Hobi',
        locationTriggerEnabled: true,
        locationLatitude: 41.0082,
        locationLongitude: 28.9784,
        locationRadiusMeters: 300,
        locationPlaceLabel: 'Kadıköy',
      );

      final restored = Reminder.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.note, original.note);
      expect(restored.isDone, isTrue);
      expect(restored.createdAt, original.createdAt);
      expect(restored.remindAt, original.remindAt);
      expect(restored.categoryId, ReminderCategoryIds.other);
      expect(restored.customCategoryLabel, 'Hobi');
      expect(restored.locationTriggerEnabled, isTrue);
      expect(restored.locationLatitude, 41.0082);
      expect(restored.locationLongitude, 28.9784);
      expect(restored.locationRadiusMeters, 300);
      expect(restored.locationPlaceLabel, 'Kadıköy');
    });

    test('round-trip keeps null optional fields null', () {
      final restored = Reminder.fromJson(buildReminder().toJson());

      expect(restored.note, isNull);
      expect(restored.remindAt, isNull);
      expect(restored.customCategoryLabel, isNull);
      expect(restored.locationLatitude, isNull);
      expect(restored.locationLongitude, isNull);
      expect(restored.locationPlaceLabel, isNull);
    });

    test('fromJson applies defaults for missing optional fields', () {
      final restored = Reminder.fromJson({
        'id': 'x',
        'title': 'Eski kayıt',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
      });

      expect(restored.isDone, isFalse);
      expect(restored.remindAt, isNull);
      expect(restored.categoryId, ReminderCategoryIds.other);
      expect(restored.locationRadiusMeters, 150);
      expect(restored.locationTriggerEnabled, isFalse);
    });

    test('fromJson accepts integer coordinates and radius', () {
      final restored = Reminder.fromJson({
        'id': 'x',
        'title': 't',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'locationLatitude': 41,
        'locationLongitude': 29,
        'locationRadiusMeters': 200,
      });

      expect(restored.locationLatitude, 41.0);
      expect(restored.locationLongitude, 29.0);
      expect(restored.locationRadiusMeters, 200.0);
    });
  });

  group('Reminder.hasValidLocation', () {
    test('true when trigger enabled and both coordinates set', () {
      final r = buildReminder(
        locationTriggerEnabled: true,
        locationLatitude: 1,
        locationLongitude: 2,
      );
      expect(r.hasValidLocation, isTrue);
    });

    test('false when trigger disabled', () {
      final r = buildReminder(locationLatitude: 1, locationLongitude: 2);
      expect(r.hasValidLocation, isFalse);
    });

    test('false when a coordinate is missing', () {
      expect(
        buildReminder(locationTriggerEnabled: true, locationLatitude: 1)
            .hasValidLocation,
        isFalse,
      );
      expect(
        buildReminder(locationTriggerEnabled: true, locationLongitude: 2)
            .hasValidLocation,
        isFalse,
      );
    });
  });

  group('Reminder.categoryDisplayLabel', () {
    test('uses default label for fixed categories', () {
      expect(
        buildReminder(categoryId: ReminderCategoryIds.market)
            .categoryDisplayLabel,
        'Market',
      );
    });

    test('ignores custom label for non-other categories', () {
      expect(
        buildReminder(
          categoryId: ReminderCategoryIds.work,
          customCategoryLabel: 'Özel',
        ).categoryDisplayLabel,
        'İş',
      );
    });

    test('uses trimmed custom label for other', () {
      expect(
        buildReminder(customCategoryLabel: '  Hobi ').categoryDisplayLabel,
        'Hobi',
      );
    });
  });

  group('Reminder notification ids', () {
    const ids = ['r1', 'abc-123', '6f1c2b1e-0000-4000-8000-000000000000', ''];

    test('are non-negative and differ from each other', () {
      for (final id in ids) {
        final r = buildReminder(id: id);
        expect(r.notificationId, greaterThanOrEqualTo(0), reason: id);
        expect(r.geoNotificationId, greaterThanOrEqualTo(0), reason: id);
        expect(r.notificationId, isNot(r.geoNotificationId), reason: id);
      }
    });

    test('fit in a 32-bit signed int', () {
      for (final id in ids) {
        final r = buildReminder(id: id);
        expect(r.notificationId, lessThanOrEqualTo(0x7FFFFFFF));
        expect(r.geoNotificationId, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('are positive, non-zero and stable (F1.5)', () {
      for (final id in ids) {
        final r = buildReminder(id: id);
        final copy = r.copyWith(title: 'değişti');
        expect(r.notificationId, inInclusiveRange(1, 0x7FFFFFFF), reason: id);
        expect(r.geoNotificationId, inInclusiveRange(1, 0x7FFFFFFF),
            reason: id);
        expect(copy.notificationId, r.notificationId, reason: id);
        expect(copy.geoNotificationId, r.geoNotificationId, reason: id);
      }
      expect(
        buildReminder(id: '6f1c2b1e-0000-4000-8000-000000000000')
            .notificationId,
        1064515057,
      );
    });
  });

  group('Reminder.copyWith', () {
    final full = buildReminder(
      id: 'full',
      title: 'Tam',
      note: 'not',
      isDone: false,
      createdAt: DateTime(2026, 2, 1),
      remindAt: DateTime(2026, 2, 2, 8),
      categoryId: ReminderCategoryIds.other,
      customCategoryLabel: 'Hobi',
      locationTriggerEnabled: true,
      locationLatitude: 41,
      locationLongitude: 29,
      locationRadiusMeters: 250,
      locationPlaceLabel: 'Yer',
    );

    test('without arguments keeps every field', () {
      expect(full.copyWith().toJson(), full.toJson());
    });

    test('replaces every field', () {
      final copy = full.copyWith(
        id: 'new',
        title: 'Yeni',
        note: () => 'yeni not',
        isDone: true,
        createdAt: DateTime(2027, 1, 1),
        remindAt: () => DateTime(2027, 1, 2),
        categoryId: ReminderCategoryIds.work,
        customCategoryLabel: () => 'Özel',
        locationTriggerEnabled: false,
        locationLatitude: () => 1,
        locationLongitude: () => 2,
        locationRadiusMeters: 400,
        locationPlaceLabel: () => 'Başka yer',
        recurrence: RecurrenceRule.daily(interval: 2),
      );

      expect(copy.toJson(), {
        'id': 'new',
        'title': 'Yeni',
        'note': 'yeni not',
        'isDone': true,
        'createdAt': DateTime(2027, 1, 1).toIso8601String(),
        'remindAt': DateTime(2027, 1, 2).toIso8601String(),
        'categoryId': ReminderCategoryIds.work,
        'customCategoryLabel': 'Özel',
        'locationTriggerEnabled': false,
        'locationLatitude': 1.0,
        'locationLongitude': 2.0,
        'locationRadiusMeters': 400.0,
        'locationPlaceLabel': 'Başka yer',
        'recurrence': {'frequency': 'daily', 'interval': 2},
      });
    });

    test('clears nullable fields when the getter returns null', () {
      final copy = full.copyWith(
        note: () => null,
        remindAt: () => null,
        customCategoryLabel: () => null,
        locationLatitude: () => null,
        locationLongitude: () => null,
        locationPlaceLabel: () => null,
      );

      expect(copy.note, isNull);
      expect(copy.remindAt, isNull);
      expect(copy.customCategoryLabel, isNull);
      expect(copy.locationLatitude, isNull);
      expect(copy.locationLongitude, isNull);
      expect(copy.locationPlaceLabel, isNull);
      expect(copy.title, 'Tam');
      expect(copy.locationTriggerEnabled, isTrue);
    });

    test('does not modify the original', () {
      full.copyWith(isDone: true, note: () => null);
      expect(full.isDone, isFalse);
      expect(full.note, 'not');
    });
  });
}
