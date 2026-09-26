import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/device_calendar_service.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/ui/calendar/calendar_event_actions.dart';
import 'package:reminder/ui/calendar/calendar_event_card.dart';
import 'package:reminder/ui/components/reminder_card.dart';
import 'package:reminder/ui/home/kor_navigation.dart';
import 'package:reminder/ui/home/home_shell.dart';
import 'package:reminder/ui/reminders/reminder_editor_sheet.dart';
import 'package:reminder/ui/settings/calendar_group.dart';
import 'package:reminder/ui/settings/permissions_group.dart';
import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/today/today_page.dart';

import '../../helpers/factories.dart';
import '../../services/fake_device_calendar_platform.dart';
import '../ui_harness.dart';

/// Sunday 13 September 2026, 14:32.
final _now = DateTime(2026, 9, 13, 14, 32);
DateTime _clock() => _now;

List<DeviceCalendarEvent> _events() => [
      buildCalendarEvent(
        id: 'standup',
        calendarId: 'cal-work',
        title: 'Ekip toplantısı',
        start: DateTime(2026, 9, 13, 16),
        location: 'Toplantı odası',
      ),
      buildCalendarEvent(
        id: 'holiday',
        calendarId: 'cal-personal',
        title: 'Resmî tatil',
        start: DateTime(2026, 9, 13),
        isAllDay: true,
      ),
      buildCalendarEvent(
        id: 'later',
        calendarId: 'cal-work',
        title: 'Yıllık değerlendirme',
        start: DateTime(2026, 9, 15, 11),
      ),
    ];

Future<UiHarness> _pumpShell(
  WidgetTester tester, {
  bool enabled = true,
  List<DeviceCalendarEvent>? events,
  AppLanguage language = AppLanguage.turkish,
}) async {
  final h = await UiHarness.create(
    reminders: [
      buildReminder(
        id: 'r1',
        title: 'Faturayı öde',
        categoryId: ReminderCategoryIds.home,
        remindAt: DateTime(2026, 9, 13, 18),
      ),
    ],
    now: _clock,
  );
  h.calendarPlatform
    ..calendarList = [
      buildDeviceCalendar(id: 'cal-personal', name: 'Kişisel'),
      buildDeviceCalendar(id: 'cal-work', name: 'İş', colorHex: '#0B8043'),
    ]
    ..eventList = events ?? _events();
  await tester.pumpWidget(
    h.app(language: language, home: const HomeShell(clock: _clock)),
  );
  await tester.pumpAndSettle();
  if (enabled) {
    await h.calendar.setEnabled(true);
    await tester.pumpAndSettle();
  }
  return h;
}

/// Taps the shell's [label] tab (the nav pill, never a page heading).
Future<void> _selectTab(WidgetTester tester, String label) async {
  // Inactive destinations are icon-only, so the label lives in semantics.
  final semantics = tester.ensureSemantics();
  await tester.tap(
    find.descendant(
      of: find.byType(KorPillNavigation),
      matching: find.bySemanticsLabel(label),
    ),
  );
  await tester.pumpAndSettle();
  semantics.dispose();
}

