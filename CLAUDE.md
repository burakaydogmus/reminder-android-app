# CLAUDE.md

Guidance for AI agents and contributors working in this repository.

## Project overview

Flutter reminder app ("Hatırlatıcı"): to-dos/shopping items with optional scheduled
notifications, location-triggered (geofence) reminders, recurring birthday reminders
and an Android home screen widget. Local storage only (SharedPreferences JSON today;
Drift migration planned). Targets **Android + iOS**. UI strings are **Turkish (`tr_TR`)**.

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
  home widget callback registration (Android), then `runApp(App())`.
- `app.dart` — `MaterialApp`, theme, localization; **composition root**: creates
  `ReminderCubit` with the real services (see Dependency injection below).
- `bloc/reminder_cubit.dart` — `ReminderCubit`: single source of app state (reminders,
  birthdays, settings); persists via the repository and re-syncs notifications,
  geofences and the home widget after every change.
- `data/reminder_repository.dart` — `ReminderRepository`: load/save reminders, birthdays
  and `AppSettings` as JSON in `SharedPreferences`. Corrupt data is tolerated per item
  (lists) / per field (settings); on any load problem the untouched raw string is kept
  under `<key>_backup` (one per key, latest problematic payload wins, identical content
  not rewritten, removed only by `clearAll`). `hasRecoveryBackup()` reports it.
  Never return `[]` for a partially bad list — the next save would wipe valid data.
- `domain/model/` — `Reminder` (with `copyWith`), `Birthday`, `ReminderCategory`,
  `AppSettings`. Nullable fields in `copyWith` take `T? Function()?`
  (`copyWith(note: () => null)` clears). `Birthday`: a Feb 29 birthday falls on
  **Feb 28 in non-leap years** (`occurrenceInYear`, used by `nextOccurrence`,
  `daysUntilNext`, `upcomingAge`); date helpers take `from:` for tests.
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
  - `places_nearby_service.dart` — Google Places Nearby over HTTP.
  - `reminder_home_widget_sync.dart` — pushes data to the `home_widget`
    (`syncRemindersToHomeWidget`); `PlatformHomeWidgetSync` implements `HomeWidgetSync`.
- `home/reminder_home_widget_callback.dart` — background entry point
  (`@pragma('vm:entry-point')`) for widget interactions (toggle a reminder while the
  app is closed). Runs in a separate isolate, so the thin entry point builds the real
  services itself and delegates to `handleReminderHomeWidgetToggle` (injected
  repository + `ScheduleSync`, tested in `test/home/`).
- `config/maps_config.dart` — reads `GOOGLE_MAPS_KEY` from `--dart-define`.
- `ui/` — screens and widgets (Kor look, see **UI structure** below):
  - `home/` — `HomeShell` (Bugün / Takvim / Listeler, `PopScope` back to Bugün,
    minute tick) and `kor_navigation.dart` (Android `KorPillNavigation`, iOS
    `KorTabBar`, `NewItemFab`).
  - `today/` — `TodayPage` + `TodaySections` (overdue / today / untimed / completed
    grouping, pure). `calendar/` — `CalendarPage` + `buildAgenda` (30-day agenda,
    `BirthdayOccurrence`). `lists/` — `ListsPage`, `ReminderFilterPage`.
  - `reminders/` — `ReminderEditorSheet`, `CategoryVisuals` (the only category id →
    `KorColorKey`/icon mapping), `reminder_actions.dart` (Düzenle/Sil menu, delete
    confirm). `birthdays/` — editor sheet, `BirthdaysPage`. `settings/`, `maps/`.
  - `components/` — `ReminderCard`, `BirthdayCard`, `SectionHeader`, `GroupedCard`,
    `EmptyState`, `TabHeader` (gear → Ayarlar). `common/` — `KorFormat` (Turkish
    date/time, locale-aware upper case), `NowScope` (injectable clock).
  - `theme/` — Kor tokens (below); `theme/adaptive/platform_chrome.dart` is the single
    Android/iOS chrome decision. `widgets/` — `ConfirmationDialog`.
- `util/` — dialogs, location permission helpers, `local_timezone.dart`
  (`configureLocalTimezone`: device zone via `flutter_timezone`, `Etc/UTC` fallback;
  used by `main()` and the home widget callback).

## Tests (`test/`)

Tests mirror `lib/`:

- `test/domain/` — pure model tests (JSON, date logic, ids, labels).
- `test/data/` — `ReminderRepository` against `SharedPreferences.setMockInitialValues`.
- `test/bloc/` — `ReminderCubit` with `bloc_test` + `mocktail` mocks.
- `test/services/` — geofence rules, `GeofenceService` sync against a fake
  `GeofencePlatform` (no platform channels), background entry handling;
  `NotificationService` against `FakeNotificationsPlugin`
  (`test/helpers/fake_notifications_plugin.dart`, via `NotificationService.forTesting`;
  records cancelled/scheduled ids and shown notifications, needs mock
  `SharedPreferences` for fingerprints); `ScheduleSync` ordering and coalescing.
- `test/home/` — widget callback core with a real repository (mock
  `SharedPreferences`) and the fake notifications plugin.
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

`ScheduleSync.syncAll` runs one sync at a time per instance; calls arriving while
one runs are coalesced (only the latest snapshot runs, all queued callers complete
with it). The widget callback isolate has its own instance, so cross-isolate races
are not serialised — the next diff sync repairs the state.

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
  its own target, tap → editor, long-press → Düzenle/Sil, semantics label +
  custom actions), `BirthdayCard`, `SectionHeader`, `GroupedCard` (fills with a
  `Material`, so `ListTile`/`InkWell` children keep their ink), `EmptyState` (one
  title, one sentence, max one action).
- **Accessibility (F4.5 criteria, apply to every PR):** 48 dp targets
  (`materialTapTargetSize.padded`), state never by colour alone (e.g. "Gecikti" text +
  icon), Turkish semantics labels, times via `KorFormat` (24 h, tabular figures,
  `KorFormat.spokenTime` for screen readers), `KorFormat.upperTr` instead of
  `toUpperCase()`, no fixed heights for text (use `minHeight`), honour
  `MediaQuery.disableAnimationsOf`.
- **Copy:** Turkish, second person singular ("Seçtiğin…"), empty-state texts from
  `kor-design-proposal.md` §3.3.11.

## Geofencing

- Plugin: [`native_geofence`](https://pub.dev/packages/native_geofence) `^1.3.1`
  (AGP 9 support).
- **Events never reach the UI isolate.** The OS wakes the app (Android: broadcast →
  WorkManager → headless `FlutterEngine`; iOS: CoreLocation relaunch → headless
  engine) and runs `geofenceEntryCallback` (`@pragma('vm:entry-point')`, top level).
  The callback must be self-contained: no cubit, no singleton state from the main
  isolate; it loads settings/reminders via `ReminderRepository`, re-initializes
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
