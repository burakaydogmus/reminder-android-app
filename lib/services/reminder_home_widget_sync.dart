import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

/// iOS App Group (F5.2): uygulama ile `ReminderWidgetExtension` verinin aynı
/// `UserDefaults` bölmesini paylaşır. Runner ve extension entitlement'larında
/// aynı kimlik durur (`ios/Runner/Runner.entitlements`,
/// `ios/ReminderWidget/ReminderWidgetExtension.entitlements`) ve Swift tarafı
/// `ReminderWidgetStore.appGroupId` olarak okur.
///
/// Android'de `home_widget` grup kimliğini yok sayar (kendi
/// `SharedPreferences` dosyasını kullanır); yine de `main` her iki platformda
/// ayarlar, böylece tek bir doğru değer vardır.
const String kHomeWidgetAppGroupId = 'group.com.burakaydogmus.reminder';

/// iOS WidgetKit widget'larının `kind` değerleri (F5.2).
///
/// Swift tarafındaki `ReminderNextWidget.kind` vb. ile **aynı** olmalı
/// (`ios/ReminderWidget/ReminderWidgetBundle.swift`): her senkrondan sonra
/// `WidgetCenter.reloadTimelines(ofKind:)` bu adlarla çağrılır. Android'deki
/// [ReminderHomeWidget.qualifiedName] listesinin karşılığıdır; "Hızlı ekle"nin
/// iOS karşılığı yok (systemSmall zaten "+" taşır).
const List<String> kIosWidgetKinds = <String>[
  'ReminderNextWidget',
  'ReminderTodayWidget',
  'ReminderListWidget',
  'ReminderLockWidget',
];

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

/// `home_widget` eklentisinin ve platform sorgularının tek sınırı.
///
/// Testler bunun yerine kaydeden bir sahte verir; `Platform.isAndroid` /
/// `Platform.isIOS` test ana bilgisayarında her zaman `false` olduğu için
/// platform dalları ancak böyle doğrulanabilir.
class HomeWidgetPlatform {
  const HomeWidgetPlatform();

  bool get isAndroid => Platform.isAndroid;

  bool get isIOS => Platform.isIOS;

  /// iOS'ta paylaşılan `UserDefaults` bölmesini seçer; Android'de etkisizdir.
  Future<void> setAppGroupId(String groupId) =>
      HomeWidget.setAppGroupId(groupId);

  /// `null` değer anahtarı siler.
  Future<void> saveWidgetData(String key, String? value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  Future<String?> readWidgetData(String key) =>
      HomeWidget.getWidgetData<String>(key);

  Future<void> updateAndroidWidget(String qualifiedName) =>
      HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);

  /// `WidgetCenter.reloadTimelines(ofKind:)`.
  Future<void> updateIosWidget(String kind) =>
      HomeWidget.updateWidget(iOSName: kind);
}

/// Widget verisini ([WidgetPayload]) yazar ve platformun widget'larını yeniler.
///
/// Android: dört `AppWidgetProvider` (F5.1). iOS: [kIosWidgetKinds] (F5.2);
/// veri App Group'a yazıldığı için önce [kHomeWidgetAppGroupId] ayarlanır —
/// arka plan isolate'leri (`main`'i çalıştırmayan bildirim aksiyonu isolate'i
/// gibi) bunu kendileri yapmaz. Başka platformlarda hiçbir şey yapılmaz.
Future<void> syncRemindersToHomeWidget(
  List<Reminder> reminders, {
  required List<Birthday> birthdays,
  required bool notificationsEnabled,
  CategoryCatalog? categories,
  DateTime Function() now = DateTime.now,
  AppLocalizations? l10n,
  @visibleForTesting HomeWidgetPlatform platform = const HomeWidgetPlatform(),
}) async {
  if (!platform.isAndroid && !platform.isIOS) return;

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
  if (platform.isIOS) {
    await platform.setAppGroupId(kHomeWidgetAppGroupId);
  }
  await platform.saveWidgetData(kHomeWidgetPayloadKey, jsonEncode(payload));
  await platform.saveWidgetData(_legacyPayloadKey, null);
  if (platform.isAndroid) {
    for (final widget in ReminderHomeWidget.values) {
      await platform.updateAndroidWidget(widget.qualifiedName);
    }
  } else {
    for (final kind in kIosWidgetKinds) {
      await platform.updateIosWidget(kind);
    }
  }
}

/// [HomeWidgetSync]'in gerçek uygulaması; [syncRemindersToHomeWidget]'e
/// delege eder.
class PlatformHomeWidgetSync implements HomeWidgetSync {
  const PlatformHomeWidgetSync({
    @visibleForTesting this.platform = const HomeWidgetPlatform(),
  });

  final HomeWidgetPlatform platform;

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
        platform: platform,
      );
}