/// Scrolls [finder] into view inside the page's own scroll view.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Scrolls [key] into view and taps it.
Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Scrolls back up to [finder].
Future<void> _scrollUpTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Bugün', () {
    testWidgets('nothing appears until the user opts in', (tester) async {
      final h = await _pumpShell(tester, enabled: false);

      expect(find.byKey(TodayPageKeys.calendarEvents), findsNothing);
      expect(find.text('Ekip toplantısı'), findsNothing);
      expect(h.calendarPlatform.calls, isEmpty);
    });

    testWidgets('today\'s events show next to the reminders', (tester) async {
      await _pumpShell(tester);

      expect(find.byKey(TodayPageKeys.calendarEvents), findsOneWidget);
      expect(find.text('Ekip toplantısı'), findsOneWidget);
      expect(find.text('Resmî tatil'), findsOneWidget);
      // A reminder card is still there, and an event of another day is not.
      expect(find.text('Faturayı öde'), findsOneWidget);
      expect(find.text('Yıllık değerlendirme'), findsNothing);
    });

    testWidgets('an all-day event renders as all-day, not 00:00',
        (tester) async {
      await _pumpShell(tester);

      final card = tester.widget<CalendarEventCard>(
        find.ancestor(
          of: find.text('Resmî tatil'),
          matching: find.byType(CalendarEventCard),
        ),
      );
      expect(card.event.isAllDay, isTrue);
      expect(find.text('Tüm gün'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
    });

    testWidgets('events are read once, not on every rebuild', (tester) async {
      final h = await _pumpShell(tester);
      final reads = h.calendarPlatform.eventQueries.length;
      expect(reads, 1);

      // Three more frames (the shell ticks, the theme is read again).
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(h.calendarPlatform.eventQueries, hasLength(reads));
    });

    testWidgets('no section at all when the day has no event', (tester) async {
      await _pumpShell(
        tester,
        events: [
          buildCalendarEvent(
            id: 'next-week',
            title: 'Gelecek hafta',
            start: DateTime(2026, 9, 20, 10),
          ),
        ],
      );

      expect(find.byKey(TodayPageKeys.calendarEvents), findsNothing);
      expect(find.text('Gelecek hafta'), findsNothing);
    });

    testWidgets('an event row is not completable or swipeable', (tester) async {
      await _pumpShell(tester);

      final row = find.ancestor(
        of: find.text('Ekip toplantısı'),
        matching: find.byType(CalendarEventCard),
      );
      expect(row, findsOneWidget);
      // No reminder machinery inside the row: no checkbox, no swipe.
      expect(
        find.descendant(of: row, matching: find.byType(ReminderCard)),
        findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.byType(Dismissible)),
        findsNothing,
      );
    });
  });

  group('Takvim', () {
    testWidgets('events appear in the agenda of their own day', (tester) async {
      await _pumpShell(tester);
      await _selectTab(tester, 'Takvim');

      expect(find.text('Ekip toplantısı'), findsOneWidget);
      await _scrollTo(tester, find.text('Yıllık değerlendirme'));
      expect(find.text('Yıllık değerlendirme'), findsOneWidget);
    });

    testWidgets('a day with only events is not a "boş gün" row',
        (tester) async {
      await _pumpShell(
        tester,
        events: [
          buildCalendarEvent(
            id: 'only-event',
            title: 'Tek etkinlik',
            start: DateTime(2026, 9, 16, 10),
          ),
        ],
      );
      await _selectTab(tester, 'Takvim');

      await _scrollTo(tester, find.text('Tek etkinlik'));
      expect(find.text('Tek etkinlik'), findsOneWidget);
      expect(find.textContaining('16 Eylül — boş gün'), findsNothing);
    });
  });

  group('event actions', () {
    testWidgets('a tap opens the platform event view', (tester) async {
      final h = await _pumpShell(tester);

      await tester.tap(find.text('Ekip toplantısı'));
      await tester.pumpAndSettle();

      expect(h.calendarPlatform.openedEventIds, ['standup']);
      expect(find.byKey(CalendarEventSheetKeys.sheet), findsNothing);
    });

    testWidgets('a failed open falls back to the read-only sheet',
        (tester) async {
      final h = await _pumpShell(tester);
      h.calendarPlatform.openSucceeds = false;

      await tester.tap(find.text('Ekip toplantısı'));
      await tester.pumpAndSettle();

      final sheet = find.byKey(CalendarEventSheetKeys.sheet);
      expect(sheet, findsOneWidget);
      expect(find.text('Etkinlik'), findsOneWidget);
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('Toplantı odası'),
        ),
        findsOneWidget,
      );
      // Read-only: the only action is drafting a reminder.
      expect(
        find.byKey(CalendarEventSheetKeys.createReminder),
        findsOneWidget,
      );
      expect(find.text('Kaydet'), findsNothing);
    });

    testWidgets('"Hatırlatıcı oluştur" prefills the editor', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.byKey(CalendarEventRowKeys.menu('standup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatıcı oluştur').last);
      await tester.pumpAndSettle();

      final field =
          tester.widget<TextField>(find.byKey(ReminderEditorKeys.title));
      expect(field.controller?.text, 'Ekip toplantısı');
      // The event's own time, not "now".
      expect(find.text('16:00'), findsWidgets);
    });

    testWidgets('the prefilled reminder saves to our own store',
        (tester) async {
      final h = await _pumpShell(tester);

      await tester.tap(find.byKey(CalendarEventRowKeys.menu('standup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatıcı oluştur').last);
      await tester.pumpAndSettle();
      await _tapKey(tester, ReminderEditorKeys.save);

      expect(
        h.cubit.state.reminders.map((r) => r.title),
        contains('Ekip toplantısı'),
      );
      // Nothing was written to the device calendar: the seam has no write
      // method, and only reads/opens were recorded.
      expect(
        h.calendarPlatform.calls.toSet(),
        everyElement(isIn(const ['calendars', 'events', 'openEvent'])),
      );
    });
  });

  group('calendarEventDraft', () {
    test('an all-day event drafts 09:00 on its day', () {
      final draft = calendarEventDraft(
        buildCalendarEvent(
          title: 'Tatil',
          start: DateTime(2026, 9, 20),
          isAllDay: true,
        ),
        now: _now,
        id: 'new',
      );
      expect(draft.title, 'Tatil');
      expect(draft.remindAt, DateTime(2026, 9, 20, 9));
    });

    test('a past event drafts an untimed reminder (a past time is blocked)',
        () {
      final draft = calendarEventDraft(
        buildCalendarEvent(
          title: 'Sabah koşusu',
          start: DateTime(2026, 9, 13, 7),
        ),
        now: _now,
        id: 'new',
      );
      expect(draft.remindAt, isNull);
      expect(draft.isDone, isFalse);
    });

    test('a future timed event keeps its own start', () {
      final start = DateTime(2026, 9, 13, 16);
      final draft = calendarEventDraft(
        buildCalendarEvent(start: start),
        now: _now,
        id: 'new',
      );
      expect(draft.remindAt, start);
    });
  });

  group('Ayarlar', () {
    Future<UiHarness> pumpSettings(
      WidgetTester tester, {
      bool enabled = false,
      CalendarPermissionState permission = CalendarPermissionState.granted,
    }) async {
      final h = await UiHarness.create(now: _clock);
      h.permissions.snapshot = h.permissions.snapshot.copyWith(
        calendar: permission,
      );
      // The system prompt grants unless a test overrides the result.
      h.permissions.calendarRequestResult = CalendarPermissionState.granted;
      h.calendarPlatform.calendarList = [
        buildDeviceCalendar(id: 'cal-personal', name: 'Kişisel'),
        buildDeviceCalendar(id: 'cal-work', name: 'İş'),
      ];
      await tester.pumpWidget(h.app(home: const SettingsPage()));
      await tester.pumpAndSettle();
      if (enabled) {
        await h.calendar.setEnabled(true);
        await tester.pumpAndSettle();
      }
      await _scrollTo(tester, find.byKey(CalendarSettingsKeys.toggle));
      return h;
    }

    testWidgets('the toggle is off and shows no picker', (tester) async {
      await pumpSettings(tester);

      expect(find.byKey(CalendarSettingsKeys.toggle), findsOneWidget);
      expect(find.text('Gösterilecek takvimler'), findsNothing);
      expect(
          find.byKey(CalendarSettingsKeys.calendar('cal-work')), findsNothing);
      // No calendar row in İzinler either while the feature is off.
      expect(find.byKey(PermissionsGroupKeys.calendar), findsNothing);
    });

    testWidgets('turning it on asks for permission, then shows the picker',
        (tester) async {
      final h = await pumpSettings(
        tester,
        permission: CalendarPermissionState.notRequested,
      );

      await tester.tap(find.byKey(CalendarSettingsKeys.toggle));
      await tester.pumpAndSettle();
      // The pre-permission sheet explains the read-only use first.
      expect(find.text('Takvimindeki etkinlikleri de görelim'), findsOneWidget);
      await tester.tap(find.text('İzin ver').last);
      await tester.pumpAndSettle();

      expect(h.permissions.calls, contains('requestCalendar'));
      expect(h.calendar.enabled, isTrue);
      expect(await h.calendarStore.isEnabled(), isTrue);
      expect(find.text('Gösterilecek takvimler'), findsOneWidget);
      expect(
        find.byKey(CalendarSettingsKeys.calendar('cal-work')),
        findsOneWidget,
      );
      await _scrollUpTo(tester, find.byKey(PermissionsGroupKeys.calendar));
      expect(find.byKey(PermissionsGroupKeys.calendar), findsOneWidget);
    });

    testWidgets('a refused permission leaves the toggle off', (tester) async {
      final h = await pumpSettings(
        tester,
        permission: CalendarPermissionState.notRequested,
      );
      h.permissions.calendarRequestResult = CalendarPermissionState.denied;

      await tester.tap(find.byKey(CalendarSettingsKeys.toggle));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İzin ver').last);
      await tester.pumpAndSettle();

      expect(h.calendar.enabled, isFalse);
      expect(await h.calendarStore.isEnabled(), isFalse);
      expect(find.text('Gösterilecek takvimler'), findsNothing);
      expect(
        find.text('Takvim izni verilmedi. Ayarlardan izin verip tekrar dene.'),
        findsOneWidget,
      );
    });

    testWidgets('per-calendar switches persist', (tester) async {
      final h = await pumpSettings(tester, enabled: true);

      final workRow = find.descendant(
        of: find.byKey(CalendarSettingsKeys.calendar('cal-work')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(workRow).value, isTrue);

      await tester.tap(find.byKey(CalendarSettingsKeys.calendar('cal-work')));
      await tester.pumpAndSettle();

      expect(h.calendar.isCalendarVisible('cal-work'), isFalse);
      expect(await h.calendarStore.visibleCalendarIds(), ['cal-personal']);
    });

    testWidgets('İzinler gains a read-only Takvim row once opted in',
        (tester) async {
      await pumpSettings(tester, enabled: true);

      await _scrollUpTo(tester, find.byKey(PermissionsGroupKeys.calendar));
      expect(find.byKey(PermissionsGroupKeys.calendar), findsOneWidget);
      expect(find.text('Yalnızca okuma izni var'), findsOneWidget);
    });

    testWidgets('turning it off hides the picker again', (tester) async {
      final h = await pumpSettings(tester, enabled: true);

      await tester.tap(find.byKey(CalendarSettingsKeys.toggle));
      await tester.pumpAndSettle();

      expect(h.calendar.enabled, isFalse);
      expect(find.text('Gösterilecek takvimler'), findsNothing);
      expect(find.byKey(PermissionsGroupKeys.calendar), findsNothing);
    });
  });

  group('English', () {
    testWidgets('rows and labels follow the app language', (tester) async {
      await _pumpShell(tester, language: AppLanguage.english);

      expect(find.text('Calendar events'), findsOneWidget);
      expect(find.text('All day'), findsOneWidget);
      expect(find.text('Ekip toplantısı'), findsOneWidget);
      expect(find.textContaining('calendar event'), findsWidgets);
    });
  });

  test('the spoken label names the row a read-only calendar event', () {
    final label = CalendarEventCard.semanticLabel(
      buildCalendarEvent(
        title: 'Ekip toplantısı',
        start: DateTime(2026, 9, 13, 16),
      ),
      _now,
      AppL10n.turkish,
      calendarName: 'İş',
    );
    expect(label, contains('takvim etkinliği'));
    expect(label, contains('yalnızca okunur'));
    // §3.6 rule 11: a time is always spoken as "saat 16:00".
    expect(label, contains('saat 16:00'));
  });
}
