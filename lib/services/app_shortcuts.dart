import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:reminder/services/widget_launch_router.dart';

/// Uygulama simgesi kısayolları (F5.3): Android launcher kısayolları ve iOS
/// ana ekran hızlı işlemleri, aynı sırayla.
///
/// [type] kalıcı sözleşmedir (Android sabitlenmiş kısayollar, iOS son
/// kayıtlı liste onu taşır); yeniden adlandırma. [icon] hem Android
/// `res/drawable/<icon>.xml` hem iOS `Assets.xcassets/<icon>.imageset`
/// (şablon görsel) adıdır.
enum AppShortcut {
  newReminder('new_reminder', 'Yeni hatırlatıcı', 'shortcut_new_reminder'),
  marketList('market_list', 'Market listesi', 'shortcut_market_list'),
  today('today', 'Bugün', 'shortcut_today'),
  newBirthday('new_birthday', 'Yeni doğum günü', 'shortcut_new_birthday');

  const AppShortcut(this.type, this.title, this.icon);

  final String type;
  final String title;
  final String icon;

  /// "Market listesi"nin hızlı yakalamada hazır metni: `#market` Market
  /// kategorisi olarak tanınır, kullanıcı ardından maddeleri yazar.
  static const String marketPrefill = '#market ';

  /// Kısayolun açtığı ekran (`HomeShell` çözer).
  WidgetLaunchTarget get target => switch (this) {
        AppShortcut.newReminder => const NewReminderTarget(),
        AppShortcut.marketList => const NewReminderTarget(
            initialText: marketPrefill,
          ),
        AppShortcut.today => const TodayTarget(),
        AppShortcut.newBirthday => const NewBirthdayTarget(),
      };

  ShortcutItem get item =>
      ShortcutItem(type: type, localizedTitle: title, icon: icon);

  /// [type]'ın kısayolu; tanınmayan (ör. eski sürümden kalmış) için `null`.
  static AppShortcut? fromType(String? type) {
    for (final shortcut in values) {
      if (shortcut.type == type) return shortcut;
    }
    return null;
  }
}

/// `quick_actions` eklentisinin kullanılan yüzü; testlerde sahtesi verilir.
abstract interface class QuickActionsPlatform {
  /// [handler]'ı kaydeder; soğuk açılışı başlatan kısayol da ona gelir.
  Future<void> initialize(void Function(String type) handler);

  Future<void> setShortcutItems(List<ShortcutItem> items);
}

/// Gerçek eklenti.
class PluginQuickActions implements QuickActionsPlatform {
  const PluginQuickActions();

  static const _plugin = QuickActions();

  @override
  Future<void> initialize(void Function(String type) handler) =>
      _plugin.initialize(handler);

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) =>
      _plugin.setShortcutItems(items);
}

/// Kısayol dokunuşlarını [WidgetLaunchRouter]'a bırakır; `HomeShell` onları
/// widget dokunuşları gibi alır, yani onboarding bitene ve kabuk kurulana
/// kadar bekler (soğuk ve sıcak açılış aynı yol).
class ShortcutRouter {
  ShortcutRouter({required this.router});

  final WidgetLaunchRouter router;

  /// [type]'ın hedefini bırakır; tanınmayan tür yok sayılır.
  void handle(String type) {
    final shortcut = AppShortcut.fromType(type);
    if (shortcut == null) return;
    router.openTarget(shortcut.target);
  }

  /// İşleyiciyi kaydeder ve dört kısayolu yayımlar. Eklenti hatası açılışı
  /// durdurmaz (kısayollar yalnızca görünmez).
  Future<void> attach(QuickActionsPlatform platform) async {
    try {
      await platform.initialize(handle);
      await platform.setShortcutItems([
        for (final shortcut in AppShortcut.values) shortcut.item,
      ]);
    } on Object catch (error) {
      debugPrint('ShortcutRouter: quick actions unavailable: $error');
    }
  }
}
