# Hatırlatıcı — Privacy Policy

**Last updated:** 13 September 2026
**App:** Hatırlatıcı (Android package and iOS bundle ID: `com.burakaydogmus.reminder`)
**Contact:** `<iletişim e-postası>`

> **Publishing note (before store submission):** Google Play and the App Store require the privacy
> policy to be available at a public, non-geofenced, non-PDF URL and linked from inside the app.
> This file is not hosted yet — see **Hosting** at the end. Replace the `<iletişim e-postası>`
> placeholder with a real contact address before publishing.

## Summary

- No account, no ads, no analytics, and **no server of ours** that receives your data.
- Your reminders, birthdays and settings are stored **only on your device**.
- Location is used on the device: to pick a place on the map and to remind you when you arrive.
- The app goes online only to load OpenStreetMap map tiles and — only in builds that include the
  feature — to search nearby supermarkets with Google Places.
- Backup files are created only when you ask and shared only where you choose.

## 1. Data stored on your device

| Data | Where | Purpose |
|---|---|---|
| Reminders (title, note, category, time, chosen place and radius, done state) | SQLite database (Drift) in the app support directory | Core functionality |
| Birthdays (name, date, note, advance reminders) | Same database | Yearly birthday reminders |
| Settings (theme, notification preferences) | Same database | Remember your preferences |
| Onboarding/permission-prompt flags, notification schedule and geofence bookkeeping | SharedPreferences (Android) / UserDefaults (iOS) | Correct operation |
| Reminder list shown on the home screen widget (Android) | Widget SharedPreferences | Update the widget |

We cannot access this data; it is never sent to a server.

**Deletion:**

- Deleting a reminder removes it from the lists; the database keeps a row marked as deleted
  (prepared for a future sync feature). That row never leaves the device either.
- **Settings → Reset all data** permanently deletes reminders, birthdays and settings from the
  database and removes pending notifications and geofences.
- Uninstalling the app removes all app data.
- On Android, inclusion in the system (Google account) backup is disabled
  (`android:allowBackup="false"`). On iOS, whether app data is part of iCloud/computer device
  backups depends on system settings (*to be verified*).

## 2. Location

We ask for location only in context — when you create a location reminder or open the map — after
an explanation. Without permission you can still pick a place manually.

- **Picking a place:** "Go to my location" reads the current position once to centre the map. It is
  not stored; only the point you choose is saved with the reminder, on the device.
- **Arrival reminders (background location):** the places of your location reminders are
  registered with the operating system's region monitoring (geofencing). When you enter a region,
  the system wakes the app and a notification is shown on the device. To work **while the app is
  closed**, "Always" location permission is required. No location history is kept and your
  location is not sent to us or anyone else.
- Region monitoring uses the Google Play services location API on Android and Core Location on
  iOS, subject to the platform's own privacy terms.

You can revoke the permission in system settings at any time; location reminders then stop
working, everything else keeps working.

## 3. Notifications

All notifications are **local**: scheduled and shown on the device. No push service is used. On
Android we may ask for the "Alarms & reminders" permission so reminders arrive on time. Reminder
titles may appear on the lock screen depending on your device settings.

## 4. Features that use the internet

No account data or reminder content is sent in these requests.

### 4.1 OpenStreetMap map tiles

When the location picker is open, map images (tiles) are downloaded from
`tile.openstreetmap.org`. As with any internet request, your **IP address**, a **user agent**
identifying the app, and the requested map area reach the OpenStreetMap Foundation (OSMF):

- OSMF Privacy Policy: <https://osmfoundation.org/wiki/Privacy_Policy>
- Tile Usage Policy: <https://operations.osmfoundation.org/policies/tiles/>

### 4.2 Nearby supermarket search with Google Places (optional)

This feature exists **only in builds compiled with a Google Maps API key**. In builds without a key
the "Show nearby supermarkets" button is not shown and no request is made to Google.

In a build that has it, tapping the button sends the **coordinates** of the point selected on the
map, a search radius and a place type to Google's Places API (`maps.googleapis.com`), together with
your IP address. The name and position of the place you pick may be stored with the reminder on
the device. Google's processing is governed by the Google Privacy Policy:
<https://policies.google.com/privacy>

## 5. Backup (export and import)

- **Export** starts only from **Settings → Back up**. Reminders, birthdays, settings and the app
  version are written to a JSON file in a temporary folder and the system **share sheet** opens.
  You decide where the file goes (Files, Drive, email, …); from then on it is subject to that
  app's or service's terms. The file is not encrypted — keep it somewhere safe.
- **Import** (**Settings → Restore**) reads a file you pick, on the device.

## 6. What we do not use

Accounts or cloud sync · advertising, advertising IDs or tracking · analytics or crash reporting
services · contacts, camera, microphone or photos · in-app purchases. If any of these is added,
this policy will be updated before the release that adds it.

## 7. Children

The app is intended for a general audience and does not knowingly collect personal data from
children; no personal data leaves the device except as described in section 4.

## 8. Your rights

Because your data stays on your device, you exercise access, correction and deletion rights (e.g.
under GDPR) directly in the app: edit, delete, export or reset. We hold no data about you. For data
reaching OpenStreetMap or Google, see their policies. Questions: `<iletişim e-postası>`

## 9. Changes

Updates are published at the same address with a new "Last updated" date; significant changes are
also mentioned in the release notes.

---

## Hosting (to do before submission, not enabled)

Recommended: **GitHub Pages** (free for this public repo) — *Settings → Pages → Deploy from a
branch → `master` / `/docs`*. The URL would likely be
`https://burakaydogmus.github.io/reminder-android-app/store/privacy-policy.en.html` (*to be
verified* after the first deploy). Then add the URL to Play Console, App Store Connect and an
in-app link in Settings (not implemented yet).
