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

Toolchain: Flutter 3.29.2 stable / Dart 3.7 (pinned in CI).
`GOOGLE_MAPS_KEY` is optional; the map (OpenStreetMap via `flutter_map`) works without it.

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
  and `AppSettings` as JSON in `SharedPreferences`.
- `domain/model/` — `Reminder` (with `copyWith`), `Birthday`, `ReminderCategory`,
  `AppSettings`.
- `domain/reminder_sorting.dart` — `compareReminders`: the single reminder ordering
  (active before done; timed by `remindAt` asc; timed before untimed; untimed by
  `createdAt` desc), used by the cubit and the home widget sync.
- `services/`
  - `sync_interfaces.dart` — `GeofenceSync` and `HomeWidgetSync` interfaces.
  - `notification_service.dart` — `flutter_local_notifications` scheduling (singleton).
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
  app is closed). Runs in a separate isolate, so it uses the real services directly
  instead of going through the cubit.
- `config/maps_config.dart` — reads `GOOGLE_MAPS_KEY` from `--dart-define`.
- `ui/` — screens and widgets: `home/`, `reminders/`, `birthdays/`, `maps/`,
  `settings/`, `theme/`, `widgets/`.
- `util/` — dialogs, location permission helpers.

## Tests (`test/`)

Tests mirror `lib/`:

- `test/domain/` — pure model tests (JSON, date logic, ids, labels).
- `test/data/` — `ReminderRepository` against `SharedPreferences.setMockInitialValues`.
- `test/bloc/` — `ReminderCubit` with `bloc_test` + `mocktail` mocks.
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

## Geofencing

- Plugin: [`native_geofence`](https://pub.dev/packages/native_geofence) (constraint
  `^1.2.1`; 1.2.2+ needs `meta` 1.17, i.e. a newer Flutter than 3.29 — it upgrades
  itself to 1.3.x with the F4.0 Flutter upgrade).
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
- iOS: `AppDelegate` must call `NativeGeofencePlugin.setPluginRegistrantCallback`
  before `GeneratedPluginRegistrant.register`. No `UIBackgroundModes` needed; events
  while the app is closed require "Always" location permission.
- Do **not** add a foreground service for geofencing (Google Play disallows it from
  28 Oct 2026); `NativeGeofenceBackgroundManager.promoteToForeground` is unused.

## Platform notes

- Development happens on Windows: **iOS is only verified through the CI macOS runner**
  (`build-ios` job). Device testing is planned separately.
- Android package / app group currently `com.fabirt.reminder` (rename planned in F1.9).
- Widget and geofence behaviour differs per platform; the home widget is Android-only today.
