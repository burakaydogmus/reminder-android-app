# CLAUDE.md

Guidance for AI agents and contributors working in this repository.

## Project overview

Flutter reminder app ("Hatırlatıcı"): to-dos/shopping items with optional scheduled
notifications, location-triggered (geofence) reminders, recurring birthday reminders
and an Android home screen widget. Local storage only (Drift/SQLite, see **Data**).
Targets **Android + iOS**. UI strings are **Turkish (`tr_TR`)**.

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
  `AppSettings`. Nullable fields in `copyWith` take `T? Function()?`
  (`copyWith(note: () => null)` clears). `Birthday`: a Feb 29 birthday falls on
  **Feb 28 in non-leap years** (`occurrenceInYear`, used by `nextOccurrence`,
  `daysUntilNext`, `upcomingAge`); date helpers take `from:` for tests.
- `domain/model/recurrence.dart` — `RecurrenceRule` (F3.1): none / daily / weekly
  (sorted Mon-first weekdays) / monthly (day of month, clamped to the month end:
  31 → 30/28/29), `interval` (every N days/weeks/months; "Özel" = daily N ≥ 2),
  optional `until` (inclusive date). `nextOccurrence(after:, anchor:)` returns the
  first occurrence strictly after `after`; the **time comes from `anchor`** (the
  reminder's `remindAt`) and dates are built from calendar fields
  (`DateTime(y, m, d + n, h, min)`), never `Duration` adds, so the wall-clock time
  survives DST. Interval grids start at the anchor's day/week/month. `summary` is the
  Turkish label ("Her gün", "2 haftada bir Pzt, Çar", "Her ayın 17'si");
  `alignedTo(date)` adapts the rule when the whole series moves to another date.
  `Reminder.recurrence` defaults to none (JSON key `recurrence`, missing/corrupt →
  none); `Reminder.isRecurring` also needs a `remindAt`.
- `domain/model/subtask.dart` — `Subtask { id, title, isDone, position }` (F3.3) and
  `Reminder.subtasks` (default empty; JSON key `subtasks`, missing → empty, unreadable
  items skipped). Change lists only through the `SubtaskList` extension (`toggled`,
  `renamed`, `added`/`addedAll`, `removed`, `reordered`, `moved`, `reset`,
  `inOrder`, progress getters): every helper returns an unmodifiable list with
  `position` = index. `splitSubtaskText` splits lines, `,` (not a decimal comma),
  `;` and a separate-word " ve " (bullets/checkboxes stripped) — the editor's
  "Maddelere böl" button; the quick-capture parser (F4.6a) has its own list
  detection (`parsing/rules/list_rules.dart`) whose items become `Subtask`s when
  capture is wired up. `splitSubtaskLines` splits line breaks only (paste, Enter). Completing a reminder never completes its subtasks and all
  subtasks done never completes the reminder (the editor only suggests it).
- `domain/parsing/` — Turkish quick-capture parser (F4.6a, see **Quick-capture
  parser**).
- `domain/reminder_completion.dart` — `completeReminder(reminder, now)`: the **only**
  "Tamamla" rule (cubit `toggleDone`, home widget toggle, notification Tamamla
  action; any new completion path must use it too). Recurring reminders are never marked done: `remindAt` advances to the
  next occurrence after `max(now, remindAt)` (early completion skips this occurrence,
  overdue ones skip missed occurrences) and its subtasks are **reset to open**
  (F3.3); a finished series and one-off reminders get `isDone = true` with subtasks
  untouched.
- `domain/reminder_sorting.dart` — `compareReminders`: the single reminder ordering
  (active before done; timed by `remindAt` asc; timed before untimed; untimed by
  `createdAt` desc), used by the cubit and the home widget sync. `ReminderCubit`
  re-sorts after **every** list change, so `state.reminders` is always in this order.
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
    notifications, exact alarms, location) with pure decision helpers;
    `PlatformPermissionService` over flutter_local_notifications + permission_handler.
  - `places_nearby_service.dart` — Google Places Nearby over HTTP.
  - `reminder_home_widget_sync.dart` — pushes data to the `home_widget`
    (`syncRemindersToHomeWidget`); `PlatformHomeWidgetSync` implements `HomeWidgetSync`.
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
  the Google Sans Flex OFL from the `fonts/GoogleSansFlex/OFL.txt` asset. Bundled
  third-party assets (fonts, data) need an entry here; Settings › Diğer › Lisanslar
  shows them via `showLicensePage`. The map must keep the visible, tappable
  "© OpenStreetMap contributors" attribution (OSMF tile policy).
