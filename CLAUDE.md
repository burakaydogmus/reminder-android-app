# CLAUDE.md

Guidance for AI agents and contributors working in this repository.

## Project overview

Flutter reminder app ("Hatırlatıcı"): to-dos/shopping items with optional scheduled
notifications, location-triggered (geofence) reminders, recurring birthday reminders
and an Android home screen widget. Local storage only (Drift/SQLite, see **Data**).
Targets **Android + iOS**. UI strings are **Turkish and English** (ARB, see
**Localization**); Turkish is the template language.

The development plan lives in [`ROADMAP.md`](ROADMAP.md) — read it before starting work.

## Commands

```bash
flutter pub get                 # install dependencies
flutter analyze --fatal-infos   # static analysis (must be clean, CI enforces)
flutter test                    # unit/widget tests (CI enforces)
flutter run                     # run on a device/emulator
flutter run --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY   # enables Google Places nearby search
flutter build apk --debug       # Android debug build
flutter build ios --no-codesign --debug              # iOS build (macOS only)
dart run flutter_launcher_icons # regenerate app icons
```

Toolchain: Flutter 3.47.4 stable / Dart 3.13 (pinned in CI). Android: AGP 9.1.0,
Gradle 9.3.1, KGP 2.4.0 (`android.builtInKotlin=false`), compileSdk/targetSdk 36,
minSdk 26, Java 17. iOS minimum 15.0 with the UIScene lifecycle. Upgrade record and
reasons: [`docs/upgrades/flutter-3.47.md`](docs/upgrades/flutter-3.47.md).
`GOOGLE_MAPS_KEY` is optional; the map (OpenStreetMap via `flutter_map`) works without it.

Local SDK: an older global Flutter cannot resolve the dependencies. Install 3.47.4 side
by side (e.g. `C:/src/flutter-3.47`) and call it by absolute path instead of running
`flutter upgrade` on a shared SDK. On Windows, when the project path contains non-ASCII
characters, `flutter analyze` crashes (LSP) — use `dart analyze --fatal-infos` locally —
and `flutter build apk` fails; build from an ASCII-path copy or rely on CI.

Formatting is enforced in CI: run `dart format lib test` before committing
(`dart format --output=none --set-exit-if-changed lib test` is the CI check).

## Architecture (`lib/`)

- `main.dart` — bootstraps timezone, date formatting, notifications, geofences,
  home widget callback registration (Android), then
  `runApp(PermissionScope(service: PlatformPermissionService.platform(), child: App()))`.
  It requests **no permissions** (see **Permissions** below).
- `app.dart` — `MaterialApp`, theme, localization; **composition root**: creates
  `ReminderCubit` with the real services (see Dependency injection below).
- `bloc/reminder_cubit.dart` — `ReminderCubit`: single source of app state (reminders,
  birthdays, settings); persists via the repository and re-syncs notifications,
  geofences and the home widget after every change.
- `data/reminder_repository.dart` — `ReminderRepository`: load/save reminders, birthdays
  and `AppSettings` in the Drift database (see **Data**). `data/db/` holds the schema
  (`app_database.dart` + generated `app_database.g.dart`), row mapping and the per-isolate
  `AppDatabaseHost`; `data/legacy_prefs_store.dart` is the old SharedPreferences JSON
  store (migration source and fallback); `data/prefs_migration.dart` the one-time import.
- `domain/model/` — `Reminder` (with `copyWith`), `Birthday`, `ReminderCategory`,
  `AppSettings`. Categories (F4.3, `reminder_category.dart`): `ReminderCategory { id,
  name, colorKey (KorColorKey.storageKey), iconKey (CategoryIconKeys, 18 fixed keys),
  position }` + `isBuiltIn`; the six built-ins (`ReminderCategoryIds`) keep their ids,
  names, colours and icons (only their order is stored) and can't be deleted.
  `CategoryCatalog(stored)` is the ordered, immutable list (built-ins added when
  missing — first when none is stored —, duplicate ids dropped, positions 0..n-1,
  value equality); `resolve(id)`/`labelOf(id)` map unknown/deleted ids to "Diğer";
  `byFoldedName` compares names case/Turkish-diacritic insensitive
  (`CategoryNames.fold`). `domain/category_label_migration.dart`
  (`CategoryLabelMigration`) is the **one** "Diğer + özel ad" → user category rule
  (schema v5 step, `PrefsMigration`, v1 backups): one category per folded label
  (first spelling wins; colour `diger`, icon `label`), a label equal to an existing
  category's name joins it (`market` → Market, `diğer` stays), stable id
  `label-<fnv1a32 hex of the folded name>`. `Reminder.customCategoryLabel` is no longer
  shown or written (kept for rollback; the editor keeps it only while the category is
  unchanged). Nullable fields in `copyWith` take `T? Function()?`
  (`copyWith(note: () => null)` clears). `Birthday`: a Feb 29 birthday falls on
  **Feb 28 in non-leap years** (`occurrenceInYear`, used by `nextOccurrence`,
  `daysUntilNext`, `upcomingAge`); date helpers take `from:` for tests. A birthday is
  **month + day + optional year** (`month`, `day`, `year`; `Birthday.onDate(date:,
  yearKnown:)` builds one from a `DateTime`, `birthDate` is null without a year):
  a birthday without a known year has `year == null`, `hasYear` false and no age
  (F4.4, F6.4). Before F6.4 the year was the sentinel `4`
  (`Birthday.legacyUnknownYear`); it survives only in the JSON `date` field (see
  **Backup**) and in the v5 → v6 migration.
- `domain/model/recurrence.dart` — `RecurrenceRule` (F3.1, yearly F3.1b): none /
  daily / weekly (sorted Mon-first weekdays) / monthly (day of month, clamped to the
  month end: 31 → 30/28/29) / **yearly** (`yearly({interval, month, dayOfMonth,
  until})`: `month` and `dayOfMonth` are optional and **fall back to the anchor's**,
  so the series follows the reminder's own date; the day is clamped the same way, so
  a **29 February rule fires on 28 February in non-leap years** — the same rule
  birthdays use, `Birthday.occurrenceInYear`. `yearlyTarget(anchor)` resolves the
  month/day pair), `interval` (every N days/weeks/months/years; "Özel" = daily
  N ≥ 2),
  optional `until` (inclusive date). `nextOccurrence(after:, anchor:)` returns the
  first occurrence strictly after `after`; the **time comes from `anchor`** (the
  reminder's `remindAt`) and dates are built from calendar fields
  (`DateTime(y, m, d + n, h, min)`), never `Duration` adds, so the wall-clock time
  survives DST. Interval grids start at the anchor's day/week/month/year. The display
  text lives in the UI: `RecurrenceText.summary(rule, l10n)` ("Her gün", "2 haftada bir
  Pzt, Çar", "Her ayın 17'si", "Her yıl", "2 yılda bir", "Her yıl 14 Şubat" (only
  when month **and** day are explicit) / "Every 2 weeks on Mon, Wed", "Every year",
  F6.1);
  `alignedTo(date)` adapts the rule when the whole series moves to another date (an
  anchor-derived yearly rule needs no change; an explicit one takes the new
  month/day unless the clamp already matches, so a 29 February rule survives a move
  to 28 February; a completion-anchored rule is returned as is — `anchorMode` never
  changes with a move).
  **Two anchor modes (`anchorMode`, `RecurrenceAnchor`, F3.1c)** cut across the
  frequencies:
  - `schedule` (default, everything above) — the series is **fixed dates**. Completing
    late does not move the next one; missed occurrences are skipped.
  - `completion` — the next occurrence is **the completion day + interval**
    ("tamamlandıktan 14 gün sonra"), built with `RecurrenceRule.afterCompletion(
    frequency, {interval, until})` and computed by
    `nextAfterCompletion(completedAt:, anchor:)`; the time of day still comes from
    `anchor`, not from the moment of completion (a 10:00 reminder completed at 23:40 on
    the 3rd with a 14-day interval lands on the 17th at **10:00**), and month/year
    intervals clamp to the month end. The calendar fields (`weekdays`, `dayOfMonth`,
    `month`) are meaningless here, so the factory does not take them and `fromJson`
    drops them; `yearlyTarget` is null. `until` still applies.
    **`nextOccurrence` (and `firstOnOrAfter` / `upcoming`) returns `null` for such a
    rule** — there is no calendar-known future date. Everything downstream falls out of
    that: an overdue one is not rescheduled and waits in Kaçanlar (`reminderFireTime`),
    native notification repeats are impossible (see **Schedule sync**), and the calendar
    shows only the current occurrence (see **Takvim**). "Hepsini yarına al" already
    skips it (`movableOverdue` skips every recurring reminder).
  `Reminder.recurrence` defaults to none (JSON key `recurrence`, missing/corrupt →
  none); `Reminder.isRecurring` also needs a `remindAt`. **`fromJson` is
  deliberately tolerant, so it is also the forward-compatibility contract:** a build
  that does not know a frequency reads the rule as `none` — the reminder survives and
  only loses its repeat. The anchor mode is written as an **extra** field
  (`anchor: 'completion'`, only in that mode), so a calendar rule's JSON is byte for
  byte what F3.1b wrote and a build without F3.1c simply ignores the field: the repeat
  keeps working but **stops chasing the completion date**. The exception is a *monthly*
  completion rule — an older reader needs `dayOfMonth` and none can be written (the rule
  does not know the anchor), so it reads as `none`. Adding a frequency or an anchor mode
  therefore needs **no schema bump** (`reminders.recurrence` is a nullable TEXT column
  holding this JSON) and no backup format bump, but it must be called out in the
  CHANGELOG.
- `domain/model/routine.dart` — `Routine`, `RoutineItem`, `RoutineTime` (F3.7,
  reminder templates) and `domain/routine_apply.dart` — `RoutineApplyPlan`, the
  single "apply a routine to a day" rule. See **Routines (F3.7)**.
- `domain/model/subtask.dart` — `Subtask { id, title, isDone, position }` (F3.3) and
  `Reminder.subtasks` (default empty; JSON key `subtasks`, missing → empty, unreadable
  items skipped). Change lists only through the `SubtaskList` extension (`toggled`,
  `renamed`, `added`/`addedAll`, `removed`, `reordered`, `moved`, `reset`,
  `inOrder`, progress getters): every helper returns an unmodifiable list with
  `position` = index. `splitSubtaskText` splits lines, `,` (not a decimal comma),
  `;` and a separate-word " ve " (bullets/checkboxes stripped) — the editor's
  "Maddelere böl" button; the quick-capture parser (F4.6a) has its own list
  detection (`parsing/rules/list_rules.dart`) whose items become `Subtask`s when
  "Maddelere böl?" is accepted in the capture sheet (F4.6b). `splitSubtaskLines` splits line breaks only (paste, Enter). Completing a reminder never completes its subtasks and all
  subtasks done never completes the reminder (the editor only suggests it).
- `domain/model/reminder_priority.dart` — `ReminderPriority` (F3.4): 0 none,
  1 Düşük, 2 Orta, 3 Yüksek — the **same scale as the quick-capture parser**
  (`!`/`!!`/`!!!`, `CaptureParseResult.priority`); `normalize` clamps, `label`,
  `marker` ("!!!"), `spoken` ("Yüksek öncelik"). `Reminder.priority` (default 0, JSON
  `priority`, missing/non-number → 0, out of range clamped) and `Reminder.pinned`
  (default false, JSON `pinned`, missing/non-bool → false). Priority does not change
  notifications.
- `domain/parsing/` — quick-capture parser, Turkish (F4.6a) and English (F4.6c)
  grammars behind one `CaptureLocale`, and
  `capture_to_reminder.dart`, its mapping to a new `Reminder` (F4.6b); see
  **Quick capture**.
- `domain/contact_birthday_import.dart` (F7.3) — the pure rules of the contacts
  birthday import: the dedupe key (`TextSearch.foldName` + month/day, year excluded),
  `candidates` (rows, duplicates marked and collapsed, sorted), `toBirthday` and
  `plan`. See **Contacts import (F7.3)**.
- `domain/reminder_completion.dart` — `completeReminder(reminder, now)`: the **only**
  "Tamamla" rule (cubit `toggleDone`, home widget toggle, notification Tamamla
  action; any new completion path must use it too). Recurring reminders are never marked done: on a
  calendar-anchored rule `remindAt` advances to the
  next occurrence after `max(now, remindAt)` (early completion skips this occurrence,
  overdue ones skip missed occurrences); on a **completion-anchored** one (F3.1c) it
  advances from `now` — the day it was really completed — through
  `nextAfterCompletion`, so completing late pushes the next one out and completing
  early pulls it in. Either way its subtasks are **reset to open**
  (F3.3); a finished series and one-off reminders get `isDone = true` with subtasks
  untouched.
- `domain/reminder_sorting.dart` — `compareReminders`: the single reminder ordering
  (§3.3.2, F3.4): active before done; **pinned before unpinned**; timed before
  untimed; timed by `remindAt` asc, same time → priority desc; untimed by priority
  desc, then `createdAt` desc. Used by the cubit, the home widget sync and every
  list/section (search and the calendar agenda only as a tie-breaker). The Bugün
  ribbon and the agenda sort by time first, so a pinned item never jumps ahead
  there. `ReminderCubit` re-sorts after **every** list change, so `state.reminders`
  is always in this order.
- Clock: `ReminderCubit(..., now: ...)` (default `DateTime.now`) is passed to every
  `ReminderState` as `clock`; date-dependent getters (`upcomingBirthdays`) use it.
- Birthday notifications repeat yearly with `DateTimeComponents.dateAndTime` and the
  **same text**, so titles/bodies must not contain the age or anything year-specific
  (`NotificationService.birthdayNotificationTitle/Body`); the age is shown in the app.
- `services/`
  - `sync_interfaces.dart` — `GeofenceSync` and `HomeWidgetSync` interfaces.
  - `schedule_sync.dart` — `NotificationSync` interface and `ScheduleSync.syncAll`,
    the **single entry point** that brings notifications, geofences and the home
    widget in line with stored state. See **Schedule sync** below.
  - `notification_service.dart` — `flutter_local_notifications` scheduling (singleton);
    implements `NotificationSync`.
  - `geofence_service.dart` — diff-based region registration (`native_geofence`);
    implements `GeofenceSync`. See **Geofencing** below.
  - `geofence_callback.dart` — `geofenceEntryCallback`, the background entry point
    that shows location notifications (also when the app is terminated).
  - `geofence_logic.dart` — pure rules: region selection/limits, sync plan, notify
    decision (cooldown, initial-trigger grace). `geofence_platform.dart` wraps the
    plugin; `geofence_state_store.dart` persists registrations and last-notified times.
  - `permission_service.dart` — `PermissionService` (check/request/open settings for
    notifications, exact alarms, location, **calendar read access**, **contacts read
    access**) with pure decision helpers; `PlatformPermissionService` over
    flutter_local_notifications + permission_handler.
  - `contacts_service.dart` (F7.3) — `ContactsPlatform`, the read-only seam over
    `flutter_contacts`, and `ContactBirthday` (name + month/day + optional year, nothing
    else). See **Contacts import (F7.3)**.
  - `device_calendar_service.dart` — `DeviceCalendarPlatform`, the testable seam over
    `device_calendar_plus` (F8.1), with `DeviceCalendarInfo` / `DeviceCalendarEvent` /
    `DeviceCalendarReadException`. **Read-only: no write method exists.**
    `calendar_settings_store.dart` — `CalendarSettingsStore` (opt-in + visible calendars in
    SharedPreferences). See **Device calendar (F8.1)**.
  - `places_nearby_service.dart` — Google Places Nearby over HTTP.
  - `reminder_home_widget_sync.dart` — writes the widget payload and refreshes the
    platform's widgets (`syncRemindersToHomeWidget`; Android `ReminderHomeWidget`, iOS
    `kIosWidgetKinds`, App Group `kHomeWidgetAppGroupId`); `HomeWidgetPlatform` is the
    testable seam over `home_widget`, `PlatformHomeWidgetSync` implements `HomeWidgetSync`.
    See **Home screen widgets — shared contract**.
  - `ios_widget_completions.dart` — the iOS widget's "complete" queue
    (`widget_completions_v1`): `parseWidgetCompletions` (pure, tolerant) and
    `applyPendingWidgetCompletions`; `applyPendingIosWidgetCompletions` builds the real
    services for `main()` and `AppStateReloader`. See **iOS widgets (F5.2)**.
  - `widget_launch_router.dart` — `WidgetLaunchTarget` / `WidgetLaunchRouter`: widget taps
    that open the app (F5.1) and app icon shortcuts (F5.3, `openTarget`).
  - `app_shortcuts.dart` — `AppShortcut`, `ShortcutRouter`, `QuickActionsPlatform`: app
    icon shortcuts (F5.3). See **App icon shortcuts (F5.3)**.
