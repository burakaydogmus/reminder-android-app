// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Reminders';

  @override
  String get shortcutNewReminder => 'New reminder';

  @override
  String get shortcutMarketList => 'Shopping list';

  @override
  String get shortcutToday => 'Today';

  @override
  String get shortcutNewBirthday => 'New birthday';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHint =>
      'System uses Turkish when the device language is Turkish, English otherwise.';
}