- `ui/` — screens and widgets (Kor look, see **UI structure** below):
  - `home/` — `HomeShell` (Bugün / Takvim / Listeler, `PopScope` back to Bugün,
    minute tick) and `kor_navigation.dart` (Android `KorPillNavigation`, iOS
    `KorTabBar`, `NewItemFab`).
  - `today/` — `TodayPage` + `TodaySections` (overdue / today / untimed / completed
    grouping and `timeline(now:)`, pure), `time_ribbon.dart` (`TimeRibbonRow`,
    `NowLine`), `overdue_actions.dart` ("Hepsini yarına al"). `calendar/` —
    `CalendarPage` + `buildAgenda` (30-day agenda, `BirthdayOccurrence`). `lists/` —
    `ListsPage` (smart-list bento + categories), `SmartList` (pure membership),
    `SmartListPage`, `ReminderFilterPage`. `search/` — `SearchPage`,
    `ReminderSearch` (pure ranking/grouping), `RecentSearchStore`.
  - `reminders/` — `ReminderEditorSheet`, `CategoryVisuals` (the only category id →
    `KorColorKey`/icon mapping), `reminder_actions.dart` (complete / snooze / delete
    handlers with undo, long-press menu), `reminder_swipe.dart`, `snooze_sheet.dart`
    + `snooze_options.dart` (pure snooze times), `undo_snack_bar.dart` (F3.5). `birthdays/` — editor sheet, `BirthdaysPage`. `settings/` (with
    `PermissionsGroup`), `maps/`.
  - `permissions/` — `PermissionScope`/`PermissionController`, `PermissionSheet`,
    `PermissionBanner`, `PermissionFlows` (see **Permissions** below).
  - `onboarding/` — `OnboardingGate` (`app.dart` `home:`), `OnboardingFlow` + `steps/`,
    `OnboardingStore` (see **Onboarding** under UI structure).
  - `components/` — `ReminderCard`, `BirthdayCard`, `SectionHeader`, `GroupedCard`,
    `EmptyState`, `TabHeader` (gear → Ayarlar). `common/` — `KorFormat` (Turkish
    date/time, locale-aware upper case), `NowScope` (injectable clock).
  - `theme/` — Kor tokens (below); `theme/adaptive/platform_chrome.dart` is the single
    Android/iOS chrome decision. `widgets/` — `ConfirmationDialog`.
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
  `SharedPreferences` for fingerprints); `ScheduleSync` ordering and coalescing.
- `test/home/` — widget callback core with a real repository (in-memory database) and
  the fake notifications plugin.
- `test/ui/theme/` — Kor token contrast (WCAG), theme/extension and font asset tests.
- `test/ui/` — widget tests on `UiHarness` (`test/ui/ui_harness.dart`: a real
  `ReminderCubit` over the mocks, loaded with given reminders/birthdays, wrapped like
  `App`). Pass a fixed clock (`HomeShell(clock: ...)`) for date-dependent screens, run
  light and dark via `korThemes`, and select iOS chrome with
  `platform: TargetPlatform.iOS`. Pure groupings (`TodaySections`, `buildAgenda`,
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
  settings, schedule mode) → bump `_ScheduleSpec._version`.
- **Recurring reminders (F3.1):** only the **next** occurrence is scheduled per
  reminder (`NotificationService.reminderFireTime`: a future `remindAt`, or for an
  overdue recurring reminder the rule's next occurrence after now, so it keeps
  notifying). Simple rules also repeat without the app through
  `matchDateTimeComponents` (`reminderRepeatComponents`): every day → `time`, every
  week on one day → `dayOfWeekAndTime`, every month on day 1–28 →
  `dayOfMonthAndTime`. Intervals > 1, several weekdays, days 29–31 (month-end clamp)
  and rules with an end date are next-only: the OS cannot express them, the diff sync
  sets the following occurrence on the next load/change. The rule (JSON) is part of
  the fingerprint.
- **Subtasks (F3.3):** with open subtasks the body is "`<note or place>` · N madde
  kaldı" (`reminderNotificationBody`; just "N madde kaldı" without a note) and
  Android uses `BigTextStyleInformation` listing up to 5 open items + "… ve N madde
  daha" (`reminderSubtaskBigText`); that text is in the fingerprint (`subtasks`), so
  ticking an item reschedules. Geofence notifications use the same helpers. iOS shows
  the summary body only.

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

