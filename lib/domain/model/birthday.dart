import 'package:reminder/domain/notification_ids.dart';

/// Yıllık tekrarlayan doğum günü hatırlatıcısı.
///
/// Tarih **gün/ay + isteğe bağlı yıl** olarak tutulur: [month] ve [day] her
/// zaman doludur, [year] bilinmiyorsa `null`'dır (F6.4, şema v6). Bildirim
/// yıllık olarak [month]/[day] kombinasyonunda tetiklenir; [year] yalnızca
/// yaş hesabında kullanılır ([hasYear] `false` ise yaş gösterilmez).
///
/// v6 öncesinde yılsız doğum günleri [legacyUnknownYear] (4) nöbetçi yılıyla
/// saklanırdı; bkz. [fromJson] ve `AppDatabase` v5 → v6 geçişi.
///
/// [advanceOffsetsMinutes] hatırlatmanın doğum gününden kaç dakika önce
/// gönderileceğini belirtir (0 = doğum gününde, 1440 = 1 gün önce, vs.).
class Birthday {
  final String id;
  final String name;
  final String? note;

  /// Doğum ayı (1–12).
  final int month;

  /// Ayın günü (1–31).
  final int day;

  /// Doğum yılı; **bilinmiyorsa `null`** (yaş hesaplanmaz).
  final int? year;

  final int notifyHour;
  final int notifyMinute;
  final List<int> advanceOffsetsMinutes;
  final DateTime createdAt;

  const Birthday({
    required this.id,
    required this.name,
    this.note,
    required this.month,
    required this.day,
    this.year,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.advanceOffsetsMinutes = const <int>[0, 1440],
    required this.createdAt,
  });

  /// Takvim tarihinden üretir; [yearKnown] `false` ise yıl atılır.
  factory Birthday.onDate({
    required String id,
    required String name,
    String? note,
    required DateTime date,
    bool yearKnown = true,
    int notifyHour = 9,
    int notifyMinute = 0,
    List<int> advanceOffsetsMinutes = const <int>[0, 1440],
    required DateTime createdAt,
  }) {
    return Birthday(
      id: id,
      name: name,
      note: note,
      month: date.month,
      day: date.day,
      year: yearKnown ? date.year : null,
      notifyHour: notifyHour,
      notifyMinute: notifyMinute,
      advanceOffsetsMinutes: advanceOffsetsMinutes,
      createdAt: createdAt,
    );
  }

  /// v6 öncesi depolama/yedeklerde yılsız doğum günü için kullanılan nöbetçi
  /// yıl (F4.4). Artık yazılmaz; yalnızca eski kayıtları okurken ve
  /// [toJson]'ın geriye dönük `date` alanında görünür.
  static const int legacyUnknownYear = 4;

  /// Doğum yılı biliniyor mu (bilinmiyorsa yaş hesaplanmaz).
  bool get hasYear => year != null;

  /// Yıl biliniyorsa tam doğum tarihi, bilinmiyorsa `null`.
  DateTime? get birthDate => year == null ? null : DateTime(year!, month, day);

  /// [offsetMinutes] önbildirimi için kararlı kimlik; FNV-1a
  /// (`birthday:<id>:<offsetMinutes>`), bkz. [NotificationIds].
  int notificationIdFor(int offsetMinutes) =>
      NotificationIds.birthdayNotificationId(id, offsetMinutes);

  /// [inYear] yılındaki doğum günü (bildirim saatiyle).
  ///
  /// 29 Şubat doğumlular artık yıl olmayan yıllarda **28 Şubat**'ta
  /// kutlanır; `DateTime(inYear, 2, 29)` bu yıllarda 1 Mart'a taşardı.
  DateTime occurrenceInYear(int inYear) {
    final d = (month == DateTime.february && day == 29 && !_isLeapYear(inYear))
        ? 28
        : day;
    return DateTime(inYear, month, d, notifyHour, notifyMinute);
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
    final birthYear = year;
    if (birthYear == null) return null;
    final next = nextOccurrence(from: from);
    final age = next.year - birthYear;
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
  /// böylece not ve yıl açıkça temizlenebilir: `b.copyWith(year: () => null)`.
  /// Parametre verilmezse mevcut değer korunur.
  Birthday copyWith({
    String? id,
    String? name,
    String? Function()? note,
    int? month,
    int? day,
    int? Function()? year,
    int? notifyHour,
    int? notifyMinute,
    List<int>? advanceOffsetsMinutes,
    DateTime? createdAt,
  }) {
    return Birthday(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note != null ? note() : this.note,
      month: month ?? this.month,
      day: day ?? this.day,
      year: year != null ? year() : this.year,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      advanceOffsetsMinutes:
          advanceOffsetsMinutes ?? this.advanceOffsetsMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// JSON (yedekleme biçimi, eski SharedPreferences deposu).
  ///
  /// `birthYear` gerçek yıldır (`null` = bilinmiyor). `date` alanı **geriye
  /// dönük uyumluluk için** korunur: eski okuyucular (ve yedek biçimi v1/v2)
  /// yalnızca onu bilir, bu yüzden yıl bilinmiyorsa [legacyUnknownYear]
  /// nöbetçi yılıyla yazılır. Okurken `birthYear` varsa o kazanır.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'date':
            DateTime(year ?? legacyUnknownYear, month, day).toIso8601String(),
        'birthYear': year,
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
    final date = DateTime.parse(json['date'] as String);
    // `birthYear` yoksa kayıt v6 öncesidir: nöbetçi yıl "bilinmiyor" demektir.
    final int? year = json.containsKey('birthYear')
        ? (json['birthYear'] as num?)?.toInt()
        : (date.year == legacyUnknownYear ? null : date.year);
    return Birthday(
      id: json['id'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      month: date.month,
      day: date.day,
      year: year,
      notifyHour: (json['notifyHour'] as num?)?.toInt() ?? 9,
      notifyMinute: (json['notifyMinute'] as num?)?.toInt() ?? 0,
      advanceOffsetsMinutes: offsets,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Editör ekranında kullanılan standart önbildirim seçenekleri. Etiketler
/// arayüzdedir (`BirthdayGroups.offsetLabel`, F6.1).
class BirthdayAdvanceOffset {
  final int minutes;

  const BirthdayAdvanceOffset(this.minutes);

  static const List<BirthdayAdvanceOffset> presets = <BirthdayAdvanceOffset>[
    BirthdayAdvanceOffset(0),
    BirthdayAdvanceOffset(60),
    BirthdayAdvanceOffset(180),
    BirthdayAdvanceOffset(1440),
    BirthdayAdvanceOffset(4320),
    BirthdayAdvanceOffset(10080),
  ];
}
