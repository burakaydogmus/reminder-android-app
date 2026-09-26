import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

/// One birthday found in the device's address book (F7.3).
///
/// Deliberately **narrow**: the name and the date are the only things the app
/// ever takes out of a contact. No contact id, no photo, no phone number, no
/// e-mail — nothing that would let an imported birthday be traced back to (or
/// re-synced with) the address book entry. See CLAUDE.md › Contacts import.
@immutable
class ContactBirthday {
  const ContactBirthday({
    required this.name,
    required this.month,
    required this.day,
    this.year,
  });

  /// The contact's display name, already trimmed.
  final String name;

  /// Birth month (1–12).
  final int month;

  /// Day of the month (1–31).
  final int day;

  /// Birth year, or `null` when the contact stores a birthday **without** a
  /// year — the common case in both address books. It is imported as
  /// `Birthday.year == null`, never as a sentinel (F6.4, schema v6).
  final int? year;

  bool get hasYear => year != null;

  @override
  bool operator ==(Object other) =>
      other is ContactBirthday &&
      other.name == name &&
      other.month == month &&
      other.day == day &&
      other.year == year;

  @override
  int get hashCode => Object.hash(name, month, day, year);

  @override
  String toString() => 'ContactBirthday($name, $day.$month, year: $year)';
}

/// Why reading the address book failed (F7.3). Everything the platform can
/// throw collapses into one of these; the UI only distinguishes
/// [permissionDenied] (explain and offer the Settings deep link) from the rest
/// (say the address book cannot be read right now).
enum ContactsFailure { permissionDenied, unavailable }

/// A contacts read that could not be completed.
class ContactsReadException implements Exception {
  const ContactsReadException(this.failure, [this.message]);

  final ContactsFailure failure;
  final String? message;

  @override
  String toString() => 'ContactsReadException($failure, $message)';
}

/// The **only** seam over `flutter_contacts` (the same role
/// `DeviceCalendarPlatform` plays for `device_calendar_plus`): tests pass a
/// fake, so every path is exercised on the test host where no plugin exists.
///
/// Read-only by contract — there is a single method and it reads. No code path
/// can create, change or delete a contact.
abstract class ContactsPlatform {
  /// Every contact that has a birthday, reduced to name + date.
  ///
  /// Contacts without a birthday are filtered out by the implementation, so the
  /// caller never sees them. Throws [ContactsReadException].
  Future<List<ContactBirthday>> birthdays();
}

/// [ContactsPlatform] over `flutter_contacts`.
///
/// Only `getAll` is used, and only with [fc.ContactProperty.event] — id and
/// display name always come back, every other property (phones, e-mails,
/// photos, notes, addresses) is left unfetched. The plugin's own permission
/// API (`FlutterContacts.permissions`) is **not** used: permission goes
/// through `PermissionService.requestContacts` like every other permission in
/// this app, so the Android manifest can stay `READ_CONTACTS`-only.
class PluginContactsPlatform implements ContactsPlatform {
  const PluginContactsPlatform();

  @override
  Future<List<ContactBirthday>> birthdays() async {
    final List<fc.Contact> contacts;
    try {
      contacts = await fc.FlutterContacts.getAll(
        properties: const {fc.ContactProperty.event},
      );
    } on Object catch (error) {
      throw _translate(error);
    }
    final found = <ContactBirthday>[];
    for (final contact in contacts) {
      final birthday = birthdayOf(contact);
      if (birthday != null) found.add(birthday);
    }
    return found;
  }

  /// The contact's birthday, or `null` when it has none, its name is empty or
  /// the stored date is not a real calendar date.
  ///
  /// A contact may carry several events (Android allows it); only the **first**
  /// one labelled `birthday` counts, and anniversaries or custom events are
  /// ignored.
  @visibleForTesting
  static ContactBirthday? birthdayOf(fc.Contact contact) {
    final name = contact.displayName?.trim() ?? '';
    if (name.isEmpty) return null;
    for (final event in contact.events) {
      if (event.label.label != fc.EventLabel.birthday) continue;
      return validBirthday(
        name: name,
        month: event.month,
        day: event.day,
        year: event.year,
      );
    }
    return null;
  }

  /// Validates a raw contact date. Providers do store nonsense (month 0, day
  /// 31 in February, a year in the future), and an invalid month/day would
  /// break `Birthday.occurrenceInYear`, so such a row is dropped instead of
  /// imported.
  @visibleForTesting
  static ContactBirthday? validBirthday({
    required String name,
    required int month,
    required int day,
    int? year,
  }) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    // Feb 29 must stay importable (Birthday handles non-leap years), so the
    // day is checked against a leap year's month length.
    if (day > _daysInLeapMonth[month - 1]) return null;
    // A year the app cannot compute an age from (year 0/negative, the pre-v6
    // sentinel 4, or the future) is dropped to `null` rather than stored: the
    // birthday still imports, just without an age.
    final keep = (year != null && year > 1000 && year <= _thisYear()) ? year : null;
    return ContactBirthday(name: name, month: month, day: day, year: keep);
  }

  static const _daysInLeapMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static int _thisYear() => DateTime.now().year;

  /// A missing runtime permission is the one failure the UI reacts to; a
  /// `MissingPluginException` (no implementation on the host), a provider error
  /// or anything else stays [ContactsFailure.unavailable].
  static ContactsReadException _translate(Object error) {
    if (_looksLikePermissionDenial(error)) {
      return ContactsReadException(
        ContactsFailure.permissionDenied,
        error.toString(),
      );
    }
    return ContactsReadException(
      ContactsFailure.unavailable,
      error.toString(),
    );
  }

  /// Android throws `SecurityException` through the channel when
  /// `READ_CONTACTS` is missing and iOS a `CNErrorDomain` authorization error.
  /// The plugin does not map either to a code of its own, so the message is all
  /// there is to go on — hence the tolerant match.
  static bool _looksLikePermissionDenial(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('securityexception') ||
        text.contains('permission') ||
        text.contains('denied') ||
        text.contains('not authorized') ||
        text.contains('authorization');
  }
}
