import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/text_search.dart';
import 'package:reminder/services/contacts_service.dart';

/// One row of the "Rehberden aktar" list (F7.3): a contact birthday plus
/// whether the app already has it.
class ContactImportCandidate {
  const ContactImportCandidate({
    required this.contact,
    required this.alreadyAdded,
  });

  final ContactBirthday contact;

  /// `true` when a stored birthday has the same folded name and the same
  /// month/day. Such a row is **shown** (as "zaten ekli") but never
  /// preselected, so the user sees why nothing happened instead of wondering
  /// where the contact went.
  final bool alreadyAdded;

  /// Stable row key: the dedupe key, which is unique within one candidate list.
  String get key => ContactBirthdayImport.dedupeKey(
        contact.name,
        contact.month,
        contact.day,
      );

  @override
  bool operator ==(Object other) =>
      other is ContactImportCandidate &&
      other.contact == contact &&
      other.alreadyAdded == alreadyAdded;

  @override
  int get hashCode => Object.hash(contact, alreadyAdded);

  @override
  String toString() =>
      'ContactImportCandidate($contact, alreadyAdded: $alreadyAdded)';
}

/// What one import run did, for the result summary (F7.3).
class ContactImportResult {
  const ContactImportResult({
    required this.imported,
    required this.skipped,
  });

  const ContactImportResult.empty()
      : imported = const [],
        skipped = const [];

  /// Names that were added, in list order.
  final List<String> imported;

  /// Names that were left out because the app already had that birthday.
  final List<String> skipped;

  int get importedCount => imported.length;
  int get skippedCount => skipped.length;
  bool get isEmpty => imported.isEmpty && skipped.isEmpty;
}

/// Pure rules for importing birthdays from the address book (F7.3).
///
/// Everything date- or name-related lives here so it can be unit tested
/// without a plugin, a widget or a database.
abstract final class ContactBirthdayImport {
  /// Comparison key for the duplicate check: the folded name
  /// ([TextSearch.foldName] — trimmed, whitespace collapsed, Turkish
  /// case/diacritic insensitive, so `İLKAY`, `ilkay` and `Ilkay` match) plus
  /// the month and day. The **year is deliberately not part of the key**: the
  /// same person hand-entered without a year and stored in the address book
  /// with one is still the same birthday.
  static String dedupeKey(String name, int month, int day) =>
      '${TextSearch.foldName(name)}|$month|$day';

  static String keyOf(Birthday birthday) =>
      dedupeKey(birthday.name, birthday.month, birthday.day);

  /// The rows to show, sorted by folded name (then month/day), with duplicates
  /// **inside** the contact list collapsed — two address book entries for the
  /// same name and date are one row.
  ///
  /// A contact whose name is blank after trimming is dropped; the platform
  /// seam already filters contacts without a birthday.
  static List<ContactImportCandidate> candidates({
    required List<ContactBirthday> contacts,
    required List<Birthday> existing,
  }) {
    final stored = {for (final b in existing) keyOf(b)};
    final seen = <String>{};
    final rows = <ContactImportCandidate>[];
    for (final contact in contacts) {
      if (contact.name.trim().isEmpty) continue;
      final key = dedupeKey(contact.name, contact.month, contact.day);
      if (!seen.add(key)) continue;
      rows.add(
        ContactImportCandidate(
          contact: contact,
          alreadyAdded: stored.contains(key),
        ),
      );
    }
    rows.sort((a, b) {
      final byName = TextSearch.foldName(a.contact.name)
          .compareTo(TextSearch.foldName(b.contact.name));
      if (byName != 0) return byName;
      final byMonth = a.contact.month.compareTo(b.contact.month);
      return byMonth != 0 ? byMonth : a.contact.day.compareTo(b.contact.day);
    });
    return List.unmodifiable(rows);
  }

  /// Keys that may be selected: every row that is not already added.
  static Set<String> selectableKeys(List<ContactImportCandidate> rows) => {
        for (final row in rows)
          if (!row.alreadyAdded) row.key,
      };

  /// The [Birthday] for an imported contact.
  ///
  /// Only the name and the date travel; [ContactBirthday.year] stays `null`
  /// when the contact has no year (**never** the pre-v6 sentinel). Notification
  /// time and advance offsets are left at the model defaults — the same ones
  /// the manual editor starts from (09:00, on the day + one day before) — so an
  /// imported birthday behaves exactly like a typed one.
  static Birthday toBirthday(
    ContactBirthday contact, {
    required String id,
    required DateTime createdAt,
  }) {
    return Birthday(
      id: id,
      name: contact.name.trim(),
      month: contact.month,
      day: contact.day,
      year: contact.year,
      createdAt: createdAt,
    );
  }

  /// The birthdays to add for [selectedKeys], plus the summary of the run.
  ///
  /// [newId] is called once per imported birthday (the caller passes
  /// `Uuid().v4`), so this stays pure and testable. Rows that are already added
  /// land in [ContactImportResult.skipped] whether or not they were selected.
  static (List<Birthday>, ContactImportResult) plan({
    required List<ContactImportCandidate> rows,
    required Set<String> selectedKeys,
    required String Function() newId,
    required DateTime createdAt,
  }) {
    final birthdays = <Birthday>[];
    final imported = <String>[];
    final skipped = <String>[];
    for (final row in rows) {
      if (row.alreadyAdded) {
        skipped.add(row.contact.name);
        continue;
      }
      if (!selectedKeys.contains(row.key)) continue;
      birthdays.add(
        toBirthday(row.contact, id: newId(), createdAt: createdAt),
      );
      imported.add(row.contact.name);
    }
    return (
      List.unmodifiable(birthdays),
      ContactImportResult(
        imported: List.unmodifiable(imported),
        skipped: List.unmodifiable(skipped),
      ),
    );
  }
}
