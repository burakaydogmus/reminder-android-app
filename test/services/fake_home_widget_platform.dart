import 'package:reminder/services/reminder_home_widget_sync.dart';

/// `home_widget` yerine geçen, çağrıları kaydeden sahte (F5.1/F5.2).
///
/// `Platform.isAndroid` / `Platform.isIOS` test ana bilgisayarında her zaman
/// `false` olduğu için platform dalları ancak buradan doğrulanabilir.
class FakeHomeWidgetPlatform extends HomeWidgetPlatform {
  FakeHomeWidgetPlatform({
    this.isAndroid = false,
    this.isIOS = false,
    Map<String, String?> stored = const {},
  }) : saved = {...stored};

  @override
  final bool isAndroid;

  @override
  final bool isIOS;

  /// Çağrı sırası ("setAppGroupId:…", "save:…", "read:…", "android:…", "ios:…").
  final List<String> calls = [];

  /// `saveWidgetData` ile yazılanlar (silme `null` olarak kalır), yazma
  /// sırasında.
  final Map<String, String?> saved;

  final List<String> appGroupIds = [];
  final List<String> androidUpdates = [];
  final List<String> iosUpdates = [];

  @override
  Future<void> setAppGroupId(String groupId) async {
    calls.add('setAppGroupId:$groupId');
    appGroupIds.add(groupId);
  }

  @override
  Future<void> saveWidgetData(String key, String? value) async {
    calls.add('save:$key');
    saved[key] = value;
  }

  @override
  Future<String?> readWidgetData(String key) async {
    calls.add('read:$key');
    return saved[key];
  }

  @override
  Future<void> updateAndroidWidget(String qualifiedName) async {
    calls.add('android:$qualifiedName');
    androidUpdates.add(qualifiedName);
  }

  @override
  Future<void> updateIosWidget(String kind) async {
    calls.add('ios:$kind');
    iosUpdates.add(kind);
  }
}
