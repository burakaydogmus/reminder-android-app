import 'package:reminder/services/contacts_service.dart';

/// In-memory [ContactsPlatform] for tests (the same role
/// `FakeDeviceCalendarPlatform` plays for `device_calendar_plus`): the real
/// plugin has no implementation on the test host, so every path — granted,
/// denied, revoked mid-read, no birthdays at all — is only reachable through
/// this fake.
class FakeContactsPlatform implements ContactsPlatform {
  FakeContactsPlatform({this.contactBirthdays = const []});

  /// What the fake address book returns. Like the real seam, this list only
  /// ever contains contacts that **have** a birthday.
  List<ContactBirthday> contactBirthdays;

  /// When set, the next [birthdays] call throws it (permission revoked between
  /// the check and the read, or a provider error).
  ContactsReadException? failure;

  /// Recorded calls, so tests can assert the address book is read once.
  int reads = 0;

  @override
  Future<List<ContactBirthday>> birthdays() async {
    reads++;
    final error = failure;
    if (error != null) throw error;
    return List.of(contactBirthdays);
  }
}

/// Builds a [ContactBirthday]; [year] defaults to `null`, the common case.
ContactBirthday buildContactBirthday({
  String name = 'Ayşe Yılmaz',
  int month = 9,
  int day = 14,
  int? year,
}) =>
    ContactBirthday(name: name, month: month, day: day, year: year);
