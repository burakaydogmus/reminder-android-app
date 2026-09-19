import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/home/widget_payload.dart';
import 'package:reminder/services/sync_interfaces.dart';

/// Ana ekran widget'larına giden veri anahtarı (F5.1, [WidgetPayload] v2).
///
/// F5.1 öncesi anahtar [_legacyPayloadKey] (yalnız id + başlık, 8 öğe) artık
/// yazılmaz, ilk senkronda silinir; widget'lar yalnız bu anahtarı okur.
const String kHomeWidgetPayloadKey = 'widget_payload_v2';

const String _legacyPayloadKey = 'reminders_active_json';

const String _androidPackage = 'com.burakaydogmus.reminder';

/// Android ana ekran widget'ları (F5.1). [qualifiedName] Kotlin
/// `AppWidgetProvider` sınıfıdır.
enum ReminderHomeWidget {
  /// Bugün 4×2: başlık "Bugün · N", hap "+", 2 satır.
  today('Bugün', '4×2 · bugünün ilk iki işi ve "+"',
      '$_androidPackage.ReminderTodayWidgetProvider'),

  /// Liste 4×4 (3×3–5×6): kaydırılabilir Kaçanlar / Bugün / Doğum günü.
  ///
  /// F5.1 öncesi tek widget'ın sınıfıdır; ana ekranda duran widget'lar
  /// bozulmadan Liste widget'ına dönüşür.
  list('Liste', '4×4 · kaydırılabilir, boyutu değişir',
      kReminderListWidgetQualifiedAndroidName),

  /// Sıradaki 2×2: sıradaki işin saati ve başlığı.
  next('Sıradaki', '2×2 · sıradaki iş ve saati',
      '$_androidPackage.ReminderNextWidgetProvider'),

  /// Hızlı ekle 1×1: yalnız "+".
  quickAdd('Hızlı ekle', '1×1 · tek dokunuşla yeni hatırlatıcı',
      '$_androidPackage.ReminderQuickAddWidgetProvider');

  const ReminderHomeWidget(this.label, this.description, this.qualifiedName);

  /// Türkçe ad (widget seçicideki ad ile aynı).
  final String label;

  /// Ayarlar'daki seçim satırının kısa açıklaması.
  final String description;

  final String qualifiedName;
}

/// Liste widget'ının (F5.1 öncesi tek widget) Android sınıf adı; onboarding
/// "Ana ekrana widget ekle" bunu sabitler.
const String kReminderListWidgetQualifiedAndroidName =
    '$_androidPackage.ReminderListWidgetProvider';

/// Widget verisini ([WidgetPayload]) yazar ve dört widget'ı yeniler.
Future<void> syncRemindersToHomeWidget(
  List<Reminder> reminders, {
  required List<Birthday> birthdays,
  required bool notificationsEnabled,
  DateTime Function() now = DateTime.now,
}) async {
  if (!Platform.isAndroid) return;

  final payload = WidgetPayload.build(
    reminders: reminders,
    birthdays: birthdays,
    notificationsEnabled: notificationsEnabled,
    now: now(),
  );
  await HomeWidget.saveWidgetData(kHomeWidgetPayloadKey, jsonEncode(payload));
  await HomeWidget.saveWidgetData<String>(_legacyPayloadKey, null);
  for (final widget in ReminderHomeWidget.values) {
    await HomeWidget.updateWidget(qualifiedAndroidName: widget.qualifiedName);
  }
}

/// [HomeWidgetSync]'in gerçek uygulaması; [syncRemindersToHomeWidget]'e
/// delege eder.
class PlatformHomeWidgetSync implements HomeWidgetSync {
  const PlatformHomeWidgetSync();

  @override
  Future<void> sync(
    List<Reminder> reminders, {
    required List<Birthday> birthdays,
    required bool notificationsEnabled,
  }) =>
      syncRemindersToHomeWidget(
        reminders,
        birthdays: birthdays,
        notificationsEnabled: notificationsEnabled,
      );
}
