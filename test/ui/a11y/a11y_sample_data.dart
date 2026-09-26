import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/services/contacts_service.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/theme/adaptive/a11y_prefs.dart';

import '../../helpers/factories.dart';
import '../../services/fake_contacts_platform.dart';
import '../../services/fake_device_calendar_platform.dart';
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
        date: DateTime(1990, 10, 3),
        yearKnown: false,
      ),
    ];

/// F7.3 contacts import sample: a long name that has to wrap at text scale
/// 2.0, a year-less contact, a year-known one and a duplicate of the stored
/// `Zeynep Aydın` birthday (so the "zaten ekli" row is audited too).
List<ContactBirthday> auditContactBirthdays() => [
      buildContactBirthday(
        name: 'Zeynep Aydın',
        month: 9,
        day: 14,
        year: 1996,
      ),
      buildContactBirthday(
        name: 'Mehmet Şükrü Karaosmanoğlu',
        month: 3,
        day: 4,
      ),
      buildContactBirthday(name: 'Bora Demir', month: 6, day: 2, year: 1985),
    ];

/// F8.1 device calendar sample: an all-day row, a long-titled timed row with a
/// place and a multi-day span, plus one on a later day for the Takvim agenda.
List<DeviceCalendarEvent> auditCalendarEvents() => [
      buildCalendarEvent(
        id: 'holiday',
        calendarId: 'cal-holidays',
        title: 'Resmî tatil — kurumlar kapalı',
        start: DateTime(2026, 9, 13),
        isAllDay: true,
      ),
      buildCalendarEvent(
        id: 'review',
        calendarId: 'cal-work',
        title: 'Çeyrek dönem değerlendirme toplantısı ve planlama',
        start: DateTime(2026, 9, 13, 16, 30),
        end: DateTime(2026, 9, 13, 18),
        location: 'Merkez ofis, 4. kat toplantı odası',
      ),
      buildCalendarEvent(
        id: 'trip',
        calendarId: 'cal-personal',
        title: 'Şehir dışı gezi',
        start: DateTime(2026, 9, 13),
        end: DateTime(2026, 9, 16),
        isAllDay: true,
      ),
      buildCalendarEvent(
        id: 'dentist',
        calendarId: 'cal-personal',
        title: 'Diş hekimi kontrolü',
        start: DateTime(2026, 9, 15, 9, 45),
      ),
    ];

/// The device calendars behind [auditCalendarEvents].
List<DeviceCalendarInfo> auditDeviceCalendars() => [
      buildDeviceCalendar(id: 'cal-personal', name: 'Kişisel'),
      buildDeviceCalendar(
        id: 'cal-work',
        name: 'İş',
        accountName: 'is@example.com',
        colorHex: '#0B8043',
      ),
      buildDeviceCalendar(
        id: 'cal-holidays',
        name: 'Resmî tatiller',
        accountName: null,
        colorHex: null,
      ),
    ];

/// Pumps [HomeShell] with the sample data for [variant] (iOS: solid-free
/// glass chrome with the glass scope off, like `home_shell_test.dart`).
Future<UiHarness> pumpAuditShell(
  WidgetTester tester,
  A11yVariant variant, {
  List<Reminder>? reminders,
  bool calendarEvents = false,
}) async {
  final h = await UiHarness.create(
    reminders: reminders ?? auditReminders(),
    birthdays: auditBirthdays(),
    now: auditClock,
  );
  if (calendarEvents) {
    h.calendarPlatform
      ..calendarList = auditDeviceCalendars()
      ..eventList = auditCalendarEvents();
  }
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
  if (calendarEvents) {
    // F8.1 is opt-in, so the audit turns it on the way Ayarlar does.
    await h.calendar.setEnabled(true);
    await tester.pumpAndSettle();
  }
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
