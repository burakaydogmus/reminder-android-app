import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/widget_launch_router.dart';

/// Uygulama simgesi kısayolları (F5.3): Android launcher kısayolları ve iOS
/// ana ekran hızlı işlemleri, aynı sırayla.
///
/// [type] kalıcı sözleşmedir (Android sabitlenmiş kısayollar, iOS son
/// kayıtlı liste onu taşır); yeniden adlandırma. [icon] hem Android
/// `res/drawable/<icon>.xml` hem iOS `Assets.xcassets/<icon>.imageset`
/// (şablon görsel) adıdır. Başlıklar uygulama dilindedir (F6.1, [titleIn]).
enum AppShortcut {
  newReminder('new_reminder', 'shortcut_new_reminder'),
  marketList('market_list', 'shortcut_market_list'),
  today('today', 'shortcut_today'),
  newBirthday('new_birthday', 'shortcut_new_birthday');

  const AppShortcut(this.type, this.icon);

  final String type;
  final String icon;

  /// Kısayol başlığı ("Yeni hatırlatıcı" / "New reminder").
  String titleIn(AppLocalizations l10n) => switch (this) {
        AppShortcut.newReminder => l10n.shortcutNewReminder,
        AppShortcut.marketList => l10n.shortcutMarketList,
        AppShortcut.today => l10n.shortcutToday,
        AppShortcut.newBirthday => l10n.shortcutNewBirthday,
      };

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

  ShortcutItem itemIn(AppLocalizations l10n) =>
      ShortcutItem(type: type, localizedTitle: titleIn(l10n), icon: icon);

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

  QuickActionsPlatform? _platform;

  /// [type]'ın hedefini bırakır; tanınmayan tür yok sayılır.
  void handle(String type) {
    final shortcut = AppShortcut.fromType(type);
    if (shortcut == null) return;
    router.openTarget(shortcut.target);
  }

  /// İşleyiciyi kaydeder ve dört kısayolu [l10n] dilinde yayımlar. Eklenti
  /// hatası açılışı durdurmaz (kısayollar yalnızca görünmez).
  Future<void> attach(
    QuickActionsPlatform platform, {
    required AppLocalizations l10n,
  }) async {
    try {
      await platform.initialize(handle);
      _platform = platform;
    } on Object catch (error) {
      debugPrint('ShortcutRouter: quick actions unavailable: $error');
      return;
    }
    await publish(l10n);
  }

  /// Kısayolları [l10n] dilinde yeniden yayımlar (F6.1: dil değişince).
  /// [attach] başarısız olduysa hiçbir şey yapmaz.
  Future<void> publish(AppLocalizations l10n) async {
    final platform = _platform;
    if (platform == null) return;
    try {
      await platform.setShortcutItems([
        for (final shortcut in AppShortcut.values) shortcut.itemIn(l10n),
      ]);
    } on Object catch (error) {
      debugPrint('ShortcutRouter: quick actions unavailable: $error');
    }
  }
}
