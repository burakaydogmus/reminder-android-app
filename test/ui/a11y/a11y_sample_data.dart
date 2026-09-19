import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';

import '../../helpers/factories.dart';
import '../ui_harness.dart';
import 'a11y_audit.dart';

/// Sunday 13 September 2026, 14:32 (the clock of the other UI tests).
final auditNow = DateTime(2026, 9, 13, 14, 32);
DateTime auditClock() => auditNow;

/// Bugün / Takvim / Listeler sample: overdue, recurring, subtasks, pinned,
/// high priority, located, untimed and completed reminders with long titles.
List<Reminder> auditReminders() => [
      buildReminder(
        id: 'overdue',
        title: 'Elektrik faturasını öde',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 11, 9, 15),
      ),
      buildReminder(
        id: 'recurring',
        title: 'Vitamin iç',
        categoryId: ReminderCategoryIds.health,
        remindAt: DateTime(2026, 9, 13, 9),
        recurrence: RecurrenceRule.daily(),
      ),
      buildReminder(
        id: 'pinned',
        title: "Ali'yi kurstan al",
        categoryId: ReminderCategoryIds.errands,
        remindAt: DateTime(2026, 9, 13, 16),
        pinned: true,
        priority: 3,
      ),
      buildReminder(
        id: 'subtasks',
        title: 'Hafta sonu market alışverişi ve temizlik malzemeleri',
        categoryId: ReminderCategoryIds.market,
        remindAt: DateTime(2026, 9, 13, 18, 30),
        subtasks: buildSubtasks(
          ['Süt', 'Ekmek', 'Deterjan', 'Peynir'],
          done: {0, 1},
        ),
        locationTriggerEnabled: true,
        locationLatitude: 41,
        locationLongitude: 29,
        locationPlaceLabel: 'Migros Kadıköy',
      ),
      buildReminder(
        id: 'tomorrow',
        title: 'Haftalık ekip toplantısı',
        categoryId: ReminderCategoryIds.work,
        remindAt: DateTime(2026, 9, 14, 8, 45),
        recurrence: RecurrenceRule.weekly([DateTime.monday]),
      ),
      buildReminder(id: 'untimed', title: 'Kitabı kütüphaneye iade et'),
      buildReminder(
        id: 'done',
        title: 'Sabah koşusu',
        isDone: true,
        remindAt: DateTime(2026, 9, 13, 7),
      ),
    ];

List<Birthday> auditBirthdays() => [
      buildBirthday(
          id: 'zeynep', name: 'Zeynep Aydın', date: DateTime(1996, 9, 14)),
      buildBirthday(
          id: 'deniz', name: 'Deniz Yılmaz', date: DateTime(2000, 2, 29)),
      buildBirthday(
        id: 'annem',
        name: 'Annem',
        date: DateTime(Birthday.unknownYear, 10, 3),
      ),
    ];

/// Pumps [HomeShell] with the sample data for [variant] (iOS: solid-free
/// glass chrome with the glass scope off, like `home_shell_test.dart`).
Future<UiHarness> pumpAuditShell(
  WidgetTester tester,
  A11yVariant variant, {
  List<Reminder>? reminders,
}) async {
  final h = await UiHarness.create(
    reminders: reminders ?? auditReminders(),
    birthdays: auditBirthdays(),
    now: auditClock,
  );
  final prefs = A11yPrefs(A11yPrefsData.none);
  addTearDown(prefs.dispose);
  await tester.pumpWidget(
    h.app(
      theme: variant.theme,
      platform: variant.platform,
      language: variant.language,
      home: HomeShell(
        clock: auditClock,
        enableGlassScope: false,
        a11yPrefs: prefs,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

/// Wraps [child] like a pushed route under the shell.
Widget auditOpener(void Function(BuildContext context) open) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

/// Taps the [auditOpener] button and settles.
Future<void> tapAuditOpener(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
