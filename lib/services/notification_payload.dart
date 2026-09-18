/// Bir bildirimin hangi kayda ait olduğunu taşıyan payload (F3.2).
///
/// Biçim: `reminder:<id>` (zamanlı ve konum hatırlatıcıları) veya
/// `birthday:<id>`. F3.2 öncesi konum bildirimleri yalnızca ham hatırlatıcı
/// id'si taşıdığı için önekisiz, boş olmayan bir değer hatırlatıcı id'si
/// sayılır.
sealed class NotificationPayload {
  const NotificationPayload();

  static const _reminderPrefix = 'reminder:';
  static const _birthdayPrefix = 'birthday:';

  /// [raw] payload'ını çözer; boş veya eksik id için `null`.
  static NotificationPayload? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith(_birthdayPrefix)) {
      final id = raw.substring(_birthdayPrefix.length);
      return id.isEmpty ? null : BirthdayPayload(id);
    }
    if (raw.startsWith(_reminderPrefix)) {
      final id = raw.substring(_reminderPrefix.length);
      return id.isEmpty ? null : ReminderPayload(id);
    }
    return ReminderPayload(raw);
  }

  /// Bildirime yazılacak dize.
  String encode();
}

/// Bir hatırlatıcının bildirimi.
final class ReminderPayload extends NotificationPayload {
  const ReminderPayload(this.reminderId);

  final String reminderId;

  @override
  String encode() => '${NotificationPayload._reminderPrefix}$reminderId';

  @override
  bool operator ==(Object other) =>
      other is ReminderPayload && other.reminderId == reminderId;

  @override
  int get hashCode => Object.hash(ReminderPayload, reminderId);

  @override
  String toString() => 'ReminderPayload($reminderId)';
}

/// Bir doğum gününün bildirimi.
final class BirthdayPayload extends NotificationPayload {
  const BirthdayPayload(this.birthdayId);

  final String birthdayId;

  @override
  String encode() => '${NotificationPayload._birthdayPrefix}$birthdayId';

  @override
  bool operator ==(Object other) =>
      other is BirthdayPayload && other.birthdayId == birthdayId;

  @override
  int get hashCode => Object.hash(BirthdayPayload, birthdayId);

  @override
  String toString() => 'BirthdayPayload($birthdayId)';
}
