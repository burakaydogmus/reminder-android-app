import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/home/widget_payload.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
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
  today('$_androidPackage.ReminderTodayWidgetProvider'),

  /// Liste 4×4 (3×3–5×6): kaydırılabilir Kaçanlar / Bugün / Doğum günü.
  ///
  /// F5.1 öncesi tek widget'ın sınıfıdır; ana ekranda duran widget'lar
  /// bozulmadan Liste widget'ına dönüşür.
  list(kReminderListWidgetQualifiedAndroidName),

  /// Sıradaki 2×2: sıradaki işin saati ve başlığı.
  next('$_androidPackage.ReminderNextWidgetProvider'),

  /// Hızlı ekle 1×1: yalnız "+".
  quickAdd('$_androidPackage.ReminderQuickAddWidgetProvider');

  const ReminderHomeWidget(this.qualifiedName);

  /// Ad (widget seçicideki ad ile aynı, `values*/strings.xml`).
  String labelIn(AppLocalizations l10n) => switch (this) {
        today => l10n.homeWidgetToday,
        list => l10n.homeWidgetList,
        next => l10n.homeWidgetNext,
        quickAdd => l10n.homeWidgetQuickAdd,
      };

  /// Ayarlar'daki seçim satırının kısa açıklaması.
  String descriptionIn(AppLocalizations l10n) => switch (this) {
        today => l10n.homeWidgetTodayDescription,
        list => l10n.homeWidgetListDescription,
        next => l10n.homeWidgetNextDescription,
        quickAdd => l10n.homeWidgetQuickAddDescription,
      };

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
  CategoryCatalog? categories,
  DateTime Function() now = DateTime.now,
  AppLocalizations? l10n,
}) async {
  if (!Platform.isAndroid) return;

  final payload = WidgetPayload.build(
    reminders: reminders,
    birthdays: birthdays,
    notificationsEnabled: notificationsEnabled,
    categories: categories,
    now: now(),
    // F6.1: labels in the stored "Dil" (or system) language, also in the
    // widget callback isolate.
    l10n: l10n ?? await BackgroundLocalizations.load(),
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
    CategoryCatalog? categories,
  }) =>
      syncRemindersToHomeWidget(
        reminders,
        birthdays: birthdays,
        notificationsEnabled: notificationsEnabled,
        categories: categories,
      );
}