- `home/widget_payload.dart` — `WidgetPayload.build`, the widgets' data contract (F5.1).
- `home/reminder_home_widget_callback.dart` — background entry point
  (`@pragma('vm:entry-point')`) for widget interactions (toggle a reminder while the
  app is closed). Runs in a separate isolate, so the thin entry point builds the real
  services itself and delegates to `handleReminderHomeWidgetToggle` (injected
  repository + `ScheduleSync`, tested in `test/home/`).
  After a saved change it calls `notifyAppOfWidgetChange()`
  (`home/widget_change_signal.dart`, `IsolateNameServer` port) so a running app
  reloads. See **App state reload** below.
- `config/maps_config.dart` — reads `GOOGLE_MAPS_KEY` from `--dart-define`.
- `config/app_links.dart` (F6.2b) — `AppLinks`: every external URL (privacy policy,
  OSM copyright) in one place; the policy URL points to the GitHub file until the
  hosted page exists (TODO). Widgets open links through an injected `LinkOpener`
  (default `openExternalLink`, `url_launcher` `launchUrl` only — no `canLaunchUrl`,
  so no `<queries>`/`LSApplicationQueriesSchemes`); tests pass a recording fake
  (`SettingsPage(linkOpener:)`, `LocationPickerPage(linkOpener:)`).
- `config/app_licenses.dart` (F6.2b) — `registerAppLicenses()` (called once in
  `main()`) adds licences Flutter doesn't collect from packages to `LicenseRegistry`:
  the Google Sans Flex OFL from the `fonts/GoogleSansFlex/OFL.txt` asset and the
  `liquid_glass_renderer` / `motor` notices vendored in `liquid_glass_widgets`
  (`assets/licenses/*.txt`, verbatim from its `THIRD_PARTY_NOTICES`; refresh them when
  the package is upgraded). Bundled third-party assets (fonts, data) and vendored code
  whose notice is not in a package `LICENSE` need an entry here; Settings › Diğer › Lisanslar
  shows them via `showLicensePage`. The map must keep the visible, tappable
  "© OpenStreetMap contributors" attribution (OSMF tile policy).
- `ui/` — screens and widgets (Kor look, see **UI structure** below):
  - `home/` — `HomeShell` (Bugün / Takvim / Listeler, `PopScope` back to Bugün,
    minute tick), `kor_navigation.dart` (Android `KorPillNavigation`, `NewItemFab`)
    and `kor_glass_tab_bar.dart` (iOS `KorGlassTabBar`, F5.4). `capture/` —
    quick capture (F4.6b): `quick_capture_sheet.dart` (`showQuickCaptureSheet`),
    `capture_text.dart` (`CaptureText`, `CaptureTextController`), `capture_bar.dart`
    (iOS `CaptureBar`). `categories/` (F4.3) — `category_editor_sheet.dart`
    (`showCategoryEditorSheet`, `CategoryEditorSheet`, `ColorSwatchButton`,
    `CategoryPreview`) and `category_list_section.dart` (Listeler › Kategorilerim,
    `CategoryListSection`).
  - `calendar/` also holds F8.1: `device_calendar_scope.dart`
    (`DeviceCalendarController` + `DeviceCalendarScope`), `calendar_event_card.dart`
    (`CalendarEventCard`) and `calendar_event_actions.dart` (open / read-only sheet /
    reminder draft); `ui/settings/calendar_group.dart` is the Ayarlar group.
  - `today/` — `TodayPage` + `TodaySections` (overdue / today / untimed / completed
    grouping and `timeline(now:)`, pure), `time_ribbon.dart` (`TimeRibbonRow`,
    `NowLine`), `overdue_actions.dart` ("Hepsini yarına al"). `calendar/` —
    `CalendarPage`, `buildAgenda` / `calendarDayMarkers` (pure, `agenda.dart`),
    `week_strip.dart` (`WeekStrip`, `MonthGrid`, `CalendarDayCell`),
    `agenda_rows.dart`, `reschedule.dart` (see **Takvim** below). `lists/` —
    `ListsPage` (smart-list bento + categories), `SmartList` (pure membership),
    `SmartListPage`, `ReminderFilterPage`. `search/` — `SearchPage`,
    `ReminderSearch` (pure ranking/grouping), `RecentSearchStore`.
  - `reminders/` — `ReminderEditorSheet`, `CategoryVisuals` (the only category id →
    `KorColorKey`/icon/label mapping; `CategoryIcons`, `CategoryColorNames`), `reminder_actions.dart` (complete / snooze / delete
    handlers with undo, long-press menu), `reminder_swipe.dart`, `snooze_sheet.dart`
    + `snooze_options.dart` (pure snooze times), `undo_snack_bar.dart` (F3.5). `birthdays/` — editor sheet, `BirthdaysPage`,
    `contact_import_sheet.dart` (F7.3 "Rehberden aktar"). `settings/` (with
    `PermissionsGroup`), `maps/`.
  - `routines/` (F3.7) — `RoutineListSection` (Listeler › Rutinlerim),
    `routine_editor_sheet.dart`, `routine_step_sheet.dart`,
    `routine_apply_sheet.dart`, `RoutineVisuals`. See **Routines (F3.7)**.
  - `permissions/` — `PermissionScope`/`PermissionController`, `PermissionSheet`,
    `PermissionBanner`, `PermissionFlows` (see **Permissions** below).
  - `onboarding/` — `OnboardingGate` (`app.dart` `home:`), `OnboardingFlow` + `steps/`,
    `OnboardingStore` (see **Onboarding** under UI structure).
  - `components/` — `ReminderCard`, `BirthdayCard`, `BirthdayRow`, `SectionHeader`,
    `StrikeThroughTitle` (§3.5: a completed title's line is drawn from the start edge
    over `KorMotion.effectsDefault`; Reduce Motion paints the final state at once —
    used by `ReminderCard` and `ReminderCompactCard`),
    `GroupedCard`, `EmptyState`, `TabHeader` (gear → Ayarlar), `KorGlassSurface` (iOS
    glass / solid fallback). `common/` — `KorFormat` (Turkish
    date/time, locale-aware upper case), `NowScope` (injectable clock).
  - `theme/` — Kor tokens (below); `theme/adaptive/platform_chrome.dart` is the single
    Android/iOS chrome decision; `theme/adaptive/a11y_prefs.dart` (`A11yPrefs`: iOS
    Reduce Transparency / Increase Contrast / Low Power over a MethodChannel). `widgets/` — `ConfirmationDialog`.
- `util/` — dialogs, `local_timezone.dart`
  (`configureLocalTimezone`: device zone via `flutter_timezone`, `Etc/UTC` fallback;
  used by `main()` and the home widget callback).

## Tests (`test/`)

Tests mirror `lib/`:

- `test/domain/` — pure model tests (JSON, date logic, ids, labels).
- `test/data/` — `ReminderRepository` on an in-memory database
  (`openTestDatabase()` from `test/helpers/test_database.dart`, `NativeDatabase.memory()`)
  plus `SharedPreferences.setMockInitialValues` for the legacy keys: round trips, soft
  delete / `updated_at`, `clearAll`, migration (valid, corrupt + backup, idempotent,
  failure fallback). No extra setup: `sqlite3` 3.x ships SQLite via build hooks, so
  `flutter test` works on Windows and the Ubuntu CI runner. `test/data/db/` holds
  the schema migration tests (`SchemaVerifier` from
  `package:drift_dev/api/migrations_native.dart`) over generated helpers in
  `test/data/db/generated/` (see **Data** → Schema changes); every new schema version
  needs a `vN-1 → vN` test that also checks existing rows survive.
- `test/bloc/` — `ReminderCubit` with `bloc_test` + `mocktail` mocks.
- `test/services/` — geofence rules, `GeofenceService` sync against a fake
  `GeofencePlatform` (no platform channels), background entry handling;
  `NotificationService` against `FakeNotificationsPlugin`
  (`test/helpers/fake_notifications_plugin.dart`, via `NotificationService.forTesting`;
  records cancelled/scheduled ids and shown notifications, needs mock
  `SharedPreferences` for fingerprints); `ScheduleSync` ordering and coalescing. Platform seams get a fake
  instead of a mock: `FakeDeviceCalendarPlatform` (F8.1) and `FakeContactsPlatform`
  (F7.3), both in `test/services/`.
- `test/home/` — widget callback core with a real repository (in-memory database) and
  the fake notifications plugin.
- `test/ui/theme/` — Kor token contrast (WCAG), theme/extension and font asset tests.
- `test/ui/` — widget tests on `UiHarness` (`test/ui/ui_harness.dart`: a real
  `ReminderCubit` over the mocks, loaded with given reminders/birthdays, wrapped like
  `App`). Pass a fixed clock (`HomeShell(clock: ...)`) for date-dependent screens, run
  light and dark via `korThemes`, and select iOS chrome with
  `platform: TargetPlatform.iOS` (iOS shell tests: `iosTestWidgets` from
  `test/ui/home/ios_platform.dart`, `HomeShell(enableGlassScope: false, a11yPrefs:
  A11yPrefs(...))`). Pure groupings (`TodaySections`, `buildAgenda`,
  `KorFormat`) have plain unit tests.
- `test/helpers/` — `buildReminder(...)` / `buildBirthday(...)` factories and mocks;
  use them instead of constructing models by hand.

Conventions:

- **Known bugs** are documented as tests asserting the *correct* behaviour, marked
  `skip: 'Known bug — fixed in F1.x'` with the roadmap item that fixes them. The PR
  fixing the bug removes the `skip` (and updates any `current behaviour: ...` test that
  locks in the buggy behaviour).
- Never call platform singletons (`GeofenceService.instance`,
  `syncRemindersToHomeWidget`, plugins) from `ReminderCubit`; inject them. Cubit tests
  use `MockNotificationService`, `MockGeofenceSync` and `MockHomeWidgetSync` from
  `test/helpers/mocks.dart` (plus the `stub...` helpers) and verify sync calls.

### Dependency injection

`ReminderCubit(repository, notifications, geofence: ..., homeWidget: ...)` receives
all side-effecting services through its constructor. `app.dart` wires the real ones
(`ReminderRepository()`, `NotificationService.instance`, `GeofenceService.instance`,
`const PlatformHomeWidgetSync()`). New services the cubit needs should follow the same
pattern: a small interface in `services/`, the real implementation `implements` it,
wired in `app.dart`, mocked in `test/helpers/mocks.dart`.

### Schedule sync

Every "bring schedules in line with stored state" goes through
`ScheduleSync.syncAll(reminders:, birthdays:, settings:)` — from `ReminderCubit.load`,
`ReminderCubit._persistAndSync` and the home widget callback. Never call the
notification/geofence/widget services one by one for a full sync; a caller that
forgot birthdays once deleted all birthday notifications (F1.2).

`NotificationService.syncSchedules` handles reminders **and** birthdays together
(there is no reminder-only sync), so the notification layer cannot drop birthdays.
Background isolates must load birthdays and settings from the repository before
syncing.

The sync is **diff-based** (F1.7):

- Desired set = id → spec (title, body, time + zone, repeat components, channel,
  payload) for future, not-done timed reminders and every birthday offset; empty
  when notifications are disabled.
- Every id in `pendingNotificationRequests()` that is not desired is cancelled with
  `cancel(id:)` — removed items and unknown/old-scheme ids included. Geo ids
  (`geo:<id>`) of the given reminders are never cancelled (they are shown, not
  scheduled). **Never use `cancelAll` in the sync path**: it would also dismiss
  shown notifications (e.g. a geofence entry). `cancelAll` is only for
  `clearAllData`, and it also clears the fingerprints.
- A desired entry is scheduled only when it is not pending or its fingerprint
  changed. Fingerprints live in SharedPreferences under
  `notification_schedule_fingerprints_v1` (`NotificationFingerprintStore`, reloaded
  before reading); they are written after scheduling. Missing/corrupt store → all
  desired entries are rescheduled. Changing how notifications are built (channel
  settings, actions, …) → bump `_ScheduleSpec._version` (currently 7; v6 = F6.1
  language, v7 = F6.4 iOS subtask subtitle).
- **Schedule mode (F6.2c):** chosen **once per sync** from `canScheduleExactNotifications()`
  (injectable via `NotificationService.forTesting(canScheduleExact:)`): permitted (or not
  Android 12+) → `exactAllowWhileIdle`, otherwise `inexactAllowWhileIdle` (may be a few
  minutes late, needs no permission). The mode is part of the fingerprint, so granting or
  revoking the permission reschedules everything on the next sync (resume reload,
  Settings return). A `PlatformException` from exact scheduling
  (`exact_alarms_not_permitted`) never aborts the sync: that notification and the rest
  of the sync fall back to inexact and store inexact fingerprints. Never hard-code the
  mode. `FakeNotificationsPlugin.exactAlarmsPermitted = false` simulates the rejection.
- **Recurring reminders (F3.1):** only the **next** occurrence is scheduled per
  reminder (`NotificationService.reminderFireTime`: a future `remindAt`, or for an
  overdue recurring reminder the rule's next occurrence after now, so it keeps
  notifying). Simple rules also repeat without the app through
  `matchDateTimeComponents` (`reminderRepeatComponents`): every day → `time`, every
  week on one day → `dayOfWeekAndTime`, every month on day 1–28 →
  `dayOfMonthAndTime`, every year → `dateAndTime` (what birthdays use). Intervals > 1,
  several weekdays, days 29–31 (month-end clamp), **a yearly rule on 29 February**
  (the native repeat would only fire in leap years, ours fires on 28 February in
  between) and rules with an end date are next-only: the OS cannot express them, the
  diff sync sets the following occurrence on the next load/change. A yearly rule that
  takes its month/day from the anchor needs it: pass
  `reminderRepeatComponents(rule, anchor: r.remindAt)`, and without a resolvable
  target the answer is next-only. **A completion-anchored rule (F3.1c) can never use a
  native repeat:** a `DateTimeComponents` is a fixed calendar pattern, and here the next
  date is unknown until the reminder is completed — so `reminderRepeatComponents` returns
  `null` and the ordinary "reschedule after completion" path (completion advances
  `remindAt`, the diff sync sets the new date) does the work. An overdue one is not
  rescheduled at all (`reminderFireTime` → `null`): it waits in Kaçanlar, like a one-off.
  The rule (JSON) is part of the fingerprint, so
  adding a frequency does **not** need a `_ScheduleSpec._version` bump: no existing
  reminder can carry the new rule, so no stored spec changes. The same test decided
  F3.1c: the anchor mode is an extra JSON field written only in the new mode, a calendar
  rule's `toJson()` is unchanged and `matchDateTimeComponents` is unchanged, and no
  **stored** rule can carry the new mode — so no stored spec's content can change and the
  version stayed **7**. Apply that test (can the spec content change for an *already
  stored* reminder?) to every change here, and record the conclusion either way.
- **Subtasks (F3.3):** with open subtasks the body is "`<note or place>` · N madde
  kaldı" (`reminderNotificationBody`; just "N madde kaldı" without a note) and
  Android uses `BigTextStyleInformation` listing up to 5 open items + "… ve N madde
  daha" (`reminderSubtaskBigText`); that text is in the fingerprint (`subtasks`), so
  ticking an item reschedules. iOS gets the same items on one line in
  `DarwinNotificationDetails.subtitle` (`reminderSubtaskSubtitle`, "Süt · Ekmek · …",
  its own fingerprint field; F6.4) — **not** appended to the body, which is shared with
  Android. Geofence notifications use the same helpers.

