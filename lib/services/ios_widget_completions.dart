import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/domain/reminder_completion.dart';
import 'package:reminder/services/geofence_service.dart';
import 'package:reminder/services/notification_service.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/services/schedule_sync.dart';

/// iOS widget'ından gelen "tamamla" isteklerinin anahtarı (F5.2).
///
/// Swift tarafı `ReminderWidgetStore.completionsKey` ile aynı; App Group'taki
/// `UserDefaults`'a JSON dizisi olarak yazılır:
///
/// ```json
/// [{"id": "…", "at": 1789999200000}]
/// ```
///
/// [kHomeWidgetPayloadKey] sözleşmesine **ek**tir, onu değiştirmez: Android
/// tarafı bu anahtarı hiç okumaz.
const String kWidgetCompletionsKey = 'widget_completions_v1';

/// Kuyruktaki bir istek: hangi hatırlatıcı, ne zaman tamamlandı.
@immutable
class WidgetCompletion {
  const WidgetCompletion(this.reminderId, this.at);

  final String reminderId;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is WidgetCompletion &&
      other.reminderId == reminderId &&
      other.at == at;

  @override
  int get hashCode => Object.hash(reminderId, at);

  @override
  String toString() => 'WidgetCompletion($reminderId, $at)';
}

/// Kuyruk JSON'unu çözer (saf, hataya toleranslı).
///
/// Dizi değilse, öğe nesne değilse, `id` yoksa/boşsa veya `at` sayı değilse o
/// öğe atlanır — widget bozuk veri yazsa bile uygulama açılır. Sonuç
/// tamamlanma zamanına göre artan sıradadır (aynı anlarda kuyruk sırası
/// korunur), böylece istekler yapıldıkları sırayla uygulanır.
List<WidgetCompletion> parseWidgetCompletions(String? json) {
  if (json == null || json.isEmpty) return const [];
  Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];
  final completions = <WidgetCompletion>[];
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final id = entry['id'];
    final at = entry['at'];
    if (id is! String || id.isEmpty) continue;
    if (at is! num) continue;
    completions.add(
      WidgetCompletion(
        id,
        DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      ),
    );
  }
  // Kararlı sıralama: List.sort kararlı değil, bu yüzden indeks bağı eklenir.
  final indexed = [
    for (var i = 0; i < completions.length; i++) (i, completions[i]),
  ]..sort((a, b) {
      final byTime = a.$2.at.compareTo(b.$2.at);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, completion) in indexed) completion];
}

/// Bekleyen widget tamamlamalarını depoya uygular (F5.2).
///
/// Android'de widget "tamamla"yı arka plan isolate'inde anında yapar
/// (`handleReminderHomeWidgetToggle`); iOS'ta widget extension'ında Flutter
/// motoru olmadığı için istek App Group'a bırakılır ve **burada**, aynı
/// [completeReminder] kuralıyla işlenir: tekrarlayan hatırlatıcı bir sonraki
/// tekrara ilerler, alt görevleri sıfırlanır; bir kereliklerde `isDone`.
///
/// Sıra: kuyruk okunur → değişiklikler kaydedilir → kuyruk **temizlenir** →
/// tüm zamanlamalar [ScheduleSync.syncAll] ile eşitlenir (F1.2: doğum günü
/// bildirimleri silinmez; widget da yeni veriyle yenilenir). Kuyruk senkrondan
/// önce temizlenir, yoksa widget aynı satırı iki kez gizlerdi.
///
/// Bulunamayan veya zaten tamamlanmış id yok sayılır (kuyruktan düşer).
/// Değişiklik yoksa hiçbir şey kaydedilmez ve zamanlamalara dokunulmaz.
/// Döndürülen sayı uygulanan tamamlamalardır.
Future<int> applyPendingWidgetCompletions({
  required ReminderRepository repository,
  required ScheduleSync schedules,
  DateTime Function() now = DateTime.now,
  HomeWidgetPlatform platform = const HomeWidgetPlatform(),
}) async {
  if (!platform.isIOS) return 0;

  await platform.setAppGroupId(kHomeWidgetAppGroupId);
  final completions =
      parseWidgetCompletions(await platform.readWidgetData(kWidgetCompletionsKey));
  if (completions.isEmpty) return 0;

  final reminders = await repository.loadReminders();
  final byId = {for (final reminder in reminders) reminder.id: reminder};
  final fallback = now();
  var applied = 0;
  for (final completion in completions) {
    final reminder = byId[completion.reminderId];
    if (reminder == null || reminder.isDone) continue;
    // Gelecek bir zaman damgası (saat değişimi, bozuk veri) tekrarlayan
    // hatırlatıcıyı ileri fırlatmasın.
    final at = completion.at.isAfter(fallback) ? fallback : completion.at;
    byId[reminder.id] = completeReminder(reminder, at);
    applied++;
  }

  // Kuyruk her durumda temizlenir: işlenemeyen id'ler (silinmiş hatırlatıcı)
  // orada birikmemeli.
  await platform.saveWidgetData(kWidgetCompletionsKey, null);

  final updated = [for (final reminder in reminders) byId[reminder.id]!];
  final birthdays = await repository.loadBirthdays();
  final settings = await repository.loadSettings();
  final categories = CategoryCatalog(await repository.loadCategories());

  if (applied == 0) {
    await schedules.refreshHomeWidget(
      reminders: reminders,
      birthdays: birthdays,
      settings: settings,
      categories: categories,
    );
    return 0;
  }

  await repository.saveReminders(updated);
  await schedules.syncAll(
    reminders: updated,
    birthdays: birthdays,
    settings: settings,
    categories: categories,
  );
  return applied;
}

/// Gerçek servisleri kurup [applyPendingWidgetCompletions]'ı çağırır.
///
/// `main` (açılış) ve `AppStateReloader` (ön plana dönüş, F1.3) bunu çağırır;
/// iOS dışında hemen döner. Depo, bu isolate'in paylaşılan bağlantısıdır
/// (`AppDatabaseHost`), bu yüzden kapatılmaz — uygulamanın kendi deposu aynı
/// bağlantıyı kullanır. Hata hiçbir zaman açılışı engellemez.
Future<void> applyPendingIosWidgetCompletions() async {
  const platform = HomeWidgetPlatform();
  if (!platform.isIOS) return;
  try {
    await applyPendingWidgetCompletions(
      repository: ReminderRepository(),
      schedules: ScheduleSync(
        notifications: NotificationService.instance,
        geofence: GeofenceService.instance,
        homeWidget: const PlatformHomeWidgetSync(),
      ),
      platform: platform,
    );
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'reminder/ios_widget_completions',
      ),
    );
  }
}
