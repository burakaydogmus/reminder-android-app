ROADMAP **F7.3** — import birthdays from the device's contacts. Read-only and one-shot: Doğum günleri › **"Rehberden aktar"** reads the address book once, lists the contacts that have a birthday, and adds the selected ones as ordinary birthdays. Nothing is ever written to contacts, there is no background sync, and nothing beyond the name and the date is taken.

The item **moves from Faz 7 (bulut) to Faz 8 (entegrasyonlar)** — contacts are device data, exactly like F8.1's calendar. The number stays `F7.3` because the branch, the commits and this PR already use it.

## Plugin vetting

Facts from pub.dev's API (`/api/packages/<name>`, `/score`), read 26 Sep 2026:

| | `flutter_contacts` **(chosen)** | `fast_contacts` (rejected) |
|---|---|---|
| Latest / 1.0+ | **2.5.0** — yes | 6.0.0 — yes |
| Publisher | **quis.co** (verified) | sonerik.dev (verified) |
| Downloads / 30 days | **287,570** | 60,451 |
| Pub points | **160 / 160** | 150 / 160 |
| Likes | 500 | 120 |
| Last publish | **2026-09-10** (16 days ago) | 2026-06-24 |
| Dart dependencies | **none** (only the Flutter SDK) | none |
| Android | `namespace co.quis.flutter_contacts`, `compileSdk 36`, `minSdk 24`, JVM 17, `is:built-in-kotlin`, **empty `AndroidManifest.xml` — declares no permissions of its own** | `compileSdk`/Kotlin fine |
| iOS | `platform :ios, '13.0'`, Swift, ships `PrivacyInfo.xcprivacy` | iOS ok |
| Resolves here? | **yes** — `flutter pub get` on Flutter 3.47.4 / Dart 3.13.3 reports *"Changed 1 dependency!"*: no transitive packages at all, so nothing can clash with our `timezone ^0.11.1` (the reason F8.1 had to drop `device_calendar`) or `intl ^0.20.3` | yes |
| Can it read a birthday? | **yes** — `Contact.events` with `Event.year` **nullable**, which is precisely what a year-less contact birthday needs | **no** |

`fast_contacts` was rejected on **capability, not health**: its `Contact` is `{id, phones, emails, structuredName, organization}` — there is no events/birthday field anywhere in the package, so it cannot implement this feature at all. Two other candidates were checked and dropped: `contacts_service` 0.6.3 (last published 2021, `sdk: <3.0.0`) and `flutter_contacts_service` 0.2.0 (606 downloads/30 days, 12 likes — too obscure).

`flutter_contacts` is 2.x, so the constraint is `^2.5.0` (major pinned, the normal 1.0+ rule) rather than F8.1's minor pin.

## Platform configuration

- **Android:** `READ_CONTACTS` **only**, with the same style of comment the `READ_CALENDAR` line carries. `WRITE_CONTACTS` is deliberately absent — nothing writes, and `permission_handler` only asks for the contacts permissions declared in the manifest (`PermissionUtils.getManifestNames`), so the runtime request is a read-only one. The plugin's own Android manifest is empty, so nothing leaks into the merged manifest either (a verification row was added to `permissions-review.md` §8 for plugin upgrades).
- **iOS keys added:** `NSContactsUsageDescription` in `ios/Runner/Info.plist` **plus** localized copies in `ios/Runner/tr.lproj/InfoPlist.strings` and `ios/Runner/en.lproj/InfoPlist.strings`. That is the only key contacts has — unlike EventKit there is no read-only/full-access split to reason about. The Podfile adds `PERMISSION_CONTACTS=1` (permission_handler compiles every permission out by default). iOS 18 *limited* access counts as granted: the OS then hands over the contacts the user picked, which is all the import needs.
- The plugin's own `FlutterContacts.permissions` API is **not** used; permission goes through `PermissionService.requestContacts` like every other permission here, which is what keeps the manifest read-only.

## Play restricted-permission research (`permissions-review.md` §10)

Contacts is **not** on Play's current restricted-permission list (checked 26 Sep 2026), so **no declaration form is needed today**. But the research turned up something the coordinator should know:

> Google announced a **Contacts Permissions** policy in April 2026 that becomes **mandatory on 27 January 2027** for apps that **target Android 17 (API 37+)**. Those apps may only request `READ_CONTACTS` when the new Android Contact Picker (`Intent.ACTION_PICK_CONTACTS`, API 37+ only) is insufficient, and must justify that in a Play Console declaration (11 predefined use cases; *User-initiated Selection* is the closest fit here).

This app targets **36**, so it is **out of scope for now**. When Play's target-API requirement forces 37, the declaration becomes mandatory — it is filed as `permissions-review.md` §8 row 16 (**Yüksek, tarihli**) so it is picked up with that upgrade. Switching to the Contact Picker instead would break the feature: the system picker does not reveal *which* contacts have a birthday and has no bulk "all contacts with a birthday" selection, which is the entire value.

