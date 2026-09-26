import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/services/contacts_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/birthdays/contact_import_sheet.dart';
import 'package:reminder/ui/calendar/calendar_event_actions.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/snooze_sheet.dart';
import 'package:reminder/ui/routines/routine_apply_sheet.dart';
import 'package:reminder/ui/routines/routine_editor_sheet.dart';
import 'package:reminder/ui/routines/routine_step_sheet.dart';

import '../../helpers/factories.dart';
import '../../services/fake_contacts_platform.dart';
import '../ui_harness.dart';
import 'a11y_audit.dart';
import 'a11y_sample_data.dart';

/// F4.5 audit: bottom sheets (§3.6) on a phone-height surface.
const _phone = Size(390, 844);
const _bothPlatforms = [TargetPlatform.android, TargetPlatform.iOS];

final _gym =
    buildCategory(id: 'gym', name: 'Spor salonu', colorKey: 'lacivert');

/// Opens a sheet from a button on a plain page.
Future<UiHarness> _openSheet(
  WidgetTester tester,
  A11yVariant variant,
  void Function(BuildContext context) open, {
  List<Reminder>? reminders,
}) async {
  final h = await UiHarness.create(
    reminders: reminders ?? auditReminders(),
    birthdays: auditBirthdays(),
    categories: [_gym],
    routines: auditRoutines(),
    now: auditClock,
  );
  await tester.pumpWidget(
    h.app(
      theme: variant.theme,
      platform: variant.platform,
      language: variant.language,
      home: NowScope(clock: auditClock, child: auditOpener(open)),
    ),
  );
  await tapAuditOpener(tester);
  return h;
}

/// F7.3: opens "Rehberden aktar" over its fake address book. [permissions] and
/// [failure] select the refused / unreadable stages.
Future<UiHarness> _openContactImport(
  WidgetTester tester,
  A11yVariant variant, {
  PermissionSnapshot? permissions,
  ContactsReadException? failure,
}) async {
  final platform = FakeContactsPlatform(
    contactBirthdays: auditContactBirthdays(),
  )..failure = failure;
  final h = await UiHarness.create(
    birthdays: auditBirthdays(),
    now: auditClock,
  );
  if (permissions != null) h.permissions.snapshot = permissions;
  await tester.pumpWidget(
    h.app(
      theme: variant.theme,
      platform: variant.platform,
      language: variant.language,
      home: NowScope(
        clock: auditClock,
        child: auditOpener(
          (context) => showContactImportSheet(context, platform: platform),
        ),
      ),
    ),
  );
  await tapAuditOpener(tester);
  return h;
}

