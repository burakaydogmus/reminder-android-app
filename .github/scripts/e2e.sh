#!/usr/bin/env bash
#
# Driver for the on-device end-to-end suite (`integration_test/`), run inside
# `reactivecircus/android-emulator-runner` by `.github/workflows/e2e.yml`.
#
# Why a script and not a matrix of steps:
# - the files must run in a **defined order** (`persistence_read_test.dart`
#   asserts what `persistence_write_test.dart` wrote in the previous process,
#   so the app data must survive between exactly those two);
# - every other file needs a **cleared** app, and `pm clear` also drops the
#   runtime permission grants, so granting has to be interleaved;
# - one failing file must not hide the others: each result is collected and the
#   script exits non-zero at the end with a summary.
#
# It does not `sleep`. Waiting happens either inside the Dart tests (polling
# expectations, see `integration_test/helpers/e2e.dart`) or through commands
# that block on a condition (`adb wait-for-device`, `am start -W`).

set -uo pipefail

PKG=com.burakaydogmus.reminder
ACTIVITY="$PKG/.MainActivity"
# `home_widget`'s launch action; the Android widgets' PendingIntents use it
# with a `reminderwidget://` URI as the intent data (F5.1), and the manifest
# declares the matching intent filter. There is no browsable URL scheme on
# Android — the iOS side is the one with `CFBundleURLTypes` (F5.2).
LAUNCH_ACTION=es.antonborri.home_widget.action.LAUNCH
# Outside build/ so a Flutter build step can never wipe it.
ARTIFACTS=e2e-artifacts
APK=build/app/outputs/flutter-apk/app-debug.apk

mkdir -p "$ARTIFACTS"
: > "$ARTIFACTS/summary.txt"
failures=0

adb wait-for-device
DEVICE=$(adb devices | awk '/\tdevice$/ {print $1; exit}')
if [ -z "$DEVICE" ]; then
  echo "No adb device found" >&2
  exit 1
fi
echo "Device: $DEVICE"
adb shell getprop ro.build.version.sdk
adb shell getprop ro.build.version.release

record() { # record <status> <name>
  printf '%-4s %s\n' "$1" "$2" >> "$ARTIFACTS/summary.txt"
}

# Runtime permissions the suite needs. Granting them with `adb` instead of
# tapping the system dialogs is deliberate and legitimate here: these are
# *system* dialogs, not app UI, so tapping them would test Android rather than
# this app — and F1.6 already forbids the app from asking at startup, so there
# is no in-app flow to drive on launch either. The permission **flows**
# themselves (`PermissionFlows`, the sheets, the Ayarlar › İzinler rows) are
# covered by the host widget tests with a fake `PermissionService`.
#
# - POST_NOTIFICATIONS (API 33+): without it Android drops every scheduled
#   notification, so `pendingNotificationRequests()` could not be asserted and
#   the onboarding's notification step would show "Şimdi değil".
# - SCHEDULE_EXACT_ALARM is an **app op**, not a runtime permission, and is
#   toggled separately below (F6.2c is about both of its states).
# - Location and calendar permissions are deliberately *not* granted: no test
#   registers a geofence or reads the device calendar, and leaving them denied
#   proves the app starts and works without them.
grant_permissions() {
  adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS \
    >/dev/null 2>&1 || true
}

# Puts the SCHEDULE_EXACT_ALARM app op in $1 (allow|deny) and echoes the state
# Android actually reports, so the Dart test asserts the observed state rather
# than an assumption about defaults.
set_exact_alarms() {
  adb shell appops set "$PKG" SCHEDULE_EXACT_ALARM "$1" >/dev/null 2>&1 || true
  if adb shell appops get "$PKG" SCHEDULE_EXACT_ALARM 2>/dev/null \
      | grep -qi 'allow'; then
    echo allow
  else
    echo deny
  fi
}

reset_app() {
  adb shell pm clear "$PKG" >/dev/null 2>&1 || true
  grant_permissions
}

# run_test <file> [extra flutter test args...]
run_test() {
  local file="$1"; shift
  local name
  name=$(basename "$file" .dart)
  echo "::group::$name"
  adb logcat -c >/dev/null 2>&1 || true
  # --timeout=none: a device test is minutes long, the 30 s per-test default
  # would kill it. --ignore-timeouts also covers the compile step.
  if flutter test "$file" -d "$DEVICE" --timeout=none "$@"; then
    record PASS "$name"
  else
    record FAIL "$name"
    failures=$((failures + 1))
  fi
  adb logcat -d > "$ARTIFACTS/logcat-$name.txt" 2>&1 || true
  adb exec-out screencap -p > "$ARTIFACTS/screen-$name.png" 2>/dev/null || true
  echo "::endgroup::"
}

