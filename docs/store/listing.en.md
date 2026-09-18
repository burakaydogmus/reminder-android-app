# Store listing draft — English

Based on the code as of 18 September 2026 (recurring reminders F3.1 and notification actions F3.2
included). Only features that work **today** are listed; not yet built: natural-language quick
capture (F4.6), iOS widget (F5.2), timeline strip (F3.6). Note: the app UI is Turkish-only until F6.1
(localization) — publish the English listing only after F6.1, or state "Turkish interface" clearly.

Limits: Play title 30, short description 80, full description 4000; App Store name and subtitle
30, keywords 100 (bytes per App Store Connect help). Sources as in [`listing.tr.md`](listing.tr.md). Lengths below
were measured by script on 18 September 2026 (characters = Unicode code points, bytes = UTF-8).

## App name options (≤ 30)

| Option | Length |
|---|---|
| Kor: Reminders | 14 |
| Kor – Reminders & Birthdays | 27 |
| Hatırlatıcı: Time & Place | 25 |
| Kor: Remind by Time & Place | 27 |

**Suggestion:** "Kor: Reminders". App Store subtitle (≤ 30): **"On time, in the right place"** (27).

## Short description (Play, ≤ 80)

> Reminders by time or place, yearly birthdays. Your data stays on your device.

(77 characters; the earlier draft "… yearly birthdays and lists. Your data stays on device." was 82.)

## Full description (≤ 4000)

```text
Don't keep it in your head. Write it down, pick a time or a place, and let the app remember.

TODAY AT A GLANCE
The Today screen groups your tasks into overdue, today, anytime and done. Calendar shows the next 30 days with reminders and birthdays. Lists lets you filter by category.

REMIND ME AT A TIME
Add a date and time and get a notification when it's due. Pick a time that has already passed and the app tells you instead of silently changing it, and suggests the same time tomorrow.

REMIND ME WHEN I ARRIVE
Choose a place on the map and set a radius. You get a notification when you arrive, even when the app is closed.

NEVER MISS A BIRTHDAY
Add a birthday once and get reminded every year, optionally a day or a week in advance. Feb 29 birthdays included.

REPEAT IT
Every day, on chosen weekdays, every month or every few days, with an optional end date. Complete a repeating reminder and it moves on to the next time.

DONE FROM THE NOTIFICATION
Use the notification buttons to complete a reminder or snooze it for 10 minutes or an hour without opening the app.

SWIPE, DONE, UNDO
Swipe right to complete, left to snooze or delete. Changed your mind? Undo is one tap away. Every action is also in the long-press menu and available to screen readers.

CATEGORIES
Groceries, home, work, health, daily chores and a custom "Other", each with its own colour and icon.

HOME SCREEN WIDGET (ANDROID)
Keep upcoming reminders on your home screen and tick them off without opening the app.

BACK UP AND MOVE
Export everything to a single file and save it wherever you like. Restore by merging or replacing.

CALM, WARM DESIGN
The "Kor" design: warm neutrals and a single ember-orange accent for what needs attention. Light and dark themes, large text and screen reader support, respects Reduce Motion.

EASY FROM DAY ONE
A short intro shows you around. Permissions are never requested all at once at launch — only when needed, with an explanation.

PRIVACY: YOUR DATA STAYS ON YOUR DEVICE
No account, no ads, no analytics. Your reminders, birthdays and location never leave your device. The internet is used only to load map images from OpenStreetMap.

Map data © OpenStreetMap contributors.
```

Length: 2,193 characters (limit 4000). Remove the widget section for iOS.

## App Store promotional text (≤ 170)

> Reminders by time or place, and birthdays every year. No account, no ads — your data stays on your device.

(106 characters)

## Keywords (App Store, ≤ 100)

```text
to do,todo list,task,grocery,shopping list,birthday,location,geofence,notification,agenda,planner
```

(97 characters = 97 bytes, ASCII only; words already in the name/subtitle are not repeated.)

## Screenshot plan

Same set as [`listing.tr.md`](listing.tr.md#ekran-görüntüsü-planı), light and dark, with English
captions — only after F6.1 so the UI in the screenshots is English:

1. Today at a glance · 2. Remind me at a time · 3. Remind me when I arrive · 4. The next 30 days ·
5. Never miss a birthday · 6. Swipe, done, undo · 7. On your home screen (Play only) ·
8. Back up and move · 9. Don't keep it in your head (onboarding)

## Content rating

- **Play (IARC):** utility/productivity; no user interaction, no shared user content, no location
  sharing with other users, no purchases, no ads → expected **Everyone / PEGI 3** (*to be verified*
  by the questionnaire result).
- **App Store:** all content questions "None", no unrestricted web access → expected **4+**.
- Not designed for children (not in Designed for Families); no ads; not a news, health or finance app.

## Category

- **Google Play:** Productivity
- **App Store:** Productivity (primary), Lifestyle (secondary)
