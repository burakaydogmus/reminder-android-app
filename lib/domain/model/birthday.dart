import 'package:reminder/domain/notification_ids.dart';

/// Yıllık tekrarlayan doğum günü hatırlatıcısı.
///
/// [date] orijinal tarihtir (yaş hesabı için yıl bilgisi de saklanır), ancak
/// bildirim yıllık olarak `date.month/date.day` kombinasyonunda tetiklenir.
/// [advanceOffsetsMinutes] hatırlatmanın doğum gününden kaç dakika önce
/// gönderileceğini belirtir (0 = doğum gününde, 1440 = 1 gün önce, vs.).
class Birthday {
  final String id;
  final String name;
  final String? note;
  final DateTime date;
  final int notifyHour;
  final int notifyMinute;
  final List<int> advanceOffsetsMinutes;
  final DateTime createdAt;

  const Birthday({
    required this.id,
    required this.name,
    this.note,
    required this.date,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.advanceOffsetsMinutes = const <int>[0, 1440],
    required this.createdAt,
  });

  /// [offsetMinutes] önbildirimi için kararlı kimlik; FNV-1a
  /// (`birthday:<id>:<offsetMinutes>`), bkz. [NotificationIds].
  int notificationIdFor(int offsetMinutes) =>
      NotificationIds.birthdayNotificationId(id, offsetMinutes);

  /// [year] yılındaki doğum günü (bildirim saatiyle).
  ///
  /// 29 Şubat doğumlular artık yıl olmayan yıllarda **28 Şubat**'ta
  /// kutlanır; `DateTime(year, 2, 29)` bu yıllarda 1 Mart'a taşardı.
  DateTime occurrenceInYear(int year) {
    final day = (date.month == DateTime.february &&
            date.day == 29 &&
            !_isLeapYear(year))
        ? 28
        : date.day;
    return DateTime(year, date.month, day, notifyHour, notifyMinute);
  }

  static bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Bugünden sonraki ilk doğum günü tarihi (geçtiyse gelecek yıl).
  /// Bildirim saatini içerir.
  DateTime nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    final candidate = occurrenceInYear(now.year);
    if (candidate.isAfter(now)) return candidate;
    return occurrenceInYear(now.year + 1);
  }

  /// Bir sonraki doğum günü için dolacak yaş (yıl bilgisi makulse).
  int? get upcomingAge => upcomingAgeFrom();

  /// [upcomingAge]'in saati verilebilen hali ([from] yoksa şimdi).
  int? upcomingAgeFrom({DateTime? from}) {
    final next = nextOccurrence(from: from);
    final age = next.year - date.year;
    if (age <= 0) return null;
    return age;
  }

  /// Bir sonraki doğum gününe kalan tam gün sayısı.
  int daysUntilNext({DateTime? from}) {
    final now = from ?? DateTime.now();
    final next = nextOccurrence(from: now);
    final today = DateTime(now.year, now.month, now.day);
    final nextDate = DateTime(next.year, next.month, next.day);
    return nextDate.difference(today).inDays;
  }

  /// Nullable alanlar `T? Function()?` olarak alınır (bkz. `Reminder.copyWith`);
  /// böylece not açıkça temizlenebilir: `b.copyWith(note: () => null)`.
  /// Parametre verilmezse mevcut değer korunur.
  Birthday copyWith({
    String? id,
    String? name,
    String? Function()? note,
    DateTime? date,
    int? notifyHour,
    int? notifyMinute,
    List<int>? advanceOffsetsMinutes,
    DateTime? createdAt,
  }) {
    return Birthday(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note != null ? note() : this.note,
      date: date ?? this.date,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      advanceOffsetsMinutes:
          advanceOffsetsMinutes ?? this.advanceOffsetsMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'date': date.toIso8601String(),
        'notifyHour': notifyHour,
        'notifyMinute': notifyMinute,
        'advanceOffsetsMinutes': advanceOffsetsMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Birthday.fromJson(Map<String, dynamic> json) {
    final offsetsRaw = json['advanceOffsetsMinutes'];
    final offsets = (offsetsRaw is List)
        ? offsetsRaw.map((e) => (e as num).toInt()).toList(growable: false)
        : const <int>[0, 1440];
    return Birthday(
      id: json['id'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      notifyHour: (json['notifyHour'] as num?)?.toInt() ?? 9,
      notifyMinute: (json['notifyMinute'] as num?)?.toInt() ?? 0,
      advanceOffsetsMinutes: offsets,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Editör ekranında kullanılan standart önbildirim seçenekleri.
class BirthdayAdvanceOffset {
  final int minutes;
  final String label;

  const BirthdayAdvanceOffset(this.minutes, this.label);

  static const List<BirthdayAdvanceOffset> presets = <BirthdayAdvanceOffset>[
    BirthdayAdvanceOffset(0, 'Doğum gününde'),
    BirthdayAdvanceOffset(60, '1 saat önce'),
    BirthdayAdvanceOffset(180, '3 saat önce'),
    BirthdayAdvanceOffset(1440, '1 gün önce'),
    BirthdayAdvanceOffset(4320, '3 gün önce'),
    BirthdayAdvanceOffset(10080, '1 hafta önce'),
  ];
}
