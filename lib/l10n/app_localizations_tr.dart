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

  @override
  String timeSpoken(String time) {
    return 'saat $time';
  }

  @override
  String get dateFormatHeader => 'EEEE, d MMMM';

  @override
  String get dateFormatDayMonth => 'd MMMM';

  @override
  String get dateFormatDayMonthYear => 'd MMMM y';

  @override
  String get dateFormatShort => 'd MMM';

  @override
  String get dateFormatShortYear => 'd MMM y';

  @override
  String get dateFormatAgenda => 'EEEE d MMMM';

  @override
  String get dateFormatAgendaYear => 'EEEE d MMMM y';

  @override
  String get dateFormatMonthYear => 'MMMM y';

  @override
  String get dateFormatMonth => 'MMMM';

  @override
  String get dateFormatDayMonthWeekday => 'd MMMM EEEE';

  @override
  String get dayToday => 'Bugün';

  @override
  String get dayTomorrow => 'Yarın';

  @override
  String get dayYesterday => 'Dün';

  @override
  String dayAndTime(String day, String time) {
    return '$day $time';
  }

  @override
  String agendaDayToday(String date) {
    return 'Bugün · $date';
  }

  @override
  String agendaDayTomorrow(String date) {
    return 'Yarın · $date';
  }

  @override
  String get recurrenceNone => 'Tekrar yok';

  @override
  String get recurrenceWeekdays => 'Hafta içi her gün';

  @override
  String recurrenceUntil(String base, String date) {
    return '$base · bitiş $date';
  }

  @override
  String get actionComplete => 'Tamamla';

  @override
  String get actionReopen => 'Geri aç';

  @override
  String get actionSnooze => 'Ertele';

  @override
  String get actionEdit => 'Düzenle';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionPin => 'Sabitle';

  @override
  String get actionUnpin => 'Sabitlemeyi kaldır';

  @override
  String get actionUndo => 'Geri al';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionConfirm => 'Onayla';

  @override
  String get actionLater => 'Sonra';

  @override
  String get priorityNone => 'Yok';

  @override
  String get priorityLow => 'Düşük';

  @override
  String get priorityMedium => 'Orta';

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String prioritySpoken(String level) {
    return '$level öncelik';
  }

  @override
  String subtasksSpoken(String progress) {
    return 'maddeler: $progress tamamlandı';
  }

  @override
  String get reminderSpokenOverdue => 'gecikti';

  @override
  String reminderSpokenRecurring(String summary) {
    return 'tekrar: $summary';
  }

  @override
  String reminderSpokenPlace(String place) {
    return 'konum: $place';
  }

  @override
  String get reminderSpokenPinned => 'sabitlendi';

  @override
  String get reminderSpokenDone => 'tamamlandı';

  @override
  String get reminderSpokenOpen => 'tamamlanmadı';

  @override
  String get reminderOverdue => 'Gecikti';

  @override
  String get reminderPlaceFallback => 'Konum';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryHome => 'Ev İşleri';

  @override
  String get categoryWork => 'İş';

  @override
  String get categoryHealth => 'Sağlık';

  @override
  String get categoryErrands => 'Günlük';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get categoryIconLabel => 'Etiket';

  @override
  String get categoryIconBasket => 'Sepet';

  @override
  String get categoryIconHome => 'Ev';

  @override
  String get categoryIconWork => 'Çanta';

  @override
  String get categoryIconHeart => 'Kalp';

  @override
  String get categoryIconSun => 'Güneş';

  @override
  String get categoryIconFitness => 'Spor';

  @override
  String get categoryIconSchool => 'Okul';

  @override
  String get categoryIconPets => 'Evcil hayvan';

  @override
  String get categoryIconCar => 'Araba';

  @override
  String get categoryIconFlight => 'Uçak';

  @override
  String get categoryIconRestaurant => 'Yemek';

  @override
  String get categoryIconPayments => 'Para';

  @override
  String get categoryIconMedication => 'İlaç';

  @override
  String get categoryIconChild => 'Çocuk';

  @override
  String get categoryIconFlower => 'Çiçek';

  @override
  String get categoryIconBuild => 'Tamir';

  @override
  String get categoryIconBook => 'Kitap';

  @override
  String get colorMarket => 'Yeşil';

  @override
  String get colorEv => 'Turkuaz';

  @override
  String get colorIs => 'Mavi';

  @override
  String get colorSaglik => 'Pembe';

  @override
  String get colorGunluk => 'Hardal';

  @override
  String get colorDiger => 'Mor';

  @override
  String get colorDogumGunu => 'Eflatun';

  @override
  String get colorKor => 'Kor';

  @override
  String get colorLacivert => 'Lacivert';

  @override
  String get colorZeytin => 'Zeytin';

  @override
  String get colorKiremit => 'Kiremit';

  @override
  String get colorArduvaz => 'Arduvaz';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
    );
    return '$_temp0';
  }

  @override
  String recurrenceDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count günde bir',
      one: 'Her gün',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeekly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haftada bir',
      one: 'Her hafta',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeeklyOn(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haftada bir $day',
      one: 'Her $day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeeklyOnDays(int count, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haftada bir $days',
      one: 'Her hafta $days',
    );
    return '$_temp0';
  }

  @override
  String recurrenceMonthly(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayda bir, ayın $day',
      one: 'Her ayın $day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceYearly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yılda bir',
      one: 'Her yıl',
    );
    return '$_temp0';
  }

  @override
  String recurrenceYearlyOn(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yılda bir $date',
      one: 'Her yıl $date',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlandıktan $count gün sonra',
      one: 'Tamamlandıktan 1 gün sonra',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlandıktan $count hafta sonra',
      one: 'Tamamlandıktan 1 hafta sonra',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlandıktan $count ay sonra',
      one: 'Tamamlandıktan 1 ay sonra',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlandıktan $count yıl sonra',
      one: 'Tamamlandıktan 1 yıl sonra',
    );
    return '$_temp0';
  }

  @override
  String birthdayTurnsAge(String age) {
    return '$age yaşına giriyor';
  }

  @override
  String birthdaySpokenLabel(String name, String countdown, String details) {
    return 'Doğum günü: $name, $countdown, $details';
  }

  @override
  String get settingsTooltip => 'Ayarlar';

  @override
  String undoCompleted(String title) {
    return '“$title” tamamlandı';
  }

  @override
  String undoReopened(String title) {
    return '“$title” geri açıldı';
  }

  @override
  String undoDeleted(String title) {
    return '“$title” silindi';
  }

  @override
  String undoPinned(String title) {
    return '“$title” sabitlendi';
  }

  @override
  String undoUnpinned(String title) {
    return '“$title” sabitlemesi kaldırıldı';
  }

  @override
  String get snoozeTenMinutes => '10 dakika';

  @override
  String get snoozeOneHour => '1 saat';

  @override
  String get snoozeThisEvening => 'Bu akşam';

  @override
  String get snoozeTomorrowEvening => 'Yarın akşam';

  @override
  String get snoozeTomorrowMorning => 'Yarın sabah';

  @override
  String snoozeWeekdayTime(String weekday, String time) {
    return '$weekday $time';
  }

  @override
  String snoozeOptionSpoken(String option, String day, String time) {
    return '$option, $day $time';
  }

  @override
  String get snoozeSheetTitle => 'Ertele';

  @override
  String get snoozeCustom => 'Tarih ve saat seç…';

  @override
  String get snoozePastError => 'Bu saat geçti. Daha ileri bir zaman seç.';

  @override
  String pastTimeSuggestion(String when) {
    return '$when mı?';
  }

  @override
  String pastTimeSuggestionSpoken(String when) {
    return '$when olarak ayarla';
  }

  @override
  String get pastTimeError => 'Bu saat geçti';

  @override
  String get pastTimeErrorSpoken => 'Hata: Bu saat geçti';

  @override
  String get recurrenceModeNone => 'Yok';

  @override
  String get recurrenceModeDaily => 'Günlük';

  @override
  String get recurrenceModeWeekly => 'Haftalık';

  @override
  String get recurrenceModeMonthly => 'Aylık';

  @override
  String get recurrenceModeYearly => 'Yıllık';

  @override
  String get recurrenceModeCustom => 'Özel';

  @override
  String recurrenceNextDay(String day, String time) {
    return '$day $time';
  }

  @override
  String recurrenceNext(String when) {
    return 'Sonraki: $when';
  }

  @override
  String get recurrencePreviewEmpty => 'Bu kuralla yaklaşan tekrar yok.';

  @override
  String get recurrenceSheetTitle => 'Tekrar';

  @override
  String get recurrenceDays => 'Günler';

  @override
  String recurrenceMonthDay(String day) {
    return 'Ayın $day.';
  }

  @override
  String recurrenceMonthDayClamped(String day) {
    return 'Ayın $day; kısa aylarda ayın son günü.';
  }

  @override
  String recurrenceYearDay(String date) {
    return 'Her yıl $date.';
  }

  @override
  String get recurrenceYearLeapDay =>
      'Her yıl 29 Şubat; artık yıl olmayan yıllarda 28 Şubat.';

  @override
  String get recurrenceAnchorLabel => 'Tekrar ölçütü';

  @override
  String get recurrenceAnchorSchedule => 'Takvime göre';

  @override
  String get recurrenceAnchorCompletion => 'Tamamlandıktan sonra';

  @override
  String get recurrenceAnchorScheduleNote =>
      'Tarihler sabit: geç tamamlasan da sıradaki tekrar kaymaz.';

  @override
  String get recurrenceAnchorCompletionNote =>
      'Sıradaki tekrar, tamamladığın günden sayılır; tamamlamadıkça burada bekler.';

  @override
  String get recurrenceCompletionPreview =>
      'Sonraki tarih, tamamladığında belirlenir.';

  @override
  String get recurrenceUntilLabel => 'Bitiş';

  @override
  String get recurrenceUntilNever => 'Hiçbir zaman';

  @override
  String get recurrenceUntilPick => 'Bitiş tarihi seç';

  @override
  String get recurrenceUntilClear => 'Bitişi kaldır';

  @override
  String get recurrenceUntilHelp => 'Bitiş tarihi';

  @override
  String get recurrenceDecrease => 'Azalt';

  @override
  String get recurrenceIncrease => 'Artır';

  @override
  String get actionDismiss => 'Vazgeç';

  @override
  String get actionDone => 'Tamam';

  @override
  String get dateFormatWeekdayDayMonth => 'EEE d MMM';

  @override
  String get dateFormatWeekdayDayMonthYear => 'EEE d MMM y';

  @override
  String get dateFormatWeekdayShort => 'EEE';

  @override
  String snoozedTo(String when, String suffix) {
    return '$when\'$suffix ertelendi';
  }

  @override
  String recurrenceEveryMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayda bir',
      one: 'Her ay',
    );
    return '$_temp0';
  }

  @override
  String recurrencePreview(int count, String dates) {
    return 'Sonraki $count: $dates';
  }

  @override
  String get editorTitleEmpty => 'Başlık boş olamaz.';

  @override
  String get editorDateMissing => 'Tarih seçin.';

  @override
  String get editorLocationMissing =>
      'Konum seçilmedi. Bir yer seç ya da «Nerede»yi kapat.';

  @override
  String get editorLocationPick => 'Konum seç';

  @override
  String editorLocationWithRadius(String place, String radius) {
    return '$place · $radius m';
  }

  @override
  String get editorLocationChosen => 'Seçilen konum';

  @override
  String get editorDatePick => 'Tarih seç';

  @override
  String get editorTimePick => 'Saat seç';

  @override
  String get editorNewTitle => 'Yeni hatırlatıcı';

  @override
  String get editorEditTitle => 'Hatırlatıcıyı düzenle';

  @override
  String get editorTitleLabel => 'Başlık';

  @override
  String get editorTitleHint => 'Ne hatırlatayım?';

  @override
  String get editorNoteLabel => 'Not (isteğe bağlı)';

  @override
  String get editorCategory => 'Kategori';

  @override
  String get editorNewCategoryChip => 'Yeni';

  @override
  String get editorNewCategoryTooltip => 'Yeni kategori';

  @override
  String get editorWhen => 'Ne zaman';

  @override
  String get editorScheduleSwitch => 'Zamanla ve bildir';

  @override
  String get editorWhenHint => 'Seçtiğin tarih ve saatte bildirim.';

  @override
  String get editorWhere => 'Nerede';

  @override
  String get editorLocationSwitch => 'Konuma gelince hatırlat';

  @override
  String get editorLocationEnterHint => 'Bölgeye girince bildirim.';

  @override
  String get editorWhereHint => 'Bir yere varınca hatırlat.';

  @override
  String editorRecurrenceSpoken(String summary) {
    return 'Tekrar: $summary';
  }

  @override
  String get editorRecurrence => 'Tekrar';

  @override
  String get editorLocationWhileInUse =>
      'Konum izni yalnızca kullanırken açık. Uygulama kapalıyken bildirim gelmeyebilir.';

  @override
  String get editorLocationDenied =>
      'Konum izni yok. Yeri haritadan seçebilirsin ama arka planda bildirim gelmeyebilir.';

  @override
  String get editorFix => 'Düzelt';

  @override
  String get editorPriority => 'Öncelik';

  @override
  String get subtasksTitle => 'Maddeler';

  @override
  String get subtasksAllDone => 'Tümü tamam — hatırlatıcıyı tamamla?';

  @override
  String get subtaskFallback => 'Madde';

  @override
  String subtaskOptions(String title) {
    return '$title seçenekleri';
  }

  @override
  String get subtaskMoveUp => 'Yukarı taşı';

  @override
  String get subtaskMoveDown => 'Aşağı taşı';

  @override
  String get subtaskHintReopen => 'Geri açmak için dokun';

  @override
  String get subtaskHintComplete => 'Tamamlamak için dokun';

  @override
  String get subtaskAdd => 'Madde ekle';

  @override
  String get subtaskSplit => 'Maddelere böl';

  @override
  String subtasksDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlanan $count madde',
    );
    return '$_temp0';
  }

  @override
  String get categoryNameEmpty => 'Kategoriye bir ad ver';

  @override
  String get categoryNameTaken => 'Bu adda bir kategori zaten var';

  @override
  String categoryDeleteTitle(String name) {
    return '“$name” silinsin mi?';
  }

  @override
  String get categoryDeleteEmpty => 'Bu kategoride hatırlatıcı yok.';

  @override
  String categoryDeleteMoves(int count, String other) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu kategorideki $count hatırlatıcı $other\'e taşınacak.',
    );
    return '$_temp0';
  }

  @override
  String get categoryNew => 'Yeni kategori';

  @override
  String get categoryEdit => 'Kategoriyi düzenle';

  @override
  String get categoryNameLabel => 'Ad';

  @override
  String get categoryNameHint => 'Örn. Spor salonu';

  @override
  String get categoryColor => 'Renk';

  @override
  String get categoryIcon => 'İkon';

  @override
  String categoryPreviewSpoken(String name) {
    return 'Önizleme: $name';
  }

  @override
  String get categoryListTitle => 'Kategorilerim';

  @override
  String get actionFinish => 'Bitti';

  @override
  String categoryRowSpoken(String name, int count) {
    return '$name, $count açık';
  }

  @override
  String categoryEditTooltip(String name) {
    return '$name düzenle';
  }

  @override
  String categoryMoveSpoken(String name) {
    return '$name taşı';
  }

  @override
  String todaySummary(int open, int overdue, int done) {
    return '$open açık · $overdue gecikmiş · $done tamam';
  }

  @override
  String get todayTitle => 'Bugün';

  @override
  String get todayNotificationsOffTitle => 'Bildirimler kapalı';

  @override
  String get todayNotificationsOffBody => 'Hatırlatmalar zamanında gelmeyecek.';

  @override
  String get permissionAllow => 'İzin ver';

  @override
  String get permissionOpenSettings => 'Ayarları aç';

  @override
  String get todayEmptyTitle => 'Bugün boş';

  @override
  String get todayEmptyBody => 'Keyfine bak ya da aklındakini aşağıya yaz.';

  @override
  String get todayEmptyAction => 'Yarını planla';

  @override
  String get todayAllDoneTitle => 'Hepsi tamam.';

  @override
  String todayAllDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugünkü $count hatırlatmanın hepsini bitirdin.',
    );
    return '$_temp0';
  }

  @override
  String get todayShowCompleted => 'Tamamlananları göster';

  @override
  String get todayHideCompleted => 'Tamamlananları gizle';

  @override
  String get todayUntimed => 'Bugün bir ara';

  @override
  String get todayOverdue => 'Kaçanlar';

  @override
  String get todayMoveOverdue => 'Hepsini yarına al';

  @override
  String get todayTimeline => 'Zaman çizelgesi';

  @override
  String todayProgressSpoken(int done, int total) {
    return 'İlerleme: $done / $total tamamlandı';
  }

  @override
  String get todayCompleted => 'Tamamlananlar';

  @override
  String todayCompletedSpokenShow(int count) {
    return 'Tamamlananlar, $count, göster';
  }

  @override
  String todayCompletedSpokenHide(int count) {
    return 'Tamamlananlar, $count, gizle';
  }

  @override
  String todayNowSpoken(String time) {
    return 'Şimdi, $time';
  }

  @override
  String overdueMovedOne(String title) {
    return '“$title” yarına alındı';
  }

  @override
  String overdueMovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı yarına alındı',
    );
    return '$_temp0';
  }

  @override
  String get calendarFilterAll => 'Tümü';

  @override
  String get calendarFilterReminders => 'Hatırlatıcılar';

  @override
  String get calendarFilterBirthdays => 'Doğum günleri';

  @override
  String get calendarFilterLocated => 'Konumlu';

  @override
  String get calendarMove => 'Taşı…';

  @override
  String get calendarSeriesNext => 'serinin sonraki tekrarı';

  @override
  String get calendarEditSeries => 'Seriyi düzenle';

  @override
  String calendarEmptyDay(String date) {
    return '$date — boş gün';
  }

  @override
  String calendarEmptyDaySpoken(String date) {
    return '$date, boş gün';
  }

  @override
  String get calendarEmptyDayHint => 'Bu güne hatırlatıcı ekle';

  @override
  String get calendarTitle => 'Takvim';

  @override
  String get calendarToday => 'Bugün';

  @override
  String get calendarWeekView => 'Hafta görünümüne geç';

  @override
  String get calendarMonthView => 'Ay görünümüne geç';

  @override
  String get calendarPreviousMonth => 'Önceki ay';

  @override
  String get calendarPreviousWeek => 'Önceki hafta';

  @override
  String get calendarNextMonth => 'Sonraki ay';

  @override
  String get calendarNextWeek => 'Sonraki hafta';

  @override
  String get calendarEmptyTitle => 'Yaklaşan bir şey yok';

  @override
  String calendarEmptyBody(int days) {
    return 'Önümüzdeki $days günde planlı hatırlatma ya da doğum günü yok.';
  }

  @override
  String calendarEmptyFilteredBody(int days) {
    return 'Bu filtreyle önümüzdeki $days günde bir şey yok.';
  }

  @override
  String get calendarAddReminder => 'Hatırlatıcı ekle';

  @override
  String calendarMoved(String title, String when) {
    return '“$title” taşındı · $when';
  }

  @override
  String get calendarMovePickerTitle => 'Hangi güne taşınsın?';

  @override
  String get calendarMoveConfirm => 'Taşı';

  @override
  String get calendarMovePast => 'Bu saat geçti; başka bir gün seç.';

  @override
  String get calendarDayToday => 'bugün';

  @override
  String get calendarDayHasEntries => 'planlı kayıt var';

  @override
  String get listsTitle => 'Listeler';

  @override
  String get listsCompleted => 'Tamamlananlar';

  @override
  String listsCompletedCountSpoken(String title, int count) {
    return '$title, $count tamamlandı';
  }

  @override
  String listsBirthdayCountSpoken(String title, int count) {
    return '$title, $count doğum günü';
  }

  @override
  String listsReminderCountSpoken(String title, int count) {
    return '$title, $count hatırlatıcı';
  }

  @override
  String get smartListOverdue => 'Gecikmiş';

  @override
  String get smartListToday => 'Bugün';

  @override
  String get smartListScheduled => 'Planlı';

  @override
  String get smartListUntimed => 'Zamansız';

  @override
  String get smartListBirthdays => 'Doğum günleri';

  @override
  String get smartListLocated => 'Konumlu';

  @override
  String smartListOpenCount(int count) {
    return '$count açık';
  }

  @override
  String get smartListOverdueEmptyTitle => 'Gecikmiş bir şey yok';

  @override
  String get smartListOverdueEmptyBody => 'Her şey zamanında, böyle devam.';

  @override
  String get smartListTodayEmptyTitle => 'Bugün için saatli bir şey yok';

  @override
  String get smartListTodayEmptyBody =>
      'Bugüne saat verdiğin hatırlatmalar burada görünür.';

  @override
  String get smartListScheduledEmptyTitle => 'Planlı hatırlatma yok';

  @override
  String get smartListScheduledEmptyBody =>
      'Saat verdiğin hatırlatmalar burada birikir.';

  @override
  String get smartListUntimedEmptyTitle => 'Zamansız hatırlatma yok';

  @override
  String get smartListUntimedEmptyBody =>
      'Saati olmayan hatırlatmalar burada durur.';

  @override
  String get smartListBirthdaysEmptyTitle => 'Henüz doğum günü yok';

  @override
  String get smartListBirthdaysEmptyBody => 'Sevdiklerinin gününü kaçırma.';

  @override
  String get smartListLocatedEmptyTitle => 'Konumlu hatırlatma yok';

  @override
  String get smartListLocatedEmptyBody =>
      'Bir yere varınca hatırlatmak için hatırlatıcıda \'Nerede\'yi aç.';

  @override
  String get filterEditCategory => 'Kategoriyi düzenle';

  @override
  String filterCompletedSummary(int count) {
    return '$count tamamlandı';
  }

  @override
  String filterCategorySummary(int open, int done) {
    return '$open açık · $done tamam';
  }

  @override
  String get filterNoCompletedTitle => 'Henüz tamamlanan yok';

  @override
  String get filterNoCompletedBody =>
      'Tamamladığın hatırlatmalar burada birikir.';

  @override
  String filterListEmptyTitle(String title) {
    return '$title listesi boş';
  }

  @override
  String get filterListEmptyBody => 'Eklemek için aşağıdaki düğmeye dokun.';

  @override
  String get filterAddToList => 'Bu listeye ekle';

  @override
  String get searchTooltip => 'Ara';

  @override
  String get searchAllCategories => 'Tüm kategoriler';

  @override
  String get actionBack => 'Geri';

  @override
  String get searchHint => 'Hatırlatıcılarda ara';

  @override
  String get actionClear => 'Temizle';

  @override
  String get searchCategoryChip => 'Kategori';

  @override
  String get searchOpenChip => 'Açık';

  @override
  String get searchCompletedChip => 'Tamamlanan';

  @override
  String get searchPickCategory => 'Kategori seç';

  @override
  String get searchEmptyTitle => 'Hatırlatıcılarında ara';

  @override
  String get searchEmptyBody =>
      'Başlık, not, kategori ya da yer adıyla bulabilirsin.';

  @override
  String get searchRecent => 'Son aramalar';

  @override
  String searchRecentSpoken(String query) {
    return 'Son arama: $query';
  }

  @override
  String searchNoResults(String query) {
    return '“$query” için sonuç yok';
  }

  @override
  String get searchNoResultsWiden =>
      'Yazımı kontrol et veya tamamlananlarda ara.';

  @override
  String get searchNoResultsBody => 'Yazımı kontrol et.';

  @override
  String get searchInCompleted => 'Tamamlananlarda ara';

  @override
  String searchResultCount(int count) {
    return '$count sonuç';
  }

  @override
  String get searchGroupReminders => 'Hatırlatıcılar';

  @override
  String get searchGroupNotes => 'Notlarda';

  @override
  String searchGroupHeader(String title, int count) {
    return '$title · $count';
  }

  @override
  String get searchUntimed => 'Zamansız';

  @override
  String searchOverdueWhen(String when) {
    return 'Gecikti · $when';
  }

  @override
  String birthdayRowAge(String date, String age) {
    return '$date · $age yaşına';
  }

  @override
  String birthdayRowNoAge(String date) {
    return '$date · yaş bilinmiyor';
  }

  @override
  String get birthdayLeapNote => 'Artık yıl değil: 28 Şubat\'ta hatırlatılır';

  @override
  String birthdayHeroAge(String when, String age) {
    return '$when · $age yaşına giriyor';
  }

  @override
  String get birthdayAddTooltip => 'Doğum günü ekle';

  @override
  String get birthdaysTitle => 'Doğum günleri';

  @override
  String get birthdaysEmptyTitle => 'Henüz doğum günü yok';

  @override
  String get birthdaysEmptyBody =>
      'Sevdiklerinin gününü kaçırma. Rehberden içe aktarma yakında.';

  @override
  String birthdayHeroDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gün',
    );
    return '$_temp0';
  }

  @override
  String birthdayHeroSpoken(String name) {
    return 'Sıradaki doğum günü: $name';
  }

  @override
  String birthdayDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün kaldı',
    );
    return '$_temp0';
  }

  @override
  String get birthdayHeroOverline => 'SIRADAKİ';

  @override
  String get birthdayDatePickerTitle => 'Doğum tarihi';

  @override
  String get birthdayTimePickerTitle => 'Bildirim saati';

  @override
  String get birthdayNameEmpty => 'İsim boş olamaz.';

  @override
  String get birthdayOffsetsEmpty => 'En az bir hatırlatma zamanı seçin.';

  @override
  String get birthdayDeleteTitle => 'Silinsin mi?';

  @override
  String birthdayDeleteBody(String name) {
    return '\"$name\" doğum günü hatırlatması silinecek.';
  }

  @override
  String get birthdayNew => 'Yeni doğum günü';

  @override
  String get birthdayEdit => 'Doğum günü düzenle';

  @override
  String get birthdayNameLabel => 'İsim';

  @override
  String get birthdayNameHint => 'Örn. Ayşe';

  @override
  String get birthdayNoteHint => 'Örn. Hediye fikri';

  @override
  String get birthdayDateCard => 'Tarih ve bildirim saati';

  @override
  String get birthdayDatePick => 'Doğum tarihi seç';

  @override
  String birthdayTimeSpoken(String time) {
    return 'Bildirim saati: $time';
  }

  @override
  String get birthdayTimePick => 'Bildirim saati seç';

  @override
  String get birthdayYearUnknown => 'Yıl bilinmiyor';

  @override
  String get birthdayYearUnknownHint =>
      'Yılı bilmiyorsan “Yıl bilinmiyor”u seç; yaş gösterilmez.';

  @override
  String get birthdayWhenCard => 'Ne zaman hatırlatayım?';

  @override
  String get birthdayWhenHint => 'Birden fazla seçim yapabilirsin.';

  @override
  String get birthdayOffsetOnDay => 'Doğum gününde';

  @override
  String birthdayOffsetMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hafta önce',
    );
    return '$_temp0';
  }

  @override
  String get captureBarLabel => 'Hızlı ekle';

  @override
  String get captureBarHint =>
      'Ne hatırlatayım? Uzun basınca ayrıntılı hatırlatıcı veya doğum günü seçilir';

  @override
  String get captureFieldHint => 'Ne hatırlatayım?';

  @override
  String get captureParserExamples =>
      'Örnek: yarın 9\'da, her pazartesi, #market';

  @override
  String get captureCategory => 'Kategori';

  @override
  String get capturePriority => 'Öncelik';

  @override
  String get captureAllDetails => 'Tüm ayrıntılar';

  @override
  String get captureDateChip => 'Tarih';

  @override
  String captureDateChipSet(String day, String time) {
    return '$day, $time';
  }

  @override
  String captureDateSpoken(String when) {
    return 'Zaman: $when';
  }

  @override
  String get captureDateAdd => 'Tarih ekle';

  @override
  String get captureRecurrenceChip => 'Tekrar';

  @override
  String captureRecurrenceSpoken(String summary) {
    return 'Tekrar: $summary';
  }

  @override
  String get captureRecurrenceAdd => 'Tekrar ekle';

  @override
  String captureNewCategory(String tag) {
    return 'Yeni kategori: #$tag';
  }

  @override
  String captureNewCategorySpoken(String tag) {
    return 'Yeni kategori: $tag. Oluşturmak için dokun';
  }

  @override
  String captureCategorySpoken(String name) {
    return 'Kategori: $name';
  }

  @override
  String get captureCategoryPick => 'Kategori seç';

  @override
  String get capturePriorityPick => 'Öncelik seç';

  @override
  String capturePlaceSpoken(String place) {
    return 'Yer: $place. Nota eklenir; konum bildirimi için Tüm ayrıntılar';
  }

  @override
  String captureSplitCount(int count) {
    return '$count madde';
  }

  @override
  String get captureSplitAsk => 'Maddelere böl?';

  @override
  String get captureSplitUndo => 'Maddelere bölmeyi geri al';

  @override
  String captureSplitDo(int count) {
    return '$count maddeye böl';
  }

  @override
  String get captureChipPlainText => 'Düz metne çevir';

  @override
  String captureAdded(String title) {
    return 'Eklendi: $title';
  }

  @override
  String get captureListTitleMarket => 'Market alışverişi';

  @override
  String captureListTitle(String category) {
    return '$category listesi';
  }

  @override
  String capturePlaceNote(String place) {
    return 'Yer: $place';
  }

  @override
  String get backupShared => 'Yedek dosyası paylaşıldı.';

  @override
  String get backupExportFailed => 'Yedek oluşturulamadı. Tekrar dene.';

  @override
  String get backupTooLarge =>
      'Bu dosya bir Hatırlatıcı yedeği olamayacak kadar büyük.';

  @override
  String get backupReadFailed => 'Dosya okunamadı.';

  @override
  String get backupReplaceTitle => 'Verileri değiştir';

  @override
  String get backupReplaceBody =>
      'Mevcut hatırlatıcıların ve doğum günlerin silinip yedektekilerle değiştirilir. Bu işlem geri alınamaz.';

  @override
  String backupRestored(int reminders, int birthdays) {
    return 'Geri yüklendi: $reminders hatırlatıcı, $birthdays doğum günü.';
  }

  @override
  String get backupRestoreFailed =>
      'Geri yükleme tamamlanamadı; veriler kısmen değişmiş olabilir. Aynı dosyayı tekrar geri yükleyebilirsin.';

  @override
  String get backupErrorNotJson =>
      'Bu dosya okunamadı: geçerli bir yedek dosyası değil.';

  @override
  String get backupErrorNotBackup => 'Bu dosya bir Hatırlatıcı yedeği değil.';

  @override
  String backupErrorNewer(String version) {
    return 'Bu yedek uygulamanın daha yeni bir sürümüyle alınmış (sürüm $version). Geri yüklemek için uygulamayı güncelle.';
  }

  @override
  String get backupErrorInvalid =>
      'Yedek dosyası bozuk; hiçbir şey değiştirilmedi.';

  @override
  String backupFound(int reminders, int birthdays) {
    return '$reminders hatırlatıcı, $birthdays doğum günü bulundu.';
  }

  @override
  String backupFoundSkipped(int reminders, int birthdays, int skipped) {
    return '$reminders hatırlatıcı, $birthdays doğum günü bulundu; $skipped kayıt okunamadı.';
  }

  @override
  String get backupRestoreTitle => 'Yedeği geri yükle';

  @override
  String backupDate(String date, String time) {
    return 'Yedek tarihi: $date $time';
  }

  @override
  String get backupSkippedHint =>
      'Okunamayan kayıtlar atlanır; diğerleri geri yüklenir.';

  @override
  String get backupMerge => 'Birleştir';

  @override
  String get backupReplace => 'Değiştir';

  @override
  String get backupMergeHint =>
      'Mevcut kayıtların kalır, yedektekiler eklenir. Aynı kayıt iki tarafta da varsa yedekteki sürüm kullanılır. Ayarlar değişmez.';

  @override
  String get backupReplaceHint =>
      'Mevcut hatırlatıcıların ve doğum günlerin silinir, yerine yedektekiler gelir. Ayarlar da yedekten alınır.';

  @override
  String get backupRestore => 'Geri yükle';

  @override
  String get permissionsTitle => 'İzinler';

  @override
  String get permissionOn => 'Açık';

  @override
  String get permissionNotificationsNotRequested =>
      'İzin verilmedi — hatırlatmalar bildirim olarak gelmez';

  @override
  String get permissionNotificationsDenied =>
      'Kapalı — hatırlatmalar zamanında gelmez';

  @override
  String get permissionNotifications => 'Bildirimler';

  @override
  String get permissionLocationAlways => 'Her zaman';

  @override
  String get permissionLocationWhileInUse =>
      'Yalnızca kullanırken — arka plan hatırlatmaları çalışmaz';

  @override
  String get permissionLocationNotRequested =>
      'İzin verilmedi — konum hatırlatmaları çalışmaz';

  @override
  String get permissionLocationDenied =>
      'Kapalı — konum hatırlatmaları çalışmaz';

  @override
  String get permissionLocation => 'Konum';

  @override
  String get permissionFix => 'Düzelt';

  @override
  String get permissionExactAlarms => 'Tam zamanlı alarmlar';

  @override
  String get permissionExactAlarmsOff =>
      'Kapalı — izin olmadan hatırlatmalar birkaç dakika gecikebilir';

  @override
  String get permissionChecking => 'Denetleniyor…';

  @override
  String get resetTitle => 'Tüm verileri sıfırla';

  @override
  String get resetBody =>
      'Tüm hatırlatmalar ve ayarlar silinir. Bu işlem geri alınamaz. Silmeden önce bir yedek alabilirsin.';

  @override
  String get resetBackupFirst => 'Önce yedekle';

  @override
  String get widgetPinUnsupported =>
      'Ana ekranda boş bir alana uzun basın → Widget\'lar → Hatırlatıcı\'yı seçin.';

  @override
  String get widgetPinTitle => 'Hangi widget?';

  @override
  String get homeWidgetToday => 'Bugün';

  @override
  String get homeWidgetList => 'Liste';

  @override
  String get homeWidgetNext => 'Sıradaki';

  @override
  String get homeWidgetQuickAdd => 'Hızlı ekle';

  @override
  String get homeWidgetTodayDescription => '4×2 · bugünün ilk iki işi ve \"+\"';

  @override
  String get homeWidgetListDescription =>
      '4×4 · kaydırılabilir, boyutu değişir';

  @override
  String get homeWidgetNextDescription => '2×2 · sıradaki iş ve saati';

  @override
  String get homeWidgetQuickAddDescription =>
      '1×1 · tek dokunuşla yeni hatırlatıcı';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeHint =>
      'Açık veya koyu temayı seç ya da sistemi takip et.';

  @override
  String get settingsHaptics => 'Titreşim geri bildirimi';

  @override
  String get settingsHapticsHint =>
      'Tamamlama, silme ve kaydırma gibi aksiyonlarda kısa titreşim.';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsReminderNotifications => 'Hatırlatma bildirimleri';

  @override
  String get settingsReminderNotificationsHint =>
      'Kapalıyken zamanlanmış hatırlatmalar gönderilmez. Açıkken sistem bildirim ayarları geçerlidir (ses, öncelik).';

  @override
  String get settingsLocationNeedsNotifications =>
      'Konum hatırlatmaları için de bildirimler açık olmalı.';

  @override
  String get settingsHomeWidget => 'Ana ekran widget\'ı';

  @override
  String get settingsHomeWidgetHint =>
      'Dört widget var: Bugün, kaydırılabilir Liste, Sıradaki ve Hızlı ekle. Daireye dokunarak işi tamamlarsın, \"+\" hızlı ekler. Liste\'nin boyutunu ana ekranda kenarlarından sürükleyerek değiştirebilirsin.';

  @override
  String get settingsAddWidget => 'Widget ekle';

  @override
  String get settingsBackup => 'Yedekle ve geri yükle';

  @override
  String get settingsBackupHint =>
      'Hatırlatıcılarını, doğum günlerini ve ayarlarını bir dosyaya yedekle; yeni bir cihazda veya yeniden kurulumdan sonra geri yükle.';

  @override
  String get settingsBackupExport => 'Yedekle';

  @override
  String get settingsOther => 'Diğer';

  @override
  String get settingsPrivacy => 'Gizlilik politikası';

  @override
  String get settingsLicenses => 'Lisanslar';

  @override
  String get settingsLinkFailed => 'Bağlantı açılamadı.';

  @override
  String navTabHint(int index, int count) {
    return 'Sekme $index / $count';
  }

  @override
  String get navShowTabs => 'Sekmeleri göster';

  @override
  String get newItemQuick => 'Hızlı ekle';

  @override
  String get newItemReminder => 'Hatırlatıcı';

  @override
  String get newItemBirthday => 'Doğum günü';

  @override
  String get newItemDetailedReminder => 'Ayrıntılı hatırlatıcı';

  @override
  String get newItemFabHint =>
      'Hızlı ekleme açılır. Uzun basınca ayrıntılı hatırlatıcı veya doğum günü seçilir';

  @override
  String get permNotifTitle => 'Hatırlatmaları zamanında al';

  @override
  String get permNotifBody =>
      'Seçtiğin saatte haber verebilmem için bildirim izni gerekiyor.';

  @override
  String get permNotifPoint1 =>
      'Hatırlatıcılar tam zamanında bildirim olarak gelir.';

  @override
  String get permNotifPoint2 => 'Doğum günlerini önceden haber veririm.';

  @override
  String get permNotifPoint3 => 'Konuma varınca da bildirim gönderirim.';

  @override
  String get permNotifConfirm => 'Bildirimlere izin ver';

  @override
  String get permNotNow => 'Şimdi değil';

  @override
  String get permExactTradeOff =>
      'İzin olmadan hatırlatmalar birkaç dakika gecikebilir.';

  @override
  String get permExactTitle => 'Tam zamanında hatırlatma';

  @override
  String permExactBody(String tradeOff) {
    return 'Bildirimlerin dakikası dakikasına gelmesi için “Alarmlar ve hatırlatıcılar” iznini açabilirsin. $tradeOff Hatırlatmaların yine de gelir.';
  }

  @override
  String get permLocationTitle => 'Bir yere varınca hatırlatayım';

  @override
  String get permLocationBody =>
      'Haritada yer seçmek ve oraya vardığında sana haber vermek için konum izni gerekiyor. Konumun yalnızca bu cihazda kullanılır.';

  @override
  String get permContinue => 'Devam';

  @override
  String get permLocationAlwaysTitle => 'Uygulama kapalıyken de çalışsın';

  @override
  String get permLocationAlwaysBodyIos =>
      'Uygulama kapalıyken de hatırlatabilmem için konum iznini “Her Zaman” yap. Açılan pencerede ya da Ayarlar’da seçebilirsin.';

  @override
  String get permLocationAlwaysBodyAndroid =>
      'Uygulama kapalıyken de çalışması için Ayarlar’da “Her zaman izin ver”i seç.';

  @override
  String permStep(String step) {
    return 'Adım $step';
  }

  @override
  String get permIllustrationTitle => 'Konum izni';

  @override
  String get permIllustrationAlways => 'Her zaman izin ver';

  @override
  String get permIllustrationWhileInUse => 'Yalnızca uygulamayı kullanırken';

  @override
  String get permIllustrationDeny => 'İzin verme';

  @override
  String get onboardingWidgetUnsupported =>
      'Ana ekranda boş bir alana uzun basın → Widget\'lar → Hatırlatıcıyı seçin.';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String onboardingStep(int index, int count) {
    return 'Adım $index / $count';
  }

  @override
  String get onboardingContinue => 'Devam';

  @override
  String get onboardingCaptureTitle => 'Yazman yeterli.';

  @override
  String get onboardingCaptureBody =>
      'Aklına geleni yaz; zamanını ve kategorisini seç. “yarın 9’da”, “#market” gibi ifadeleri kendiliğinden anlama özelliği de yolda.';

  @override
  String get onboardingDemoSentence => 'yarın 9\'da eczaneye uğra #sağlık';

  @override
  String get onboardingDemoWhen => 'yarın 9\'da';

  @override
  String get onboardingDemoCategory => '#sağlık';

  @override
  String get onboardingDemoCardTitle => 'Eczaneye uğra';

  @override
  String get onboardingDemoCardMeta => 'Sağlık · Yarın 09:00';

  @override
  String onboardingDemoSpoken(String sentence, String title) {
    return 'Örnek: “$sentence” yazınca hatırlatıcı oluşur: $title, Sağlık, yarın saat 09:00';
  }

  @override
  String get onboardingNotifTitle => 'Doğru anda haber verelim';

  @override
  String get onboardingNotifBenefit1 => 'Zamanı gelince bildirim';

  @override
  String get onboardingNotifBenefit2 =>
      'Bildirimden tek dokunuşla tamamla veya ertele';

  @override
  String get onboardingNotifBenefit3 => 'Doğum günlerini önceden hatırlat';

  @override
  String get onboardingNotifOn => 'Bildirimler açık.';

  @override
  String get onboardingNotifOff =>
      'Bildirimler kapalı. İstediğin zaman Ayarlar › İzinler’den açabilirsin.';

  @override
  String get onboardingMockSpoken =>
      'Örnek bildirim: Market alışverişi. Migros Kadıköy’e yaklaştın, 6 maddeden 2’si tamam. Tamamla, 10 dk ertele';

  @override
  String get onboardingMockApp => 'Hatırlatıcı · şimdi';

  @override
  String get onboardingMockTitle => 'Market alışverişi';

  @override
  String get onboardingMockBody => 'Migros Kadıköy’e yaklaştın · 2/6 madde';

  @override
  String get onboardingMockSnooze => '10 dk ertele';

  @override
  String get onboardingEnterApp => 'Uygulamaya geç';

  @override
  String get onboardingReadyTitle => 'Hazırsın.';

  @override
  String get onboardingReadyBody => 'İlk hatırlatıcını ekleyelim mi?';

  @override
  String get onboardingMarketList => 'Market listesi oluştur';

  @override
  String get onboardingAddBirthday => 'Bir doğum günü ekle';

  @override
  String get onboardingAddWidget => 'Ana ekrana widget ekle';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get onboardingWelcomeTitle => 'Aklında kalmasın.';

  @override
  String get onboardingWelcomeBody =>
      'Yaz, zamanını ya da yerini söyle; gerisini Hatırlatıcı takip etsin.';

  @override
  String get onboardingNow => 'şimdi';

  @override
  String get mapsServicesOff => 'Konum servisleri kapalı.';

  @override
  String get mapsPermissionOff => 'Konum izni kapalı.';

  @override
  String get mapsLocationFailed => 'Konum alınamadı.';

  @override
  String get mapsPlacesKeyMissing =>
      'Yakındaki marketler için Google Places anahtarı gerekir (isteğe bağlı: --dart-define=GOOGLE_MAPS_KEY=...).';

  @override
  String get mapsNoMarkets => 'Yakında market bulunamadı.';

  @override
  String get mapsNearbyMarkets => 'Yakındaki marketler';

  @override
  String get mapsTapToPick => 'Seçmek için dokunun';

  @override
  String get mapsBusiness => 'İşletme';

  @override
  String get mapsTitle => 'Konum seç';

  @override
  String get mapsHint =>
      'Haritaya dokun, yarıçapı ayarla ve «Bu konumu kaydet» ile onayla.';

  @override
  String get mapsRadius => 'Yarıçap';

  @override
  String mapsRadiusMeters(int meters) {
    return '$meters m';
  }

  @override
  String mapsRadiusSpoken(int meters) {
    return 'Yarıçap $meters metre';
  }

  @override
  String get mapsShowMarkets => 'Yakındaki marketleri göster';

  @override
  String get mapsMap => 'Harita';

  @override
  String get mapsMapHint => 'İşaretçiyi taşımak için dokun';

  @override
  String get mapsMyLocation => 'Konumuma git';

  @override
  String get mapsSave => 'Bu konumu kaydet';

  @override
  String get mapsAttributionHint => 'Telif hakkı sayfasını açar';

  @override
  String get notifChannelReminders => 'Hatırlatmalar';

  @override
  String get notifChannelRemindersDescription =>
      'Zamanlanmış hatırlatıcı bildirimleri';

  @override
  String get notifChannelLocation => 'Konum hatırlatmaları';

  @override
  String get notifChannelLocationDescription => 'Seçtiğiniz yere geldiğinizde';

  @override
  String get notifChannelBirthdays => 'Doğum günü hatırlatmaları';

  @override
  String get notifChannelBirthdaysDescription =>
      'Yıllık olarak tekrarlayan doğum günü bildirimleri';

  @override
  String get notifTitleFallback => 'Hatırlatıcı';

  @override
  String get notifBodyFallback => 'Hatırlatma zamanı';

  @override
  String get notifGeoFallback => 'Kayıtlı konuma girdiniz';

  @override
  String notifSubtasksLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count madde kaldı',
    );
    return '$_temp0';
  }

  @override
  String notifBodyWithSubtasks(String lead, String remaining) {
    return '$lead · $remaining';
  }

  @override
  String notifSubtasksMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '… ve $count madde daha',
    );
    return '$_temp0';
  }

  @override
  String notifBirthdayTitle(String name) {
    return '🎂 $name';
  }

  @override
  String notifBirthdayTitleSoon(String name) {
    return '🎂 Yaklaşıyor: $name';
  }

  @override
  String get notifBirthdayToday => 'Bugün doğum günü.';

  @override
  String notifBirthdayInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika sonra doğum günü.',
    );
    return '$_temp0';
  }

  @override
  String notifBirthdayInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat sonra doğum günü.',
    );
    return '$_temp0';
  }

  @override
  String get notifBirthdayTomorrow => 'Yarın doğum günü.';

  @override
  String notifBirthdayInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün sonra doğum günü.',
    );
    return '$_temp0';
  }

  @override
  String get notifActionComplete => 'Tamamla';

  @override
  String get notifActionSnooze10 => '10 dk';

  @override
  String get notifActionSnooze1h => '1 saat';

  @override
  String get notifActionSnooze10Long => '10 dk ertele';

  @override
  String get notifActionSnooze1hLong => '1 saat ertele';

  @override
  String get notifActionTomorrowMorning => 'Yarın sabah';

  @override
  String get permCalendarTitle => 'Takvimindeki etkinlikleri de görelim';

  @override
  String get permCalendarBody =>
      'Cihazının takvimindeki etkinlikleri Bugün ve Takvim sekmelerinde hatırlatıcılarının yanında gösterelim. Yalnızca okuruz: takvimine hiçbir şey yazılmaz, hiçbir etkinlik değiştirilmez.';

  @override
  String get permCalendarPoint1 => 'Etkinlikler yalnızca bu cihazda okunur';

  @override
  String get permCalendarPoint2 => 'Takvimine hiçbir şey yazılmaz';

  @override
  String get permCalendarPoint3 => 'İstediğin zaman kapatabilirsin';

  @override
  String get permCalendarConfirm => 'İzin ver';

  @override
  String get permissionCalendar => 'Takvim';

  @override
  String get permissionCalendarNotRequested =>
      'Takvim etkinlikleri için izin gerekiyor';

  @override
  String get permissionCalendarDenied =>
      'İzin verilmedi — takvim etkinlikleri gösterilemiyor';

  @override
  String get permissionCalendarGranted => 'Yalnızca okuma izni var';

  @override
  String get settingsCalendar => 'Takvim etkinlikleri';

  @override
  String get settingsCalendarToggle => 'Takvim etkinlikleri';

  @override
  String get settingsCalendarToggleHint =>
      'Cihazının takvimindeki etkinlikler Bugün ve Takvim\'de görünür. Yalnızca okunur.';

  @override
  String get settingsCalendarPickerTitle => 'Gösterilecek takvimler';

  @override
  String get settingsCalendarPickerHint =>
      'Kapattığın takvimlerin etkinlikleri gösterilmez.';

  @override
  String get settingsCalendarLoading => 'Takvimler okunuyor…';

  @override
  String get settingsCalendarNone => 'Bu cihazda takvim bulunamadı.';

  @override
  String get settingsCalendarUnavailable =>
      'Takvim şu an okunamıyor. Daha sonra tekrar dene.';

  @override
  String get settingsCalendarDenied =>
      'Takvim izni verilmedi. Ayarlardan izin verip tekrar dene.';

  @override
  String get settingsCalendarAllHidden =>
      'Her takvimi kapattın, bu yüzden etkinlik gösterilmiyor.';

  @override
  String get calendarEventsSection => 'Takvim etkinlikleri';

  @override
  String get calendarEventAllDay => 'Tüm gün';

  @override
  String get calendarEventSpokenAllDay => 'tüm gün';

  @override
  String get calendarEventSpoken => 'takvim etkinliği';

  @override
  String get calendarEventSpokenReadOnly => 'yalnızca okunur';

  @override
  String get calendarEventOpenInCalendar => 'Takvimde aç';

  @override
  String get calendarEventCreateReminder => 'Hatırlatıcı oluştur';

  @override
  String get calendarEventDetailsTitle => 'Etkinlik';

  @override
  String get calendarEventNoCalendarApp => 'Takvim uygulaması açılamadı.';

  @override
  String get calendarEventMoreActions => 'Etkinlik işlemleri';

  @override
  String calendarEventCalendarLabel(String name) {
    return 'Takvim: $name';
  }

  @override
  String calendarEventLocationLabel(String place) {
    return 'Yer: $place';
  }

  @override
  String get calendarEventWhenLabel => 'Zaman';

  @override
  String calendarEventMultiDay(String start, String end) {
    return '$start – $end';
  }
}