- **Schema v3** (`lib/data/db/app_database.dart`, exported to
  `drift_schemas/drift_schema_v1.json` … `drift_schema_v3.json`): `reminders` and
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
  first. SQLite foreign keys are not enforced (no `PRAGMA foreign_keys`). **Model times**
  (`created_at`, `remind_at`, `birthdays.date`) are TEXT in exactly the old JSON format,
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
  (`format: "hatirlatici-backup"`, `version: 1`, `exportedAt` UTC, `app.version`,
  `reminders`/`birthdays` as the models' `toJson`, `settings`). New model fields travel
  automatically (items are `toJson`/`fromJson`); bump `BackupFormat.version` only for
  changes an older reader would misread — a newer file is rejected with "update the
  app". Import is tolerant per item (not an object, `fromJson` fails, empty or repeated
  id → skipped and counted); a non-JSON file, wrong `format`, bad/newer `version` or a
  non-list `reminders`/`birthdays` throws `BackupFormatException` and **nothing is
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

  Then add the `vN-1 → vN` case to `test/data/db/migration_test.dart`. Generated
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
  Changing notification details → bump `_ScheduleSpec._version` (v2 = F3.2 actions, v3 = F3.1 recurrence rule in the fingerprint, v4 = F3.3 subtasks body/BigText).
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

## Quick-capture parser (F4.6a)

- `lib/domain/parsing/`: pure Dart, no Flutter or model imports besides
  `ReminderCategoryIds`. Entry point `CaptureParser.parse(input, now:, config:)` in
  `turkish_capture_parser.dart`; the rules are `part` files in `rules/` (scanner,
  tags, dates, times, recurrence, resolution, list split); `turkish_text.dart` does
  Turkish casing/folding (İ↔i, I↔ı) **without shifting string offsets**.
- Result types (`capture_parse_result.dart`) are **neutral**: `CaptureToken` (kind,
  exact `start`/`end` in the original input, `confidence`), `RecurrenceSpec`
  (daily / weekly / monthly / everyNDays), `CaptureParseResult` (title, tokens,
  `dateTime` + `hasExplicitTime`, `isPast`, recurrence, `categoryKey`/`categoryId`,
  priority 0–3, `placeKey`, `splitSuggestion`), `CaptureParserConfig` (day-part hours
  for "Ayarlar › sabah saati", category aliases, list categories).
- Rules: high-confidence matches only, first match per slot wins (later ones stay in
  the title), day parts used as nouns (`akşam yemeği`, `bir akşam`) are text,
  `pazar` with a suffix is the market, a time without a date is today if still
  ahead, else tomorrow. Details in each rule file's doc comment.
- **F4.6b maps the results; don't add model mapping here.** `RecurrenceSpec` →
  `RecurrenceRule` (`lib/domain/model/recurrence.dart`): daily → `daily()`,
  everyNDays → `daily(interval: n)`, weekly → `weekly(days, interval:)`, monthly →
  `monthly(dayOfMonth:)`. `RecurrenceRule` clamps day 31 to short months while the
  parser's first occurrence skips them, so compute the first `remindAt` with the
  rule when they differ. `isPast` → the F1.8b past-time warning; `categoryId == null`
  with a `categoryKey` → "Yeni kategori oluştur?"; priority → F3.4.
- Tests: `test/domain/parsing/` — table-driven `CaptureCase`s in `cases/` on a fixed
  clock (`kNow`, 13 Eylül 2026 14:32; the table must keep ≥ 200 sentences), plus
  `turkish_capture_parser_edge_test.dart` for other clocks, offsets and config.

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
  resolver). `kor_theme.dart` — `KorTheme` builders; `haptics.dart` — `KorHaptics`.
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

## UI structure