`ScheduleSync.syncAll` runs one sync at a time per instance; calls arriving while
one runs are coalesced (only the latest snapshot runs, all queued callers complete
with it). The widget callback isolate has its own instance, so cross-isolate races
are not serialised — the next diff sync repairs the state.

### App state reload (F1.3)

The home widget writes storage from a background isolate, so the in-memory
`ReminderCubit` state can be stale and the next in-app save would revert the change.
`AppStateReloader` (`ui/home/app_lifecycle_reloader.dart`, wraps the app in `app.dart`)
refreshes the main isolate's `SharedPreferences` cache (`reload()` — the repository
reads the per-isolate cache) and calls `ReminderCubit.load()`:

- on `resumed` after the app was `hidden` (not on plain `inactive` → `resumed`, e.g.
  notification shade or permission dialogs), ignored within 1 s of the last load; the
  startup load counts, so launch does not load twice;
- when the widget callback's port signal arrives (process alive: foreground,
  split screen or background); signals are not throttled, concurrent ones coalesce.

Reload only replaces cubit state; editor sheets keep their own controllers. Limits: a
reload racing an in-flight in-app save can briefly show the pre-save state (storage
stays correct); background isolates in another process would not reach the port.
Background writers other than the widget should also call `notifyAppOfWidgetChange`
or an equivalent signal.

### Data

Storage is **Drift (SQLite)**, file `reminder.sqlite` in the application support
directory (`drift` ^2.35, `drift_flutter` ^0.3.1, `sqlite3` ^3.6 — SQLite is bundled by
the sqlite3 build hooks, no `sqlite3_flutter_libs`). The `ReminderRepository` API is
unchanged; the cubit, callbacks and UI don't know about the database.

