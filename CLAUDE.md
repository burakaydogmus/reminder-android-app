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
  - `geofence_service.dart` — region registration/listening (`flutter_geofence_manager`);
    implements `GeofenceSync`.
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

## Platform notes

- Development happens on Windows: **iOS is only verified through the CI macOS runner**
  (`build-ios` job). Device testing is planned separately.
- Android package / app group currently `com.fabirt.reminder` (rename planned in F1.9).
- Widget and geofence behaviour differs per platform; the home widget is Android-only today.