# --- 1. The plain app, for the checks that need the real launcher entry point
# ----------------------------------------------------------------------------
# `flutter test integration_test/x.dart` installs an APK whose Dart entry point
# is that test file, so the adb-level checks below have to happen while the
# ordinary debug APK is installed.
echo "::group::Build and install the debug APK"
flutter build apk --debug || exit 1
adb install -r -t "$APK" || exit 1
grant_permissions
echo "::endgroup::"

echo "::group::Native launch, app shortcuts and widget deep links"
native_failures=0
adb logcat -c >/dev/null 2>&1 || true

# A cold launch must reach a resumed activity.
if adb shell am start -W -n "$ACTIVITY" 2>&1 | tee /dev/stderr \
    | grep -q 'Status: ok'; then
  echo "launcher start: ok"
else
  echo "FAIL: the launcher intent did not start $ACTIVITY"
  native_failures=$((native_failures + 1))
fi

# F5.3: `quick_actions` publishes four dynamic launcher shortcuts from
# `main()`. Only the real launcher/ShortcutManager can show this.
adb shell dumpsys shortcut > "$ARTIFACTS/dumpsys-shortcut.txt" 2>&1 || true
for shortcut in new_reminder market_list today new_birthday; do
  if grep -q "$shortcut" "$ARTIFACTS/dumpsys-shortcut.txt"; then
    echo "shortcut $shortcut: published"
  else
    echo "FAIL: shortcut '$shortcut' was not published to ShortcutManager"
    native_failures=$((native_failures + 1))
  fi
done

# F5.1: the four widget providers must be registered as app widgets.
adb shell dumpsys appwidget > "$ARTIFACTS/dumpsys-appwidget.txt" 2>&1 || true
for provider in ReminderTodayWidgetProvider ReminderListWidgetProvider \
    ReminderNextWidgetProvider ReminderQuickAddWidgetProvider; do
  if grep -q "$provider" "$ARTIFACTS/dumpsys-appwidget.txt"; then
    echo "widget provider $provider: registered"
  else
    echo "FAIL: widget provider '$provider' is not registered"
    native_failures=$((native_failures + 1))
  fi
done

# The real widget deep links, delivered the way the widgets deliver them.
for uri in \
    'reminderwidget://new?homeWidget=true' \
    'reminderwidget://open?id=missing&homeWidget=true' \
    'reminderwidget://birthday?id=missing&homeWidget=true' \
    'reminderwidget://permissions?homeWidget=true'; do
  if adb shell am start -W -n "$ACTIVITY" -a "$LAUNCH_ACTION" -d "$uri" 2>&1 \
      | grep -q 'Status: ok'; then
    echo "deep link $uri: delivered"
  else
    echo "FAIL: '$uri' did not reach $ACTIVITY"
    native_failures=$((native_failures + 1))
  fi
done

adb logcat -d > "$ARTIFACTS/logcat-native.txt" 2>&1 || true
if grep -qE 'FATAL EXCEPTION|E AndroidRuntime' "$ARTIFACTS/logcat-native.txt"
then
  echo "FAIL: a fatal exception was logged during the native checks"
  grep -nE 'FATAL EXCEPTION|E AndroidRuntime' -A 20 \
    "$ARTIFACTS/logcat-native.txt" | head -60
  native_failures=$((native_failures + 1))
fi

if [ "$native_failures" -eq 0 ]; then
  record PASS native-checks
else
  record FAIL native-checks
  failures=$((failures + native_failures))
fi
echo "::endgroup::"

# --- 2. The Dart suite, in order --------------------------------------------

# Cold start: needs a device with no database at all.
reset_app
run_test integration_test/cold_start_test.dart

# Notifications, once with the exact-alarm app op denied (the F6.2c inexact
# fallback, which is also how Android installs the app on API 34+) and once
# with it granted.
reset_app
state=$(set_exact_alarms deny)
echo "SCHEDULE_EXACT_ALARM reported as: $state"
run_test integration_test/notifications_test.dart \
  "--dart-define=E2E_EXACT_ALARMS=$state"

reset_app
state=$(set_exact_alarms allow)
echo "SCHEDULE_EXACT_ALARM reported as: $state"
run_test integration_test/notifications_test.dart \
  "--dart-define=E2E_EXACT_ALARMS=$state"

reset_app
run_test integration_test/home_widget_test.dart

reset_app
run_test integration_test/backup_test.dart

reset_app
run_test integration_test/deep_link_test.dart

reset_app
run_test integration_test/routine_test.dart

# Persistence: phase 1 writes, phase 2 asserts the rows survived a real process
# restart — so **no** `pm clear` between them. Last in the list, so nothing
# else can clear the data in between.
reset_app
run_test integration_test/persistence_write_test.dart
run_test integration_test/persistence_read_test.dart

# --- 3. Summary --------------------------------------------------------------
echo "::group::Summary"
cat "$ARTIFACTS/summary.txt"
echo "::endgroup::"
if [ "$failures" -ne 0 ]; then
  echo "e2e: $failures failing step(s)" >&2
  exit 1
fi
echo "e2e: all steps passed"
