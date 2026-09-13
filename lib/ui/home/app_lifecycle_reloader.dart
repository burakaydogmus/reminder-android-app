import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/home/widget_change_signal.dart';

/// Ana isolate'in `SharedPreferences` önbelleğini diskten tazeler.
///
/// Widget callback'i ayrı bir isolate'te yazar; ana isolate'in önbelleği bu
/// yazıyı `reload()` olmadan görmez.
Future<void> refreshSharedPreferencesCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
}

/// Uygulama durumunu depodan yeniden yükler (F1.3), böylece ana ekran
/// widget'ının arka planda yaptığı değişikliği bellekteki eski durum ezmez.
///
/// İki tetikleyici vardır:
/// - **Ön plana dönüş:** uygulama gizlendikten (`hidden`) sonra `resumed`
///   olduğunda. Yalnızca `inactive` → `resumed` (bildirim perdesi, izin
///   diyaloğu) yeniden yükleme yapmaz. Son yüklemeden [minInterval] içinde
///   gelen dönüşler yok sayılır; açılıştaki yükleme de sayılır, böylece ilk
///   açılışta çift yükleme olmaz.
/// - **Widget sinyali:** widget callback'i kaydettikten sonra
///   [notifyAppOfWidgetChange] ile [widgetChangePortName] portuna yazar;
///   uygulama süreci canlıysa (ön planda, bölünmüş ekranda veya arka planda)
///   hemen yeniden yüklenir. Sinyal kısıtlamaya takılmaz.
///
/// Yeniden yükleme yalnızca cubit durumunu değiştirir; açık düzenleyici
/// sayfaları kendi controller'larını koruduğu için yazılan metin kaybolmaz.
class AppStateReloader extends StatefulWidget {
  const AppStateReloader({
    super.key,
    required this.child,
    this.clock = DateTime.now,
    this.minInterval = const Duration(seconds: 1),
    this.refreshStorage = refreshSharedPreferencesCache,
    this.listenToWidgetChanges = true,
  });

  final Widget child;

  /// Testler için enjekte edilir.
  final DateTime Function() clock;

  /// İki ön plana dönüş yüklemesi arasındaki en kısa süre.
  final Duration minInterval;

  /// `ReminderCubit.load` öncesi depo önbelleğini tazeler.
  final Future<void> Function() refreshStorage;

  /// `false` ise widget sinyal portu kaydedilmez.
  final bool listenToWidgetChanges;

  @override
  State<AppStateReloader> createState() => _AppStateReloaderState();
}

class _AppStateReloaderState extends State<AppStateReloader> {
  late final AppLifecycleListener _lifecycle;
  ReceivePort? _port;
  StreamSubscription<Object?>? _portSubscription;

  /// Açılışta `App` cubit'i zaten yüklüyor; bu an ilk yükleme sayılır.
  late DateTime _lastLoad;
  bool _hiddenSinceLoad = false;
  bool _loading = false;
  bool _reloadAgain = false;

  @override
  void initState() {
    super.initState();
    _lastLoad = widget.clock();
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenSinceLoad = true,
      onResume: _onResume,
    );
    if (widget.listenToWidgetChanges) _listenToWidgetChanges();
  }

  void _listenToWidgetChanges() {
    final port = ReceivePort();
    // Hot restart'tan kalan eski eşleme varsa üzerine yaz.
    IsolateNameServer.removePortNameMapping(widgetChangePortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      widgetChangePortName,
    );
    _port = port;
    _portSubscription = port.listen((_) => unawaited(_reload()));
  }

  void _onResume() {
    if (!_hiddenSinceLoad) return;
    _hiddenSinceLoad = false;
    if (widget.clock().difference(_lastLoad) < widget.minInterval) return;
    unawaited(_reload());
  }

  Future<void> _reload() async {
    if (_loading) {
      _reloadAgain = true;
      return;
    }
    _loading = true;
    final cubit = context.read<ReminderCubit>();
    try {
      do {
        _reloadAgain = false;
        _lastLoad = widget.clock();
        await widget.refreshStorage();
        if (!mounted) return;
        await cubit.load();
      } while (_reloadAgain && mounted);
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_portSubscription?.cancel());
    final port = _port;
    if (port != null) {
      if (IsolateNameServer.lookupPortByName(widgetChangePortName) ==
          port.sendPort) {
        IsolateNameServer.removePortNameMapping(widgetChangePortName);
      }
      port.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
