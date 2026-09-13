import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/reminder_category.dart';

void main() {
  group('ReminderCategoryIds.defaultLabel', () {
    test('maps every known id to its Turkish label', () {
      expect(ReminderCategoryIds.defaultLabel(ReminderCategoryIds.market),
          'Market');
      expect(ReminderCategoryIds.defaultLabel(ReminderCategoryIds.home),
          'Ev İşleri');
      expect(ReminderCategoryIds.defaultLabel(ReminderCategoryIds.work), 'İş');
      expect(ReminderCategoryIds.defaultLabel(ReminderCategoryIds.health),
          'Sağlık');
      expect(ReminderCategoryIds.defaultLabel(ReminderCategoryIds.errands),
          'Günlük');
      expect(
          ReminderCategoryIds.defaultLabel(ReminderCategoryIds.other), 'Diğer');
    });

    test('falls back to Diğer for unknown ids', () {
      expect(ReminderCategoryIds.defaultLabel('unknown'), 'Diğer');
    });

    test('orderedIds contains every category once, other last', () {
      expect(ReminderCategoryIds.orderedIds.toSet().length, 6);
      expect(ReminderCategoryIds.orderedIds.last, ReminderCategoryIds.other);
    });
  });

  group('ReminderCategoryIds.displayLabel', () {
    test('uses trimmed custom label for other', () {
      expect(
        ReminderCategoryIds.displayLabel(ReminderCategoryIds.other, ' Hobi '),
        'Hobi',
      );
    });

    test('falls back to default for other with null or blank label', () {
      expect(
        ReminderCategoryIds.displayLabel(ReminderCategoryIds.other, null),
        'Diğer',
      );
      expect(
        ReminderCategoryIds.displayLabel(ReminderCategoryIds.other, '   '),
        'Diğer',
      );
    });

    test('ignores custom label for fixed categories', () {
      expect(
        ReminderCategoryIds.displayLabel(ReminderCategoryIds.health, 'X'),
        'Sağlık',
      );
    });
  });
}