void main() {
  a11yAudit(
    'Hatırlatıcı editörü (yeni)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showReminderEditorSheet(context, now: auditClock),
      );
      expect(find.byKey(ReminderEditorKeys.save), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: _phone,
  );

  a11yAudit(
    'Hatırlatıcı editörü (tekrar, konum, maddeler)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showReminderEditorSheet(
          context,
          existing: auditReminders().firstWhere((r) => r.id == 'subtasks'),
          now: auditClock,
        ),
      );
    },
    surface: const Size(390, 2400),
  );

  a11yAudit(
    'Hızlı yakalama (ayrıştırılmış metin)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        // F5.3 opens it pre-filled (share / shortcut); same parsed state
        // as typing. F4.6c: the grammar follows the app language, so each
        // language needs its own sentence to audit **filled** chips.
        (context) => showQuickCaptureSheet(
          context,
          now: auditClock,
          initialText: variant.language == AppLanguage.english
              ? 'tomorrow at 9 the grocery shopping #groceries !'
              : 'yarın 9da market alışverişi #market !',
        ),
      );
      expect(find.byKey(QuickCaptureKeys.field), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: _phone,
  );

  a11yAudit('Kategori editörü (yeni)', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showCategoryEditorSheet(context),
    );
  }, surface: const Size(390, 1600));

  a11yAudit('Kategori editörü (mevcut)', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showCategoryEditorSheet(context, existing: _gym),
    );
  }, surface: const Size(390, 1600));

  a11yAudit('Doğum günü editörü', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showBirthdayEditorSheet(
        context,
        existing: auditBirthdays().first,
      ),
    );
  }, surface: const Size(390, 1600));

  // F8.1: the read-only fallback shown when the platform cannot open the
  // event itself. It has no editing controls, only "Hatırlatıcı oluştur".
  a11yAudit(
    'Takvim etkinliği (salt okunur)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showCalendarEventSheet(
          context,
          auditCalendarEvents().firstWhere((e) => e.id == 'review'),
          calendarName: 'İş',
          now: auditClock,
        ),
      );
      expect(
        find.byKey(CalendarEventSheetKeys.createReminder),
        findsOneWidget,
      );
    },
    platforms: _bothPlatforms,
    surface: _phone,
  );

  a11yAudit(
    'Takvim etkinliği (tüm gün, çok günlü)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showCalendarEventSheet(
          context,
          auditCalendarEvents().firstWhere((e) => e.id == 'trip'),
          calendarName: 'Kişisel',
          now: auditClock,
        ),
      );
    },
    surface: _phone,
  );

  a11yAudit('Ertele', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showSnoozeSheet(
        context,
        reminder: auditReminders().first,
        now: auditClock,
      ),
    );
  }, surface: _phone);

  a11yAudit('Tekrar', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showRecurrenceSheet(
        context,
        initial: RecurrenceRule.weekly([DateTime.monday, DateTime.thursday]),
        anchor: DateTime(2026, 9, 14, 9),
        now: auditNow,
      ),
    );
  }, surface: const Size(390, 1600));

  // The yearly option adds a sixth segment and its own note line.
  a11yAudit('Tekrar (yıllık, 29 Şubat)', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showRecurrenceSheet(
        context,
        initial: RecurrenceRule.yearly(interval: 2),
        anchor: DateTime(2028, 2, 29, 9),
        now: auditNow,
      ),
    );
  }, surface: const Size(390, 1600));

  // F3.1c: the "Tekrar ölçütü" control adds a second segmented button and a
  // long explanation line ("Tamamlandıktan sonra" / "After completion"), both
  // of which have to hold at text scale 2.0 in either language.
  a11yAudit('Tekrar (tamamlandıktan sonra)', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showRecurrenceSheet(
        context,
        initial: RecurrenceRule.afterCompletion(
          RecurrenceFrequency.daily,
          interval: 14,
        ),
        anchor: DateTime(2026, 9, 14, 9),
        now: auditNow,
      ),
    );
  }, surface: const Size(390, 1600));

  // Category chips keep working when the list is long.
  a11yAudit('Hatırlatıcı editörü (kategori seçili)', (tester, variant) async {
    await _openSheet(
      tester,
      variant,
      (context) => showReminderEditorSheet(
        context,
        initialCategoryId: ReminderCategoryIds.work,
        now: auditClock,
      ),
    );
  }, surface: const Size(390, 2400));

  // F3.7 routines: the editor (with steps and a repeat), the step sheet and
  // the apply sheet with its duplicate warning, in both languages.
  a11yAudit(
    'Rutin editörü (yeni)',
    (tester, variant) async {
      await _openSheet(tester, variant, showRoutineEditorSheet);
      expect(find.byKey(RoutineEditorKeys.save), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: const Size(390, 2800),
  );

  a11yAudit(
    'Rutin editörü (adımlar, haftalık tekrar)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showRoutineEditorSheet(
          context,
          existing: auditRoutines().firstWhere((r) => r.id == 'evening'),
        ),
      );
    },
    surface: const Size(390, 2800),
  );

  a11yAudit(
    'Rutin adımı',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showRoutineStepSheet(
          context,
          existing: auditRoutines()
              .firstWhere((r) => r.id == 'morning')
              .items
              .firstWhere((i) => i.id == 'vitamin'),
        ),
      );
      expect(find.byKey(RoutineStepKeys.save), findsOneWidget);
    },
    surface: const Size(390, 2400),
  );

  a11yAudit(
    'Rutini uygula',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showRoutineApplySheet(
          context,
          routine: auditRoutines().firstWhere((r) => r.id == 'morning'),
          now: auditClock,
        ),
      );
      expect(find.byKey(RoutineApplyKeys.apply), findsOneWidget);
    },
    platforms: _bothPlatforms,
    surface: const Size(390, 1400),
  );

  // The duplicate warning and its two actions must survive 200 % text.
  a11yAudit(
    'Rutini uygula (zaten uygulanmış)',
    (tester, variant) async {
      await _openSheet(
        tester,
        variant,
        (context) => showRoutineApplySheet(
          context,
          routine: auditRoutines().firstWhere((r) => r.id == 'evening'),
          now: auditClock,
        ),
        reminders: [
          ...auditReminders(),
          buildReminder(
            id: 'routine-book',
            title: 'Kitap oku',
            remindAt: DateTime(2026, 9, 14, 22),
            recurrence: RecurrenceRule.weekly(const [
              DateTime.monday,
              DateTime.wednesday,
              DateTime.friday,
            ]),
            routineId: 'evening',
            routineItemId: 'book',
          ),
        ],
      );
      expect(find.byKey(RoutineApplyKeys.warning), findsOneWidget);
    },
    surface: const Size(390, 1600),
  );
  // F7.3: the contacts import sheet. Long contact names, the "zaten ekli" /
  // "yıl bilinmiyor" notes and the checkbox rows all have to hold at text
  // scale 2.0 in either language.
  a11yAudit('Rehberden aktar (liste)', (tester, variant) async {
    await _openContactImport(tester, variant);
    expect(find.byKey(ContactImportKeys.importButton), findsOneWidget);
  }, surface: const Size(390, 1200));

  a11yAudit('Rehberden aktar (özet)', (tester, variant) async {
    await _openContactImport(tester, variant);
    await tester.tap(find.byKey(ContactImportKeys.selectAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportKeys.importButton));
    await tester.pumpAndSettle();
    expect(find.byKey(ContactImportKeys.done), findsOneWidget);
  }, surface: const Size(390, 1200));

  a11yAudit('Rehberden aktar (izin yok)', (tester, variant) async {
    await _openContactImport(
      tester,
      variant,
      permissions: const PermissionSnapshot(
        notifications: NotificationPermissionState.granted,
        exactAlarms: ExactAlarmState.granted,
        location: LocationPermissionState.always,
        contacts: ContactsPermissionState.denied,
      ),
    );
    expect(find.byKey(ContactImportKeys.openSettings), findsOneWidget);
  }, surface: const Size(390, 1000));
}