## Design

- **Seam:** `ContactsPlatform` (`lib/services/contacts_service.dart`) is the only place that touches the plugin — the role `DeviceCalendarPlatform` plays for `device_calendar_plus`. It has **one method** (`birthdays()`), so no code path can create or change a contact. `getAll` is called with `ContactProperty.event` **only**, so phones, e-mails, addresses, organizations, notes and photos are never fetched; the unavoidable contact id is dropped at the seam. `ContactBirthday` is name + month + day + optional year and nothing else.
- **Year-less is the normal case:** `Event.year == null` imports as `Birthday.year == null` — never the pre-v6 sentinel. **No schema change**: birthdays have stored a nullable year since v6 / #44, so `lib/data/db/**` is untouched (F9 routines owns it).
- **Dedupe** (`lib/domain/contact_birthday_import.dart`, pure): `TextSearch.foldName(name)` + month + day. `foldName` is a new shared helper on the existing `TextSearch` (trim, collapse whitespace, Turkish case/diacritic fold — `İLKAY` = `ilkay` = `Ilkay`); `CategoryNames.fold` now delegates to it instead of duplicating the same three operations. **The year is not part of the key**: the same person typed without a year and stored with one is the same birthday. A duplicate row is **shown as "zaten ekli", unselected and disabled** — never silently dropped — and "Tümünü seç" cannot pick it up. Duplicates *within* the address book collapse too (first spelling wins).
- **Defaults:** imported birthdays get the model defaults for notification time and offsets (09:00, `[0, 1440]`) — the same ones the manual editor starts from, not a new set — and the existing `PermissionFlows.beforeScheduling` runs before the import, exactly as saving a birthday by hand does.
- **Nothing is preselected.** A first run on a large address book would otherwise flood the list on one tap; `Tümünü seç (N)` makes the bulk case one tap anyway and the import button stays disabled at zero.
- **Result summary:** after the import the sheet switches to a summary step listing what was added and what was already there, and a snackbar repeats the counts on close — so "what just happened" is answerable after the fact.
- **Graceful degradation:** a refused permission, or one revoked between the check and the read, shows the explanation plus `[Ayarları aç]`; coming back granted re-reads in place. A non-permission failure says the address book cannot be read right now. An **already denied** permission returns from `PermissionFlows.contacts` immediately instead of bouncing the user into system settings just for opening the sheet. The action never looks broken and birthdays can always be typed by hand.
- **No Settings › İzinler row for contacts** — a deliberate call, documented in CLAUDE.md. The permission is one-shot and backs no ongoing capability, so a permanent "Rehber — izin gerekiyor" line would advertise a feature that is not there. The precedent is right next door: the calendar row is rendered only while the calendar feature is on.

## Tests

**2508 → 2577 (+69), all green.**

Following F8.1's structure, `FakeContactsPlatform` (`test/services/fake_contacts_platform.dart`) makes every path reachable on the test host:

- permission granted / refused at the prompt / already denied (no second prompt) / revoked between the check and the read / a non-permission read failure, and the "denied → Ayarları aç → granted → reads" round trip;
- contacts without a birthday filtered out (including anniversary, other and custom events), blank/missing display names dropped, impossible dates dropped (month 0/13, 30 February, 31 April) with 29 February kept, an implausible year cleared to `null` while the date still imports;
- year-less vs year-known import, and that the imported record carries the app's default time and offsets;
- duplicate detection with Turkish `İ`/`ı` folding, whitespace collapsing, year-independence, in-list collapsing, and that a duplicate cannot be imported even when its key is selected;
- select all / clear selection, the disabled import button at zero, the empty state ("Rehberde doğum günü yok"), the result summary and its snackbar, and the English variants of all of it;
- **a11y audits** for the list, summary and refused stages — text scale 1.0 and 2.0, both languages, light and dark.

## Notes for the coordinator

- **No bulk cubit API.** The sheet calls `ReminderCubit.addBirthday` once per imported birthday (N persists + N diff syncs), because the parallel F9 routines branch owns `lib/bloc/**`. An `addBirthdays` bulk method is the obvious follow-up once that branch lands — worth a look if a large first import feels slow on device.
- `lib/domain/model/reminder_category.dart` has a one-line change: `CategoryNames.fold` delegates to the new `TextSearch.foldName` (same behaviour, covered by the existing category tests).
- **Device testing is still owed** (`permissions-review.md` §8 row 18): the permission flow on Android 14+ and iOS, including iOS 18 *limited* access, cannot be verified from Windows.
- The Android and iOS build jobs both run here (`pubspec.yaml`, `android/**` and `ios/**` all changed), so this PR is also the compile proof for the new plugin.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
