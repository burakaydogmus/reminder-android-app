import 'package:reminder/domain/model/reminder_category.dart';

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

  int get notificationId => id.hashCode & 0x7FFFFFFF;

  /// Zamanlı bildirimlerden ayrı kimlik (çakışmayı azaltır).
  int get geoNotificationId {
    var h = id.hashCode ^ 0x5f3759df;
    if (h < 0) h = -h;
    return h & 0x7FFFFFFF;
  }

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
