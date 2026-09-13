# Flutter 3.47 toolchain upgrade (F4.0a)

Record of the upgrade from Flutter 3.29.2 to 3.47.4 (PR `chore/flutter-upgrade`).
Versions were checked on 2026-09-13 against the Flutter release JSON, the
Flutter 3.47.4 tool source/templates and pub.dev.

## Why

- The Flutter 3.47 tool **fails** Android builds below AGP 8.11.1, Gradle 8.14,
  KGP 2.2.20 or Java 17 (warns below AGP 9.0.1 / Gradle 9.1.0 / KGP 2.3.20).
  The repo was on AGP 8.6.1 / Gradle 8.7 / KGP 2.1.10.
- Flutter 3.47 raised the iOS minimum to 15.0.
- Google Play requires targetSdk 36 for updates since 2026-08-31.
- Apple will require the UIScene lifecycle for apps built with the SDK after
  iOS 26; Flutter templates use it by default since 3.41.
- `package:flutter/material.dart` / `cupertino.dart` are frozen since 3.44 and
  scheduled for deprecation in the November stable release; with
  `--fatal-infos` that would break CI.

## Versions

| Item | From | To |
|---|---|---|
| Flutter / Dart | 3.29.2 / 3.7.2 | **3.47.4 / 3.13.3** (CI pin) |
| AGP | 8.6.1 | 9.1.0 |
| Gradle wrapper | 8.7 | 9.3.1 |
| Kotlin Gradle Plugin | 2.1.10 | 2.4.0 |
| compileSdk / targetSdk | 35 / 35 | 36 / 36 (`flutter.compileSdkVersion` / `flutter.targetSdkVersion`) |
| minSdk | 26 | 26 |
| NDK | not set | `flutter.ndkVersion` (28.2.13676358) |
| Java | 17 | 17 |
| iOS deployment target | 14.0 | 15.0 |
| CI iOS runner | `macos-latest` | `macos-26` |
| flutter_local_notifications | 18.0.1 | 22.3.1 |
| timezone | 0.9.4 | 0.11.1 |
| flutter_timezone | 3.0.1 | 5.1.0 |
| home_widget | 0.9.1 | 0.9.4 |
| native_geofence | 1.2.1 | 1.3.1 |
| intl | 0.19.0 | 0.20.3 (required by 3.47's localizations) |
| permission_handler | 12.0.1 | 12.0.3 |
| geolocator / flutter_map | 14.0.2 / 8.3.0 | 14.0.3 / 8.3.2 |
| shared_preferences / uuid / cupertino_icons | 2.5.3 / 4.5.3 / 1.0.8 | 2.5.5 / 4.6.0 / 1.0.9 |
| animations | 2.1.0 | 3.0.0 |
| material_ui / cupertino_ui | — | 1.2.0 / 1.0.2 |
| flutter_localizations | SDK | removed (delegates come from material_ui) |
| flutter_lints | 5.0.0 | 6.0.0 |

Deliberately **not** upgraded:

- `permission_handler` 13.x: permission_handler_android 14 needs compileSdk 37.
  Stay on 12.x until Flutter's default compileSdk moves to 37.
- `flutter_bloc` 9 / `bloc_test` 10: not required by 3.47 (8.x resolves and
  passes); a separate change if ever needed.
- `latlong2` 0.10, `shared_preferences` async API: not required.
- `dynamic_color`, `motor`: added with the features that use them (F4.1/F4.7).

## Android

- `settings.gradle`: AGP 9.1.0, KGP 2.4.0. Wrapper: Gradle 9.3.1.
- `gradle.properties`: `android.newDsl=false` and `android.builtInKotlin=false`,
  exactly as the 3.47 app template (Flutter's migrator adds both when missing).
  With built-in Kotlin off, the Flutter Gradle plugin applies `kotlin-android`
  to the app and to plugin modules that don't apply it, so the app no longer
  lists `kotlin-android` itself. Built-in Kotlin can be enabled later, once no
  plugin applies KGP itself (the build currently warns for flutter_timezone,
  home_widget, native_geofence and shared_preferences_android).
  flutter_geofence_manager, which forced this in the original plan, is gone
  since F1.1.
- `app/build.gradle`: `kotlinOptions` → top-level `kotlin { compilerOptions }`
  (JVM 17); SDK/NDK values from `flutter.*`; removed the explicit
  `kotlin-stdlib` dependency; `core-ktx` 1.13.1 → 1.16.0.
- `build.gradle`: `buildDir` → `layout.buildDirectory` (template form).

### Removed force pins

| Pin | Why it existed | Why it could go |
|---|---|---|
| `androidx.glance:glance-appwidget:1.1.1` | home_widget 0.9.1 used `1.+` | home_widget ≥0.9.2 pins 1.2.0 |
| `androidx.work:work-runtime(-ktx):2.9.1` | home_widget used `2.+` | pinned to 2.11.2 upstream |
| `kotlinx-coroutines-*:1.8.1` | home_widget used `1.+` | pinned to 1.10.2 upstream |
| `androidx.core:core(-ktx):1.13.1` | newer core needed compileSdk 35+/AGP 8.6+ | compileSdk 36; geolocator_android needs 1.16 |
| `kotlin-stdlib(-jdk7/-jdk8):2.1.10` | matched KGP 2.1.10 | would downgrade stdlib below KGP 2.4.0 |

## iOS

- Podfile, `project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET` 15.0.
- `Flutter/AppFrameworkInfo.plist`: `MinimumOSVersion` removed (the 3.47
  template has none and the tool's migrator deletes it).
- UIScene: `Info.plist` gets `UIApplicationSceneManifest` with
  `FlutterSceneDelegate` (the manifest Flutter's own migrator inserts).
  `AppDelegate` is `@main` + `FlutterImplicitEngineDelegate`:
  - `didFinishLaunching`: `NativeGeofencePlugin.setPluginRegistrantCallback`
    first (static callback; must be set before a background, scene-less
    location relaunch starts the headless engine — see native_geofence issue
    #45), then `UNUserNotificationCenter.current().delegate`.
  - `didInitializeImplicitFlutterEngine`:
    `FlutterLocalNotificationsPlugin.setPluginRegistrantCallback` and
    `GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)`.

## Dart code

- `NotificationService`: flutter_local_notifications 20+ named parameters for
  `initialize(settings:)`, `show(id:, title:, body:, notificationDetails:)`,
  `cancel(id:)`, `zonedSchedule(id:, scheduledDate:, notificationDetails:,
  androidScheduleMode:, ...)`; `uiLocalNotificationDateInterpretation` removed
  (gone since 19.0). Channel ids are unchanged.
- `lib/util/local_timezone.dart`: shared timezone setup for `main()` and the
  home widget callback; `FlutterTimezone.getLocalTimezone()` now returns
  `TimezoneInfo` (`.identifier`); fallback zone `Etc/UTC` (timezone 0.11).
- Theme: deprecated `ThemeData.indicatorColor` → `TabBarThemeData.indicatorColor`
  (read via `TabBarTheme.of(context)`); `pageTransitionsTheme` pins Android to
  `ZoomPageTransitionsBuilder`, because 3.38 changed the Android default.
  `useMaterial3: false` unchanged — no visual change intended.
- material_ui / cupertino_ui: `dart fix --apply --code=migrate_design_widgets`
  (import-only) and `GlobalMaterialLocalizations.delegates` from material_ui.
- `analysis_options.yaml`: the 3.47 tool added `build/`, `android/`, `ios/`,
  `web/` to `analyzer.exclude`.

## Local development

- Build the app with Flutter 3.47.4 after merging; 3.29 can no longer resolve
  the dependencies.
- On Windows, `flutter analyze` crashes when the project path contains
  non-ASCII characters (LSP Content-Length mismatch); `dart analyze
  --fatal-infos` runs the same analysis. `flutter build apk` needs an ASCII
  path as well.

## Needs device verification

- Scheduled and yearly birthday notifications (Android 16, iOS), tapping a
  notification, foreground presentation on iOS.
- Geofence entry notifications while the app is terminated, especially on iOS
  after the UIScene change.
- Android home widget: list rendering and background toggle.
- Page transitions and bottom nav indicator colour look as before.
