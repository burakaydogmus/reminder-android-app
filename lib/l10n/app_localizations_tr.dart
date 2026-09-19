// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Hatırlatıcı';

  @override
  String get shortcutNewReminder => 'Yeni hatırlatıcı';

  @override
  String get shortcutMarketList => 'Market listesi';

  @override
  String get shortcutToday => 'Bugün';

  @override
  String get shortcutNewBirthday => 'Yeni doğum günü';

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get settingsLanguageSystem => 'Sistem';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHint =>
      'Sistem, cihaz dili Türkçeyse Türkçe, değilse İngilizce kullanır.';
}