- **Shell:** `HomeShell` has three tabs (Bugün / Takvim / Listeler) in an
  `IndexedStack`; Ayarlar is a pushed route from the gear in `TabHeader`. Back on
  Takvim/Listeler selects Bugün (`PopScope`). Android: floating `KorPillNavigation` +
  64 px `NewItemFab` (long-press: Hatırlatıcı / Doğum günü); iOS: plain `KorTabBar` +
  FAB. Decide platform chrome only through `PlatformChrome` (reads
  `Theme.of(context).platform`, so tests override it via the theme).
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
  (Tamamla/Geri aç, Ertele, Düzenle, Sil) and semantics custom actions (WCAG 2.5.7)
  — add new card actions to all three. Actions apply immediately and show
  `UndoSnackBar` (one at a time, a new one replaces the old; 5 s, 10 s with
  `MediaQuery.accessibleNavigationOf` and accessibility focus on "Geri al"; pass
  `persist: false`, a `SnackBar` with an action otherwise never closes). Reminder
  delete has **no confirm dialog**; undo re-adds the same object with
  `addReminder`. Confirm dialogs stay for irreversible bulk actions ("Tüm verileri
  sıfırla"). Snooze times come only from `SnoozeOptions.from(now)` (pure, injected
  clock); the Ertele sheet never accepts a past custom time.
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
- **Accessibility (F4.5 criteria, apply to every PR):** 48 dp targets
  (`materialTapTargetSize.padded`), state never by colour alone (e.g. "Gecikti" text +
  icon), Turkish semantics labels, times via `KorFormat` (24 h, tabular figures,
  `KorFormat.spokenTime` for screen readers), `KorFormat.upperTr` instead of
  `toUpperCase()`, no fixed heights for text (use `minHeight`), honour
  `MediaQuery.disableAnimationsOf`.
- **Editor past times (F1.8b):** never shift a chosen time silently. The "Ne zaman"
  section flags a past date/time (`PastTime` / `PastTimeHint` in
  `reminders/past_time_hint.dart`: error-coloured chips, icon + "Bu saat geçti",
  "Yarın HH:mm mı?" suggestion) and `_save` blocks it inline. Only an existing
  reminder's unchanged overdue time saves (original `remindAt` kept).
  `showReminderEditorSheet(now: ...)` takes the clock (default: `NowScope`).
- **Recurrence UI (F3.1):** the "Ne zaman" card has a Tekrar row that opens
  `reminders/recurrence_sheet.dart` (segments Yok / Günlük / Haftalık / Aylık / Özel,
  48 dp weekday circles, "Her [N] …" stepper, Bitiş, "Sonraki 3: …" preview via
  `RecurrenceFormat`). A rule needs a time: without one, choosing a rule schedules
  today + 1 hour (dismissing changes nothing). A weekly rule whose days exclude the
  date moves the date to the first chosen day (visible in the date chip); changing the
  date of a recurring reminder moves the **whole series** (`alignedTo`). "Yalnızca
  bu sefer" (B7) is not built yet. Turning scheduling off clears the rule. The card
  meta line shows a repeat icon + `summary`; completing a recurring reminder keeps
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
  single-pointer alternative. No swipe delete. Changes are kept in the editor and
  saved with "Kaydet" (empty titles dropped). When all items are done the card
  suggests "Tümü tamam — hatırlatıcıyı tamamla?": it saves, then runs
  `toggleReminderDoneWithUndo`. `ReminderCard` meta shows ☑ icon + "2/6" and a 3 px
  bar; `ReminderCompactCard`'s default subtitle adds "☑ 2/6"; both add
  "maddeler: 2/6 tamamlandı" to the semantics label. Liste detayı checklist mode
  (§3.3.6) is not built yet.
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
- **Copy:** Turkish, second person singular ("Seçtiğin…"), empty-state texts from
  `kor-design-proposal.md` §3.3.11.

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
- Exact alarms: the manifest keeps `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM`; the Play
  policy decision is F6.2; the inexact fallback when exact alarms are denied (then
  dropping `USE_EXACT_ALARM`) is F6.2c.

## Platform notes

- Development happens on Windows: **iOS is only verified through the CI macOS runner**
  (`build-ios` job). Device testing is planned separately.
- Package / bundle id `com.burakaydogmus.reminder` (Android `namespace`/`applicationId`,
  Kotlin package, iOS `PRODUCT_BUNDLE_IDENTIFIER`); home_widget App Group
  `group.com.burakaydogmus.reminder` (iOS entitlements come with F5.2).
- Release (Android): signed from `android/key.properties` when present, otherwise with the
  debug key plus a Gradle warning (never publish those). R8 + `shrinkResources` are on;
  keep rules live in `android/app/proguard-rules.pro`, runtime-looked-up resources in
  `res/raw/keep.xml`. The `build-android-release` CI job catches R8 breakage.
- Widget and geofence behaviour differs per platform; the home widget is Android-only today.
- Store readiness (privacy policy, data safety answers, permissions/policy review, listing drafts,
  licensing): [`docs/store/`](docs/store/) — update it when data flows or permissions change.
