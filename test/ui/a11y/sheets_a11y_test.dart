import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/recurrence.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/birthdays/birthday_editor_sheet.dart';
import 'package:reminder/ui/capture/quick_capture_sheet.dart';
import 'package:reminder/ui/categories/category_editor_sheet.dart';
import 'package:reminder/ui/common/now_scope.dart';
import 'package:reminder/ui/reminders/recurrence_sheet.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/reminders/snooze_sheet.dart';

import '../../helpers/factories.dart';
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
  void Function(BuildContext context) open,
) async {
  final h = await UiHarness.create(
    reminders: auditReminders(),
    birthdays: auditBirthdays(),
    categories: [_gym],
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
}
