import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/notification_ids.dart';

class Reminder {
  final String id;
  final String title;
  final String? note;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? remindAt;

  /// [ReminderCategoryIds] değerlerinden biri.
  final String categoryId;

  /// Yalnızca [ReminderCategoryIds.other] için kullanıcı tanımlı isim.
  final String? customCategoryLabel;

  final bool locationTriggerEnabled;
  final double? locationLatitude;
  final double? locationLongitude;

  /// Geofence yarıçapı (metre), örn. 100–500.
  final double locationRadiusMeters;

  /// Harita / yer adı özeti.
  final String? locationPlaceLabel;

  const Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.isDone,
    required this.createdAt,
    this.remindAt,
    this.categoryId = ReminderCategoryIds.other,
    this.customCategoryLabel,
    this.locationTriggerEnabled = false,
    this.locationLatitude,
    this.locationLongitude,
    this.locationRadiusMeters = 150,
    this.locationPlaceLabel,
  });

  /// Belirtilen alanları değiştirilmiş bir kopya döndürür.
  ///
  /// Nullable alanlar `T? Function()?` olarak alınır; böylece değer açıkça
  /// `null` yapılabilir: `r.copyWith(note: () => null)`. Parametre verilmezse
  /// mevcut değer korunur.
  Reminder copyWith({
    String? id,
    String? title,
    String? Function()? note,
    bool? isDone,
    DateTime? createdAt,
    DateTime? Function()? remindAt,
    String? categoryId,
    String? Function()? customCategoryLabel,
    bool? locationTriggerEnabled,
    double? Function()? locationLatitude,
    double? Function()? locationLongitude,
    double? locationRadiusMeters,
    String? Function()? locationPlaceLabel,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note != null ? note() : this.note,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      remindAt: remindAt != null ? remindAt() : this.remindAt,
      categoryId: categoryId ?? this.categoryId,
      customCategoryLabel: customCategoryLabel != null
          ? customCategoryLabel()
          : this.customCategoryLabel,
      locationTriggerEnabled:
          locationTriggerEnabled ?? this.locationTriggerEnabled,
      locationLatitude:
          locationLatitude != null ? locationLatitude() : this.locationLatitude,
      locationLongitude: locationLongitude != null
          ? locationLongitude()
          : this.locationLongitude,
      locationRadiusMeters: locationRadiusMeters ?? this.locationRadiusMeters,
      locationPlaceLabel: locationPlaceLabel != null
          ? locationPlaceLabel()
          : this.locationPlaceLabel,
    );
  }

  /// Zamanlı bildirim kimliği; kararlı FNV-1a (`reminder:<id>`), bkz.
  /// [NotificationIds].
  int get notificationId => NotificationIds.reminderNotificationId(id);

  /// Konum bildirimi kimliği; zamanlı bildirimden ayrı isim alanı
  /// (`geo:<id>`), bkz. [NotificationIds].
  int get geoNotificationId => NotificationIds.geoNotificationId(id);

  bool get hasValidLocation =>
      locationLatitude != null &&
      locationLongitude != null &&
      locationTriggerEnabled;

  String get categoryDisplayLabel =>
      ReminderCategoryIds.displayLabel(categoryId, customCategoryLabel);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'remindAt': remindAt?.toIso8601String(),
        'categoryId': categoryId,
        'customCategoryLabel': customCategoryLabel,
        'locationTriggerEnabled': locationTriggerEnabled,
        'locationLatitude': locationLatitude,
        'locationLongitude': locationLongitude,
        'locationRadiusMeters': locationRadiusMeters,
        'locationPlaceLabel': locationPlaceLabel,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String?,
      isDone: json['isDone'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      remindAt: json['remindAt'] != null
          ? DateTime.parse(json['remindAt'] as String)
          : null,
      categoryId: json['categoryId'] as String? ?? ReminderCategoryIds.other,
      customCategoryLabel: json['customCategoryLabel'] as String?,
      locationTriggerEnabled: json['locationTriggerEnabled'] as bool? ?? false,
      locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
      locationRadiusMeters:
          (json['locationRadiusMeters'] as num?)?.toDouble() ?? 150,
      locationPlaceLabel: json['locationPlaceLabel'] as String?,
    );
  }
}
