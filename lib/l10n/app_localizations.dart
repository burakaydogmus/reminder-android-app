import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// App name (task switcher, MaterialApp.title).
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get appTitle;

  /// App icon shortcut (Android launcher / iOS quick action).
  ///
  /// In tr, this message translates to:
  /// **'Yeni hatırlatıcı'**
  String get shortcutNewReminder;

  /// App icon shortcut; opens quick capture prefilled with #market.
  ///
  /// In tr, this message translates to:
  /// **'Market listesi'**
  String get shortcutMarketList;

  /// App icon shortcut.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get shortcutToday;

  /// App icon shortcut.
  ///
  /// In tr, this message translates to:
  /// **'Yeni doğum günü'**
  String get shortcutNewBirthday;

  /// Ayarlar › Görünüm: language setting title.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguageTitle;

  /// Language segment: follow the device language.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsLanguageSystem;

  /// Language segment; always the endonym.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTurkish;

  /// Language segment; always the endonym.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In tr, this message translates to:
  /// **'Sistem, cihaz dili Türkçeyse Türkçe, değilse İngilizce kullanır.'**
  String get settingsLanguageHint;

  /// Screen-reader time (§3.6 rule 11): every spoken time uses this.
  ///
  /// In tr, this message translates to:
  /// **'saat {time}'**
  String timeSpoken(String time);

  /// intl DateFormat pattern: Bugün header date.
  ///
  /// In tr, this message translates to:
  /// **'EEEE, d MMMM'**
  String get dateFormatHeader;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'d MMMM'**
  String get dateFormatDayMonth;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'d MMMM y'**
  String get dateFormatDayMonthYear;

  /// intl DateFormat pattern: short date on cards.
  ///
  /// In tr, this message translates to:
  /// **'d MMM'**
  String get dateFormatShort;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'d MMM y'**
  String get dateFormatShortYear;

  /// intl DateFormat pattern: agenda day header.
  ///
  /// In tr, this message translates to:
  /// **'EEEE d MMMM'**
  String get dateFormatAgenda;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'EEEE d MMMM y'**
  String get dateFormatAgendaYear;

  /// intl DateFormat pattern: month title.
  ///
  /// In tr, this message translates to:
  /// **'MMMM y'**
  String get dateFormatMonthYear;

  /// intl DateFormat pattern: month name.
  ///
  /// In tr, this message translates to:
  /// **'MMMM'**
  String get dateFormatMonth;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'d MMMM EEEE'**
  String get dateFormatDayMonthWeekday;

  /// No description provided for @dayToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get dayYesterday;

  /// "Yarın 09:00", "14 Eyl saat 09:00".
  ///
  /// In tr, this message translates to:
  /// **'{day} {time}'**
  String dayAndTime(String day, String time);

  /// No description provided for @agendaDayToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün · {date}'**
  String agendaDayToday(String date);

  /// No description provided for @agendaDayTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın · {date}'**
  String agendaDayTomorrow(String date);

  /// No description provided for @recurrenceNone.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar yok'**
  String get recurrenceNone;

  /// No description provided for @recurrenceWeekdays.
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi her gün'**
  String get recurrenceWeekdays;

  /// No description provided for @recurrenceUntil.
  ///
  /// In tr, this message translates to:
  /// **'{base} · bitiş {date}'**
  String recurrenceUntil(String base, String date);

  /// No description provided for @actionComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamla'**
  String get actionComplete;

  /// No description provided for @actionReopen.
  ///
  /// In tr, this message translates to:
  /// **'Geri aç'**
  String get actionReopen;

  /// No description provided for @actionSnooze.
  ///
  /// In tr, this message translates to:
  /// **'Ertele'**
  String get actionSnooze;

  /// No description provided for @actionEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get actionDelete;

  /// No description provided for @actionPin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitle'**
  String get actionPin;

  /// No description provided for @actionUnpin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlemeyi kaldır'**
  String get actionUnpin;

  /// No description provided for @actionUndo.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get actionUndo;

  /// No description provided for @actionCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get actionSave;

  /// No description provided for @actionConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get actionConfirm;

  /// No description provided for @actionLater.
  ///
  /// In tr, this message translates to:
  /// **'Sonra'**
  String get actionLater;

  /// No description provided for @priorityNone.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get priorityHigh;

  /// "Yüksek öncelik".
  ///
  /// In tr, this message translates to:
  /// **'{level} öncelik'**
  String prioritySpoken(String level);

  /// progress is "2/6".
  ///
  /// In tr, this message translates to:
  /// **'maddeler: {progress} tamamlandı'**
  String subtasksSpoken(String progress);

  /// No description provided for @reminderSpokenOverdue.
  ///
  /// In tr, this message translates to:
  /// **'gecikti'**
  String get reminderSpokenOverdue;

  /// No description provided for @reminderSpokenRecurring.
  ///
  /// In tr, this message translates to:
  /// **'tekrar: {summary}'**
  String reminderSpokenRecurring(String summary);

  /// No description provided for @reminderSpokenPlace.
  ///
  /// In tr, this message translates to:
  /// **'konum: {place}'**
  String reminderSpokenPlace(String place);

  /// No description provided for @reminderSpokenPinned.
  ///
  /// In tr, this message translates to:
  /// **'sabitlendi'**
  String get reminderSpokenPinned;

  /// No description provided for @reminderSpokenDone.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get reminderSpokenDone;

  /// No description provided for @reminderSpokenOpen.
  ///
  /// In tr, this message translates to:
  /// **'tamamlanmadı'**
  String get reminderSpokenOpen;

  /// No description provided for @reminderOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Gecikti'**
  String get reminderOverdue;

  /// Place label when a location reminder has no name.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get reminderPlaceFallback;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get categoryMarket;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'Ev İşleri'**
  String get categoryHome;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'İş'**
  String get categoryWork;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get categoryHealth;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get categoryErrands;

  /// Built-in category name.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get categoryOther;

  /// Category icon name for screen readers.
  ///
  /// In tr, this message translates to:
  /// **'Etiket'**
  String get categoryIconLabel;

  /// No description provided for @categoryIconBasket.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get categoryIconBasket;

  /// No description provided for @categoryIconHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get categoryIconHome;

  /// No description provided for @categoryIconWork.
  ///
  /// In tr, this message translates to:
  /// **'Çanta'**
  String get categoryIconWork;

  /// No description provided for @categoryIconHeart.
  ///
  /// In tr, this message translates to:
  /// **'Kalp'**
  String get categoryIconHeart;

  /// No description provided for @categoryIconSun.
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get categoryIconSun;

  /// No description provided for @categoryIconFitness.
  ///
  /// In tr, this message translates to:
  /// **'Spor'**
  String get categoryIconFitness;

  /// No description provided for @categoryIconSchool.
  ///
  /// In tr, this message translates to:
  /// **'Okul'**
  String get categoryIconSchool;

  /// No description provided for @categoryIconPets.
  ///
  /// In tr, this message translates to:
  /// **'Evcil hayvan'**
  String get categoryIconPets;

  /// No description provided for @categoryIconCar.
  ///
  /// In tr, this message translates to:
  /// **'Araba'**
  String get categoryIconCar;

  /// No description provided for @categoryIconFlight.
  ///
  /// In tr, this message translates to:
  /// **'Uçak'**
  String get categoryIconFlight;

  /// No description provided for @categoryIconRestaurant.
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get categoryIconRestaurant;

  /// No description provided for @categoryIconPayments.
  ///
  /// In tr, this message translates to:
  /// **'Para'**
  String get categoryIconPayments;

  /// No description provided for @categoryIconMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get categoryIconMedication;

  /// No description provided for @categoryIconChild.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk'**
  String get categoryIconChild;

  /// No description provided for @categoryIconFlower.
  ///
  /// In tr, this message translates to:
  /// **'Çiçek'**
  String get categoryIconFlower;

  /// No description provided for @categoryIconBuild.
  ///
  /// In tr, this message translates to:
  /// **'Tamir'**
  String get categoryIconBuild;

  /// No description provided for @categoryIconBook.
  ///
  /// In tr, this message translates to:
  /// **'Kitap'**
  String get categoryIconBook;

  /// Category colour name for screen readers.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil'**
  String get colorMarket;

  /// No description provided for @colorEv.
  ///
  /// In tr, this message translates to:
  /// **'Turkuaz'**
  String get colorEv;

  /// No description provided for @colorIs.
  ///
  /// In tr, this message translates to:
  /// **'Mavi'**
  String get colorIs;

  /// No description provided for @colorSaglik.
  ///
  /// In tr, this message translates to:
  /// **'Pembe'**
  String get colorSaglik;

  /// No description provided for @colorGunluk.
  ///
  /// In tr, this message translates to:
  /// **'Hardal'**
  String get colorGunluk;

  /// No description provided for @colorDiger.
  ///
  /// In tr, this message translates to:
  /// **'Mor'**
  String get colorDiger;

  /// No description provided for @colorDogumGunu.
  ///
  /// In tr, this message translates to:
  /// **'Eflatun'**
  String get colorDogumGunu;

  /// No description provided for @colorKor.
  ///
  /// In tr, this message translates to:
  /// **'Kor'**
  String get colorKor;

  /// No description provided for @colorLacivert.
  ///
  /// In tr, this message translates to:
  /// **'Lacivert'**
  String get colorLacivert;

  /// No description provided for @colorZeytin.
  ///
  /// In tr, this message translates to:
  /// **'Zeytin'**
  String get colorZeytin;

  /// No description provided for @colorKiremit.
  ///
  /// In tr, this message translates to:
  /// **'Kiremit'**
  String get colorKiremit;

  /// No description provided for @colorArduvaz.
  ///
  /// In tr, this message translates to:
  /// **'Arduvaz'**
  String get colorArduvaz;

  /// Birthday countdown (2+ days).
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} gün}}'**
  String countdownDays(int count);

  /// No description provided for @recurrenceDaily.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her gün} other{{count} günde bir}}'**
  String recurrenceDaily(int count);

  /// No description provided for @recurrenceWeekly.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her hafta} other{{count} haftada bir}}'**
  String recurrenceWeekly(int count);

  /// No description provided for @recurrenceWeeklyOn.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her {day}} other{{count} haftada bir {day}}}'**
  String recurrenceWeeklyOn(int count, String day);

  /// No description provided for @recurrenceWeeklyOnDays.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her hafta {days}} other{{count} haftada bir {days}}}'**
  String recurrenceWeeklyOnDays(int count, String days);

  /// No description provided for @recurrenceMonthly.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her ayın {day}} other{{count} ayda bir, ayın {day}}}'**
  String recurrenceMonthly(int count, String day);

  /// Yıllık tekrar özeti; aralık 1 ise 'Her yıl'.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her yıl} other{{count} yılda bir}}'**
  String recurrenceYearly(int count);

  /// Ay/günü açıkça belirtilmiş yıllık tekrar: 'Her yıl 14 Şubat'.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her yıl {date}} other{{count} yılda bir {date}}}'**
  String recurrenceYearlyOn(int count, String date);

  /// Tamamlamaya bağlı günlük tekrarın özeti (F3.1c).
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Tamamlandıktan 1 gün sonra} other{Tamamlandıktan {count} gün sonra}}'**
  String recurrenceAfterCompletionDays(int count);

  /// Tamamlamaya bağlı haftalık tekrarın özeti (F3.1c).
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Tamamlandıktan 1 hafta sonra} other{Tamamlandıktan {count} hafta sonra}}'**
  String recurrenceAfterCompletionWeeks(int count);

  /// Tamamlamaya bağlı aylık tekrarın özeti (F3.1c).
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Tamamlandıktan 1 ay sonra} other{Tamamlandıktan {count} ay sonra}}'**
  String recurrenceAfterCompletionMonths(int count);

  /// Tamamlamaya bağlı yıllık tekrarın özeti (F3.1c).
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Tamamlandıktan 1 yıl sonra} other{Tamamlandıktan {count} yıl sonra}}'**
  String recurrenceAfterCompletionYears(int count);

  /// No description provided for @birthdayTurnsAge.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşına giriyor'**
  String birthdayTurnsAge(String age);

  /// No description provided for @birthdaySpokenLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü: {name}, {countdown}, {details}'**
  String birthdaySpokenLabel(String name, String countdown, String details);

  /// Gear button tooltip and Ayarlar page title.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTooltip;

  /// Undo snackbar.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” tamamlandı'**
  String undoCompleted(String title);

  /// No description provided for @undoReopened.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” geri açıldı'**
  String undoReopened(String title);

  /// No description provided for @undoDeleted.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” silindi'**
  String undoDeleted(String title);

  /// No description provided for @undoPinned.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” sabitlendi'**
  String undoPinned(String title);

  /// No description provided for @undoUnpinned.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” sabitlemesi kaldırıldı'**
  String undoUnpinned(String title);

  /// Snooze option.
  ///
  /// In tr, this message translates to:
  /// **'10 dakika'**
  String get snoozeTenMinutes;

  /// No description provided for @snoozeOneHour.
  ///
  /// In tr, this message translates to:
  /// **'1 saat'**
  String get snoozeOneHour;

  /// No description provided for @snoozeThisEvening.
  ///
  /// In tr, this message translates to:
  /// **'Bu akşam'**
  String get snoozeThisEvening;

  /// No description provided for @snoozeTomorrowEvening.
  ///
  /// In tr, this message translates to:
  /// **'Yarın akşam'**
  String get snoozeTomorrowEvening;

  /// No description provided for @snoozeTomorrowMorning.
  ///
  /// In tr, this message translates to:
  /// **'Yarın sabah'**
  String get snoozeTomorrowMorning;

  /// Snooze option time on another day: "Pzt 09:00".
  ///
  /// In tr, this message translates to:
  /// **'{weekday} {time}'**
  String snoozeWeekdayTime(String weekday, String time);

  /// "10 dakika, bugün saat 14:42".
  ///
  /// In tr, this message translates to:
  /// **'{option}, {day} {time}'**
  String snoozeOptionSpoken(String option, String day, String time);

  /// No description provided for @snoozeSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ertele'**
  String get snoozeSheetTitle;

  /// No description provided for @snoozeCustom.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat seç…'**
  String get snoozeCustom;

  /// No description provided for @snoozePastError.
  ///
  /// In tr, this message translates to:
  /// **'Bu saat geçti. Daha ileri bir zaman seç.'**
  String get snoozePastError;

  /// Past-time suggestion chip: "Yarın 18:30 mı?".
  ///
  /// In tr, this message translates to:
  /// **'{when} mı?'**
  String pastTimeSuggestion(String when);

  /// No description provided for @pastTimeSuggestionSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{when} olarak ayarla'**
  String pastTimeSuggestionSpoken(String when);

  /// No description provided for @pastTimeError.
  ///
  /// In tr, this message translates to:
  /// **'Bu saat geçti'**
  String get pastTimeError;

  /// No description provided for @pastTimeErrorSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Hata: Bu saat geçti'**
  String get pastTimeErrorSpoken;

  /// Tekrar sheet segment.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get recurrenceModeNone;

  /// No description provided for @recurrenceModeDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get recurrenceModeDaily;

  /// No description provided for @recurrenceModeWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get recurrenceModeWeekly;

  /// No description provided for @recurrenceModeMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get recurrenceModeMonthly;

  /// No description provided for @recurrenceModeYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get recurrenceModeYearly;

  /// No description provided for @recurrenceModeCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get recurrenceModeCustom;

  /// No description provided for @recurrenceNextDay.
  ///
  /// In tr, this message translates to:
  /// **'{day} {time}'**
  String recurrenceNextDay(String day, String time);

  /// Snackbar after completing a recurring reminder.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki: {when}'**
  String recurrenceNext(String when);

  /// No description provided for @recurrencePreviewEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu kuralla yaklaşan tekrar yok.'**
  String get recurrencePreviewEmpty;

  /// No description provided for @recurrenceSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get recurrenceSheetTitle;

  /// No description provided for @recurrenceDays.
  ///
  /// In tr, this message translates to:
  /// **'Günler'**
  String get recurrenceDays;

  /// No description provided for @recurrenceMonthDay.
  ///
  /// In tr, this message translates to:
  /// **'Ayın {day}.'**
  String recurrenceMonthDay(String day);

  /// No description provided for @recurrenceMonthDayClamped.
  ///
  /// In tr, this message translates to:
  /// **'Ayın {day}; kısa aylarda ayın son günü.'**
  String recurrenceMonthDayClamped(String day);

  /// Yıllık tekrar seçildiğinde sheet'teki not: 'Her yıl 17 Mart.'
  ///
  /// In tr, this message translates to:
  /// **'Her yıl {date}.'**
  String recurrenceYearDay(String date);

  /// 29 Şubat'a kurulu yıllık tekrarın sheet'teki notu.
  ///
  /// In tr, this message translates to:
  /// **'Her yıl 29 Şubat; artık yıl olmayan yıllarda 28 Şubat.'**
  String get recurrenceYearLeapDay;

  /// Tekrar sayfasındaki ölçüt seçiminin başlığı (F3.1c).
  ///
  /// In tr, this message translates to:
  /// **'Tekrar ölçütü'**
  String get recurrenceAnchorLabel;

  /// Ölçüt seçeneği: seri sabit tarihlerden oluşur.
  ///
  /// In tr, this message translates to:
  /// **'Takvime göre'**
  String get recurrenceAnchorSchedule;

  /// Ölçüt seçeneği: sıradaki tekrar tamamlama gününden sayılır.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandıktan sonra'**
  String get recurrenceAnchorCompletion;

  /// Takvime göre ölçütünün tek satırlık açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Tarihler sabit: geç tamamlasan da sıradaki tekrar kaymaz.'**
  String get recurrenceAnchorScheduleNote;

  /// Tamamlandıktan sonra ölçütünün tek satırlık açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki tekrar, tamamladığın günden sayılır; tamamlamadıkça burada bekler.'**
  String get recurrenceAnchorCompletionNote;

  /// Tamamlamaya bağlı kuralda 'Sonraki 3: …' yerine geçen satır.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki tarih, tamamladığında belirlenir.'**
  String get recurrenceCompletionPreview;

  /// No description provided for @recurrenceUntilLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get recurrenceUntilLabel;

  /// No description provided for @recurrenceUntilNever.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir zaman'**
  String get recurrenceUntilNever;

  /// No description provided for @recurrenceUntilPick.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş tarihi seç'**
  String get recurrenceUntilPick;

  /// No description provided for @recurrenceUntilClear.
  ///
  /// In tr, this message translates to:
  /// **'Bitişi kaldır'**
  String get recurrenceUntilClear;

  /// Date picker title.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş tarihi'**
  String get recurrenceUntilHelp;

  /// No description provided for @recurrenceDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get recurrenceDecrease;

  /// No description provided for @recurrenceIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get recurrenceIncrease;

  /// Secondary sheet button.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get actionDismiss;

  /// No description provided for @actionDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get actionDone;

  /// intl DateFormat pattern: "Cmt 20 Eyl".
  ///
  /// In tr, this message translates to:
  /// **'EEE d MMM'**
  String get dateFormatWeekdayDayMonth;

  /// intl DateFormat pattern.
  ///
  /// In tr, this message translates to:
  /// **'EEE d MMM y'**
  String get dateFormatWeekdayDayMonthYear;

  /// intl DateFormat pattern: short weekday.
  ///
  /// In tr, this message translates to:
  /// **'EEE'**
  String get dateFormatWeekdayShort;

  /// Snackbar after snoozing. suffix is the Turkish dative ending (a/e/ya/ye) computed in code; unused in English.
  ///
  /// In tr, this message translates to:
  /// **'{when}\'{suffix} ertelendi'**
  String snoozedTo(String when, String suffix);

  /// No description provided for @recurrenceEveryMonth.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Her ay} other{{count} ayda bir}}'**
  String recurrenceEveryMonth(int count);

  /// No description provided for @recurrencePreview.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki {count}: {dates}'**
  String recurrencePreview(int count, String dates);

  /// No description provided for @editorTitleEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Başlık boş olamaz.'**
  String get editorTitleEmpty;

  /// No description provided for @editorDateMissing.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seçin.'**
  String get editorDateMissing;

  /// No description provided for @editorLocationMissing.
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmedi. Bir yer seç ya da «Nerede»yi kapat.'**
  String get editorLocationMissing;

  /// No description provided for @editorLocationPick.
  ///
  /// In tr, this message translates to:
  /// **'Konum seç'**
  String get editorLocationPick;

  /// No description provided for @editorLocationWithRadius.
  ///
  /// In tr, this message translates to:
  /// **'{place} · {radius} m'**
  String editorLocationWithRadius(String place, String radius);

  /// No description provided for @editorLocationChosen.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen konum'**
  String get editorLocationChosen;

  /// No description provided for @editorDatePick.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get editorDatePick;

  /// No description provided for @editorTimePick.
  ///
  /// In tr, this message translates to:
  /// **'Saat seç'**
  String get editorTimePick;

  /// No description provided for @editorNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hatırlatıcı'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıyı düzenle'**
  String get editorEditTitle;

  /// No description provided for @editorTitleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get editorTitleLabel;

  /// No description provided for @editorTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Ne hatırlatayım?'**
  String get editorTitleHint;

  /// No description provided for @editorNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get editorNoteLabel;

  /// No description provided for @editorCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get editorCategory;

  /// No description provided for @editorNewCategoryChip.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get editorNewCategoryChip;

  /// No description provided for @editorNewCategoryTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori'**
  String get editorNewCategoryTooltip;

  /// No description provided for @editorWhen.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman'**
  String get editorWhen;

  /// No description provided for @editorScheduleSwitch.
  ///
  /// In tr, this message translates to:
  /// **'Zamanla ve bildir'**
  String get editorScheduleSwitch;

  /// No description provided for @editorWhenHint.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin tarih ve saatte bildirim.'**
  String get editorWhenHint;

  /// No description provided for @editorWhere.
  ///
  /// In tr, this message translates to:
  /// **'Nerede'**
  String get editorWhere;

  /// No description provided for @editorLocationSwitch.
  ///
  /// In tr, this message translates to:
  /// **'Konuma gelince hatırlat'**
  String get editorLocationSwitch;

  /// No description provided for @editorLocationEnterHint.
  ///
  /// In tr, this message translates to:
  /// **'Bölgeye girince bildirim.'**
  String get editorLocationEnterHint;

  /// No description provided for @editorWhereHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir yere varınca hatırlat.'**
  String get editorWhereHint;

  /// No description provided for @editorRecurrenceSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar: {summary}'**
  String editorRecurrenceSpoken(String summary);

  /// No description provided for @editorRecurrence.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get editorRecurrence;

  /// No description provided for @editorLocationWhileInUse.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni yalnızca kullanırken açık. Uygulama kapalıyken bildirim gelmeyebilir.'**
  String get editorLocationWhileInUse;

  /// No description provided for @editorLocationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni yok. Yeri haritadan seçebilirsin ama arka planda bildirim gelmeyebilir.'**
  String get editorLocationDenied;

  /// No description provided for @editorFix.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt'**
  String get editorFix;

  /// No description provided for @editorPriority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get editorPriority;

  /// Editor card with checklist items (subtasks).
  ///
  /// In tr, this message translates to:
  /// **'Maddeler'**
  String get subtasksTitle;

  /// No description provided for @subtasksAllDone.
  ///
  /// In tr, this message translates to:
  /// **'Tümü tamam — hatırlatıcıyı tamamla?'**
  String get subtasksAllDone;

  /// Name of an untitled item; also the item field hint.
  ///
  /// In tr, this message translates to:
  /// **'Madde'**
  String get subtaskFallback;

  /// No description provided for @subtaskOptions.
  ///
  /// In tr, this message translates to:
  /// **'{title} seçenekleri'**
  String subtaskOptions(String title);

  /// No description provided for @subtaskMoveUp.
  ///
  /// In tr, this message translates to:
  /// **'Yukarı taşı'**
  String get subtaskMoveUp;

  /// No description provided for @subtaskMoveDown.
  ///
  /// In tr, this message translates to:
  /// **'Aşağı taşı'**
  String get subtaskMoveDown;

  /// No description provided for @subtaskHintReopen.
  ///
  /// In tr, this message translates to:
  /// **'Geri açmak için dokun'**
  String get subtaskHintReopen;

  /// No description provided for @subtaskHintComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlamak için dokun'**
  String get subtaskHintComplete;

  /// No description provided for @subtaskAdd.
  ///
  /// In tr, this message translates to:
  /// **'Madde ekle'**
  String get subtaskAdd;

  /// No description provided for @subtaskSplit.
  ///
  /// In tr, this message translates to:
  /// **'Maddelere böl'**
  String get subtaskSplit;

  /// No description provided for @subtasksDoneCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{Tamamlanan {count} madde}}'**
  String subtasksDoneCount(int count);

  /// No description provided for @categoryNameEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriye bir ad ver'**
  String get categoryNameEmpty;

  /// No description provided for @categoryNameTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu adda bir kategori zaten var'**
  String get categoryNameTaken;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'“{name}” silinsin mi?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride hatırlatıcı yok.'**
  String get categoryDeleteEmpty;

  /// No description provided for @categoryDeleteMoves.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{Bu kategorideki {count} hatırlatıcı {other}\'e taşınacak.}}'**
  String categoryDeleteMoves(int count, String other);

  /// No description provided for @categoryNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriyi düzenle'**
  String get categoryEdit;

  /// No description provided for @categoryNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Spor salonu'**
  String get categoryNameHint;

  /// No description provided for @categoryColor.
  ///
  /// In tr, this message translates to:
  /// **'Renk'**
  String get categoryColor;

  /// No description provided for @categoryIcon.
  ///
  /// In tr, this message translates to:
  /// **'İkon'**
  String get categoryIcon;

  /// No description provided for @categoryPreviewSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme: {name}'**
  String categoryPreviewSpoken(String name);

  /// No description provided for @categoryListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategorilerim'**
  String get categoryListTitle;

  /// No description provided for @actionFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get actionFinish;

  /// No description provided for @categoryRowSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {count} açık'**
  String categoryRowSpoken(String name, int count);

  /// No description provided for @categoryEditTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{name} düzenle'**
  String categoryEditTooltip(String name);

  /// No description provided for @categoryMoveSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{name} taşı'**
  String categoryMoveSpoken(String name);

  /// No description provided for @todaySummary.
  ///
  /// In tr, this message translates to:
  /// **'{open} açık · {overdue} gecikmiş · {done} tamam'**
  String todaySummary(int open, int overdue, int done);

  /// Bugün tab title.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get todayTitle;

  /// No description provided for @todayNotificationsOffTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapalı'**
  String get todayNotificationsOffTitle;

  /// No description provided for @todayNotificationsOffBody.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar zamanında gelmeyecek.'**
  String get todayNotificationsOffBody;

  /// No description provided for @permissionAllow.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get permissionAllow;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get permissionOpenSettings;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün boş'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Keyfine bak ya da aklındakini aşağıya yaz.'**
  String get todayEmptyBody;

  /// No description provided for @todayEmptyAction.
  ///
  /// In tr, this message translates to:
  /// **'Yarını planla'**
  String get todayEmptyAction;

  /// No description provided for @todayAllDoneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi tamam.'**
  String get todayAllDoneTitle;

  /// No description provided for @todayAllDoneBody.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{Bugünkü {count} hatırlatmanın hepsini bitirdin.}}'**
  String todayAllDoneBody(int count);

  /// No description provided for @todayShowCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananları göster'**
  String get todayShowCompleted;

  /// No description provided for @todayHideCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananları gizle'**
  String get todayHideCompleted;

  /// No description provided for @todayUntimed.
  ///
  /// In tr, this message translates to:
  /// **'Bugün bir ara'**
  String get todayUntimed;

  /// No description provided for @todayOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Kaçanlar'**
  String get todayOverdue;

  /// No description provided for @todayMoveOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Hepsini yarına al'**
  String get todayMoveOverdue;

  /// No description provided for @todayTimeline.
  ///
  /// In tr, this message translates to:
  /// **'Zaman çizelgesi'**
  String get todayTimeline;

  /// No description provided for @todayProgressSpoken.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme: {done} / {total} tamamlandı'**
  String todayProgressSpoken(int done, int total);

  /// No description provided for @todayCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar'**
  String get todayCompleted;

  /// No description provided for @todayCompletedSpokenShow.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar, {count}, göster'**
  String todayCompletedSpokenShow(int count);

  /// No description provided for @todayCompletedSpokenHide.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar, {count}, gizle'**
  String todayCompletedSpokenHide(int count);

  /// No description provided for @todayNowSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi, {time}'**
  String todayNowSpoken(String time);

  /// No description provided for @overdueMovedOne.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” yarına alındı'**
  String overdueMovedOne(String title);

  /// No description provided for @overdueMovedMany.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} hatırlatıcı yarına alındı}}'**
  String overdueMovedMany(int count);

  /// No description provided for @calendarFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get calendarFilterAll;

  /// No description provided for @calendarFilterReminders.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar'**
  String get calendarFilterReminders;

  /// No description provided for @calendarFilterBirthdays.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günleri'**
  String get calendarFilterBirthdays;

  /// No description provided for @calendarFilterLocated.
  ///
  /// In tr, this message translates to:
  /// **'Konumlu'**
  String get calendarFilterLocated;

  /// Agenda action: pick another day.
  ///
  /// In tr, this message translates to:
  /// **'Taşı…'**
  String get calendarMove;

  /// No description provided for @calendarSeriesNext.
  ///
  /// In tr, this message translates to:
  /// **'serinin sonraki tekrarı'**
  String get calendarSeriesNext;

  /// No description provided for @calendarEditSeries.
  ///
  /// In tr, this message translates to:
  /// **'Seriyi düzenle'**
  String get calendarEditSeries;

  /// No description provided for @calendarEmptyDay.
  ///
  /// In tr, this message translates to:
  /// **'{date} — boş gün'**
  String calendarEmptyDay(String date);

  /// No description provided for @calendarEmptyDaySpoken.
  ///
  /// In tr, this message translates to:
  /// **'{date}, boş gün'**
  String calendarEmptyDaySpoken(String date);

  /// No description provided for @calendarEmptyDayHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne hatırlatıcı ekle'**
  String get calendarEmptyDayHint;

  /// No description provided for @calendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendarTitle;

  /// Button: jump to today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get calendarToday;

  /// No description provided for @calendarWeekView.
  ///
  /// In tr, this message translates to:
  /// **'Hafta görünümüne geç'**
  String get calendarWeekView;

  /// No description provided for @calendarMonthView.
  ///
  /// In tr, this message translates to:
  /// **'Ay görünümüne geç'**
  String get calendarMonthView;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In tr, this message translates to:
  /// **'Önceki ay'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarPreviousWeek.
  ///
  /// In tr, this message translates to:
  /// **'Önceki hafta'**
  String get calendarPreviousWeek;

  /// No description provided for @calendarNextMonth.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ay'**
  String get calendarNextMonth;

  /// No description provided for @calendarNextWeek.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki hafta'**
  String get calendarNextWeek;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan bir şey yok'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Önümüzdeki {days} günde planlı hatırlatma ya da doğum günü yok.'**
  String calendarEmptyBody(int days);

  /// No description provided for @calendarEmptyFilteredBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtreyle önümüzdeki {days} günde bir şey yok.'**
  String calendarEmptyFilteredBody(int days);

  /// No description provided for @calendarAddReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı ekle'**
  String get calendarAddReminder;

  /// No description provided for @calendarMoved.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” taşındı · {when}'**
  String calendarMoved(String title, String when);

  /// No description provided for @calendarMovePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi güne taşınsın?'**
  String get calendarMovePickerTitle;

  /// No description provided for @calendarMoveConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Taşı'**
  String get calendarMoveConfirm;

  /// No description provided for @calendarMovePast.
  ///
  /// In tr, this message translates to:
  /// **'Bu saat geçti; başka bir gün seç.'**
  String get calendarMovePast;

  /// No description provided for @calendarDayToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get calendarDayToday;

  /// No description provided for @calendarDayHasEntries.
  ///
  /// In tr, this message translates to:
  /// **'planlı kayıt var'**
  String get calendarDayHasEntries;

  /// Listeler tab title.
  ///
  /// In tr, this message translates to:
  /// **'Listeler'**
  String get listsTitle;

  /// No description provided for @listsCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar'**
  String get listsCompleted;

  /// No description provided for @listsCompletedCountSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{title}, {count} tamamlandı'**
  String listsCompletedCountSpoken(String title, int count);

  /// No description provided for @listsBirthdayCountSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{title}, {count} doğum günü'**
  String listsBirthdayCountSpoken(String title, int count);

  /// No description provided for @listsReminderCountSpoken.
  ///
  /// In tr, this message translates to:
  /// **'{title}, {count} hatırlatıcı'**
  String listsReminderCountSpoken(String title, int count);

  /// No description provided for @smartListOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Gecikmiş'**
  String get smartListOverdue;

  /// No description provided for @smartListToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get smartListToday;

  /// No description provided for @smartListScheduled.
  ///
  /// In tr, this message translates to:
  /// **'Planlı'**
  String get smartListScheduled;

  /// No description provided for @smartListUntimed.
  ///
  /// In tr, this message translates to:
  /// **'Zamansız'**
  String get smartListUntimed;

  /// No description provided for @smartListBirthdays.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günleri'**
  String get smartListBirthdays;

  /// No description provided for @smartListLocated.
  ///
  /// In tr, this message translates to:
  /// **'Konumlu'**
  String get smartListLocated;

  /// No description provided for @smartListOpenCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} açık'**
  String smartListOpenCount(int count);

  /// No description provided for @smartListOverdueEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gecikmiş bir şey yok'**
  String get smartListOverdueEmptyTitle;

  /// No description provided for @smartListOverdueEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Her şey zamanında, böyle devam.'**
  String get smartListOverdueEmptyBody;

  /// No description provided for @smartListTodayEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için saatli bir şey yok'**
  String get smartListTodayEmptyTitle;

  /// No description provided for @smartListTodayEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne saat verdiğin hatırlatmalar burada görünür.'**
  String get smartListTodayEmptyBody;

  /// No description provided for @smartListScheduledEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planlı hatırlatma yok'**
  String get smartListScheduledEmptyTitle;

  /// No description provided for @smartListScheduledEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Saat verdiğin hatırlatmalar burada birikir.'**
  String get smartListScheduledEmptyBody;

  /// No description provided for @smartListUntimedEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zamansız hatırlatma yok'**
  String get smartListUntimedEmptyTitle;

  /// No description provided for @smartListUntimedEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Saati olmayan hatırlatmalar burada durur.'**
  String get smartListUntimedEmptyBody;

  /// No description provided for @smartListBirthdaysEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz doğum günü yok'**
  String get smartListBirthdaysEmptyTitle;

  /// No description provided for @smartListBirthdaysEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiklerinin gününü kaçırma.'**
  String get smartListBirthdaysEmptyBody;

  /// No description provided for @smartListLocatedEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konumlu hatırlatma yok'**
  String get smartListLocatedEmptyTitle;

  /// No description provided for @smartListLocatedEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir yere varınca hatırlatmak için hatırlatıcıda \'Nerede\'yi aç.'**
  String get smartListLocatedEmptyBody;

  /// No description provided for @filterEditCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriyi düzenle'**
  String get filterEditCategory;

  /// No description provided for @filterCompletedSummary.
  ///
  /// In tr, this message translates to:
  /// **'{count} tamamlandı'**
  String filterCompletedSummary(int count);

  /// No description provided for @filterCategorySummary.
  ///
  /// In tr, this message translates to:
  /// **'{open} açık · {done} tamam'**
  String filterCategorySummary(int open, int done);

  /// No description provided for @filterNoCompletedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanan yok'**
  String get filterNoCompletedTitle;

  /// No description provided for @filterNoCompletedBody.
  ///
  /// In tr, this message translates to:
  /// **'Tamamladığın hatırlatmalar burada birikir.'**
  String get filterNoCompletedBody;

  /// No description provided for @filterListEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'{title} listesi boş'**
  String filterListEmptyTitle(String title);

  /// No description provided for @filterListEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Eklemek için aşağıdaki düğmeye dokun.'**
  String get filterListEmptyBody;

  /// No description provided for @filterAddToList.
  ///
  /// In tr, this message translates to:
  /// **'Bu listeye ekle'**
  String get filterAddToList;

  /// No description provided for @searchTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get searchTooltip;

  /// No description provided for @searchAllCategories.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kategoriler'**
  String get searchAllCategories;

  /// No description provided for @actionBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get actionBack;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılarda ara'**
  String get searchHint;

  /// No description provided for @actionClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get actionClear;

  /// No description provided for @searchCategoryChip.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get searchCategoryChip;

  /// No description provided for @searchOpenChip.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get searchOpenChip;

  /// No description provided for @searchCompletedChip.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get searchCompletedChip;

  /// No description provided for @searchPickCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori seç'**
  String get searchPickCategory;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılarında ara'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Başlık, not, kategori ya da yer adıyla bulabilirsin.'**
  String get searchEmptyBody;

  /// No description provided for @searchRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son aramalar'**
  String get searchRecent;

  /// No description provided for @searchRecentSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Son arama: {query}'**
  String searchRecentSpoken(String query);

  /// No description provided for @searchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'“{query}” için sonuç yok'**
  String searchNoResults(String query);

  /// No description provided for @searchNoResultsWiden.
  ///
  /// In tr, this message translates to:
  /// **'Yazımı kontrol et veya tamamlananlarda ara.'**
  String get searchNoResultsWiden;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In tr, this message translates to:
  /// **'Yazımı kontrol et.'**
  String get searchNoResultsBody;

  /// No description provided for @searchInCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlarda ara'**
  String get searchInCompleted;

  /// No description provided for @searchResultCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} sonuç'**
  String searchResultCount(int count);

  /// No description provided for @searchGroupReminders.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar'**
  String get searchGroupReminders;

  /// No description provided for @searchGroupNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlarda'**
  String get searchGroupNotes;

  /// No description provided for @searchGroupHeader.
  ///
  /// In tr, this message translates to:
  /// **'{title} · {count}'**
  String searchGroupHeader(String title, int count);

  /// No description provided for @searchUntimed.
  ///
  /// In tr, this message translates to:
  /// **'Zamansız'**
  String get searchUntimed;

  /// No description provided for @searchOverdueWhen.
  ///
  /// In tr, this message translates to:
  /// **'Gecikti · {when}'**
  String searchOverdueWhen(String when);

  /// No description provided for @birthdayRowAge.
  ///
  /// In tr, this message translates to:
  /// **'{date} · {age} yaşına'**
  String birthdayRowAge(String date, String age);

  /// No description provided for @birthdayRowNoAge.
  ///
  /// In tr, this message translates to:
  /// **'{date} · yaş bilinmiyor'**
  String birthdayRowNoAge(String date);

  /// No description provided for @birthdayLeapNote.
  ///
  /// In tr, this message translates to:
  /// **'Artık yıl değil: 28 Şubat\'ta hatırlatılır'**
  String get birthdayLeapNote;

  /// No description provided for @birthdayHeroAge.
  ///
  /// In tr, this message translates to:
  /// **'{when} · {age} yaşına giriyor'**
  String birthdayHeroAge(String when, String age);

  /// No description provided for @birthdayAddTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü ekle'**
  String get birthdayAddTooltip;

  /// No description provided for @birthdaysTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günleri'**
  String get birthdaysTitle;

  /// No description provided for @birthdaysEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz doğum günü yok'**
  String get birthdaysEmptyTitle;

  /// No description provided for @birthdaysEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiklerinin gününü kaçırma. Rehberden içe aktarma yakında.'**
  String get birthdaysEmptyBody;

  /// Unit under the large countdown number.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{gün}}'**
  String birthdayHeroDaysUnit(int count);

  /// No description provided for @birthdayHeroSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki doğum günü: {name}'**
  String birthdayHeroSpoken(String name);

  /// No description provided for @birthdayDaysLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} gün kaldı}}'**
  String birthdayDaysLeft(int count);

  /// No description provided for @birthdayHeroOverline.
  ///
  /// In tr, this message translates to:
  /// **'SIRADAKİ'**
  String get birthdayHeroOverline;

  /// No description provided for @birthdayDatePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi'**
  String get birthdayDatePickerTitle;

  /// No description provided for @birthdayTimePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim saati'**
  String get birthdayTimePickerTitle;

  /// No description provided for @birthdayNameEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İsim boş olamaz.'**
  String get birthdayNameEmpty;

  /// No description provided for @birthdayOffsetsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'En az bir hatırlatma zamanı seçin.'**
  String get birthdayOffsetsEmpty;

  /// No description provided for @birthdayDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Silinsin mi?'**
  String get birthdayDeleteTitle;

  /// No description provided for @birthdayDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" doğum günü hatırlatması silinecek.'**
  String birthdayDeleteBody(String name);

  /// No description provided for @birthdayNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni doğum günü'**
  String get birthdayNew;

  /// No description provided for @birthdayEdit.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü düzenle'**
  String get birthdayEdit;

  /// No description provided for @birthdayNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get birthdayNameLabel;

  /// No description provided for @birthdayNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Ayşe'**
  String get birthdayNameHint;

  /// No description provided for @birthdayNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Hediye fikri'**
  String get birthdayNoteHint;

  /// No description provided for @birthdayDateCard.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve bildirim saati'**
  String get birthdayDateCard;

  /// No description provided for @birthdayDatePick.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi seç'**
  String get birthdayDatePick;

  /// No description provided for @birthdayTimeSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim saati: {time}'**
  String birthdayTimeSpoken(String time);

  /// No description provided for @birthdayTimePick.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim saati seç'**
  String get birthdayTimePick;

  /// No description provided for @birthdayYearUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Yıl bilinmiyor'**
  String get birthdayYearUnknown;

  /// No description provided for @birthdayYearUnknownHint.
  ///
  /// In tr, this message translates to:
  /// **'Yılı bilmiyorsan “Yıl bilinmiyor”u seç; yaş gösterilmez.'**
  String get birthdayYearUnknownHint;

  /// No description provided for @birthdayWhenCard.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman hatırlatayım?'**
  String get birthdayWhenCard;

  /// No description provided for @birthdayWhenHint.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçim yapabilirsin.'**
  String get birthdayWhenHint;

  /// No description provided for @birthdayOffsetOnDay.
  ///
  /// In tr, this message translates to:
  /// **'Doğum gününde'**
  String get birthdayOffsetOnDay;

  /// No description provided for @birthdayOffsetMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} dakika önce}}'**
  String birthdayOffsetMinutes(int count);

  /// No description provided for @birthdayOffsetHours.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} saat önce}}'**
  String birthdayOffsetHours(int count);

  /// No description provided for @birthdayOffsetDays.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} gün önce}}'**
  String birthdayOffsetDays(int count);

  /// No description provided for @birthdayOffsetWeeks.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} hafta önce}}'**
  String birthdayOffsetWeeks(int count);

  /// No description provided for @captureBarLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ekle'**
  String get captureBarLabel;

  /// No description provided for @captureBarHint.
  ///
  /// In tr, this message translates to:
  /// **'Ne hatırlatayım? Uzun basınca ayrıntılı hatırlatıcı veya doğum günü seçilir'**
  String get captureBarHint;

  /// No description provided for @captureFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'Ne hatırlatayım?'**
  String get captureFieldHint;

  /// Helper line under the quick capture field: examples of the natural-language phrases the parser understands, in the app language.
  ///
  /// In tr, this message translates to:
  /// **'Örnek: yarın 9\'da, her pazartesi, #market'**
  String get captureParserExamples;

  /// No description provided for @captureCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get captureCategory;

  /// No description provided for @capturePriority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get capturePriority;

  /// No description provided for @captureAllDetails.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ayrıntılar'**
  String get captureAllDetails;

  /// No description provided for @captureDateChip.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get captureDateChip;

  /// No description provided for @captureDateChipSet.
  ///
  /// In tr, this message translates to:
  /// **'{day}, {time}'**
  String captureDateChipSet(String day, String time);

  /// No description provided for @captureDateSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Zaman: {when}'**
  String captureDateSpoken(String when);

  /// No description provided for @captureDateAdd.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ekle'**
  String get captureDateAdd;

  /// No description provided for @captureRecurrenceChip.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get captureRecurrenceChip;

  /// No description provided for @captureRecurrenceSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar: {summary}'**
  String captureRecurrenceSpoken(String summary);

  /// No description provided for @captureRecurrenceAdd.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar ekle'**
  String get captureRecurrenceAdd;

  /// No description provided for @captureNewCategory.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori: #{tag}'**
  String captureNewCategory(String tag);

  /// No description provided for @captureNewCategorySpoken.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori: {tag}. Oluşturmak için dokun'**
  String captureNewCategorySpoken(String tag);

  /// No description provided for @captureCategorySpoken.
  ///
  /// In tr, this message translates to:
  /// **'Kategori: {name}'**
  String captureCategorySpoken(String name);

  /// No description provided for @captureCategoryPick.
  ///
  /// In tr, this message translates to:
  /// **'Kategori seç'**
  String get captureCategoryPick;

  /// No description provided for @capturePriorityPick.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik seç'**
  String get capturePriorityPick;

  /// No description provided for @capturePlaceSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Yer: {place}. Nota eklenir; konum bildirimi için Tüm ayrıntılar'**
  String capturePlaceSpoken(String place);

  /// No description provided for @captureSplitCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} madde'**
  String captureSplitCount(int count);

  /// No description provided for @captureSplitAsk.
  ///
  /// In tr, this message translates to:
  /// **'Maddelere böl?'**
  String get captureSplitAsk;

  /// No description provided for @captureSplitUndo.
  ///
  /// In tr, this message translates to:
  /// **'Maddelere bölmeyi geri al'**
  String get captureSplitUndo;

  /// No description provided for @captureSplitDo.
  ///
  /// In tr, this message translates to:
  /// **'{count} maddeye böl'**
  String captureSplitDo(int count);

  /// No description provided for @captureChipPlainText.
  ///
  /// In tr, this message translates to:
  /// **'Düz metne çevir'**
  String get captureChipPlainText;

  /// No description provided for @captureAdded.
  ///
  /// In tr, this message translates to:
  /// **'Eklendi: {title}'**
  String captureAdded(String title);

  /// Title of a split grocery list.
  ///
  /// In tr, this message translates to:
  /// **'Market alışverişi'**
  String get captureListTitleMarket;

  /// No description provided for @captureListTitle.
  ///
  /// In tr, this message translates to:
  /// **'{category} listesi'**
  String captureListTitle(String category);

  /// Note of a captured reminder with @place.
  ///
  /// In tr, this message translates to:
  /// **'Yer: {place}'**
  String capturePlaceNote(String place);

  /// No description provided for @backupShared.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası paylaşıldı.'**
  String get backupShared;

  /// No description provided for @backupExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek oluşturulamadı. Tekrar dene.'**
  String get backupExportFailed;

  /// No description provided for @backupTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya bir Hatırlatıcı yedeği olamayacak kadar büyük.'**
  String get backupTooLarge;

  /// No description provided for @backupReadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dosya okunamadı.'**
  String get backupReadFailed;

  /// No description provided for @backupReplaceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verileri değiştir'**
  String get backupReplaceTitle;

  /// No description provided for @backupReplaceBody.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut hatırlatıcıların ve doğum günlerin silinip yedektekilerle değiştirilir. Bu işlem geri alınamaz.'**
  String get backupReplaceBody;

  /// No description provided for @backupRestored.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklendi: {reminders} hatırlatıcı, {birthdays} doğum günü.'**
  String backupRestored(int reminders, int birthdays);

  /// No description provided for @backupRestoreFailed.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme tamamlanamadı; veriler kısmen değişmiş olabilir. Aynı dosyayı tekrar geri yükleyebilirsin.'**
  String get backupRestoreFailed;

  /// No description provided for @backupErrorNotJson.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya okunamadı: geçerli bir yedek dosyası değil.'**
  String get backupErrorNotJson;

  /// No description provided for @backupErrorNotBackup.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya bir Hatırlatıcı yedeği değil.'**
  String get backupErrorNotBackup;

  /// No description provided for @backupErrorNewer.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedek uygulamanın daha yeni bir sürümüyle alınmış (sürüm {version}). Geri yüklemek için uygulamayı güncelle.'**
  String backupErrorNewer(String version);

  /// No description provided for @backupErrorInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası bozuk; hiçbir şey değiştirilmedi.'**
  String get backupErrorInvalid;

  /// No description provided for @backupFound.
  ///
  /// In tr, this message translates to:
  /// **'{reminders} hatırlatıcı, {birthdays} doğum günü bulundu.'**
  String backupFound(int reminders, int birthdays);

  /// No description provided for @backupFoundSkipped.
  ///
  /// In tr, this message translates to:
  /// **'{reminders} hatırlatıcı, {birthdays} doğum günü bulundu; {skipped} kayıt okunamadı.'**
  String backupFoundSkipped(int reminders, int birthdays, int skipped);

  /// No description provided for @backupRestoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği geri yükle'**
  String get backupRestoreTitle;

  /// No description provided for @backupDate.
  ///
  /// In tr, this message translates to:
  /// **'Yedek tarihi: {date} {time}'**
  String backupDate(String date, String time);

  /// No description provided for @backupSkippedHint.
  ///
  /// In tr, this message translates to:
  /// **'Okunamayan kayıtlar atlanır; diğerleri geri yüklenir.'**
  String get backupSkippedHint;

  /// No description provided for @backupMerge.
  ///
  /// In tr, this message translates to:
  /// **'Birleştir'**
  String get backupMerge;

  /// No description provided for @backupReplace.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get backupReplace;

  /// No description provided for @backupMergeHint.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kayıtların kalır, yedektekiler eklenir. Aynı kayıt iki tarafta da varsa yedekteki sürüm kullanılır. Ayarlar değişmez.'**
  String get backupMergeHint;

  /// No description provided for @backupReplaceHint.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut hatırlatıcıların ve doğum günlerin silinir, yerine yedektekiler gelir. Ayarlar da yedekten alınır.'**
  String get backupReplaceHint;

  /// No description provided for @backupRestore.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükle'**
  String get backupRestore;

  /// No description provided for @permissionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzinler'**
  String get permissionsTitle;

  /// No description provided for @permissionOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get permissionOn;

  /// No description provided for @permissionNotificationsNotRequested.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilmedi — hatırlatmalar bildirim olarak gelmez'**
  String get permissionNotificationsNotRequested;

  /// No description provided for @permissionNotificationsDenied.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı — hatırlatmalar zamanında gelmez'**
  String get permissionNotificationsDenied;

  /// No description provided for @permissionNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get permissionNotifications;

  /// No description provided for @permissionLocationAlways.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman'**
  String get permissionLocationAlways;

  /// No description provided for @permissionLocationWhileInUse.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca kullanırken — arka plan hatırlatmaları çalışmaz'**
  String get permissionLocationWhileInUse;

  /// No description provided for @permissionLocationNotRequested.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilmedi — konum hatırlatmaları çalışmaz'**
  String get permissionLocationNotRequested;

  /// No description provided for @permissionLocationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı — konum hatırlatmaları çalışmaz'**
  String get permissionLocationDenied;

  /// No description provided for @permissionLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get permissionLocation;

  /// No description provided for @permissionFix.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt'**
  String get permissionFix;

  /// No description provided for @permissionExactAlarms.
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanlı alarmlar'**
  String get permissionExactAlarms;

  /// No description provided for @permissionExactAlarmsOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı — izin olmadan hatırlatmalar birkaç dakika gecikebilir'**
  String get permissionExactAlarmsOff;

  /// No description provided for @permissionChecking.
  ///
  /// In tr, this message translates to:
  /// **'Denetleniyor…'**
  String get permissionChecking;

  /// No description provided for @resetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileri sıfırla'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm hatırlatmalar ve ayarlar silinir. Bu işlem geri alınamaz. Silmeden önce bir yedek alabilirsin.'**
  String get resetBody;

  /// No description provided for @resetBackupFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce yedekle'**
  String get resetBackupFirst;

  /// No description provided for @widgetPinUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda boş bir alana uzun basın → Widget\'lar → Hatırlatıcı\'yı seçin.'**
  String get widgetPinUnsupported;

  /// No description provided for @widgetPinTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi widget?'**
  String get widgetPinTitle;

  /// Home widget name; same as the Android widget picker (values/strings.xml).
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get homeWidgetToday;

  /// No description provided for @homeWidgetList.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get homeWidgetList;

  /// No description provided for @homeWidgetNext.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki'**
  String get homeWidgetNext;

  /// No description provided for @homeWidgetQuickAdd.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ekle'**
  String get homeWidgetQuickAdd;

  /// No description provided for @homeWidgetTodayDescription.
  ///
  /// In tr, this message translates to:
  /// **'4×2 · bugünün ilk iki işi ve \"+\"'**
  String get homeWidgetTodayDescription;

  /// No description provided for @homeWidgetListDescription.
  ///
  /// In tr, this message translates to:
  /// **'4×4 · kaydırılabilir, boyutu değişir'**
  String get homeWidgetListDescription;

  /// No description provided for @homeWidgetNextDescription.
  ///
  /// In tr, this message translates to:
  /// **'2×2 · sıradaki iş ve saati'**
  String get homeWidgetNextDescription;

  /// No description provided for @homeWidgetQuickAddDescription.
  ///
  /// In tr, this message translates to:
  /// **'1×1 · tek dokunuşla yeni hatırlatıcı'**
  String get homeWidgetQuickAddDescription;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeHint.
  ///
  /// In tr, this message translates to:
  /// **'Açık veya koyu temayı seç ya da sistemi takip et.'**
  String get settingsThemeHint;

  /// No description provided for @settingsHaptics.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim geri bildirimi'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlama, silme ve kaydırma gibi aksiyonlarda kısa titreşim.'**
  String get settingsHapticsHint;

  /// No description provided for @settingsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotifications;

  /// No description provided for @settingsReminderNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma bildirimleri'**
  String get settingsReminderNotifications;

  /// No description provided for @settingsReminderNotificationsHint.
  ///
  /// In tr, this message translates to:
  /// **'Kapalıyken zamanlanmış hatırlatmalar gönderilmez. Açıkken sistem bildirim ayarları geçerlidir (ses, öncelik).'**
  String get settingsReminderNotificationsHint;

  /// No description provided for @settingsLocationNeedsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Konum hatırlatmaları için de bildirimler açık olmalı.'**
  String get settingsLocationNeedsNotifications;

  /// No description provided for @settingsHomeWidget.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekran widget\'ı'**
  String get settingsHomeWidget;

  /// No description provided for @settingsHomeWidgetHint.
  ///
  /// In tr, this message translates to:
  /// **'Dört widget var: Bugün, kaydırılabilir Liste, Sıradaki ve Hızlı ekle. Daireye dokunarak işi tamamlarsın, \"+\" hızlı ekler. Liste\'nin boyutunu ana ekranda kenarlarından sürükleyerek değiştirebilirsin.'**
  String get settingsHomeWidgetHint;

  /// No description provided for @settingsAddWidget.
  ///
  /// In tr, this message translates to:
  /// **'Widget ekle'**
  String get settingsAddWidget;

  /// No description provided for @settingsBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle ve geri yükle'**
  String get settingsBackup;

  /// No description provided for @settingsBackupHint.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılarını, doğum günlerini ve ayarlarını bir dosyaya yedekle; yeni bir cihazda veya yeniden kurulumdan sonra geri yükle.'**
  String get settingsBackupHint;

  /// No description provided for @settingsBackupExport.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get settingsBackupExport;

  /// No description provided for @settingsOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get settingsOther;

  /// No description provided for @settingsPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik politikası'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Lisanslar'**
  String get settingsLicenses;

  /// No description provided for @settingsLinkFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı.'**
  String get settingsLinkFailed;

  /// No description provided for @navTabHint.
  ///
  /// In tr, this message translates to:
  /// **'Sekme {index} / {count}'**
  String navTabHint(int index, int count);

  /// No description provided for @navShowTabs.
  ///
  /// In tr, this message translates to:
  /// **'Sekmeleri göster'**
  String get navShowTabs;

  /// No description provided for @newItemQuick.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ekle'**
  String get newItemQuick;

  /// No description provided for @newItemReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get newItemReminder;

  /// No description provided for @newItemBirthday.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü'**
  String get newItemBirthday;

  /// No description provided for @newItemDetailedReminder.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntılı hatırlatıcı'**
  String get newItemDetailedReminder;

  /// No description provided for @newItemFabHint.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ekleme açılır. Uzun basınca ayrıntılı hatırlatıcı veya doğum günü seçilir'**
  String get newItemFabHint;

  /// No description provided for @permNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmaları zamanında al'**
  String get permNotifTitle;

  /// No description provided for @permNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin saatte haber verebilmem için bildirim izni gerekiyor.'**
  String get permNotifBody;

  /// No description provided for @permNotifPoint1.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar tam zamanında bildirim olarak gelir.'**
  String get permNotifPoint1;

  /// No description provided for @permNotifPoint2.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günlerini önceden haber veririm.'**
  String get permNotifPoint2;

  /// No description provided for @permNotifPoint3.
  ///
  /// In tr, this message translates to:
  /// **'Konuma varınca da bildirim gönderirim.'**
  String get permNotifPoint3;

  /// No description provided for @permNotifConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlere izin ver'**
  String get permNotifConfirm;

  /// No description provided for @permNotNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get permNotNow;

  /// No description provided for @permExactTradeOff.
  ///
  /// In tr, this message translates to:
  /// **'İzin olmadan hatırlatmalar birkaç dakika gecikebilir.'**
  String get permExactTradeOff;

  /// No description provided for @permExactTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanında hatırlatma'**
  String get permExactTitle;

  /// No description provided for @permExactBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlerin dakikası dakikasına gelmesi için “Alarmlar ve hatırlatıcılar” iznini açabilirsin. {tradeOff} Hatırlatmaların yine de gelir.'**
  String permExactBody(String tradeOff);

  /// No description provided for @permLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir yere varınca hatırlatayım'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In tr, this message translates to:
  /// **'Haritada yer seçmek ve oraya vardığında sana haber vermek için konum izni gerekiyor. Konumun yalnızca bu cihazda kullanılır.'**
  String get permLocationBody;

  /// No description provided for @permContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get permContinue;

  /// No description provided for @permLocationAlwaysTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kapalıyken de çalışsın'**
  String get permLocationAlwaysTitle;

  /// No description provided for @permLocationAlwaysBodyIos.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kapalıyken de hatırlatabilmem için konum iznini “Her Zaman” yap. Açılan pencerede ya da Ayarlar’da seçebilirsin.'**
  String get permLocationAlwaysBodyIos;

  /// No description provided for @permLocationAlwaysBodyAndroid.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kapalıyken de çalışması için Ayarlar’da “Her zaman izin ver”i seç.'**
  String get permLocationAlwaysBodyAndroid;

  /// No description provided for @permStep.
  ///
  /// In tr, this message translates to:
  /// **'Adım {step}'**
  String permStep(String step);

  /// No description provided for @permIllustrationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni'**
  String get permIllustrationTitle;

  /// No description provided for @permIllustrationAlways.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman izin ver'**
  String get permIllustrationAlways;

  /// No description provided for @permIllustrationWhileInUse.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca uygulamayı kullanırken'**
  String get permIllustrationWhileInUse;

  /// No description provided for @permIllustrationDeny.
  ///
  /// In tr, this message translates to:
  /// **'İzin verme'**
  String get permIllustrationDeny;

  /// No description provided for @onboardingWidgetUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda boş bir alana uzun basın → Widget\'lar → Hatırlatıcıyı seçin.'**
  String get onboardingWidgetUnsupported;

  /// No description provided for @onboardingSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get onboardingSkip;

  /// No description provided for @onboardingStep.
  ///
  /// In tr, this message translates to:
  /// **'Adım {index} / {count}'**
  String onboardingStep(int index, int count);

  /// No description provided for @onboardingContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get onboardingContinue;

  /// No description provided for @onboardingCaptureTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yazman yeterli.'**
  String get onboardingCaptureTitle;

  /// No description provided for @onboardingCaptureBody.
  ///
  /// In tr, this message translates to:
  /// **'Aklına geleni yaz; zamanını ve kategorisini seç. “yarın 9’da”, “#market” gibi ifadeleri kendiliğinden anlama özelliği de yolda.'**
  String get onboardingCaptureBody;

  /// Scripted demo. Must start with onboardingDemoWhen and end with onboardingDemoCategory.
  ///
  /// In tr, this message translates to:
  /// **'yarın 9\'da eczaneye uğra #sağlık'**
  String get onboardingDemoSentence;

  /// No description provided for @onboardingDemoWhen.
  ///
  /// In tr, this message translates to:
  /// **'yarın 9\'da'**
  String get onboardingDemoWhen;

  /// No description provided for @onboardingDemoCategory.
  ///
  /// In tr, this message translates to:
  /// **'#sağlık'**
  String get onboardingDemoCategory;

  /// No description provided for @onboardingDemoCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eczaneye uğra'**
  String get onboardingDemoCardTitle;

  /// No description provided for @onboardingDemoCardMeta.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık · Yarın 09:00'**
  String get onboardingDemoCardMeta;

  /// No description provided for @onboardingDemoSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Örnek: “{sentence}” yazınca hatırlatıcı oluşur: {title}, Sağlık, yarın saat 09:00'**
  String onboardingDemoSpoken(String sentence, String title);

  /// No description provided for @onboardingNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğru anda haber verelim'**
  String get onboardingNotifTitle;

  /// No description provided for @onboardingNotifBenefit1.
  ///
  /// In tr, this message translates to:
  /// **'Zamanı gelince bildirim'**
  String get onboardingNotifBenefit1;

  /// No description provided for @onboardingNotifBenefit2.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimden tek dokunuşla tamamla veya ertele'**
  String get onboardingNotifBenefit2;

  /// No description provided for @onboardingNotifBenefit3.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günlerini önceden hatırlat'**
  String get onboardingNotifBenefit3;

  /// No description provided for @onboardingNotifOn.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler açık.'**
  String get onboardingNotifOn;

  /// No description provided for @onboardingNotifOff.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapalı. İstediğin zaman Ayarlar › İzinler’den açabilirsin.'**
  String get onboardingNotifOff;

  /// No description provided for @onboardingMockSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Örnek bildirim: Market alışverişi. Migros Kadıköy’e yaklaştın, 6 maddeden 2’si tamam. Tamamla, 10 dk ertele'**
  String get onboardingMockSpoken;

  /// No description provided for @onboardingMockApp.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı · şimdi'**
  String get onboardingMockApp;

  /// No description provided for @onboardingMockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Market alışverişi'**
  String get onboardingMockTitle;

  /// No description provided for @onboardingMockBody.
  ///
  /// In tr, this message translates to:
  /// **'Migros Kadıköy’e yaklaştın · 2/6 madde'**
  String get onboardingMockBody;

  /// No description provided for @onboardingMockSnooze.
  ///
  /// In tr, this message translates to:
  /// **'10 dk ertele'**
  String get onboardingMockSnooze;

  /// No description provided for @onboardingEnterApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamaya geç'**
  String get onboardingEnterApp;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazırsın.'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In tr, this message translates to:
  /// **'İlk hatırlatıcını ekleyelim mi?'**
  String get onboardingReadyBody;

  /// No description provided for @onboardingMarketList.
  ///
  /// In tr, this message translates to:
  /// **'Market listesi oluştur'**
  String get onboardingMarketList;

  /// No description provided for @onboardingAddBirthday.
  ///
  /// In tr, this message translates to:
  /// **'Bir doğum günü ekle'**
  String get onboardingAddBirthday;

  /// No description provided for @onboardingAddWidget.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrana widget ekle'**
  String get onboardingAddWidget;

  /// No description provided for @onboardingStart.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get onboardingStart;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aklında kalmasın.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'Yaz, zamanını ya da yerini söyle; gerisini Hatırlatıcı takip etsin.'**
  String get onboardingWelcomeBody;

  /// Pill on the welcome illustration's now line (shown upper-case).
  ///
  /// In tr, this message translates to:
  /// **'şimdi'**
  String get onboardingNow;

  /// No description provided for @mapsServicesOff.
  ///
  /// In tr, this message translates to:
  /// **'Konum servisleri kapalı.'**
  String get mapsServicesOff;

  /// No description provided for @mapsPermissionOff.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kapalı.'**
  String get mapsPermissionOff;

  /// No description provided for @mapsLocationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı.'**
  String get mapsLocationFailed;

  /// No description provided for @mapsPlacesKeyMissing.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki marketler için Google Places anahtarı gerekir (isteğe bağlı: --dart-define=GOOGLE_MAPS_KEY=...).'**
  String get mapsPlacesKeyMissing;

  /// No description provided for @mapsNoMarkets.
  ///
  /// In tr, this message translates to:
  /// **'Yakında market bulunamadı.'**
  String get mapsNoMarkets;

  /// No description provided for @mapsNearbyMarkets.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki marketler'**
  String get mapsNearbyMarkets;

  /// No description provided for @mapsTapToPick.
  ///
  /// In tr, this message translates to:
  /// **'Seçmek için dokunun'**
  String get mapsTapToPick;

  /// Name of a nearby place without a name.
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get mapsBusiness;

  /// No description provided for @mapsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum seç'**
  String get mapsTitle;

  /// No description provided for @mapsHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritaya dokun, yarıçapı ayarla ve «Bu konumu kaydet» ile onayla.'**
  String get mapsHint;

  /// No description provided for @mapsRadius.
  ///
  /// In tr, this message translates to:
  /// **'Yarıçap'**
  String get mapsRadius;

  /// No description provided for @mapsRadiusMeters.
  ///
  /// In tr, this message translates to:
  /// **'{meters} m'**
  String mapsRadiusMeters(int meters);

  /// No description provided for @mapsRadiusSpoken.
  ///
  /// In tr, this message translates to:
  /// **'Yarıçap {meters} metre'**
  String mapsRadiusSpoken(int meters);

  /// No description provided for @mapsShowMarkets.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki marketleri göster'**
  String get mapsShowMarkets;

  /// No description provided for @mapsMap.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get mapsMap;

  /// No description provided for @mapsMapHint.
  ///
  /// In tr, this message translates to:
  /// **'İşaretçiyi taşımak için dokun'**
  String get mapsMapHint;

  /// No description provided for @mapsMyLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumuma git'**
  String get mapsMyLocation;

  /// No description provided for @mapsSave.
  ///
  /// In tr, this message translates to:
  /// **'Bu konumu kaydet'**
  String get mapsSave;

  /// No description provided for @mapsAttributionHint.
  ///
  /// In tr, this message translates to:
  /// **'Telif hakkı sayfasını açar'**
  String get mapsAttributionHint;

  /// Android notification channel name (system settings).
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar'**
  String get notifChannelReminders;

  /// No description provided for @notifChannelRemindersDescription.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlanmış hatırlatıcı bildirimleri'**
  String get notifChannelRemindersDescription;

  /// No description provided for @notifChannelLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum hatırlatmaları'**
  String get notifChannelLocation;

  /// No description provided for @notifChannelLocationDescription.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğiniz yere geldiğinizde'**
  String get notifChannelLocationDescription;

  /// No description provided for @notifChannelBirthdays.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü hatırlatmaları'**
  String get notifChannelBirthdays;

  /// No description provided for @notifChannelBirthdaysDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık olarak tekrarlayan doğum günü bildirimleri'**
  String get notifChannelBirthdaysDescription;

  /// Notification title of a reminder without a title.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı'**
  String get notifTitleFallback;

  /// No description provided for @notifBodyFallback.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma zamanı'**
  String get notifBodyFallback;

  /// No description provided for @notifGeoFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı konuma girdiniz'**
  String get notifGeoFallback;

  /// No description provided for @notifSubtasksLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} madde kaldı}}'**
  String notifSubtasksLeft(int count);

  /// No description provided for @notifBodyWithSubtasks.
  ///
  /// In tr, this message translates to:
  /// **'{lead} · {remaining}'**
  String notifBodyWithSubtasks(String lead, String remaining);

  /// No description provided for @notifSubtasksMore.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{… ve {count} madde daha}}'**
  String notifSubtasksMore(int count);

  /// No description provided for @notifBirthdayTitle.
  ///
  /// In tr, this message translates to:
  /// **'🎂 {name}'**
  String notifBirthdayTitle(String name);

  /// No description provided for @notifBirthdayTitleSoon.
  ///
  /// In tr, this message translates to:
  /// **'🎂 Yaklaşıyor: {name}'**
  String notifBirthdayTitleSoon(String name);

  /// No description provided for @notifBirthdayToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün doğum günü.'**
  String get notifBirthdayToday;

  /// No description provided for @notifBirthdayInMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} dakika sonra doğum günü.}}'**
  String notifBirthdayInMinutes(int count);

  /// No description provided for @notifBirthdayInHours.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} saat sonra doğum günü.}}'**
  String notifBirthdayInHours(int count);

  /// No description provided for @notifBirthdayTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın doğum günü.'**
  String get notifBirthdayTomorrow;

  /// No description provided for @notifBirthdayInDays.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} gün sonra doğum günü.}}'**
  String notifBirthdayInDays(int count);

  /// Notification action button.
  ///
  /// In tr, this message translates to:
  /// **'Tamamla'**
  String get notifActionComplete;

  /// Android notification action (short).
  ///
  /// In tr, this message translates to:
  /// **'10 dk'**
  String get notifActionSnooze10;

  /// No description provided for @notifActionSnooze1h.
  ///
  /// In tr, this message translates to:
  /// **'1 saat'**
  String get notifActionSnooze1h;

  /// iOS notification action.
  ///
  /// In tr, this message translates to:
  /// **'10 dk ertele'**
  String get notifActionSnooze10Long;

  /// No description provided for @notifActionSnooze1hLong.
  ///
  /// In tr, this message translates to:
  /// **'1 saat ertele'**
  String get notifActionSnooze1hLong;

  /// No description provided for @notifActionTomorrowMorning.
  ///
  /// In tr, this message translates to:
  /// **'Yarın sabah'**
  String get notifActionTomorrowMorning;

  /// No description provided for @permCalendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takvimindeki etkinlikleri de görelim'**
  String get permCalendarTitle;

  /// Pre-permission sheet body for read-only device calendar access (F8.1).
  ///
  /// In tr, this message translates to:
  /// **'Cihazının takvimindeki etkinlikleri Bugün ve Takvim sekmelerinde hatırlatıcılarının yanında gösterelim. Yalnızca okuruz: takvimine hiçbir şey yazılmaz, hiçbir etkinlik değiştirilmez.'**
  String get permCalendarBody;

  /// No description provided for @permCalendarPoint1.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler yalnızca bu cihazda okunur'**
  String get permCalendarPoint1;

  /// No description provided for @permCalendarPoint2.
  ///
  /// In tr, this message translates to:
  /// **'Takvimine hiçbir şey yazılmaz'**
  String get permCalendarPoint2;

  /// No description provided for @permCalendarPoint3.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin zaman kapatabilirsin'**
  String get permCalendarPoint3;

  /// No description provided for @permCalendarConfirm.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get permCalendarConfirm;

  /// No description provided for @permissionCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get permissionCalendar;

  /// No description provided for @permissionCalendarNotRequested.
  ///
  /// In tr, this message translates to:
  /// **'Takvim etkinlikleri için izin gerekiyor'**
  String get permissionCalendarNotRequested;

  /// No description provided for @permissionCalendarDenied.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilmedi — takvim etkinlikleri gösterilemiyor'**
  String get permissionCalendarDenied;

  /// No description provided for @permissionCalendarGranted.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca okuma izni var'**
  String get permissionCalendarGranted;

  /// No description provided for @settingsCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim etkinlikleri'**
  String get settingsCalendar;

  /// No description provided for @settingsCalendarToggle.
  ///
  /// In tr, this message translates to:
  /// **'Takvim etkinlikleri'**
  String get settingsCalendarToggle;

  /// Ayarlar > Takvim etkinlikleri switch subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazının takvimindeki etkinlikler Bugün ve Takvim\'de görünür. Yalnızca okunur.'**
  String get settingsCalendarToggleHint;

  /// No description provided for @settingsCalendarPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gösterilecek takvimler'**
  String get settingsCalendarPickerTitle;

  /// No description provided for @settingsCalendarPickerHint.
  ///
  /// In tr, this message translates to:
  /// **'Kapattığın takvimlerin etkinlikleri gösterilmez.'**
  String get settingsCalendarPickerHint;

  /// No description provided for @settingsCalendarLoading.
  ///
  /// In tr, this message translates to:
  /// **'Takvimler okunuyor…'**
  String get settingsCalendarLoading;

  /// No description provided for @settingsCalendarNone.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda takvim bulunamadı.'**
  String get settingsCalendarNone;

  /// No description provided for @settingsCalendarUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Takvim şu an okunamıyor. Daha sonra tekrar dene.'**
  String get settingsCalendarUnavailable;

  /// No description provided for @settingsCalendarDenied.
  ///
  /// In tr, this message translates to:
  /// **'Takvim izni verilmedi. Ayarlardan izin verip tekrar dene.'**
  String get settingsCalendarDenied;

  /// No description provided for @settingsCalendarAllHidden.
  ///
  /// In tr, this message translates to:
  /// **'Her takvimi kapattın, bu yüzden etkinlik gösterilmiyor.'**
  String get settingsCalendarAllHidden;

  /// No description provided for @calendarEventsSection.
  ///
  /// In tr, this message translates to:
  /// **'Takvim etkinlikleri'**
  String get calendarEventsSection;

  /// No description provided for @calendarEventAllDay.
  ///
  /// In tr, this message translates to:
  /// **'Tüm gün'**
  String get calendarEventAllDay;

  /// No description provided for @calendarEventSpokenAllDay.
  ///
  /// In tr, this message translates to:
  /// **'tüm gün'**
  String get calendarEventSpokenAllDay;

  /// Screen reader marker that a row is a device calendar event, not a reminder.
  ///
  /// In tr, this message translates to:
  /// **'takvim etkinliği'**
  String get calendarEventSpoken;

  /// No description provided for @calendarEventSpokenReadOnly.
  ///
  /// In tr, this message translates to:
  /// **'yalnızca okunur'**
  String get calendarEventSpokenReadOnly;

  /// No description provided for @calendarEventOpenInCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvimde aç'**
  String get calendarEventOpenInCalendar;

  /// No description provided for @calendarEventCreateReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı oluştur'**
  String get calendarEventCreateReminder;

  /// No description provided for @calendarEventDetailsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get calendarEventDetailsTitle;

  /// No description provided for @calendarEventNoCalendarApp.
  ///
  /// In tr, this message translates to:
  /// **'Takvim uygulaması açılamadı.'**
  String get calendarEventNoCalendarApp;

  /// No description provided for @calendarEventMoreActions.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik işlemleri'**
  String get calendarEventMoreActions;

  /// No description provided for @calendarEventCalendarLabel.
  ///
  /// In tr, this message translates to:
  /// **'Takvim: {name}'**
  String calendarEventCalendarLabel(String name);

  /// No description provided for @calendarEventLocationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yer: {place}'**
  String calendarEventLocationLabel(String place);

  /// No description provided for @calendarEventWhenLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zaman'**
  String get calendarEventWhenLabel;

  /// Start and end of a multi-day or all-day span.
  ///
  /// In tr, this message translates to:
  /// **'{start} – {end}'**
  String calendarEventMultiDay(String start, String end);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
