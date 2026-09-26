#!/usr/bin/env bash
#
# Driver for the on-device end-to-end suite (`integration_test/`), run inside
# `reactivecircus/android-emulator-runner` by `.github/workflows/e2e.yml`.
#
# Why a script and not a matrix of steps:
# - the files must run in a **defined order**, and
#   `persistence_restart_test.dart` runs **twice** with the app data surviving
#   in between (its second run asserts what the first one wrote);
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
  # Allowed by default so `PermissionFlows.beforeScheduling` does not stop the
  # UI tests with the exact-alarm explanation sheet on the first timed save.
  # notifications_test.dart overrides this per run (see set_exact_alarms).
  adb shell appops set "$PKG" SCHEDULE_EXACT_ALARM allow >/dev/null 2>&1 || true
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

# run_test <label> <file> [extra flutter test args...]
#
# The label names the artifacts, so the same file can run twice (the exact-alarm
# pair, the persistence phases) without overwriting them. Flutter's output is
# kept in `$ARTIFACTS/out-<label>.txt` so later checks can assert on it.
run_test() {
  local label="$1"; shift
  local file="$1"; shift
  echo "::group::$label"
  adb logcat -c >/dev/null 2>&1 || true
  # --timeout=none: a device test is minutes long, the 30 s per-test default
  # would kill it. `pipefail` is on, so tee does not hide the exit status.
  # -r expanded: the default GitHub reporter only prints a group for a *failing*
  # test, so a passing test's `print` (the E2E_PHASE marker) would be swallowed.
  if flutter test "$file" -d "$DEVICE" --timeout=none -r expanded "$@" 2>&1 \
      | tee "$ARTIFACTS/out-$label.txt"; then
    record PASS "$label"
  else
    record FAIL "$label"
    failures=$((failures + 1))
  fi
  adb logcat -d > "$ARTIFACTS/logcat-$label.txt" 2>&1 || true
  adb exec-out screencap -p > "$ARTIFACTS/screen-$label.png" 2>/dev/null || true
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
# Captured rather than piped through `tee /dev/stderr`: that device does not
# exist on the runner, and its failure broke the pipeline being grepped.
launch_output=$(adb shell am start -W -n "$ACTIVITY" 2>&1)
echo "$launch_output"
if printf '%s' "$launch_output" | grep -q 'Status: ok'; then
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
  # "'$uri'" keeps the URI in one piece for the shell that runs ON the device:
  # adb re-parses the arguments there, and an unquoted '&' would background the
  # command instead of staying part of the query string.
  if adb shell am start -W -n "$ACTIVITY" -a "$LAUNCH_ACTION" -d "'$uri'" 2>&1 \
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
run_test cold_start integration_test/cold_start_test.dart

# Notifications, once with the exact-alarm app op denied (the F6.2c inexact
# fallback, which is also how Android installs the app on API 34+) and once
# with it granted.
reset_app
state=$(set_exact_alarms deny)
echo "SCHEDULE_EXACT_ALARM reported as: $state"
run_test notifications-inexact integration_test/notifications_test.dart \
  "--dart-define=E2E_EXACT_ALARMS=$state"

reset_app
state=$(set_exact_alarms allow)
echo "SCHEDULE_EXACT_ALARM reported as: $state"
run_test notifications-exact integration_test/notifications_test.dart \
  "--dart-define=E2E_EXACT_ALARMS=$state"

reset_app
run_test home_widget integration_test/home_widget_test.dart

reset_app
run_test backup integration_test/backup_test.dart

reset_app
run_test deep_link integration_test/deep_link_test.dart

reset_app
run_test routine integration_test/routine_test.dart

# Persistence across a real restart: the **same file** twice, so `flutter test`
# has no different APK to install — it uninstalls before installing a different
# one, and `adb uninstall` takes the app data with it (that is how the first
# version of this check failed). No `pm clear` between the runs; `am force-stop`
# kills the process, so the second run is a genuine cold start against the
# database the first one left behind. Last in the list, so nothing else can
# clear the data in between.
reset_app
run_test persistence-write integration_test/persistence_restart_test.dart
adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
run_test persistence-read integration_test/persistence_restart_test.dart

# The file picks its phase from a marker it stores on the device. Assert that
# both phases really ran: if the app data was wiped in between, the second run
# takes the write branch again and would otherwise pass on an empty database.
echo "::group::Persistence phases"
phase_failures=0
for expected in write:persistence-write read:persistence-read; do
  want=${expected%%:*}
  label=${expected#*:}
  if grep -q "E2E_PHASE=$want" "$ARTIFACTS/out-$label.txt"; then
    echo "$label ran the '$want' phase"
  else
    echo "FAIL: $label did not run the '$want' phase — the app data did not"
    echo "      survive between the two runs, so the restart was not tested."
    grep -o 'E2E_PHASE=[a-z]*' "$ARTIFACTS/out-$label.txt" \
      || echo "      (no E2E_PHASE line at all)"
    phase_failures=$((phase_failures + 1))
  fi
done
if [ "$phase_failures" -eq 0 ]; then
  record PASS persistence-phases
else
  record FAIL persistence-phases
  failures=$((failures + phase_failures))
fi
echo "::endgroup::"

# --- 3. Summary --------------------------------------------------------------
echo "::group::Summary"
cat "$ARTIFACTS/summary.txt"
echo "::endgroup::"
if [ "$failures" -ne 0 ]; then
  echo "e2e: $failures failing step(s)" >&2
  exit 1
fi
echo "e2e: all steps passed"