- **Schema v7** (`lib/data/db/app_database.dart`, exported to
  `drift_schemas/drift_schema_v1.json` … `drift_schema_v7.json`): `reminders` and
  `birthdays` (every model field as a column + `position`, `updated_at`, `deleted_at`),
  `settings` (single row, `id = 1`), `app_meta` (key/value, e.g. the migration marker).
  v2 (F3.1) adds `reminders.recurrence`: nullable TEXT with `RecurrenceRule.toJson()`
  (`NULL` = no recurrence; unreadable text loads as none, the row is kept); the
  `onUpgrade` step `from < 2` adds the column. v3 (F3.3) adds the `subtasks` table
  (`reminder_id` → `reminders.id`, `id`, `title`, `is_done`, `position`,
  `updated_at`, `deleted_at`; primary key `(reminder_id, id)`), created by the
  `from < 3` step. `saveReminders` writes subtasks in the **same transaction** with
  the same diff rule (unchanged rows untouched, missing ones soft-deleted — also all
  subtasks of a deleted reminder; re-saving, e.g. undo, restores them);
  `loadReminders` reads both tables in one transaction; `clearAll` deletes subtasks
  first. v4 (F3.4) adds `reminders.priority` (INTEGER, default 0) and
  `reminders.pinned` (BOOLEAN, default false) in the `from < 4` step; existing rows
  get the defaults. v5 (F4.3) adds the `categories` table (`id`, `name`, `color_key`,
  `icon_key`, `position`, `updated_at`, `deleted_at`); the `from < 5` step creates it
  and runs `AppDatabase.migrateCustomCategoryLabels` (raw SQL, so later schema changes
  don't break it): non-deleted `other` reminders with a `custom_category_label` get a
  user category per `CategoryLabelMigration` and their `category_id` (+ `updated_at`)
  repointed; `custom_category_label` itself is left as is (rollback safety, no longer
  read by the UI). `loadCategories`/`saveCategories` follow the list rule below (the
  cubit saves the whole catalog, built-ins included, so their order persists; a
  deleted user category is soft-deleted); `clearAll` deletes categories;
  `PrefsMigration` converts legacy labels the same way. The SharedPreferences fallback
  session has no categories (built-ins only). v6 (F6.4) replaces `birthdays.date`
  (TEXT) with `birth_month` / `birth_day` (INTEGER) + **nullable** `birth_year`: the
  `from < 6` step (`AppDatabase.migrateBirthdayYear`, a `TableMigration` that rebuilds
  the table) splits the ISO text with `strftime` and turns the sentinel year 4 into
  `NULL`; an unparseable `date` leaves month/day 0 and `birthdayFromRow` throws, so the
  repository skips that row as before. **SQLite foreign keys are enforced** since F6.4:
  `PRAGMA foreign_keys = ON` in the `beforeOpen` hook (after the migration steps, so
  table-rebuild migrations still run unconstrained). `subtasks.reminder_id` therefore
  cannot point at a missing reminder and a reminder row with subtasks cannot be
  **hard**-deleted (default `NO ACTION` = restrict) — repository deletes are soft and
  `clearAll` removes subtasks first, so nothing else changed
  (`test/data/db/foreign_keys_test.dart`). v7 (F3.7) adds the `routines` and
  `routine_items` tables plus the nullable `reminders.routine_id` /
  `routine_item_id` link (see **Routines (F3.7)**): `routine_items.routine_id`
  **is** a foreign key (the `subtasks` pattern), the reminder link deliberately is
  **not**. **Model times**
  (`created_at`, `remind_at`) are TEXT in exactly the old JSON format,
  `DateTime.toIso8601String()`: local values have no offset, so they are **wall-clock**
  ("18:30" stays 18:30 after a time zone change) and `DateTime.parse` returns the same
  fields and `isUtc` as the old `fromJson`. Don't convert them to UTC/epoch — that
  changes behaviour. Only repository bookkeeping (`updated_at`, `deleted_at`) is UTC
  epoch microseconds (INTEGER). Offsets are JSON text (`[0,1440]`).
- **Sync-ready columns** are managed only in the repository, never in domain models:
  `saveX(list)` runs in one transaction, upserts rows whose content or position changed
  (`updated_at` = now; unchanged rows are not touched), and soft-deletes rows missing
  from the list (`deleted_at` = `updated_at` = now). Re-saving a soft-deleted id restores
  it. Loads filter `deleted_at IS NULL` and order by `position`. Write rows with
  `row.toCompanion(false)` — a data class passed to `insertOnConflictUpdate` drops null
  columns, so cleared fields would keep their old value.
- **`clearAll`** hard-deletes all rows of `reminders`/`birthdays`/`settings` and removes
  the legacy SharedPreferences keys and `<key>_backup` recovery keys. `app_meta` is kept,
  so cleared data never comes back from the legacy keys.
- **One-time migration** (`PrefsMigration`) runs on the first repository call when
  `app_meta` has no `prefs_migration_v1` marker: `LegacyPrefsStore` reads `reminders_v1`,
  `birthdays_v1`, `app_settings_v1` with the F1.4 tolerant parsing (corrupt items are
  skipped, the untouched raw string goes to `<key>_backup`; one backup per key, latest
  problematic payload wins, `hasRecoveryBackup()` reports it), then rows and marker are
  written in **one transaction** with `INSERT OR IGNORE` (idempotent, never overwrites).
  The legacy keys are **not deleted** — safety net for one release; remove them (and
  `LegacyPrefsStore`'s write path) in a later release.
- **Fallback:** if opening the database or the migration fails, that repository instance
  works on `LegacyPrefsStore` for the session (old data visible, writes go to the legacy
  keys) and, with no marker written, the migration is retried on the next launch.
- **Isolates / engines:** the app, `geofenceEntryCallback` and
  `reminderHomeWidgetCallback` run in **separate Flutter engines**. drift's
  `shareAcrossIsolates` only finds databases inside one engine, so each engine opens its
  own connection to the same file — drift's documented option for independent
  isolates — with `PRAGMA journal_mode = WAL` and `busy_timeout = 5000`
  (`AppDatabase.configureConnection`). `ReminderRepository()` takes the isolate's shared,
  reference-counted database from `AppDatabaseHost` lazily; background entry points call
  `repository.close()` in `finally`; the app's repository stays open. Stream queries
  don't cross engines (the app doesn't use them; the cubit reloads).
- **Backup (F2.2)** — `lib/data/backup/`: `BackupFormat` is a versioned JSON document
  (`format: "hatirlatici-backup"`, `version: 2`, `exportedAt` UTC, `app.version`,
  `reminders`/`birthdays`/`categories` as the models' `toJson`, `settings`). Version 2
  (F4.3) added `categories` (the full catalog in order); version 1 files still import:
  their "Diğer + özel ad" labels become categories through `CategoryLabelMigration`
  in `decode` (a stray `categories` key in a v1 file is ignored). Merge mode merges
  categories by id (local order kept) and maps a new backup category whose folded
  name matches a local one onto it (`BackupService.mergeCategories`); replace mode
  saves the backup's categories. A birthday's JSON keeps the legacy `date` field (with the sentinel year 4
  when the year is unknown) **and** an explicit `birthYear` (`null` = unknown, wins on
  read), so v6 files still open in older readers and pre-v6 files import with the
  sentinel converted (F6.4, no version bump). `routines` (F3.7) is an additive key
  in the same way, so a file written with routines still imports in an older build
  (which drops them) instead of being rejected; see **Routines (F3.7)**. New model
  fields travel
  automatically (items are `toJson`/`fromJson`); bump `BackupFormat.version` only for
  changes an older reader would misread — a newer file is rejected with "update the
  app". Import is tolerant per item (not an object, `fromJson` fails, empty or repeated
  id → skipped and counted); a non-JSON file, wrong `format`, bad/newer `version` or a
  non-list `reminders`/`birthdays`/`categories` throws `BackupFormatException` and **nothing is
  applied**. `BackupService` exports from and applies to the repository's public API:
  **merge** = upsert by id (backup wins, local-only items kept, settings unchanged),
  **replace** = the backup's lists (others soft-deleted) plus its settings when
  readable; the caller then runs `ReminderCubit.load()` so schedules resync. The three
  `saveX` calls are separate transactions (a failure mid-way can leave earlier lists
  applied; re-importing repairs it). Plugins (`share_plus` share sheet,
  `file_selector` picker, `package_info_plus`) sit behind `BackupIo`; widget tests pass
  a fake via `SettingsPage(backupIo:, backupService:)`.
- **Schema changes:** edit the tables, bump `schemaVersion`, add the step in
  `MigrationStrategy.onUpgrade`, then regenerate and export:

  ```bash
  dart run build_runner build
  dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
  dart run drift_dev schema generate --data-classes --companions \
    drift_schemas/ test/data/db/generated/
  dart format lib test
  ```

  Then add the `vN-1 → vN` case to `test/data/db/migration_test.dart` and bump its
  `latest`: `AppDatabase` always migrates to its current version, so every older
  start version is validated against the latest schema, and migrated files are read
  back through the latest generated classes (older classes cannot reopen a newer
  file). Generated
  `*.g.dart` files and schema helpers are committed (CI doesn't run `build_runner`)
  and formatted. On Windows with a non-ASCII project path, run these in an ASCII-path
  copy and copy `app_database.g.dart`, the schema JSON and `test/data/db/generated/`
  back. Tests use `openTestDatabase()`.

### Notification ids

`Reminder.notificationId`, `Reminder.geoNotificationId` and
`Birthday.notificationIdFor(offset)` come from `lib/domain/notification_ids.dart`
(`NotificationIds`): 32-bit FNV-1a over the UTF-8 bytes of a namespaced key
(`reminder:<id>`, `geo:<id>`, `birthday:<id>:<offsetMinutes>`), masked to 31 bits,
0 mapped to 1. Never use `String.hashCode` for anything persisted or shared between
isolates — it is not stable across Dart versions/runs (F1.5). The ids are a persisted
contract (hard-coded in `test/domain/notification_ids_test.dart`); changing the
algorithm or key format requires clearing old-id notifications. The F1.5 migration
relies on every `syncSchedules` (run on each app load) cancelling all pending ids it
does not recognise; keep that cleanup if the sync changes again.

### Notification actions (F3.2)

- **Payload** (`services/notification_payload.dart`): timed and geofence reminder
  notifications carry `reminder:<id>`, birthdays `birthday:<id>`; `NotificationPayload.parse`
  also accepts a bare id (geofence notifications shown before F3.2).
- **Actions:** reminder and geofence notifications only (birthdays: tap only). Android
  `androidReminderActions` — Tamamla · 10 dk · 1 saat (`showsUserInterface: false`,
  `cancelNotification: true`, needs `ActionBroadcastReceiver` in the manifest). iOS
  category `reminder_actions` (`darwinNotificationCategories`, registered in
  `NotificationService.initialize` with the F1.6 no-prompt flags; details set
  `categoryIdentifier`) — Tamamla · 10 dk ertele · 1 saat ertele · Yarın sabah. Action
  ids (`NotificationActionIds`) are persisted in shown notifications; don't rename them.
  Changing notification details → bump `_ScheduleSpec._version` (v2 = F3.2 actions, v3 = F3.1 recurrence rule in the fingerprint, v4 = F3.3 subtasks body/BigText, v7 = F6.4 iOS subtask subtitle).
- **Handling** (`services/notification_actions.dart`): non-foreground actions always run
  in the plugin's **separate, long-lived engine** (`notificationActionBackgroundHandler`,
  `@pragma('vm:entry-point')`), even while the app is open. It reloads the
  SharedPreferences cache, builds real services, closes its repository in `finally` and
  delegates to `handleNotificationAction(response, repository:, schedules:, now:)`:
  complete → `completeReminder` (done, or the next occurrence for recurring reminders);
  snooze → `remindAt` from `snoozedRemindAt`, which reuses the
  Ertele sheet's `SnoozeOptions.from(now)` (10 dk, 1 saat, Yarın sabah 09:00), also for
  untimed/overdue reminders; then save →
  `ScheduleSync.syncAll` (birthdays + settings from the repository) →
  `notifyAppOfWidgetChange()`. Unknown action, non-reminder payload, missing or done
  reminder → no-op. Keep "Tamamla" in that one function, delegating to the shared
  `completeReminder` (F3.1). `NotificationService.initialize` always passes both handlers, also in
  background isolates.
- **Tap:** `onNotificationResponse` (main isolate) and, for cold starts, `main.dart`
  (`NotificationTapRouter.instance.openFromLaunch(NotificationService.instance.appLaunchDetails)`)
  queue the target in `NotificationTapRouter`. `HomeShell` listens (and checks once
  after its first frame): a reminder payload opens `showReminderEditorSheet` once the
  reminder is in the cubit state (waits up to 5 s for the first load; deleted → nothing),
  a birthday payload selects Listeler and pushes `BirthdaysPage`. `app.dart` is unchanged.

## Routines (F3.7)

Ready-made reminder packs ("sabah rutini" = spor + vitamin + su) applied with one
tap. Nothing here is a parallel domain vocabulary: a routine **step** carries a
title, an optional time of day, a `ReminderCategory` id, a `ReminderPriority`
level and `Subtask`s, and a routine's auto-apply setting is a `RecurrenceRule`.

- `domain/model/routine.dart` — `Routine { id, name, colorKey?, iconKey?, items,
  repeat, createdAt, position }`, `RoutineItem { id, title, time, categoryId,
  priority, subtasks, position }` and `RoutineTime` (hour/minute, stored and
  exported as `HH:MM`; a broken value simply means "no time"). Colour and icon
  keys come from the **category** vocabulary (`KorColorKey.storageKey`,
  `CategoryIconKeys`), never a hex. A step's template subtasks are always open
  and renumbered (`SubtaskList.normalized(...).reset` in the constructor). List
  helpers (`RoutineItemList`, `RoutineList`) follow the `SubtaskList` contract:
  every helper returns an unmodifiable list with `position` = index.
- `domain/routine_apply.dart` — `RoutineApplyPlan`, the **only** apply rule.
  `RoutineApplyPlan.from(routine:, date:, existing:)` is pure and clock-free;
  `plan.build(now:, newId:, newSubtaskId:, mode:)` produces the reminders, so the
  UI can show a preview without generating ids. Per step:
  - **Time:** a timed step gets that time on the chosen day; a **timeless step
    becomes a timeless reminder** (`remindAt == null`), exactly like the editor
    with "Zamanla ve bildir" off — no invented default hour. A timeless reminder
    has no date, so the chosen day only affects timed steps.
  - **Recurrence (automatic application):** a routine's `repeat` rule is copied
    onto the reminders of its **timed** steps; a weekly rule whose days exclude
    the chosen day starts at the first chosen weekday (`firstOnOrAfter`, like the
    editor). Timeless steps never repeat (a reminder without a time schedules no
    notification). **There is no background scheduler and there must not be
    one:** iOS gives no guarantee that a background task runs, so a routine would
    silently not appear some mornings. Completion advances the created series
    through the shared `completeReminder`, like any recurring reminder.
  - **Link:** every created reminder carries `routineId` + `routineItemId`
    (`Reminder`, schema v7). It is a **loose link, not a foreign key** (like a
    category id): a backup restores reminders and routines in separate
    transactions and an old backup may have no routines at all, so a constraint
    would break imports. An unknown routine id only means the link is lost.
- **Duplicate rule** (the same function, documented there): a step counts as
  applied when a reminder **linked** to that routine and step exists — for a
  repeating routine anywhere (the series already exists), otherwise only for that
  day (timed: `remindAt`'s day; timeless: `createdAt`'s day). Without a link, a
  reminder with the same folded title (`TextSearch.fold`) and category on that
  day counts as *similar* (hand-made or pre-F3.7 rows). Completed reminders count
  too, and one reminder is consumed by one step only. Modes:
  `onlyNew` (default, skips), `replaceExisting` (moves the routine's **linked**
  reminders to the new day/rule and refreshes title, category and priority while
  keeping id, note, pin and subtask state — repeating routines only) and `addAll`
  ("Yine de hepsini ekle"). Nothing is ever duplicated silently.
- `ReminderCubit`: `state.routines` (new list object only when routines change),
  `saveRoutine` / `deleteRoutine` / `moveRoutine` / `reorderRoutines` (write only
  `saveRoutines`, never reminders) and `applyRoutine(routine, date:, mode:)`,
  which rebuilds the plan at apply time and goes through the **normal**
  `_persistAndSync` (repository + `ScheduleSync.syncAll`), so notifications,
  widgets and the calendar follow by themselves. Editing a routine never rewrites
  the reminders it already created; deleting one leaves them alone. The **one**
  exception is the explicit bulk action `refreshRoutineReminders(routine)` (see
  **UI** below), with `planRoutineReminderRefresh(routine)` for the preview count;
  it also emits once and goes through `_persistAndSync`, so notifications are
  rescheduled exactly once at the end and the routines themselves are not written.
  `ReminderCubit(newId:)` injects the id factory (tests).
- **Storage (schema v7):** `routines` (`repeat_rule` = `RecurrenceRule.toJson()`
  text or NULL, `created_at` ISO wall clock, `position`, `updated_at`,
  `deleted_at`) and `routine_items` (primary key `(routine_id, id)`,
  `routine_id` → `routines.id` **with** a foreign key, `time_of_day` `HH:MM`,
  `subtasks` JSON text, soft delete) — the `subtasks` table's pattern, written in
  the same transaction as the routine with the same diff rule. `reminders` gains
  the two nullable link columns. The `from < 7` step creates the tables and adds
  the columns; `clearAll` deletes `routine_items` before `routines` (FKs are on).
- **Backup:** `routines` is an **additive** key in format **version 2** (no
  bump), as are the reminder's link fields. An older build therefore still
  imports the file and only loses the routines, instead of rejecting the whole
  file with "update the app" — routines are self-contained, nothing else depends
  on them. `BackupService` merges routines by id (local order kept) or replaces
  them, and `BackupApplyResult.routines` counts them.
- **UI** (`ui/routines/`): Listeler › **Rutinlerim** (`RoutineListSection`, same
  shape as Kategorilerim, above it because a routine is an action, not a filter):
  rows open **Rutini uygula** (`routine_apply_sheet.dart`: day chip defaulting to
  today, step preview, duplicate warning with the two/three choices, snackbar
  count), "Düzenle" is a `ReorderableListView` (handle only; items carry the
  localized "Yukarı taşı / Aşağı taşı" actions), "+ Yeni rutin" opens
  `routine_editor_sheet.dart` (name, 12 swatches, 18 icons, "Otomatik uygula"
  Yok / Her gün / Seçili günler + weekday circles, ordered steps with a ⋮ menu,
  [Sil] · [Kaydet]; nothing is written before "Kaydet"). A step is edited in
  `routine_step_sheet.dart`, which reuses the shared `SubtasksCard`.
  The editor also carries **Hatırlatıcıları güncelle** → [Hatırlatıcılara uygula]
  (`RoutineEditorKeys.refreshReminders`), shown only for a stored routine that
  actually has linked reminders: it saves the edit on screen, then pushes the
  steps' **title, time, category and priority** onto the reminders this routine
  created. It asks for confirmation naming how many will change (and says
  "zaten rutinle aynı" instead of asking when none would), and it never touches
  completion state, notes, pins, subtask progress, location or the recurrence
  rule. The day stays the reminder's own — moving a repeating routine's series
  to another day is the apply sheet's job (`RoutineApplyMode.replaceExisting`).
  Both paths share `reminderWithRoutineItem` in `domain/routine_apply.dart`, the
  single list of "fields a routine owns"; the matching/counting rule for this one
  is the pure `routineReminderRefresh` (link = `routineId` + `routineItemId`,
  day-independent, unchanged reminders excluded so the count is honest, a
  reminder whose step was deleted counted but left alone).
  `RoutineVisuals` is the only routine colour/icon/row-text mapping. The weekday
  circle is `ui/common/weekday_toggle.dart` (`WeekdayToggle`), extracted from the
  recurrence sheet so both look and sound the same.

## Home screen widgets — shared contract

One payload, three implementations. `WidgetPayload.build`
(`lib/home/widget_payload.dart`, pure, tested) is written by
`syncRemindersToHomeWidget` (`lib/services/reminder_home_widget_sync.dart`) as **one JSON
string** under `widget_payload_v2` (`kHomeWidgetPayloadKey`) and read by
`WidgetPayload.kt` (Android, F5.1) and `WidgetPayload.swift` (iOS, F5.2). Both native
sides **recompute every time-dependent field at draw time** from `dueAt` / `date`
(sections, "Gecikti", "Yarın", counts, next, birthday label) because widgets outlive the
last sync. Adding a field is compatible; changing a meaning bumps the version **and** the
key, and all three sides move together. Unreadable data falls back to the empty state.
`lang` (`tr`/`en`, F6.1) makes the native chrome follow the in-app language:
Kotlin through `values/` + `values-en/`, Swift through `tr.lproj`/`en.lproj`
(`WidgetStrings`) — keep the `widget_*` keys in sync across all three.

`HomeWidgetPlatform` is the only seam over `home_widget` + `Platform`; pass a fake
(`test/services/fake_home_widget_platform.dart`) to test platform branches, since
`Platform.isIOS` is always false on the test host.

## Android home screen widgets (F5.1)

Four `AppWidgetProvider`s in `android/app/src/main/kotlin/com/burakaydogmus/reminder/`,
all extending `ReminderWidgetProvider` (reads the payload, draws every instance, arms
the refresh alarm). Dart lists them in `ReminderHomeWidget` (`reminder_home_widget_sync.dart`,
same labels as the widget picker) and refreshes all four after every sync.

| Widget | Provider | Size | Content |
|---|---|---|---|
| Bugün | `ReminderTodayWidgetProvider` | 4×2 | "Bugün · N" + 56×40 pill "+", first two of overdue + today + untimed, 48dp check circles |
| Liste | `ReminderListWidgetProvider` (**pre-F5.1 class name kept** so placed widgets keep working) | 4×4, 3×3–5×6 | scrollable Kaçanlar / Bugün / Doğum günü / Sonra |
| Sıradaki | `ReminderNextWidgetProvider` | 2×2 | "SIRADAKİ", 28sp time, 2-line title, "+N daha", round "+" |
| Hızlı ekle | `ReminderQuickAddWidgetProvider` | 1×1 | "+" only |

- **Data contract:** `WidgetPayload.build` (`lib/home/widget_payload.dart`, pure, tested)
  → JSON under `widget_payload_v2` (`v: 2`, ≤ 60 items with section, labels, `dueAt`,
  category colour key, subtask progress, recurring flag; counts; next; today/tomorrow
  birthdays; `notificationsEnabled`). Kotlin `WidgetPayload.kt` parses it and **recomputes
  every time-dependent field at draw time** from `dueAt` / `date` (sections, "Gecikti",
  "Yarın", counts, next) because widgets outlive the last sync. Adding fields is
  compatible; changing a meaning bumps the version and the key. The pre-F5.1 key
  `reminders_active_json` is deleted on sync.
- **URIs** (`reminderwidget://`): `toggle?id=` → background callback
  (`handleReminderHomeWidgetToggle`, shared `completeReminder`; it also passes birthdays
  and settings to the widget sync); `new`, `open?id=`, `birthday?id=`, `permissions`
  open the app with `HomeWidgetLaunchIntent` (direct activity PendingIntents, no
  trampoline). `WidgetLaunchRouter` (`services/widget_launch_router.dart`, attached in
  `main.dart` on Android) queues the target like `NotificationTapRouter`; `HomeShell`
  takes it (so it waits for onboarding): `new` → quick capture
  (`showQuickCaptureSheet`, F4.6b), `open` → editor after the first load, `birthday` →
  Doğum günleri, `permissions` → Ayarlar.
- **Liste collection:** API 31+ `RemoteViews.RemoteCollectionItems`; API 26–30
  `ReminderListWidgetService` (`RemoteViewsService` + factory), both built by `ListRows`.
  Collection children cannot carry their own PendingIntents, so rows use one mutable
  template (`ReminderWidgetClickReceiver`) + fill-in URIs: `toggle` is forwarded to
  `HomeWidgetBackgroundReceiver`, `open`/`birthday` start the activity (BAL grant from the
  launcher's send; the sender opts in on API 34+). Every other tap is a direct
  activity PendingIntent.
- **Refresh:** `updatePeriodMillis = 0`. After each draw `ReminderWidgetRefreshReceiver`
  arms **one non-waking inexact alarm** (`AlarmManager.RTC`, `set`) at the next `dueAt`
  or midnight, whichever is first; it is delivered when the device wakes, so no battery
  is spent while nobody looks. Reboots/app updates drop alarms, but the system then
  sends `APPWIDGET_UPDATE`, which re-arms it; `TIME_SET` / `TIMEZONE_CHANGED` redraw.
- **Look:** Kor colours in `values/` + `values-night/`; Android 12+ `@android:color/system_*`
  (neutral surface, accent pill) and `system_app_widget_background_radius` in
  `values-v31/` + `values-night-v31/`; category colours stay Kor. On API 31+ text/tint
  colours are set as resources (`RemoteViews.setColor`) so theme switches re-resolve.
  Strings and TalkBack descriptions in `values/strings.xml`.
- Settings › "Widget ekle" (`ui/settings/widget_pin_sheet.dart`) lets the user pick one
  of the four and pins it (`HomeWidgetPinner`, fake in tests); onboarding still pins Liste.
- R8: providers, the list service and the widget receivers are kept by name in
  `proguard-rules.pro`. Kotlin is only compiled by CI (`build-android-release`).

## iOS widgets (F5.2)

`ios/ReminderWidget/` is the `ReminderWidgetExtension` target (WidgetKit + SwiftUI + App
Intents). Owner-side Xcode steps, device test plan and the known limits:
[`docs/ios-widget-setup.md`](docs/ios-widget-setup.md).

| Widget | `kind` | Families | Content |
|---|---|---|---|
| Sıradaki | `ReminderNextWidget` | systemSmall | "SIRADAKİ", monospaced clock, 2-line title, complete circle, "+N daha", "+" |
| Bugün | `ReminderTodayWidget` | systemMedium | "Bugün · N" + wide pill "+", three rows |
| Liste | `ReminderListWidget` | systemLarge | header + weekday/date, Kaçanlar / Bugün (/ Sonra) sections, ≤6 rows, birthday footer |
| Kilit ekranı | `ReminderLockWidget` | accessoryCircular, accessoryRectangular, accessoryInline | open count / next task |

- **App Group `group.com.burakaydogmus.reminder`** is the transport: `kHomeWidgetAppGroupId`
  (Dart) = `ReminderWidgetStore.appGroupId` (Swift) = both `.entitlements` files. `main()`
  calls `HomeWidget.setAppGroupId` on both platforms and `syncRemindersToHomeWidget` sets it
  again on iOS before saving (background isolates never run `main`). The `kind` list is
  `kIosWidgetKinds`; every sync reloads all four
  (`WidgetCenter.reloadTimelines(ofKind:)`). `test/services/reminder_home_widget_sync_test.dart`
  asserts these identifiers against the native files — **no Swift test runs in CI**, so that
  contract test is the guard.
- **Complete from the widget** is `CompleteReminderIntent` (`Button(intent:)`). The widget
  extension has no Flutter engine, so the intent only appends `{id, at}` to
  `widget_completions_v1` in the App Group (an **additive**, iOS-only key; Android never reads
  it) and reloads the timelines; the widget hides queued ids, so the row disappears at once.
  `applyPendingWidgetCompletions` (`lib/services/ios_widget_completions.dart`) applies the
  queue through the shared `completeReminder`, clears it **before** `ScheduleSync.syncAll`
  and is called from `main()` (launch) and `AppStateReloader` (before `cubit.load()`, F1.3
  reasoning). Consequence to keep in mind: until the app runs, notifications of a
  widget-completed reminder are not cancelled. `home_widget`'s iOS interactivity
  (`HomeWidgetBackgroundWorker`) was deliberately not used — it links Flutter into the
  extension.
- **Deep links** use the `reminderwidget://` scheme (`CFBundleURLTypes` in
  `ios/Runner/Info.plist`) and the existing `WidgetLaunchRouter` (`attach` now runs on iOS
  too). `ReminderWidgetStore.launchURL` appends `homeWidget=true`, which `home_widget`'s
  `isWidgetUrl` requires; `WidgetLaunchTarget.parse` ignores the extra parameter. Accessory
  families only support `widgetURL`, system families also use `Link` per row.
- **Look:** `WidgetTheme` holds the same Kor hex values as `res/values{,-night}/colors.xml`
  (no dynamic colour on iOS, per design §3.1). Only the complete circles are
  `widgetAccentable()`, so accented/tinted and vibrant modes stay readable; state is never
  colour-only ("Gecikti" is text). `containerBackground(for: .widget)` everywhere; accessory
  families get a clear background.
- **Deployment target:** the extension is **iOS 17.0** (interactive buttons,
  `AppIntentConfiguration`, `containerBackground`); Runner stays **15.0**. A higher extension
  minimum is allowed; the reverse is not.
- **project.pbxproj is hand-edited** (no Mac here). Object ids of the F5.2 additions start
  with `F52A`. The `ios.yml` step "Verify the widget extension is embedded" asserts
  `Runner.app/PlugIns/ReminderWidgetExtension.appex`, its binary, the tr/en strings and the
  WidgetKit extension point — a green `flutter build ios` alone would not prove the target
  was built. Keep that step when touching the project file.

## App icon shortcuts (F5.3)

- Plugin: `quick_actions` (flutter.dev) — Android launcher shortcuts
  (`ShortcutManagerCompat` dynamic shortcuts, API 25+) and iOS Home Screen quick actions
  (UIScene-aware since `quick_actions_ios` 1.2.4: registers as a scene delegate, so it
  works with `FlutterSceneDelegate` + plugin registration in
  `didInitializeImplicitFlutterEngine`; no `AppDelegate`/`Info.plist` changes).
- `AppShortcut` (`services/app_shortcuts.dart`) is the list, in display order: `new_reminder`
  "Yeni hatırlatıcı" → `NewReminderTarget()` (quick capture), `market_list` "Market
  listesi" → `NewReminderTarget(initialText: '#market ')` (quick capture prefilled via
  `showQuickCaptureSheet(initialText:)`), `today` "Bugün" → `TodayTarget` (pops pushed
  routes/sheets, selects Bugün), `new_birthday` "Yeni doğum günü" → `NewBirthdayTarget`
  (`showBirthdayEditorSheet`). The `type` strings are persisted by the OS (pinned
  shortcuts); never rename them.
- `main.dart` runs `ShortcutRouter(router: WidgetLaunchRouter.instance).attach(const
  PluginQuickActions())` on both platforms: `initialize` (a launching shortcut is
  delivered to the handler, cold start) then `setShortcutItems`; failures are only
  logged. The handler calls `WidgetLaunchRouter.openTarget`, so shortcuts are queued and
  handled by `HomeShell` exactly like widget taps (after onboarding, cold and warm start).
  Tests pass a fake `QuickActionsPlatform` (`test/services/app_shortcuts_test.dart`,
  `test/ui/home/shortcut_routing_test.dart`).
- Icons share one name per shortcut (`AppShortcut.icon`, e.g. `shortcut_today`):
  Android `res/drawable/shortcut_*.xml` (48dp: 44dp `@color/shortcut_background` circle
  + 24dp single-colour Material Icons glyph in `@color/shortcut_foreground`; Kor
  primaryContainer / onPrimaryContainer, night variants in `values-night`), looked up with
  `getIdentifier`, kept from `shrinkResources` by `res/raw/keep.xml` (`@drawable/*`);
  iOS `Assets.xcassets/shortcut_*.imageset` (the same glyph as SVG, template rendering,
  vector preserved) — the plugin only supports `UIApplicationShortcutIcon(templateImageName:)`,
  not SF Symbols. Titles come from the ARB (`AppShortcut.titleIn(l10n)`, F6.1): `attach`
  publishes them in the resolved language, `publish` again after a language change.

## Quick-capture parser (F4.6a Turkish, F4.6c English)

- `lib/domain/parsing/`: pure Dart, no Flutter or model imports besides
  `ReminderCategoryIds` (except the separate F4.6b mapping,
  `capture_to_reminder.dart`). Entry point
  `CaptureParser.parse(input, now:, config:, locale:)` in `capture_parser.dart`
  (`turkish_capture_parser.dart` is a re-export so older imports keep working).
- **`locale` picks the grammar** (`CaptureLocale { turkish, english }`,
  `capture_locale.dart`), defaults to Turkish and is an **explicit parameter** — the
  parser never reads a locale from the platform. The UI passes the resolved **app**
  language (F6.1), through `CaptureLocaleOfL10n.captureLocale` on `AppLocalizations`
  (`ui/capture/capture_text.dart`); `CaptureLocale.forLanguageCode('tr_TR')` is the
  pure equivalent for code without an `l10n`. `CaptureLocale` also carries the
  locale-safe `toLower` / `fold` / `capitalizeFirst`, so no rule calls
  `String.toLowerCase` directly.
- **Layout:** `rules/capture_scanner.dart` holds the shared abstract `_Scanner` with
  the grammar hooks `ruleAt`, `leadingConnector`, `trailingConnector`,
  `listSeparators`, `tidyListItems`; the language rules are `part` files under
  `rules/tr/` (`tr_scanner`, `tr_date_rules`, `tr_time_rules`,
  `tr_recurrence_rules`) and `rules/en/` (the same four). Tags, resolution and the
  list split are shared (`rules/tag_rules.dart`, `resolution.dart`,
  `list_rules.dart`). `turkish_text.dart` / `english_text.dart` do the casing and
  folding — one UTF-16 code unit per code unit, so **string offsets never shift**;
  they differ only in the dotted/dotless `i` (`I`→`ı` in Turkish, `I`→`i` in
  English), and both fold Turkish diacritics so `#saglik` keeps matching "Sağlık".
- **Adding or changing a rule:** work in the `rules/<lang>/` file of that language
  only, keep the result types neutral, and add table rows to
  `test/domain/parsing/cases/<lang>/`. A rule that must apply to both languages
  belongs in the shared file, and then **both** corpora need rows. Never make a rule
  read the language from anywhere but the `locale` it was given.
- Result types (`capture_parse_result.dart`) are **neutral**: `CaptureToken` (kind,
  exact `start`/`end` in the original input, `confidence`), `RecurrenceSpec`
  (daily / weekly / monthly / yearly / everyNDays), `CaptureParseResult` (title, tokens,
  `dateTime` + `hasExplicitTime`, `isPast`, recurrence, `categoryKey`/`categoryId`,
  priority 0–3, `placeKey`, `splitSuggestion`), `CaptureParserConfig` (day-part hours
  for "Ayarlar › sabah saati", category aliases, list categories).
- Rules: high-confidence matches only, first match per slot wins (later ones stay in
  the title), day parts used as nouns (`akşam yemeği`, `bir akşam`) are text,
  `pazar` with a suffix is the market, a time without a date is today if still
  ahead, else tomorrow. Details in each rule file's doc comment.
- English specifics (F4.6c): numeric dates are **month/day** (en_US — `5/3` is
  3 May), with a day/month fallback when the first number cannot be a month
  (`25/12`); ISO `2027-05-03` is always y-m-d; a **dot form is never a date** in
  English (`9.30` is a time). Weekday abbreviations (`mon`, `sat`) only count after
  `on`/`by`/`next`/`this`/`every`. A bare day part before a compound noun is text
  (`morning run`, `night cream`, `evening class`) — the guard applies **only** to a
  bare day part, so `this morning stretch` is a time.
- **Yearly (F3.1b):** Turkish `her yıl`, `her sene`, `yıllık`, `senelik`,
  `N yılda bir`, `N senede bir`; English `every year`, `yearly`, `annually`,
  `every N years`, `every other year` — all `RecurrenceKind.yearly`, and the parser
  never sets a month or day of its own (the rule takes them from the first
  occurrence). Like `weekly`/`monthly`, the **adjective** forms `yıllık`/`senelik`
  and `yearly` stay text in front of a noun (`yıllık rapor hazırla`,
  `yearly budget review`; the noun lists are `_yearlyNouns` and `_repeatNouns`);
  `annually` is only ever an adverb, so it always repeats. Before F3.1b these were
  deliberately unparsed — the corpus rows that asserted that are now positive.
- **Completion-anchored repeats (F3.1c) are deliberately not parsed.** The parser only
  ever produces calendar-anchored rules (`RecurrenceAnchor.schedule`). Natural phrasing
  for the other mode ("yıkadıktan 14 gün sonra" / "14 days after I wash them") is
  ambiguous against the existing date and interval rules, and both corpora are large —
  it belongs in its own roadmap item, not smuggled in. Set the mode in the Tekrar sheet.
- **Category aliases (F4.3):** `category_aliases.dart`
  (`CategoryAliases.of(catalog, locale:)`, `configFor(catalog, base:, locale:)`) builds
  `CaptureParserConfig.categoryAliases` from the current categories: built-ins keep
  the grammar's default aliases + folded name, user categories their folded name; the
  first category wins a folded clash. The capture sheet passes it — with the same
  `locale` it parses with — on every parse. `categoryAliases` is **nullable**: `null`
  means "the built-ins of the locale" (`CaptureParserConfig.aliasesFor`,
  `builtInAliasesOf`), Turkish `defaultCategoryAliases` or English
  `englishCategoryAliases` (the Turkish aliases stay in the English map — the stored
  built-in names are Turkish).
- **No model mapping in the parser.** `capture_to_reminder.dart` (F4.6b) is the only
  place that turns a `CaptureParseResult` into a `Reminder` (see **Quick capture**).
- Tests: `test/domain/parsing/` — table-driven `CaptureCase`s in `cases/tr/` and
  `cases/en/` on a fixed clock (`kNow`, 13 Eylül 2026 14:32; **each** table must keep
  ≥ 200 sentences), run by `turkish_capture_parser_test.dart` /
  `english_capture_parser_test.dart`, plus `*_capture_parser_edge_test.dart` per
  language for other clocks, offsets and config, `turkish_text_test.dart` /
  `english_text_test.dart` for casing, folding and offset stability (and
  `CaptureLocale.forLanguageCode`), and `capture_to_reminder_test.dart` for the
  mapping in both languages. The widget-level locale choice is
  `test/ui/capture/quick_capture_sheet_test.dart` → "the grammar follows the app
  language". English case lists must be `final` (a `DateTime` is not const), so the
  `DateTime`-free entries need their own `const`.

## Quick capture (F4.6b)

- **Mapping** (`domain/parsing/capture_to_reminder.dart`, pure,
  `CaptureToReminder.map(result, now:, id:, newSubtaskId:, acceptSplit:)` →
  `CaptureDraft { reminder, isPast, newCategoryTag, placeLabel }`):
  `RecurrenceSpec` → `RecurrenceRule` (`ruleOf`: daily → `daily()`, everyNDays →
  `daily(interval: n)`, weekly → `weekly(days, interval:)`, monthly →
  `monthly(dayOfMonth:)`, yearly → `yearly(interval:)` with no month/day, so the rule
  follows the reminder's date). Time (`remindAtOf`): none → untimed; explicit time → as
  parsed; a day without a time → that day at `defaultHour` (09:00), but **today
  without a time stays untimed**; a repeat → the rule's first occurrence at or after
  now (untimed repeats at 09:00; the month-end clamp wins over the parser's skipped
  month: `her ayın 31'i` in September → 30 Eylül). Priority 0–3 as is. Category: the
  matched id (user categories too, via `CategoryAliases`), else "Diğer" with
  `newCategoryTag`: the sheet's "Yeni kategori: #tag" chip opens
  `showCategoryEditorSheet(initialName:)` (tag → "Spor salonu") and the capture then
  uses the created category. `@place` → note `Yer: <place>`
  (the model's `locationPlaceLabel` belongs to the geofence; never registers one).
  `acceptSplit` → title `listTitle` ("Market alışverişi") + one open subtask per
  item. `isPast` (one-off only) → warn, never save silently.
- **Sheet** (`ui/capture/quick_capture_sheet.dart`, `showQuickCaptureSheet(context,
  now:, initialText:)`; `initialText` is parsed after the first frame without the token
  haptic, F5.3): opens with `KorMotion.sheetStyleOf` (spatialSlow, fade under Reduce
  Motion). Autofocus field; `CaptureTextController.buildTextSpan` paints token ranges
  (date/time/repeat → `primaryContainer`/`onPrimaryContainer`; category → category
  `container` + `onContainer`; priority → `primary` text with a stroked `background`
  Paint (a span cannot have a border); place → `secondaryContainer`); plain while an
  IME composition is active. `KorHaptics.tokenRecognized()` when a new token appears.
  Chip row: date, Tekrar, category (or the new-tag hint), priority, place, "Maddelere
  böl?"; tapping opens the matching picker (date+time, `showRecurrenceSheet`, list
  sheets) whose value overrides the parsed one; "×" turns the phrases back into text
  through `CaptureText.parse(suppressed:)` (whole-word occurrences masked with a
  same-length private-use run, original text restored in the title). Past one-off
  time → `PastTimeHint` + blocked save. Save (Enter or the 48 px ↑): `addReminder`
  (after `PermissionFlows.beforeScheduling` for timed ones), field cleared, sheet
  stays open, an in-sheet toast "Eklendi: … · Geri al" (3 s, 10 s with a screen
  reader; a snackbar would sit under the sheet) whose undo deletes it. "Tüm
  ayrıntılar" pops the sheet with the draft and opens `showReminderEditorSheet(draft:)`
  — the editor fills from `existing ?? draft`, but only `existing` decides update vs.
  add and the overdue-time allowance.
- **Entry points:** Android `NewItemFab` tap → capture; long-press (`showNewItemMenu`)
  Hızlı ekle / Hatırlatıcı / Doğum günü, the last two also as semantics actions
  (`newItemSemanticsActions`). iOS: no FAB; `CaptureBar` ("Ne hatırlatayım?", glass
  through `KorGlassSurface`, 52 high) is `KorGlassTabBar.accessory`, above the
  capsule inside the fixed-height chrome; collapsing moves it down to 48 between the
  collapsed tab and the search circle. Long-press opens the same menu.

## Localization (F6.1)

- **Rule: no hardcoded user-visible strings.** Every text a user can see or hear
  (labels, snackbars, tooltips, semantics labels/hints, empty states, notification
  titles/bodies/actions/channel names, widget payload labels, shortcut titles) comes from
  `lib/l10n/app_tr.arb` (template) and `lib/l10n/app_en.arb`.
  `test/l10n/arb_parity_test.dart` fails on missing/extra keys, empty values, undeclared
  placeholders and on Turkish string literals in `lib/ui`, `lib/services`, `lib/home`
  (allowlist: grammar tables in `kor_format.dart`, `recurrence_text.dart`,
  `snooze_options.dart`, `capture_text.dart`). The quick-capture parser
  (`lib/domain/parsing/`) has a grammar **per language** (F4.6c) and is not scanned:
  its rule tables are Turkish and English *grammar*, not UI strings, so they need no
  allowlist entry — but a new user-visible string in the capture UI still does.
- **Adding a string:** add the key to `app_tr.arb` (with `@key.description` when the context
  is not obvious, and `placeholders` for arguments; counts use ICU plurals —
  `{count, plural, =1{…} other{…}}`, Turkish usually only `other`), then the same key to
  `app_en.arb`. `flutter pub get` (or `flutter gen-l10n`) regenerates
  `lib/l10n/app_localizations*.dart` (`flutter: generate: true` + `l10n.yaml`, formatted);
  commit the generated files — CI fails when they are stale. `flutter_localizations` is a
  direct dependency only because the generated file imports it; the app's Material/Cupertino
  delegates still come from `material_ui` (`App.localizationsDelegates`).
- **Adding a parser rule for a language:** grammar is **not** localization — it lives
  in `lib/domain/parsing/rules/tr/` or `rules/en/` (see **Quick-capture parser**), is
  chosen by the explicit `CaptureLocale` the UI derives from the app language
  (`AppLocalizations.captureLocale`), and never goes through the ARB. Adding a language
  means a new `CaptureLocale` value, a `rules/<lang>/` set, a `<Lang>Text` helper and a
  ≥ 200-sentence corpus under `test/domain/parsing/cases/<lang>/`. Only the strings
  *around* the parser are localized: `captureParserExamples` (the helper line under the
  capture field, example phrases in the app language), `captureListTitle*` and the
  `@place` note, which the sheet passes in as `CaptureTexts`.
- **Using strings:** `context.l10n.key` (`lib/l10n/l10n.dart`; without `AppLocalizations`
  in the tree — isolated widget tests — it falls back to Turkish). Pure helpers take an
  `AppLocalizations l10n` parameter instead of a context (`KorFormat.when(at, now, l10n)`,
  `RecurrenceText.summary(rule, l10n)`, `PriorityPinVisuals.label(p, l10n)`,
  `SnoozeOption.labelIn(l10n)`, enum `labelIn(l10n)`). Domain models carry no display
  strings. Built-in categories are shown through `CategoryVisuals.nameOf/labelOf/labelIn`
  (translated), user categories keep the typed name; the stored built-in names stay
  Turkish (parser aliases, search also matches the translated name).
- **Dates and times:** `KorFormat` with patterns from the ARB (`dateFormat*` keys, e.g.
  `d MMMM` / `MMMM d`) in the `l10n.intlLocale` (`tr_TR` / `en_US`); times are 24 h in both
  languages; spoken times use `KorFormat.spokenTime` (`saat 16:00` / `at 16:00`); upper case
  via `l10n.upper` (Turkish İ/I rules for `tr`). `main` and background entry points
  initialize both date symbol sets.
- **Language choice:** `lib/l10n/app_language.dart` — `AppLanguage` (Sistem / Türkçe /
  English), persisted by `AppLanguageStore` in SharedPreferences `app_language_v1` (like the
  haptics flag, not in Drift: background isolates read it without the database; no schema
  bump). "Sistem" = Turkish when the first preferred device language is Turkish, English
  otherwise (`AppLocales.resolve`); `MaterialApp.locale` is `null` then, so device changes
  apply. `main` reads the stored choice before `runApp` (`App(initialLanguage:)`);
  `AppLanguageScope` (above `MaterialApp`) serves Ayarlar › Görünüm › Dil; a change reloads
  the cubit (→ resync of notification texts and the widget) and republishes the shortcut
  titles (`ShortcutRouter.publish`).
- **Background texts:** code without a `BuildContext` resolves the same choice through
  `BackgroundLocalizations.load()` (reloads SharedPreferences, reads the system locales via
  `PlatformDispatcher`/`Platform.localeName`, loads date symbols): `NotificationService`
  (per sync and per geofence entry; injectable via `forTesting(localizations:)`, Turkish by
  default), `syncRemindersToHomeWidget`, shortcuts. The language is in the notification
  fingerprint (`_ScheduleSpec._version` 6), so switching reschedules everything once. iOS
  action categories are registered at `initialize` (next launch after a change).
- **Native strings:** Android `res/values/strings.xml` (Turkish) + `res/values-en/strings.xml`
  — keep them in sync. The widget payload carries `lang`; Kotlin draws with
  `WidgetPayload.localized(context, lang)`, so widgets follow the app language even when the
  device language differs (launcher labels and the widget picker follow the device).
  `res/xml/locales_config.xml` (`android:localeConfig`) enables the Android 13+ per-app
  language setting. iOS: `ios/Runner/{tr,en}.lproj/InfoPlist.strings` (location usage
  descriptions; in `project.pbxproj` as a variant group), `CFBundleLocalizations` tr + en.
- **Tests:** `UiHarness.app(language:)` defaults to Turkish, so existing expectations stay
  Turkish; pass `AppLanguage.english` for English. The a11y audit runs every entry in both
  languages (`A11yVariant.language`, `auditLanguages`) — English strings are longer, so
  overflow must hold in both. The a11y capture-sheet entry opens with an `initialText`
  per language, so both audits see filled chips (F4.6c). English smoke tests:
  `test/ui/english_screens_test.dart`.
  Pure tests pass `AppL10n.turkish` / `AppL10n.english`; call `initTestDateFormatting`
  (`test/helpers/l10n_setup.dart`) when they format dates.

## Workflow rules (from ROADMAP.md)

- **Branch name:** `<type>/<short-name>` — `feat/`, `fix/`, `chore/`, `refactor/`,
  `docs/`, `test/`. Use the branch named in the roadmap item.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) —
  `feat(scope): ...`, `fix(scope): ...`, `chore(deps): ...`.
- **One roadmap item per PR.** The PR description includes the item ID (e.g. `F1.2`),
  what changed and test steps (see `.github/pull_request_template.md`).
- **Mark the item `[x]` in `ROADMAP.md` within the same PR.**
- **CI must pass** (analyze + test + Android APK + iOS no-codesign build) before merge.
- **Merge:** PRs are merged via GitHub by the repo owner after CI passes (merge method
  is the owner's choice); the branch is deleted after merge.

## Conflict hotspots

`lib/bloc/reminder_cubit.dart`, `lib/services/notification_service.dart` and the models
in `lib/domain/model/` are touched by many roadmap items. Items that modify them must
land **sequentially**; keep changes there minimal and rebase often.

## Theme tokens

The "Kor" design system (`docs/design/kor-design-proposal.md` §3.1, §5.3) lives in
`lib/ui/theme/` and is wired in `app.dart` (`theme: KorTheme.light()`,
`darkTheme: KorTheme.dark()`, `themeMode` from the stored setting). `KorTheme` also
owns the component themes (app bar, buttons, inputs, chips, segmented button,
dialog, FAB, progress, menus, bottom sheet), so widgets only choose roles.

- `tokens/` — `kor_palette.dart` (raw hex, `KorColorKey` category keys),
  `kor_color_scheme.dart` (all M3 roles by hand), `kor_typography.dart` (Google Sans
  Flex, `FontVariation` wght/opsz/ROND, tabular time styles), `kor_shapes.dart`
  (`KorRadius`, `CookieShapeBorder`), `kor_spacing.dart`, `kor_elevation.dart`.
- `extensions/` — `KorColors` (`context.korColors`: success, glass, now line,
  `category(key)`) and `KorMotion` (`context.korMotion`: 6 springs, Reduce Motion
  resolver). `kor_theme.dart` — `KorTheme` builders; `haptics.dart` — `KorHaptics`,
  `HapticsScope`; `haptics_store.dart` — `HapticsStore` (see **UI structure** → Motion
  and haptics).
- Font: `fonts/GoogleSansFlex/GoogleSansFlex-Latin.ttf` (OFL, subset latin + latin-ext).
- Imports: `package:material_ui/material_ui.dart` / `package:cupertino_ui/cupertino_ui.dart`,
  never `package:flutter/material.dart` or `cupertino.dart` (deprecated in-framework
  libraries; the types are not interchangeable).
- Rules for UI: colours from `Theme.of(context).colorScheme` / `context.korColors`,
  text from `textTheme`, sizes from the token files. **No raw `Color(0x…)`, `Colors.*`
  or hard-coded `fontSize` in widgets** (token files and `KorTheme` are the only
  places with literal values). Categories store a `KorColorKey`, never a hex.
- New colour tokens must pass `test/ui/theme/contrast_test.dart` (text ≥ 4.5, UI ≥ 3.0);
  a failing design value is skipped with its measured ratio, not silently changed.
- A new **non-category** token (the F8.3 `deviceEvent` day dot is the latest) goes in
  `kor_palette.dart` as a documented `static const` in **both** `KorPaletteLight` and
  `KorPaletteDark` under the same name, then through `KorColors` as a plain field
  (constructor, `light`, `dark`, `==`, `hashCode`, `copyWith`, `lerp`) — copy `nowLine`
  end to end. Do **not** add a `KorColorKey` value for it: that enum is the persisted
  *user category* palette and its `storageKey` list is a pinned contract, so a 13th
  value would show up in the category colour picker and break the round-trip test.

## UI structure

- **Shell:** `HomeShell` has three tabs (Bugün / Takvim / Listeler) in an
  `IndexedStack`; Ayarlar is a pushed route from the gear in `TabHeader`. Back on
  Takvim/Listeler selects Bugün (`PopScope`). Android: floating `KorPillNavigation` +
  64 px `NewItemFab` (tap: quick capture; long-press: Hızlı ekle / Hatırlatıcı /
  Doğum günü); iOS: floating glass `KorGlassTabBar` with the `CaptureBar` above it,
  no FAB (below, and **Quick capture**). Decide platform chrome only through `PlatformChrome` (reads
  `Theme.of(context).platform`, so tests override it via the theme).
- **iOS glass chrome (F5.4):** `liquid_glass_widgets` (MIT) is used **only** through
  `KorGlassSurface` and only for iOS floating chrome (tab bar, search circle,
  the F4.6b capture bar); content and cards stay opaque, Android never uses glass.
  `KorGlassTabBar`: 290×62 capsule (Bugün/Takvim/Listeler, icon + label, sliding
  `primaryContainer` indicator on `spatialDefault`, jump under Reduce Motion) + a
  separate 62 "Ara" circle → `openSearch`, over a `surface` edge fade. `HomeShell`
  uses `extendBody`; scrolling down past `KorGlass.scrollSlop` collapses it to the
  selected icon (tap expands), scrolling up / reaching the top / switching tabs
  expands it, VoiceOver (`accessibleNavigation`) keeps it expanded; the outer bar
  height never changes, so the body does not relayout. Solid fallback
  (`surfaceContainerHigh` + 1px `outline`, 2px with `MediaQuery.highContrastOf`)
  when `A11yPrefs` reports Reduce Transparency, Increase Contrast or Low Power, or
  the `GlassAdaptiveScope` drops to `minimal`. The native side is
  `ios/Runner/AppDelegate.swift` (`com.burakaydogmus.reminder/a11y_prefs`: `get`,
  `changed`). Sizes live in `KorGlass` (`kor_elevation.dart`). Tab labels clamp text
  scale at 1.3 (fixed capsule height; full label in semantics). `SearchIconButton`
  hides itself on iOS on the shell's (first) route, so Bugün/Listeler only have the
  glass circle; pushed pages (smart lists) keep it. `main()` pre-warms the shaders with
  `LiquidGlassWidgets.initialize()` on iOS only (started early, awaited before `runApp`).
- **Date logic in the UI layer:** groupings are pure functions of cubit state and a
  clock (`TodaySections.from`, `buildAgenda`); screens read the clock from `NowScope`
  (the shell ticks it every minute; pushed routes use `NowScope.carry`). Do not add
  view groupings to `ReminderCubit`.
- **Components:** reuse `ReminderCard` for any reminder row (48 dp complete toggle as
  its own target, tap → editor, long-press menu, swipe, semantics label + custom
  actions), `BirthdayCard`, `SectionHeader`, `GroupedCard` (fills with a
  `Material`, so `ListTile`/`InkWell` children keep their ink), `EmptyState` (one
  title, one sentence, max one action).
- **Swipe and undo (F3.5):** `ReminderCard` wraps itself in `ReminderSwipe` (plain
  `GestureDetector`, hidden from semantics): start→end Tamamla / Geri aç
  (`success`), end→start past 30 % Ertele (`tertiary`, open reminders only), past
  60 % Sil (`error`); 30 % scales the icon and plays `KorHaptics.swipeThreshold`
  once; release springs back with `spatialDefault` (tween under Reduce Motion).
  Every action lives in `reminders/reminder_actions.dart`
  (`toggleReminderDoneWithUndo`, `snoozeReminderWithUndo`,
  `deleteReminderWithUndo`) and is reachable three ways: swipe, long-press menu
  (Tamamla/Geri aç, Ertele, Sabitle, Düzenle, Sil) and semantics custom actions (WCAG 2.5.7)
  — add new card actions to all three. Actions apply immediately and show
  `UndoSnackBar` (one at a time, a new one replaces the old; 5 s, 10 s with
  `MediaQuery.accessibleNavigationOf` and accessibility focus on "Geri al"; pass
  `persist: false`, a `SnackBar` with an action otherwise never closes). Reminder
  delete has **no confirm dialog**; undo re-adds the same object with
  `addReminder`. Confirm dialogs stay for irreversible bulk actions ("Tüm verileri
  sıfırla"). Snooze times come only from `SnoozeOptions.from(now)` (pure, injected
  clock); the Ertele sheet never accepts a past custom time.
- **Motion and haptics (F4.7):** springs come from `KorMotion` (`context.korMotion`;
  `resolveOf` turns spatial springs into a 150 ms fade under
  `MediaQuery.disableAnimationsOf`, effects springs stay). APIs that only take a
  duration + curve use `KorSpring.settleDuration` / `KorSpring.curve()` (e.g.
  `KorMotion.sheetStyleOf` for `showModalBottomSheet(sheetAnimationStyle: ...)`; the
  reminder editor stays a sheet on both platforms, no container transform). The
  complete toggle of `ReminderCard` / `ReminderCompactCard` is
  `components/kor_checkbox.dart` (`KorCheckbox`): 0 ms `KorHaptics.complete` + press
  1 → 0.85 (spatialFast), 0–240 ms circle → `CookieShapeBorder` morph + fill, 120–300
  ms check path, then a hold; the commit runs at **900 ms** (`KorCheckbox.hold`). A
  second tap during the hold cancels; disposal during the hold still commits.
  `onToggle` is called at tap time and returns the commit, so capture context there —
  `prepareToggleReminderDone(context, reminder, hapticPlayed: true)` does that for
  reminders. Reduce Motion: no press/morph/check/hold, commit at once, 150 ms fade.
  `ring:` draws an outline 2 px outside the shape (F3.4 priority ring). Widget tests
  that tap the checkbox must `pump(KorCheckbox.hold)` before `pumpAndSettle`
  (a `Timer`, not an animation). `CookieShapeBorder` (9 lobes, `depth` 0 = circle,
  lerps from/to `CircleBorder`) is the only expressive shape. Tabs switch through
  `FadeThroughIndexedStack` (effectsSlow fade + 0.96 → 1 scale; fade only under
  Reduce Motion; the pages keep their state). Haptics: always `KorHaptics.of(context)`
  (never `HapticFeedback` directly, never the only feedback): complete medium, swipe
  threshold / token selectionClick, undo and reorder drop light, delete heavy, reorder
  lift medium. The Ayarlar › Görünüm "Titreşim geri bildirimi" switch is
  `HapticsScope` (in `App`'s `MaterialApp.builder`; `UiHarness` uses
  `HapticsStore.memory()`, exposed as `h.haptics`) over `HapticsStore`
  (SharedPreferences `haptics_enabled_v1`, default on; UI-only, not in Drift).
  Test haptics by mocking `SystemChannels.platform` (`HapticFeedback.vibrate`).
- **Bugün, Listeler, Arama (F3.6):** Bugün = Kaçanlar ("Hepsini yarına al": all
  overdue to tomorrow at the same wall-clock time via `updateReminder`, one undo
  that restores all; recurring reminders are skipped in `movableOverdue`, the
  button hides when nothing is movable) → time ribbon
  (`TodaySections.timeline`: chronological, ŞİMDİ marker before the first item due
  after now; 56 px gutter, rail, nodes filled when done, open cards with
  `ReminderTimeStyle.hidden`, completed rows as `ReminderCompactCard`, toggle
  "Tamamlananları gizle"; above text scale 1.3 gutter and rail go away and the
  time is shown in the card) → Bugün bir ara (untimed) → Tamamlananlar (completed
  untimed). `NowLine` moves on the shell's minute tick without animation, glows
  once (1.2 s) on first build unless Reduce Motion. `ReminderCompactCard` keeps
  every `ReminderCard` contract (one semantics node, F3.5 actions, swipe, menu);
  use it where a row needs custom spans. Listeler: bento of `SmartList`
  (Gecikmiş / Bugün / Planlı / Zamansız / Doğum günleri / Konumlu, open reminders
  only). Arama (`TabHeader.actions` → `SearchIconButton`): matching goes through
  `domain/text_search.dart` only (`TextSearch.fold` is 1:1 per code unit, so match
  ranges index the original text; İ/I/ı→i, ş→s, ğ→g, ç→c, ö→o, ü→u, â/î/û); every
  query word must hit title, note, category or place label; rank title word start
  < title < category/place < note; note-only matches go to "Notlarda". Recent
  searches: SharedPreferences `search_recent_v1`, max 8, newest first.
- **Takvim and Doğum günleri (F4.4):** pure date math in `domain/calendar_dates.dart`
  (Monday-first weeks, 6×7 month grid from the Monday on or before the 1st, calendar
  field arithmetic) and `domain/recurrence_expansion.dart` (`reminderOccurrences`: the
  stored `remindAt` plus following `RecurrenceRule` occurrences inside `[from, to)`,
  never before the stored `remindAt`). A **completion-anchored** series (F3.1c) expands
  to **only the current occurrence**, exactly like a one-off: it has no known future
  dates (the next one is "completion + interval" and the completion has not happened),
  so projecting one would be a guess the calendar then shows as fact, and every date
  after the first would move the moment the user completes the reminder. An overdue one
  is therefore not picked up in a later range either. `buildAgenda(from:, filter:,
  includeEmptyDays:)` starts at the selected day (default today, 30 days): not-done
  timed reminders incl. overdue ones of the range, recurring ones at every occurrence
  (`ReminderOccurrence.isStored` false → read-only `AgendaOccurrenceRow`, tap opens the
  series), birthdays as all-day rows (29 Şubat → 28 Şubat in non-leap years, like the
  notifications); filters Tümü / Hatırlatıcılar / Doğum günleri / Konumlu also apply
  to the ≤3 day dots (`calendarDayMarkers`, birthdays first). A dot is a
  `CalendarDayMarker` (`agenda.dart`): either a category colour (`colorKey`) or the
  **neutral** device calendar marker (F8.3, `colorKey == null`) — a device event has no
  category, so it cannot be a `KorColorKey` and uses the `KorColors.deviceEvent` token
  instead; `CategoryDots.colorOf` is the only marker → colour mapping. Device markers
  come **last**, so on a day already at the 3-dot cap the user's own reminders keep
  their dots; they are passed in as `deviceEventDays` (day midnights) only while the
  calendar feature is on, they follow the agenda rows in ignoring the filter chips, and
  the controller has already applied the per-calendar selection when it read those
  events — never filter by calendar again in the marker code. `CalendarPage` reads the
  events for the agenda **and** the marker range in one `eventsInRange` call so paging
  does not thrash the controller's cached window. Selecting a day
  (strip, grid, "Bugün") re-bases the agenda on it. The week strip changes week on a
  horizontal fling (chevrons are the button alternative); it is deliberately not a
  `Scrollable`, so the agenda stays the page's only vertical scroll view (the iOS
  shrink-on-scroll tab bar and its tests rely on that). The grid opens with ▦ or a
  pull on the handle. **Reschedule:** `AgendaReminderRow` wraps `ReminderCard` in a
  `LongPressDraggable` (400 ms, shorter than the card's long-press so the drag wins);
  dropping on a strip/grid day calls `rescheduleReminderWithUndo` (same time on the
  new day via `updateReminder`, one `UndoSnackBar`; a recurring series moves as a
  whole — new anchor + `alignedTo`, undo restores both); drops that would land in the
  past are refused. Long-press + release opens the calendar menu (Taşı… + card
  actions); the row is one semantics node re-exposing the card actions plus "Taşı…"
  (date picker). Doğum günleri: `BirthdayGroups` (pure: hero, month groups,
  subtitles, 29 Şubat note); text on the birthday container uses `onContainer`. The
  birthday editor has a "Yıl bilinmiyor" chip (saved as `Birthday.year == null`;
  the picker keeps a leap year as a placeholder so a year-less 29 Şubat stays).
- **Accessibility (F4.5 criteria, apply to every PR):** 48 dp targets
  (`materialTapTargetSize.padded`), state never by colour alone (e.g. "Gecikti" text +
  icon), localized semantics labels (ARB), times via `KorFormat` (24 h, tabular figures,
  `KorFormat.spokenTime` for screen readers — any semantics label with a time says
  "saat 16:00" / "at 16:00"), `l10n.upper` (or `KorFormat.upperTr` for Turkish-only
  text) instead of `toUpperCase()`, no fixed heights for
  text (use `minHeight`), honour `MediaQuery.disableAnimationsOf`. Text + action rows
  must survive 200 % text: `Expanded`/`Flexible` for the text, or `OverflowBar` so the
  action drops below (`SectionHeader` does this; `ReminderCard.stacksTime` puts the time
  under the title above 1.3). Surfaces floating over lists absorb taps. Rules, their tests
  and the manual TalkBack/VoiceOver checks: [`docs/a11y-checklist.md`](docs/a11y-checklist.md).
- **A11y audit (F4.5):** `test/ui/a11y/` — `a11yAudit(description, pump, platforms:,
  languages:, surface:)` runs one test per light/dark × text scale 1.0/2.0 × platform ×
  language (Türkçe + English, F6.1; pass `variant.language` to `UiHarness.app`) and
  `expectAccessible` checks overflow, `android`/`iOSTapTargetGuideline`,
  `labeledTapTargetGuideline`, `textContrastGuideline` and bare `HH:mm` in semantics.
  Sample data and `pumpAuditShell` / `auditOpener` live in `a11y_sample_data.dart`
  (fixed clock `auditClock`). **Every new screen or sheet gets an `a11yAudit` entry**
  (both platforms when the chrome differs); rules the guidelines cannot see go to
  `semantics_contract_test.dart`. Run `flutter test test/ui/a11y`; add
  `--dart-define=A11Y_SHOTS=true` to write each variant to `build/a11y_shots/` (square
  test font, so overflow checks are pessimistic). Guidelines skip off-screen/edge nodes
  and links, so use a tall `surface` and test link hit areas separately.
- **Editor past times (F1.8b):** never shift a chosen time silently. The "Ne zaman"
  section flags a past date/time (`PastTime` / `PastTimeHint` in
  `reminders/past_time_hint.dart`: error-coloured chips, icon + "Bu saat geçti",
  "Yarın HH:mm mı?" suggestion) and `_save` blocks it inline. Only an existing
  reminder's unchanged overdue time saves (original `remindAt` kept).
  `showReminderEditorSheet(now: ...)` takes the clock (default: `NowScope`).
- **Recurrence UI (F3.1):** the "Ne zaman" card has a Tekrar row that opens
  `reminders/recurrence_sheet.dart` (segments Yok / Günlük / Haftalık / Aylık /
  Yıllık / Özel,
  48 dp weekday circles, "Her [N] …" stepper, Bitiş, "Sonraki 3: …" preview via
  `RecurrenceFormat`). Yıllık (F3.1b) repeats on the **anchor's** month and day — the
  sheet writes no explicit month/day — and its note line says which date that is, or
  explains 28 February for a 29 February anchor
  (`RecurrenceSheetKeys.yearNote`). Below the frequency segments every rule (not "Yok")
  offers **Tekrar ölçütü** (F3.1c, `RecurrenceAnchorMode`,
  `RecurrenceSheetKeys.anchorSegments`): Takvime göre / Tamamlandıktan sonra, with a
  one-line explanation of the difference under it (`anchorNote`). In completion mode the
  weekday circles and the monthly/yearly note lines **go away** (their values are not
  part of such a rule), the stepper reads "Tamamlandıktan N gün sonra"
  (`RecurrenceText.afterCompletion`) and the preview line is replaced by "Sonraki tarih,
  tamamladığında belirlenir." — there is no date series to list. A rule needs a time: without one, choosing a rule schedules
  today + 1 hour (dismissing changes nothing). A weekly rule whose days exclude the
  date moves the date to the first chosen day (visible in the date chip; a
  completion-anchored rule has no such day, and `firstOnOrAfter` returns null, so the
  date is left alone); changing the
  date of a recurring reminder moves the **whole series** (`alignedTo`). "Yalnızca
  bu sefer" (B7) is not built yet. Turning scheduling off clears the rule. The card
  meta line shows a repeat icon + `RecurrenceText.summary`; completing a recurring reminder keeps
  the card and `toggleReminderDoneWithUndo` shows "Sonraki: Cmt 20 Eyl 16:00" in the
  single undo snackbar, whose undo restores the previous `remindAt` (and the
  subtasks the advance reset).
- **Subtasks UI (F3.3):** the editor's "Maddeler" card is
  `reminders/subtasks_card.dart` (`SubtasksCard`, below "Nerede"): "2/6" + 6 px bar in
  the category `fg` (`reminders/subtask_progress.dart`), open rows (48 dp circle
  toggle labelled with the title, inline title field, ⋮ menu Yukarı taşı / Aşağı
  taşı / Sil, drag handle), "+ Madde ekle" (Enter adds and keeps focus; a multi-line
  paste adds one item per line; a "Maddelere böl" button splits commas/" ve "),
  collapsible "Tamamlanan N madde". Reorder = `ReorderableListView` with
  `buildDefaultDragHandles: false` (handle only) — its items already expose the
  localized "Yukarı taşı / Aşağı taşı" semantics actions; the row menu is the
  single-pointer alternative. No swipe delete; "Sil" applies at once and shows the
  `UndoSnackBar` (F3.5 style, delete/undo haptics, reuses `undoDeleted`) whose "Geri
  al" puts the item back at its old position in the list as it is *then*, so edits
  made meanwhile survive (F6.4). Changes are kept in the editor and
  saved with "Kaydet" (empty titles dropped). When all items are done the card
  suggests "Tümü tamam — hatırlatıcıyı tamamla?": it saves, then runs
  `toggleReminderDoneWithUndo`. `ReminderCard` meta shows ☑ icon + "2/6" and a 3 px
  bar; `ReminderCompactCard`'s default subtitle adds "☑ 2/6"; both add
  "maddeler: 2/6 tamamlandı" to the semantics label. Liste detayı checklist mode
  (§3.3.6) is not built yet.
- **Priority and pinning (F3.4):** editor top bar has a 📌 `IconButton` toggle
  (`ReminderEditorKeys.pin`, tooltip "Sabitle" / "Sabitlemeyi kaldır") and the
  Kategori section an "Öncelik" `SegmentedButton<int>` Yok / Düşük / Orta / Yüksek
  (`ReminderEditorKeys.priority`); both saved with "Kaydet". Shared visuals in
  `reminders/priority_pin_visuals.dart` (`PriorityPinVisuals`). `ReminderCard`: pin
  icon before the title, "!!! Yüksek" (marker + text, colour never alone) in the
  meta line, and for open high-priority reminders a 2.5 px `primary` ring
  (`PriorityPinVisuals.checkboxRing`) passed as `KorCheckbox(ring: …)` — never edit
  the checkbox's own border for it. `ReminderCompactCard`: pin icon, the same ring
  and a trailing "!!" marker. Labels add "sabitlendi" and "Yüksek öncelik".
  `togglePinnedWithUndo` is the pin action: long-press menus (card and calendar
  agenda) and semantics custom actions "Sabitle" / "Sabitlemeyi kaldır"; there is
  no pin swipe.
- **Onboarding (F4.2):** `OnboardingGate` shows the 4-step `OnboardingFlow` (§3.3.1)
  once. The flag `onboarding_completed_v1` lives in SharedPreferences through
  `OnboardingStore` (UI-only; never in the repository/database). Users who already
  have reminders or birthdays skip it (flag set), also when that data arrives while
  step 1 is still untouched. "Atla", "Uygulamaya geç" and the step-4 suggestions set
  the flag; suggestions open their editor on top of `HomeShell`. Step 3 asks only
  for notifications (`PermissionFlows.fixNotifications`); exact alarms and location
  stay contextual. The capture demo is scripted (no parsing; F4.6). Illustrations
  are one-shot (`OneShotAnimation`, final frame under Reduce Motion) — never add a
  repeating animation. Each step scrolls, so 200% text never overflows.
- **Categories (F4.3):** `ReminderState.categories` (`CategoryCatalog`) is a new object
  only when categories change (`load` keeps the old one when equal). UI reads it through
  `CategoryVisuals`: `labelOf` / `colorsOf` / `iconFor(context, id)` resolve built-in
  ids without the cubit and other ids with `context.select<ReminderCubit?, …>` — call
  them **only in `build`** (select asserts elsewhere); outside build (callbacks, text
  styles computed while parsing) use `readCatalog` / `readColorsOf`. Without a cubit
  (isolated widgets) only built-ins exist; unknown ids show as "Diğer". Pure code takes
  a catalog (`calendarDayMarkers(categories:)`, `ReminderSearch.run(categories:)`,
  `agendaReminderLabel(categoryLabel:)`). Text on a category `container` uses
  `onContainer`, icons `fg` (light "kor" fails 4.5:1 with `fg` text). Cubit:
  `saveCategory` (append new / update user category in place; built-ins ignored),
  `reorderCategories(ids)`, `moveCategory(from, to)` (`to` = index after removal, like
  `onReorderItem`), `deleteCategory(id)` → its reminders (done ones too) move to "Diğer",
  returns the count. Listeler › Kategorilerim (`CategoryListSection`): rows with open
  counts ("Spor, 3 açık") → `ReminderFilterPage.category` (app-bar "Kategoriyi düzenle"
  for user categories; leaves the page when deleted); "Düzenle" → `ReorderableListView`
  (handle only, its items carry "Yukarı taşı / Aşağı taşı"; lift/drop haptics), a
  pencil/tap opens the editor for user categories; "+ Yeni kategori". Category editor
  sheet (§3.3.6): live preview pill, Ad (max 24, required, unique by folded name incl.
  built-ins), 12 swatches (40 in 48 dp cells, 6 columns; selected = 3 px `onSurface`
  ring + ✓; semantics = colour name + selected flag, e.g. "Lacivert, seçili"), 18 icons
  (48 cells, 6 columns, spoken names), [Sil] (existing only; confirm "Bu kategorideki N
  hatırlatıcı Diğer'e taşınacak.") · [Kaydet]. Reminder editor: chips for every
  category in catalog order + "+ Yeni" (creates and selects); the old "Özel ad" field
  is gone. Search's category filter lists the catalog. Home widget colours:
  `ScheduleSync.syncAll` / `refreshHomeWidget(categories:)` → `HomeWidgetSync.sync(
  categories:)` → `WidgetPayload.build(categories:)` (`null` = built-ins); the cubit
  passes `state.categories` (and refreshes the widget after category edits), the
  widget and notification-action isolates load them from the repository. Mock stubs
  match `categories: any(named: 'categories')` (`test/helpers/mocks.dart`).
- **Copy:** Turkish, second person singular ("Seçtiğin…"), empty-state texts from
  `kor-design-proposal.md` §3.3.11; English copy is second person, plain and short (see
  **Localization**).

## Geofencing

- Plugin: [`native_geofence`](https://pub.dev/packages/native_geofence) `^1.3.1`
  (AGP 9 support).
- **Events never reach the UI isolate.** The OS wakes the app (Android: broadcast →
  WorkManager → headless `FlutterEngine`; iOS: CoreLocation relaunch → headless
  engine) and runs `geofenceEntryCallback` (`@pragma('vm:entry-point')`, top level).
  The callback must be self-contained: no cubit, no singleton state from the main
  isolate; it loads settings/reminders via `ReminderRepository` (own database
  connection, closed at the end — see **Data**), re-initializes
  `NotificationService`, then calls `showGeofenceEntry`. Keep it short (iOS gives
  ~10 s). `GeofenceService.startListening` is a no-op kept for compatibility.
- SharedPreferences is shared between isolates but each isolate caches it:
  `GeofenceStateStore` calls `reload()` before reading.
- Regions: enter-only, no initial trigger, radius clamped 100–500 m. Sync is
  diff-based (`planGeofenceSync`) — unchanged regions are not re-registered.
- Limits: iOS 20 regions, Android 100 geofences. Above the limit the **most recently
  created** eligible reminders are registered (`buildGeofenceTargets`).
- Duplicate suppression: no notification within 30 s of registering a region
  (initial state) or within 10 min of the last notification for that reminder.
- Reboot / update (Android): `NativeGeofenceRebootBroadcastReceiver` re-creates
  regions on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`; `GeofenceService.initialize()`
  also re-creates them on every app start (covers force-stop). iOS keeps regions
  across reboots itself.
- iOS (UIScene lifecycle, `FlutterSceneDelegate` in `Info.plist`): `AppDelegate` sets
  `NativeGeofencePlugin.setPluginRegistrantCallback` at the top of
  `didFinishLaunchingWithOptions`, before any plugin registration (a location relaunch
  may have no scene). Plugins register in `didInitializeImplicitFlutterEngine`, together
  with `FlutterLocalNotificationsPlugin.setPluginRegistrantCallback`. No
  `UIBackgroundModes` needed; events while the app is closed require "Always" location
  permission.
- Do **not** add a foreground service for geofencing (Google Play disallows it from
  28 Oct 2026); `NativeGeofenceBackgroundManager.promoteToForeground` is unused.

## Permissions (F1.6)

- **Never request permissions at startup** (nor in `initState` of a page, nor in
  `NotificationService.initialize` — iOS Darwin init flags stay `false`).
- Ask in context through `PermissionFlows` (`lib/ui/permissions/`):
  `beforeScheduling` on the first save of a timed/location reminder or a birthday
  (notification pre-permission sheet, then the Android exact-alarm sheet);
  `location` when "Nerede" is turned on or the picker opens (2 steps: while in use,
  then "Her zaman" with [Ayarları aç]/[Sonra]); `fix*` for Settings/banner actions.
- Each explanation sheet is shown once (`shouldShowPrompt`/`markPromptShown`); after
  the system prompt was requested once and denied, fixes open system settings instead
  of re-asking. Flags live in SharedPreferences (`permissions.*`).
- Missing permission never blocks saving or the map; it is shown instead: Settings →
  İzinler (live, re-checked on resume by `PermissionController`), Bugün
  `tertiaryContainer` banner, inline warning in the editor's "Nerede" card.
- UI reads `PermissionScope.of(context).snapshot`; widget tests get a
  `FakePermissionService` (`test/helpers/fake_permission_service.dart`) through
  `UiHarness.permissions` (default: all granted).
- iOS: `ios/Podfile` sets `PERMISSION_LOCATION=1` for permission_handler (all its
  permissions are compiled out by default); notification permission goes through
  flutter_local_notifications.
- Calendar (F8.1): `PermissionFlows.calendar` is only ever reached from the Ayarlar
  toggle — nothing else asks for the calendar. `fixCalendar` is the Settings row's action.
  See **Device calendar (F8.1)** for the platform details.
- Contacts (F7.3): `PermissionFlows.contacts` is only ever reached from the Doğum
  günleri › "Rehberden aktar" action — nothing else asks for the address book, and an
  **already denied** permission returns straight away instead of bouncing the user into
  system settings; the sheet explains and offers `fixContacts` as a deliberate choice.
  There is deliberately **no Settings › İzinler row** for contacts: the permission is
  one-shot and backs no ongoing capability, so a permanent "Rehber — izin gerekiyor" line
  would imply a feature that is not there (the calendar row exists only while the calendar
  feature is on, for the same reason). See **Contacts import (F7.3)**.
- Exact alarms (F6.2c): the manifest declares only `SCHEDULE_EXACT_ALARM` —
  **never add `USE_EXACT_ALARM`** (Play restricts it to alarm-clock/calendar apps; see
  `docs/store/permissions-review.md` §3). The permission is optional: without it
  notifications are scheduled inexact (see **Schedule sync**). The exact-alarm sheet and the
  Settings row explain "İzin olmadan hatırlatmalar birkaç dakika gecikebilir"
  (`PermissionFlows.exactAlarmTradeOff`); `PermissionFlows.fixExactAlarms` reloads the cubit
  (→ resync) when the state changed on return from system settings.

## Device calendar (F8.1)

Device calendar events are shown **read-only** next to reminders, opt-in and off by default.

- **Plugin:** [`device_calendar_plus`](https://pub.dev/packages/device_calendar_plus) `^0.9.0`
  (federated: `_android` / `_ios` / `_platform_interface`). `device_calendar`, the usual
  choice, **cannot be used here**: 4.x pins `timezone ^0.9.0` against our `^0.11.1`
  (required by `flutter_local_notifications` 22) and its Android module still does
  `apply plugin: 'kotlin-android'` with `compileSdkVersion 34` and its own AGP 4.1.3
  classpath, which AGP 9 / built-in Kotlin rejects; 3.9.0 resolves but is Dart 2
  (`sdk: <3.0.0`), has no `namespace` and pins AGP 3.4.2 / Kotlin 1.3.41.
  `device_calendar_plus` has **no Dart dependencies of its own** (so nothing to pin),
  `namespace` + built-in Kotlin, `compileSdk 36` / `minSdk 24`, iOS 13 and the iOS 17
  EventKit access API. It is pre-1.0, so the constraint pins the minor (`^0.9.0`) — read
  its CHANGELOG before upgrading. Its Android module ships its own
  `consumerProguardFiles`, so `android/app/proguard-rules.pro` needs no entry.
- **Seam:** `DeviceCalendarPlatform` (`lib/services/device_calendar_service.dart`) is the
  only place that touches the plugin — the same role `HomeWidgetPlatform` plays for
  `home_widget`. It has `calendars()`, `events()` and `openEvent()` and **no write
  method**, so no code path can create or change a device event. Tests pass
  `FakeDeviceCalendarPlatform` (`test/services/fake_device_calendar_platform.dart`); the
  real plugin has no implementation on the test host.
  **Do not use the plugin's own `requestPermissions` / `hasPermissions`:** they require
  `WRITE_CALENDAR` to be declared in the manifest even for a read, while its read
  endpoints gate on `READ_CALENDAR` alone (`PermissionGates.readAccessFailure`).
  `DeviceCalendar.autoPermissions` therefore stays at its default `null` and permission
  goes through `PermissionService.requestCalendar` like every other permission.
- **Permissions:** Android declares **only `READ_CALENDAR`** — never add `WRITE_CALENDAR`
  (it would widen the Play data-safety answer for a feature that writes nothing;
  permission_handler only asks for permissions declared in the manifest, see
  `PermissionUtils.getManifestNames`). iOS needs
  `NSCalendarsFullAccessUsageDescription` (iOS 17+, `requestFullAccessToEvents`) **and**
  the legacy `NSCalendarsUsageDescription` for iOS 15/16 (`requestAccess(to: .event)`);
  `NSCalendarsWriteOnlyAccessUsageDescription` is deliberately absent because EventKit's
  write-only tier **cannot read**. Localized copies live in
  `ios/Runner/{tr,en}.lproj/InfoPlist.strings`, and the Podfile sets
  `PERMISSION_EVENTS=1` + `PERMISSION_EVENTS_FULL_ACCESS=1` (permission_handler compiles
  every permission out by default).
- **State and caching:** `DeviceCalendarController` (`ui/calendar/device_calendar_scope.dart`)
  holds the opt-in, the selection and **one padded window** of occurrences
  (`padBeforeDays` 7, `padAfterDays` 45). `eventsInRange` / `eventsOnDay` answer from that
  cache and are safe to call from `build`: a range outside the window schedules **one**
  read in a microtask (concurrent requests coalesce), so a rebuild — the shell's minute
  tick, a theme change, a scroll — never touches the calendar API. Changing the calendar
  selection invalidates the window. `DeviceCalendarScope` sits above `MaterialApp` in
  `app.dart`, so the tabs and the pushed Ayarlar route share one cache, and it reloads on
  `resumed` (the same foreground trigger `AppStateReloader` uses for stored state).
- **Graceful degradation:** a `permissionDenied` read (or a `refresh` that finds the
  permission gone) persists the opt-in back to **off**, clears the cache and the calendar
  list and notifies — the sections disappear instead of showing an empty header. A
  non-permission failure (`unavailable`: no calendar provider, a plugin error) keeps the
  feature on and shows nothing new. `permissionsNotDeclared` maps to `unavailable`, not to
  a denial: it is a build-configuration bug, not a user decision.
- **UI:** `CalendarEventCard` is a **sibling** of the reminder cards, never a
  reconfigured `ReminderCard`: no `KorCheckbox`, no `ReminderSwipe`, no long-press
  delete, no `LongPressDraggable`. It is a flat card with a 3 px colour rail (in a
  `Stack`, not a stretched `Row` — a stretch cross-axis cannot resolve inside a sliver
  list) and a meta line that always starts with "takvim etkinliği", so the row never
  relies on colour alone; the semantics label adds "yalnızca okunur" and the time goes
  through `KorFormat.spokenTime`. An all-day event shows "Tüm gün", never `00:00`, and the
  time stacks under the title above text scale 1.3 (`ReminderCard.stacksTime`).
  Recurring series arrive already expanded from the platform: one `DeviceCalendarEvent`
  per occurrence sharing `eventId` but with its own `id` (the platform's *unstable*
  instance id — never persist it).
- **Opening an event:** `openCalendarEvent` calls the plugin's `showEventModal` (Android
  `ACTION_VIEW` on the event, i.e. the system calendar app; iOS `EKEventViewController`).
  `url_launcher` is deliberately **not** used: there is no cross-platform event URL and
  probing one would need the `<queries>` / `LSApplicationQueriesSchemes` entries the
  project avoids (see `config/app_links.dart`). When the platform cannot show it, the
  read-only `showCalendarEventSheet` opens instead, so a tap is never a dead end.
- **"Hatırlatıcı oluştur"** is the one write-ish path and writes only to **our** store:
  `calendarEventDraft` (pure) then `showReminderEditorSheet(draft:)`. An all-day event
  drafts 09:00 on its day; a start already in the past drafts an **untimed** reminder,
  because the editor rightly refuses a past time (F1.8b).
- **Day dots (F8.3):** days with device events get a neutral dot in the week strip and
  month grid, through `CalendarDayMarker` and the `KorColors.deviceEvent` token — see
  **Takvim** for the ordering, the cap and the single widened `eventsInRange` call.
- **Not done on purpose:** writing to the device calendar (F8.2).

## Contacts import (F7.3)

Doğum günleri › "Rehberden aktar" imports birthdays from the address book in **one
read-only pass**. There is no background sync and nothing is ever written to contacts.

- **Plugin:** [`flutter_contacts`](https://pub.dev/packages/flutter_contacts) `^2.5.0`
  (quis.co, 160/160 pub points, ~288k downloads/30 days, **no Dart dependencies of its
  own**, so nothing can clash with our `timezone`/`intl` pins). `fast_contacts` was
  rejected on capability, not on health: its `Contact` exposes only phones, e-mails, the
  structured name and the organization — it **cannot read birthdays at all**.
  `flutter_contacts` gives `Contact.events` with a nullable `Event.year`, which is exactly
  what a year-less contact birthday needs. Its Android module declares **no permissions in
  its own manifest** (so the merged manifest stays read-only), has `namespace`, built-in
  Kotlin, `compileSdk 36` / `minSdk 24`, JVM 17; iOS 13 with a `PrivacyInfo.xcprivacy`.
- **Seam:** `ContactsPlatform` (`lib/services/contacts_service.dart`) is the only place
  that touches the plugin — the same role `DeviceCalendarPlatform` plays for
  `device_calendar_plus`. It has **one method**, `birthdays()`, so no code path can create
  or change a contact. Tests pass `FakeContactsPlatform`
  (`test/services/fake_contacts_platform.dart`); the real plugin has no implementation on
  the test host, so the fake is the only way to reach any path.
  **Do not use the plugin's own `FlutterContacts.permissions`:** permission goes through
  `PermissionService.requestContacts` like every other permission here, which is what keeps
  the Android manifest `READ_CONTACTS`-only.
- **What is deliberately not stored:** `getAll` is called with **`ContactProperty.event`
  only**, so phones, e-mails, addresses, organizations, notes and photos are never even
  fetched; id and display name come back unavoidably and the id is dropped at the seam.
  `ContactBirthday` is name + month + day + optional year, nothing else. Never widen it —
  a stored contact id would turn a one-shot import into a link that has to be kept in sync,
  and it would change the Play data-safety and App Store answers.
- **Permissions:** Android declares **only `READ_CONTACTS`** — never add `WRITE_CONTACTS`
  (nothing writes, and permission_handler only asks for declared permissions, see
  `PermissionUtils.getManifestNames`). iOS needs `NSContactsUsageDescription` — contacts has
  a single access tier, so unlike EventKit there is no read-only/full choice to make — with
  localized copies in `ios/Runner/{tr,en}.lproj/InfoPlist.strings`, and the Podfile sets
  `PERMISSION_CONTACTS=1`. iOS 18 *limited* access counts as granted
  (`resolveContactsState`): the OS then hands over the contacts the user picked, which is all
  the import needs. **Play's Contacts Permissions policy (27 Jan 2027) applies to targetSdk
  37+** and will need a Play Console declaration when the target moves off 36 — see
  `docs/store/permissions-review.md` §10.
- **Dedupe rule** (`lib/domain/contact_birthday_import.dart`, pure): the key is
  `TextSearch.foldName(name)` + month + day. `foldName` is the shared name key (trim,
  collapse whitespace, Turkish case/diacritic fold — `İLKAY`, `ilkay` and `Ilkay` match);
  `CategoryNames.fold` now delegates to it. **The year is not part of the key**: the same
  person typed without a year and stored in the address book with one is the same birthday.
  A duplicate row is **shown as "zaten ekli", unselected and disabled** — never silently
  dropped — and "Tümünü seç" cannot pick it up. Duplicates *inside* the address book are
  collapsed too (first spelling wins).
- **Import:** `ContactBirthdayImport.plan` is pure (`newId` is injected) and returns the
  birthdays plus a `ContactImportResult`. Imported birthdays keep the **model defaults** for
  notification time and offsets (09:00, `[0, 1440]`) — the same ones the manual editor starts
  from, not a separate set — and a contact without a year imports as `year: null`, never the
  pre-v6 sentinel. A date the provider cannot mean (month 0/13, 30 February, a future year) is
  dropped at the seam (`PluginContactsPlatform.validBirthday`) rather than imported; an
  implausible **year** only clears the year, the date still imports.
- **Bulk add:** the sheet calls `ReminderCubit.addBirthdays(birthdays)` **once**, not
  `addBirthday` per row. The bulk path emits one state change, writes the whole list with a
  single `saveBirthdays` transaction and runs `ScheduleSync.syncAll` **once** at the end
  (importing 200 contacts used to mean 200 persists + 200 diff syncs). It does not rewrite
  reminders or settings, since only birthdays changed, and an empty list is a no-op. The
  single-add API is unchanged — use `addBirthday` for one, `addBirthdays` for a batch.
- **Nothing is preselected.** A first run on a large address book would otherwise flood the
  birthday list on one tap; "Tümünü seç (N)" makes the bulk case one tap anyway, and the
  import button stays disabled at zero selected.
- **Graceful degradation:** a refused permission (or one revoked between the check and the
  read) shows the explanation plus [Ayarları aç], and coming back granted re-reads in place.
  A non-permission failure says the address book cannot be read right now. Both keep the
  action usable and birthdays can always be typed by hand.
- **Result summary:** after the import the sheet switches to a summary step listing what was
  added and what was already there, and a snackbar repeats the counts on close — so "what
  happened" is answerable after the fact, which a silent drop would not be.
- **Not done on purpose:** writing to contacts, any kind of ongoing contact↔birthday sync,
  storing the contact id or photo, and Android 17's `Intent.ACTION_PICK_CONTACTS` picker
  (it cannot show *which* contacts have a birthday, which is the whole feature).

## Platform notes

- Development happens on Windows: **iOS is only verified through the CI macOS runner**
  (`build-ios` job). Device testing is planned separately.
- Package / bundle id `com.burakaydogmus.reminder` (Android `namespace`/`applicationId`,
  Kotlin package, iOS `PRODUCT_BUNDLE_IDENTIFIER`); the iOS widget extension is
  `com.burakaydogmus.reminder.ReminderWidget`. home_widget App Group
  `group.com.burakaydogmus.reminder` (`ios/Runner/Runner.entitlements` +
  `ios/ReminderWidget/ReminderWidgetExtension.entitlements`, F5.2).
- Release (Android): signed from `android/key.properties` when present, otherwise with the
  debug key plus a Gradle warning (never publish those). CI writes that file from the optional
  `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` /
  `ANDROID_KEY_PASSWORD` secrets, so consecutive APKs share one signature and install over each
  other; without the secrets every runner generates its own debug key and the APKs cannot
  replace each other on a device (uninstall = data loss). Details and the owner's setup steps:
  [`docs/android-signing.md`](docs/android-signing.md). R8 + `shrinkResources` are on;
  keep rules live in `android/app/proguard-rules.pro`, runtime-looked-up resources in
  `res/raw/keep.xml`. The `build-android-release` CI job catches R8 breakage; it builds
  `--split-per-abi` and uploads `app-release-arm64-apk` (the one to install) plus an
  `…-other-abis-apk` for armeabi-v7a and x86_64. Splits carry Flutter's per-ABI
  `versionCode` offsets, so a device must stay on one variant. The job's **"Audit the merged
  manifest"** step is the permanent guard behind `docs/store/permissions-review.md` §8 rows 8, 13
  and 17: it finds the merged manifest (under `build/app`, because `android/build.gradle` moves the
  Gradle build directory), prints every `uses-permission` and every `service`/`receiver`/`provider`
  with its `foregroundServiceType` — so an unused foreground-service component a plugin contributes
  is visible in the log — and **fails** when `WRITE_CALENDAR` (the calendar feature is read-only),
  `WRITE_CONTACTS` (the import is read-only) or `REQUEST_INSTALL_PACKAGES` appears. Declaring one of
  them on purpose means changing that list *and* the review doc.
- Releases for the owner's own device (F6.3b): `release.yml`, run manually. It **requires** the
  signing secrets (a debug-signed release could not install as an update, so it fails instead),
  derives `versionCode` from `date -u +%y%m%d%H` — `pubspec.yaml` pins `+8`, so every build
  would otherwise carry the same code and no updater could tell two builds apart — and publishes
  fixed-name APKs (`reminder-arm64-v8a.apk` …) under a `v<name>+<number>` tag. The phone tracks
  those releases with Obtainium; see [`docs/updates.md`](docs/updates.md). **Do not rename the
  assets** (the updater matches by name) and do not add an in-app updater without discussing
  `REQUEST_INSTALL_PACKAGES` first.
- Widget and geofence behaviour differs per platform, but both platforms now have home screen
  widgets over one payload (see **Home screen widgets — shared contract**): Android
  RemoteViews (F5.1), iOS WidgetKit (F5.2, `docs/ios-widget-setup.md`).
- Store readiness (privacy policy, data safety answers, permissions/policy review, listing drafts,
  licensing): [`docs/store/`](docs/store/) — update it when data flows or permissions change
  (F8.1 added `READ_CALENDAR` and the iOS calendar keys there).
