import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';

import '../helpers/factories.dart';

void main() {
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
