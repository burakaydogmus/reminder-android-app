import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ana ekran widget'ından uygulamayı açan bir dokunuşun hedefi (F5.1).
///
/// Adresler (`reminderwidget://…`, Kotlin tarafıyla ortak):
/// - `new` → hızlı yakalama ("+", F4.6b),
/// - `open?id=<id>` → o hatırlatıcının düzenleyicisi,
/// - `birthday?id=<id>` → Doğum günleri,
/// - `permissions` → Ayarlar (İzinler grubu en üstte).
///
/// `toggle?id=` uygulamayı açmaz (arka plan callback'i), burada yok sayılır.
///
/// Uygulama simgesi kısayolları (F5.3, `services/app_shortcuts.dart`) adres
/// değil, doğrudan hedef bırakır ([WidgetLaunchRouter.openTarget]): "Market
/// listesi" metinli [NewReminderTarget], [TodayTarget], [NewBirthdayTarget].
sealed class WidgetLaunchTarget {
  const WidgetLaunchTarget();

  static const String scheme = 'reminderwidget';

  /// [uri]'yi çözer; tanınmayan veya eksik adres için `null`.
  static WidgetLaunchTarget? parse(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;
    String? id() {
      final value = uri.queryParameters['id'];
      return value == null || value.isEmpty ? null : value;
    }

    switch (uri.host) {
      case 'new':
        return const NewReminderTarget();
      case 'open':
        final reminderId = id();
        return reminderId == null ? null : OpenReminderTarget(reminderId);
      case 'birthday':
        final birthdayId = id();
        return birthdayId == null ? null : OpenBirthdayTarget(birthdayId);
      case 'permissions':
        return const PermissionsTarget();
    }
    return null;
  }
}

/// "+" → hızlı yakalama; [initialText] alanı doldurur (F5.3 "Market
/// listesi" → `#market `).
final class NewReminderTarget extends WidgetLaunchTarget {
  const NewReminderTarget({this.initialText = ''});

  final String initialText;

  @override
  bool operator ==(Object other) =>
      other is NewReminderTarget && other.initialText == initialText;

  @override
  int get hashCode => Object.hash(NewReminderTarget, initialText);

  @override
  String toString() => 'NewReminderTarget($initialText)';
}

/// Kısayol "Bugün" (F5.3) → Bugün sekmesi, açık sayfalar kapanır.
final class TodayTarget extends WidgetLaunchTarget {
  const TodayTarget();

  @override
  bool operator ==(Object other) => other is TodayTarget;

  @override
  int get hashCode => (TodayTarget).hashCode;

  @override
  String toString() => 'TodayTarget()';
}

/// Kısayol "Yeni doğum günü" (F5.3) → boş doğum günü düzenleyicisi.
final class NewBirthdayTarget extends WidgetLaunchTarget {
  const NewBirthdayTarget();

  @override
  bool operator ==(Object other) => other is NewBirthdayTarget;

  @override
  int get hashCode => (NewBirthdayTarget).hashCode;

  @override
  String toString() => 'NewBirthdayTarget()';
}

/// Satıra dokunma → hatırlatıcının düzenleyicisi.
final class OpenReminderTarget extends WidgetLaunchTarget {
  const OpenReminderTarget(this.reminderId);

  final String reminderId;

  @override
  bool operator ==(Object other) =>
      other is OpenReminderTarget && other.reminderId == reminderId;

  @override
  int get hashCode => Object.hash(OpenReminderTarget, reminderId);

  @override
  String toString() => 'OpenReminderTarget($reminderId)';
}

/// Doğum günü satırı → Doğum günleri.
final class OpenBirthdayTarget extends WidgetLaunchTarget {
  const OpenBirthdayTarget(this.birthdayId);

  final String birthdayId;

  @override
  bool operator ==(Object other) =>
      other is OpenBirthdayTarget && other.birthdayId == birthdayId;

  @override
  int get hashCode => Object.hash(OpenBirthdayTarget, birthdayId);

  @override
  String toString() => 'OpenBirthdayTarget($birthdayId)';
}

/// "Bildirimler kapalı — açmak için dokun" → Ayarlar › İzinler.
final class PermissionsTarget extends WidgetLaunchTarget {
  const PermissionsTarget();

  @override
  bool operator ==(Object other) => other is PermissionsTarget;

  @override
  int get hashCode => (PermissionsTarget).hashCode;

  @override
  String toString() => 'PermissionsTarget()';
}

/// Widget'tan (F5.1) ve uygulama simgesi kısayollarından (F5.3) açılışları
/// arayüze iletir; `NotificationTapRouter` (F3.2) ile aynı kalıp.
///
/// Platform kaynağı ([attach]) hedefi [open] ile bırakır; `HomeShell` dinler
/// ve [take] ile bir kez alır. `HomeShell` yalnız onboarding bittikten sonra
/// kurulduğu için hedef o zamana kadar bekler (soğuk açılış, onboarding).
class WidgetLaunchRouter extends ChangeNotifier {
  WidgetLaunchRouter();

  /// Uygulamanın kullandığı örnek.
  static final WidgetLaunchRouter instance = WidgetLaunchRouter();

  WidgetLaunchTarget? _pending;
  StreamSubscription<Uri?>? _clicks;

  /// Henüz açılmamış hedef.
  WidgetLaunchTarget? get pending => _pending;

  /// [uri]'nin hedefini bırakır (öncekinin yerini alır); tanınmayan adres
  /// yok sayılır.
  void open(Uri? uri) {
    final target = WidgetLaunchTarget.parse(uri);
    if (target == null) return;
    openTarget(target);
  }

  /// [target]'ı bırakır (öncekinin yerini alır); kısayollar (F5.3).
  void openTarget(WidgetLaunchTarget target) {
    _pending = target;
    notifyListeners();
  }

  /// Bekleyen hedefi döndürür ve temizler.
  WidgetLaunchTarget? take() {
    final target = _pending;
    _pending = null;
    return target;
  }

  /// Soğuk açılış hedefini ([initialLaunch]) bırakır ve sonraki dokunuşları
  /// ([clicks]) dinler. Uygulamada `HomeWidget.initiallyLaunchedFromHomeWidget`
  /// ve `HomeWidget.widgetClicked`; testlerde sahte kaynaklar.
  Future<void> attach({
    required Future<Uri?> Function() initialLaunch,
    required Stream<Uri?> clicks,
  }) async {
    await _clicks?.cancel();
    _clicks = clicks.listen(open, onError: (Object _) {});
    try {
      open(await initialLaunch());
    } on Object catch (error) {
      // Kanal yoksa (ör. eklenti kaydı başarısız) normal açılış sayılır.
      debugPrint('WidgetLaunchRouter: initial launch unavailable: $error');
    }
  }

  @override
  void dispose() {
    _clicks?.cancel();
    super.dispose();
  }
}
