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

  @override
  String timeSpoken(String time) {
    return 'at $time';
  }

  @override
  String get dateFormatHeader => 'EEEE, MMMM d';

  @override
  String get dateFormatDayMonth => 'MMMM d';

  @override
  String get dateFormatDayMonthYear => 'MMMM d, y';

  @override
  String get dateFormatShort => 'MMM d';

  @override
  String get dateFormatShortYear => 'MMM d, y';

  @override
  String get dateFormatAgenda => 'EEEE, MMMM d';

  @override
  String get dateFormatAgendaYear => 'EEEE, MMMM d, y';

  @override
  String get dateFormatMonthYear => 'MMMM y';

  @override
  String get dateFormatMonth => 'MMMM';

  @override
  String get dateFormatDayMonthWeekday => 'EEEE, MMMM d';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String dayAndTime(String day, String time) {
    return '$day $time';
  }

  @override
  String agendaDayToday(String date) {
    return 'Today · $date';
  }

  @override
  String agendaDayTomorrow(String date) {
    return 'Tomorrow · $date';
  }

  @override
  String get recurrenceNone => 'No repeat';

  @override
  String get recurrenceWeekdays => 'Every weekday';

  @override
  String recurrenceUntil(String base, String date) {
    return '$base · until $date';
  }

  @override
  String get actionComplete => 'Complete';

  @override
  String get actionReopen => 'Reopen';

  @override
  String get actionSnooze => 'Snooze';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionPin => 'Pin';

  @override
  String get actionUnpin => 'Unpin';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionLater => 'Later';

  @override
  String get priorityNone => 'None';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String prioritySpoken(String level) {
    return '$level priority';
  }

  @override
  String subtasksSpoken(String progress) {
    return 'items: $progress done';
  }

  @override
  String get reminderSpokenOverdue => 'overdue';

  @override
  String reminderSpokenRecurring(String summary) {
    return 'repeats: $summary';
  }

  @override
  String reminderSpokenPlace(String place) {
    return 'location: $place';
  }

  @override
  String get reminderSpokenPinned => 'pinned';

  @override
  String get reminderSpokenDone => 'done';

  @override
  String get reminderSpokenOpen => 'not done';

  @override
  String get reminderOverdue => 'Overdue';

  @override
  String get reminderPlaceFallback => 'Location';

  @override
  String get categoryMarket => 'Groceries';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryErrands => 'Errands';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryIconLabel => 'Label';

  @override
  String get categoryIconBasket => 'Basket';

  @override
  String get categoryIconHome => 'House';

  @override
  String get categoryIconWork => 'Briefcase';

  @override
  String get categoryIconHeart => 'Heart';

  @override
  String get categoryIconSun => 'Sun';

  @override
  String get categoryIconFitness => 'Fitness';

  @override
  String get categoryIconSchool => 'School';

  @override
  String get categoryIconPets => 'Pets';

  @override
  String get categoryIconCar => 'Car';

  @override
  String get categoryIconFlight => 'Plane';

  @override
  String get categoryIconRestaurant => 'Food';

  @override
  String get categoryIconPayments => 'Money';

  @override
  String get categoryIconMedication => 'Medicine';

  @override
  String get categoryIconChild => 'Child';

  @override
  String get categoryIconFlower => 'Flower';

  @override
  String get categoryIconBuild => 'Repair';

  @override
  String get categoryIconBook => 'Book';

  @override
  String get colorMarket => 'Green';

  @override
  String get colorEv => 'Turquoise';

  @override
  String get colorIs => 'Blue';

  @override
  String get colorSaglik => 'Pink';

  @override
  String get colorGunluk => 'Mustard';

  @override
  String get colorDiger => 'Purple';

  @override
  String get colorDogumGunu => 'Lilac';

  @override
  String get colorKor => 'Ember';

  @override
  String get colorLacivert => 'Navy';

  @override
  String get colorZeytin => 'Olive';

  @override
  String get colorKiremit => 'Terracotta';

  @override
  String get colorArduvaz => 'Slate';

  @override
  String countdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceDaily(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeekly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeeklyOn(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks on $day',
      one: 'Every $day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceWeeklyOnDays(int count, String days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks on $days',
      one: 'Every week on $days',
    );
    return '$_temp0';
  }

  @override
  String recurrenceMonthly(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months on the $day',
      one: 'Monthly on the $day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceYearly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String recurrenceYearlyOn(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years on $date',
      one: 'Every year on $date',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days after completion',
      one: '1 day after completion',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks after completion',
      one: '1 week after completion',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months after completion',
      one: '1 month after completion',
    );
    return '$_temp0';
  }

  @override
  String recurrenceAfterCompletionYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years after completion',
      one: '1 year after completion',
    );
    return '$_temp0';
  }

  @override
  String birthdayTurnsAge(String age) {
    return 'turns $age';
  }

  @override
  String birthdaySpokenLabel(String name, String countdown, String details) {
    return 'Birthday: $name, $countdown, $details';
  }

  @override
  String get settingsTooltip => 'Settings';

  @override
  String undoCompleted(String title) {
    return '“$title” completed';
  }

  @override
  String undoReopened(String title) {
    return '“$title” reopened';
  }

  @override
  String undoDeleted(String title) {
    return '“$title” deleted';
  }

  @override
  String undoPinned(String title) {
    return '“$title” pinned';
  }

  @override
  String undoUnpinned(String title) {
    return '“$title” unpinned';
  }

  @override
  String get snoozeTenMinutes => '10 minutes';

  @override
  String get snoozeOneHour => '1 hour';

  @override
  String get snoozeThisEvening => 'This evening';

  @override
  String get snoozeTomorrowEvening => 'Tomorrow evening';

  @override
  String get snoozeTomorrowMorning => 'Tomorrow morning';

  @override
  String snoozeWeekdayTime(String weekday, String time) {
    return '$weekday $time';
  }

  @override
  String snoozeOptionSpoken(String option, String day, String time) {
    return '$option, $day $time';
  }

  @override
  String get snoozeSheetTitle => 'Snooze';

  @override
  String get snoozeCustom => 'Pick date and time…';

  @override
  String get snoozePastError => 'This time has passed. Pick a later time.';

  @override
  String pastTimeSuggestion(String when) {
    return '$when?';
  }

  @override
  String pastTimeSuggestionSpoken(String when) {
    return 'Set to $when';
  }

  @override
  String get pastTimeError => 'This time has passed';

  @override
  String get pastTimeErrorSpoken => 'Error: This time has passed';

  @override
  String get recurrenceModeNone => 'None';

  @override
  String get recurrenceModeDaily => 'Daily';

  @override
  String get recurrenceModeWeekly => 'Weekly';

  @override
  String get recurrenceModeMonthly => 'Monthly';

  @override
  String get recurrenceModeYearly => 'Yearly';

  @override
  String get recurrenceModeCustom => 'Custom';

  @override
  String recurrenceNextDay(String day, String time) {
    return '$day $time';
  }

  @override
  String recurrenceNext(String when) {
    return 'Next: $when';
  }

  @override
  String get recurrencePreviewEmpty =>
      'No upcoming occurrences with this rule.';

  @override
  String get recurrenceSheetTitle => 'Repeat';

  @override
  String get recurrenceDays => 'Days';

  @override
  String recurrenceMonthDay(String day) {
    return 'On the $day of the month.';
  }

  @override
  String recurrenceMonthDayClamped(String day) {
    return 'On the $day; the last day in shorter months.';
  }

  @override
  String recurrenceYearDay(String date) {
    return 'Every year on $date.';
  }

  @override
  String get recurrenceYearLeapDay =>
      'Every year on February 29; February 28 in non-leap years.';

  @override
  String get recurrenceAnchorLabel => 'Repeat basis';

  @override
  String get recurrenceAnchorSchedule => 'On schedule';

  @override
  String get recurrenceAnchorCompletion => 'After completion';

  @override
  String get recurrenceAnchorScheduleNote =>
      'Fixed dates: completing late does not move the next one.';

  @override
  String get recurrenceAnchorCompletionNote =>
      'The next repeat counts from the day you complete it; until then it waits here.';

  @override
  String get recurrenceCompletionPreview =>
      'The next date is set when you complete it.';

  @override
  String get recurrenceUntilLabel => 'Ends';

  @override
  String get recurrenceUntilNever => 'Never';

  @override
  String get recurrenceUntilPick => 'Pick end date';

  @override
  String get recurrenceUntilClear => 'Remove end date';

  @override
  String get recurrenceUntilHelp => 'End date';

  @override
  String get recurrenceDecrease => 'Decrease';

  @override
  String get recurrenceIncrease => 'Increase';

  @override
  String get actionDismiss => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String get dateFormatWeekdayDayMonth => 'EEE, MMM d';

  @override
  String get dateFormatWeekdayDayMonthYear => 'EEE, MMM d, y';

  @override
  String get dateFormatWeekdayShort => 'EEE';

  @override
  String snoozedTo(String when, String suffix) {
    return 'Snoozed until $when';
  }

  @override
  String recurrenceEveryMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String recurrencePreview(int count, String dates) {
    return 'Next $count: $dates';
  }

  @override
  String get editorTitleEmpty => 'The title can\'t be empty.';

  @override
  String get editorDateMissing => 'Pick a date.';

  @override
  String get editorLocationMissing =>
      'No location chosen. Pick a place or turn off “Where”.';

  @override
  String get editorLocationPick => 'Pick a location';

  @override
  String editorLocationWithRadius(String place, String radius) {
    return '$place · $radius m';
  }

  @override
  String get editorLocationChosen => 'Chosen location';

  @override
  String get editorDatePick => 'Pick date';

  @override
  String get editorTimePick => 'Pick time';

  @override
  String get editorNewTitle => 'New reminder';

  @override
  String get editorEditTitle => 'Edit reminder';

  @override
  String get editorTitleLabel => 'Title';

  @override
  String get editorTitleHint => 'What should I remind you of?';

  @override
  String get editorNoteLabel => 'Note (optional)';

  @override
  String get editorCategory => 'Category';

  @override
  String get editorNewCategoryChip => 'New';

  @override
  String get editorNewCategoryTooltip => 'New category';

  @override
  String get editorWhen => 'When';

  @override
  String get editorScheduleSwitch => 'Schedule and notify';

  @override
  String get editorWhenHint =>
      'A notification at the date and time you choose.';

  @override
  String get editorWhere => 'Where';

  @override
  String get editorLocationSwitch => 'Remind me at a place';

  @override
  String get editorLocationEnterHint => 'Notifies when you arrive.';

  @override
  String get editorWhereHint => 'Get reminded when you arrive somewhere.';

  @override
  String editorRecurrenceSpoken(String summary) {
    return 'Repeat: $summary';
  }

  @override
  String get editorRecurrence => 'Repeat';

  @override
  String get editorLocationWhileInUse =>
      'Location access is only allowed while using the app. Notifications may not arrive when it\'s closed.';

  @override
  String get editorLocationDenied =>
      'No location access. You can still pick the place on the map, but notifications may not arrive in the background.';

  @override
  String get editorFix => 'Fix';

  @override
  String get editorPriority => 'Priority';

  @override
  String get subtasksTitle => 'Items';

  @override
  String get subtasksAllDone => 'All done — complete the reminder?';

  @override
  String get subtaskFallback => 'Item';

  @override
  String subtaskOptions(String title) {
    return '$title options';
  }

  @override
  String get subtaskMoveUp => 'Move up';

  @override
  String get subtaskMoveDown => 'Move down';

  @override
  String get subtaskHintReopen => 'Tap to reopen';

  @override
  String get subtaskHintComplete => 'Tap to complete';

  @override
  String get subtaskAdd => 'Add item';

  @override
  String get subtaskSplit => 'Split into items';

  @override
  String subtasksDoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed items',
      one: '1 completed item',
    );
    return '$_temp0';
  }

  @override
  String get categoryNameEmpty => 'Give the category a name';

  @override
  String get categoryNameTaken => 'A category with this name already exists';

  @override
  String categoryDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get categoryDeleteEmpty => 'There are no reminders in this category.';

  @override
  String categoryDeleteMoves(int count, String other) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders in this category will move to $other.',
      one: '1 reminder in this category will move to $other.',
    );
    return '$_temp0';
  }

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryNameHint => 'E.g. Gym';

  @override
  String get categoryColor => 'Colour';

  @override
  String get categoryIcon => 'Icon';

  @override
  String categoryPreviewSpoken(String name) {
    return 'Preview: $name';
  }

  @override
  String get categoryListTitle => 'My categories';

  @override
  String get actionFinish => 'Done';

  @override
  String categoryRowSpoken(String name, int count) {
    return '$name, $count open';
  }

  @override
  String categoryEditTooltip(String name) {
    return 'Edit $name';
  }

  @override
  String categoryMoveSpoken(String name) {
    return 'Move $name';
  }

  @override
  String todaySummary(int open, int overdue, int done) {
    return '$open open · $overdue overdue · $done done';
  }

  @override
  String get todayTitle => 'Today';

  @override
  String get todayNotificationsOffTitle => 'Notifications are off';

  @override
  String get todayNotificationsOffBody => 'Reminders won\'t arrive on time.';

  @override
  String get permissionAllow => 'Allow';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String get todayEmptyTitle => 'Nothing today';

  @override
  String get todayEmptyBody =>
      'Enjoy your day, or jot down what\'s on your mind below.';

  @override
  String get todayEmptyAction => 'Plan tomorrow';

  @override
  String get todayAllDoneTitle => 'All done.';

  @override
  String todayAllDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You finished all $count of today\'s reminders.',
      one: 'You finished today\'s reminder.',
    );
    return '$_temp0';
  }

  @override
  String get todayShowCompleted => 'Show completed';

  @override
  String get todayHideCompleted => 'Hide completed';

  @override
  String get todayUntimed => 'Sometime today';

  @override
  String get todayOverdue => 'Missed';

  @override
  String get todayMoveOverdue => 'Move all to tomorrow';

  @override
  String get todayTimeline => 'Timeline';

  @override
  String todayProgressSpoken(int done, int total) {
    return 'Progress: $done of $total done';
  }

  @override
  String get todayCompleted => 'Completed';

  @override
  String todayCompletedSpokenShow(int count) {
    return 'Completed, $count, show';
  }

  @override
  String todayCompletedSpokenHide(int count) {
    return 'Completed, $count, hide';
  }

  @override
  String todayNowSpoken(String time) {
    return 'Now, $time';
  }

  @override
  String overdueMovedOne(String title) {
    return '“$title” moved to tomorrow';
  }

  @override
  String overdueMovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders moved to tomorrow',
      one: '1 reminder moved to tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get calendarFilterAll => 'All';

  @override
  String get calendarFilterReminders => 'Reminders';

  @override
  String get calendarFilterBirthdays => 'Birthdays';

  @override
  String get calendarFilterLocated => 'With location';

  @override
  String get calendarMove => 'Move…';

  @override
  String get calendarSeriesNext => 'next occurrence of the series';

  @override
  String get calendarEditSeries => 'Edit series';

  @override
  String calendarEmptyDay(String date) {
    return '$date — free day';
  }

  @override
  String calendarEmptyDaySpoken(String date) {
    return '$date, free day';
  }

  @override
  String get calendarEmptyDayHint => 'Add a reminder on this day';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarWeekView => 'Switch to week view';

  @override
  String get calendarMonthView => 'Switch to month view';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarPreviousWeek => 'Previous week';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarNextWeek => 'Next week';

  @override
  String get calendarEmptyTitle => 'Nothing coming up';

  @override
  String calendarEmptyBody(int days) {
    return 'No scheduled reminders or birthdays in the next $days days.';
  }

  @override
  String calendarEmptyFilteredBody(int days) {
    return 'Nothing in the next $days days with this filter.';
  }

  @override
  String get calendarAddReminder => 'Add reminder';

  @override
  String calendarMoved(String title, String when) {
    return '“$title” moved · $when';
  }

  @override
  String get calendarMovePickerTitle => 'Move to which day?';

  @override
  String get calendarMoveConfirm => 'Move';

  @override
  String get calendarMovePast => 'This time has passed; pick another day.';

  @override
  String get calendarDayToday => 'today';

  @override
  String get calendarDayHasEntries => 'has plans';

  @override
  String get listsTitle => 'Lists';

  @override
  String get listsCompleted => 'Completed';

  @override
  String listsCompletedCountSpoken(String title, int count) {
    return '$title, $count done';
  }

  @override
  String listsBirthdayCountSpoken(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$title, $count birthdays',
      one: '$title, 1 birthday',
    );
    return '$_temp0';
  }

  @override
  String listsReminderCountSpoken(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$title, $count reminders',
      one: '$title, 1 reminder',
    );
    return '$_temp0';
  }

  @override
  String get smartListOverdue => 'Overdue';

  @override
  String get smartListToday => 'Today';

  @override
  String get smartListScheduled => 'Scheduled';

  @override
  String get smartListUntimed => 'No time';

  @override
  String get smartListBirthdays => 'Birthdays';

  @override
  String get smartListLocated => 'With location';

  @override
  String smartListOpenCount(int count) {
    return '$count open';
  }

  @override
  String get smartListOverdueEmptyTitle => 'Nothing overdue';

  @override
  String get smartListOverdueEmptyBody => 'Everything\'s on time. Keep it up.';

  @override
  String get smartListTodayEmptyTitle => 'Nothing timed for today';

  @override
  String get smartListTodayEmptyBody =>
      'Reminders with a time today show up here.';

  @override
  String get smartListScheduledEmptyTitle => 'No scheduled reminders';

  @override
  String get smartListScheduledEmptyBody =>
      'Reminders with a time collect here.';

  @override
  String get smartListUntimedEmptyTitle => 'No reminders without a time';

  @override
  String get smartListUntimedEmptyBody => 'Reminders without a time stay here.';

  @override
  String get smartListBirthdaysEmptyTitle => 'No birthdays yet';

  @override
  String get smartListBirthdaysEmptyBody =>
      'Never miss your loved ones\' special day.';

  @override
  String get smartListLocatedEmptyTitle => 'No location reminders';

  @override
  String get smartListLocatedEmptyBody =>
      'To get reminded when you arrive somewhere, turn on “Where” in a reminder.';

  @override
  String get filterEditCategory => 'Edit category';

  @override
  String filterCompletedSummary(int count) {
    return '$count done';
  }

  @override
  String filterCategorySummary(int open, int done) {
    return '$open open · $done done';
  }

  @override
  String get filterNoCompletedTitle => 'Nothing completed yet';

  @override
  String get filterNoCompletedBody => 'Reminders you complete collect here.';

  @override
  String filterListEmptyTitle(String title) {
    return '$title is empty';
  }

  @override
  String get filterListEmptyBody => 'Tap the button below to add one.';

  @override
  String get filterAddToList => 'Add to this list';

  @override
  String get searchTooltip => 'Search';

  @override
  String get searchAllCategories => 'All categories';

  @override
  String get actionBack => 'Back';

  @override
  String get searchHint => 'Search reminders';

  @override
  String get actionClear => 'Clear';

  @override
  String get searchCategoryChip => 'Category';

  @override
  String get searchOpenChip => 'Open';

  @override
  String get searchCompletedChip => 'Completed';

  @override
  String get searchPickCategory => 'Pick a category';

  @override
  String get searchEmptyTitle => 'Search your reminders';

  @override
  String get searchEmptyBody => 'Find them by title, note, category or place.';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String searchRecentSpoken(String query) {
    return 'Recent search: $query';
  }

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsWiden =>
      'Check the spelling or search completed reminders.';

  @override
  String get searchNoResultsBody => 'Check the spelling.';

  @override
  String get searchInCompleted => 'Search completed';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get searchGroupReminders => 'Reminders';

  @override
  String get searchGroupNotes => 'In notes';

  @override
  String searchGroupHeader(String title, int count) {
    return '$title · $count';
  }

  @override
  String get searchUntimed => 'No time';

  @override
  String searchOverdueWhen(String when) {
    return 'Overdue · $when';
  }

  @override
  String birthdayRowAge(String date, String age) {
    return '$date · turns $age';
  }

  @override
  String birthdayRowNoAge(String date) {
    return '$date · age unknown';
  }

  @override
  String get birthdayLeapNote => 'Not a leap year: reminded on February 28';

  @override
  String birthdayHeroAge(String when, String age) {
    return '$when · turns $age';
  }

  @override
  String get birthdayAddTooltip => 'Add birthday';

  @override
  String get birthdaysTitle => 'Birthdays';

  @override
  String get birthdaysEmptyTitle => 'No birthdays yet';

  @override
  String get birthdaysEmptyBody =>
      'Never miss your loved ones\' special day. Importing from contacts is coming soon.';

  @override
  String birthdayHeroDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String birthdayHeroSpoken(String name) {
    return 'Next birthday: $name';
  }

  @override
  String birthdayDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get birthdayHeroOverline => 'NEXT UP';

  @override
  String get birthdayDatePickerTitle => 'Birth date';

  @override
  String get birthdayTimePickerTitle => 'Notification time';

  @override
  String get birthdayNameEmpty => 'The name can\'t be empty.';

  @override
  String get birthdayOffsetsEmpty => 'Pick at least one reminder time.';

  @override
  String get birthdayDeleteTitle => 'Delete?';

  @override
  String birthdayDeleteBody(String name) {
    return 'The birthday reminder for \"$name\" will be deleted.';
  }

  @override
  String get birthdayNew => 'New birthday';

  @override
  String get birthdayEdit => 'Edit birthday';

  @override
  String get birthdayNameLabel => 'Name';

  @override
  String get birthdayNameHint => 'E.g. Ayşe';

  @override
  String get birthdayNoteHint => 'E.g. Gift idea';

  @override
  String get birthdayDateCard => 'Date and notification time';

  @override
  String get birthdayDatePick => 'Pick birth date';

  @override
  String birthdayTimeSpoken(String time) {
    return 'Notification time: $time';
  }

  @override
  String get birthdayTimePick => 'Pick notification time';

  @override
  String get birthdayYearUnknown => 'Year unknown';

  @override
  String get birthdayYearUnknownHint =>
      'If you don\'t know the year, choose “Year unknown”; no age is shown.';

  @override
  String get birthdayWhenCard => 'When should I remind you?';

  @override
  String get birthdayWhenHint => 'You can pick more than one.';

  @override
  String get birthdayOffsetOnDay => 'On the day';

  @override
  String birthdayOffsetMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String birthdayOffsetWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks before',
      one: '1 week before',
    );
    return '$_temp0';
  }

  @override
  String get captureBarLabel => 'Quick add';

  @override
  String get captureBarHint =>
      'What should I remind you of? Long-press for a detailed reminder or a birthday';

  @override
  String get captureFieldHint => 'What should I remind you of?';

  @override
  String get captureParserExamples =>
      'Example: tomorrow at 9, every monday, #market';

  @override
  String get captureCategory => 'Category';

  @override
  String get capturePriority => 'Priority';

  @override
  String get captureAllDetails => 'All details';

  @override
  String get captureDateChip => 'Date';

  @override
  String captureDateChipSet(String day, String time) {
    return '$day, $time';
  }

  @override
  String captureDateSpoken(String when) {
    return 'Time: $when';
  }

  @override
  String get captureDateAdd => 'Add date';

  @override
  String get captureRecurrenceChip => 'Repeat';

  @override
  String captureRecurrenceSpoken(String summary) {
    return 'Repeat: $summary';
  }

  @override
  String get captureRecurrenceAdd => 'Add repeat';

  @override
  String captureNewCategory(String tag) {
    return 'New category: #$tag';
  }

  @override
  String captureNewCategorySpoken(String tag) {
    return 'New category: $tag. Tap to create it';
  }

  @override
  String captureCategorySpoken(String name) {
    return 'Category: $name';
  }

  @override
  String get captureCategoryPick => 'Pick a category';

  @override
  String get capturePriorityPick => 'Pick a priority';

  @override
  String capturePlaceSpoken(String place) {
    return 'Place: $place. Added to the note; use All details for a location notification';
  }

  @override
  String captureSplitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get captureSplitAsk => 'Split into items?';

  @override
  String get captureSplitUndo => 'Undo split';

  @override
  String captureSplitDo(int count) {
    return 'Split into $count items';
  }

  @override
  String get captureChipPlainText => 'Turn into plain text';

  @override
  String captureAdded(String title) {
    return 'Added: $title';
  }

  @override
  String get captureListTitleMarket => 'Grocery shopping';

  @override
  String captureListTitle(String category) {
    return '$category list';
  }

  @override
  String capturePlaceNote(String place) {
    return 'Place: $place';
  }

  @override
  String get backupShared => 'Backup file shared.';

  @override
  String get backupExportFailed => 'Couldn\'t create the backup. Try again.';

  @override
  String get backupTooLarge =>
      'This file is too large to be a backup of this app.';

  @override
  String get backupReadFailed => 'Couldn\'t read the file.';

  @override
  String get backupReplaceTitle => 'Replace data';

  @override
  String get backupReplaceBody =>
      'Your current reminders and birthdays are deleted and replaced with the ones in the backup. This can\'t be undone.';

  @override
  String backupRestored(int reminders, int birthdays) {
    return 'Restored — reminders: $reminders, birthdays: $birthdays.';
  }

  @override
  String get backupRestoreFailed =>
      'The restore didn\'t finish; some data may have changed. You can restore the same file again.';

  @override
  String get backupErrorNotJson =>
      'Couldn\'t read this file: it isn\'t a valid backup file.';

  @override
  String get backupErrorNotBackup => 'This file isn\'t a backup of this app.';

  @override
  String backupErrorNewer(String version) {
    return 'This backup was made with a newer version of the app (version $version). Update the app to restore it.';
  }

  @override
  String get backupErrorInvalid =>
      'The backup file is damaged; nothing was changed.';

  @override
  String backupFound(int reminders, int birthdays) {
    return 'Found — reminders: $reminders, birthdays: $birthdays.';
  }

  @override
  String backupFoundSkipped(int reminders, int birthdays, int skipped) {
    return 'Found — reminders: $reminders, birthdays: $birthdays; unreadable entries: $skipped.';
  }

  @override
  String get backupRestoreTitle => 'Restore backup';

  @override
  String backupDate(String date, String time) {
    return 'Backup date: $date $time';
  }

  @override
  String get backupSkippedHint =>
      'Unreadable entries are skipped; the rest are restored.';

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupReplace => 'Replace';

  @override
  String get backupMergeHint =>
      'Your current entries stay and the backup\'s are added. If an entry exists in both, the backup\'s version wins. Settings don\'t change.';

  @override
  String get backupReplaceHint =>
      'Your current reminders and birthdays are deleted and the backup\'s take their place. Settings are restored from the backup too.';

  @override
  String get backupRestore => 'Restore';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionOn => 'On';

  @override
  String get permissionNotificationsNotRequested =>
      'Not allowed — reminders won\'t arrive as notifications';

  @override
  String get permissionNotificationsDenied =>
      'Off — reminders won\'t arrive on time';

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String get permissionLocationAlways => 'Always';

  @override
  String get permissionLocationWhileInUse =>
      'Only while in use — background reminders won\'t work';

  @override
  String get permissionLocationNotRequested =>
      'Not allowed — location reminders won\'t work';

  @override
  String get permissionLocationDenied => 'Off — location reminders won\'t work';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionFix => 'Fix';

  @override
  String get permissionExactAlarms => 'Exact alarms';

  @override
  String get permissionExactAlarmsOff =>
      'Off — without it, reminders may be a few minutes late';

  @override
  String get permissionChecking => 'Checking…';

  @override
  String get resetTitle => 'Reset all data';

  @override
  String get resetBody =>
      'All reminders and settings are deleted. This can\'t be undone. You can make a backup first.';

  @override
  String get resetBackupFirst => 'Back up first';

  @override
  String get widgetPinUnsupported =>
      'Long-press an empty spot on your home screen → Widgets → choose Hatırlatıcı.';

  @override
  String get widgetPinTitle => 'Which widget?';

  @override
  String get homeWidgetToday => 'Today';

  @override
  String get homeWidgetList => 'List';

  @override
  String get homeWidgetNext => 'Up next';

  @override
  String get homeWidgetQuickAdd => 'Quick add';

  @override
  String get homeWidgetTodayDescription =>
      '4×2 · today\'s first two tasks and \"+\"';

  @override
  String get homeWidgetListDescription => '4×4 · scrollable, resizable';

  @override
  String get homeWidgetNextDescription => '2×2 · the next task and its time';

  @override
  String get homeWidgetQuickAddDescription => '1×1 · a new reminder in one tap';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeHint =>
      'Pick a light or dark theme, or follow the system.';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsHint =>
      'A short vibration on actions like completing, deleting and swiping.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsReminderNotifications => 'Reminder notifications';

  @override
  String get settingsReminderNotificationsHint =>
      'When off, scheduled reminders aren\'t sent. When on, the system notification settings apply (sound, priority).';

  @override
  String get settingsLocationNeedsNotifications =>
      'Location reminders also need notifications on.';

  @override
  String get settingsHomeWidget => 'Home screen widget';

  @override
  String get settingsHomeWidgetHint =>
      'There are four widgets: Today, the scrollable List, Up next and Quick add. Tap the circle to complete a task; \"+\" adds quickly. Resize the List by dragging its edges on the home screen.';

  @override
  String get settingsAddWidget => 'Add widget';

  @override
  String get settingsBackup => 'Back up and restore';

  @override
  String get settingsBackupHint =>
      'Back up your reminders, birthdays and settings to a file; restore them on a new device or after reinstalling.';

  @override
  String get settingsBackupExport => 'Back up';

  @override
  String get settingsOther => 'Other';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsLinkFailed => 'Couldn\'t open the link.';

  @override
  String navTabHint(int index, int count) {
    return 'Tab $index of $count';
  }

  @override
  String get navShowTabs => 'Show tabs';

  @override
  String get newItemQuick => 'Quick add';

  @override
  String get newItemReminder => 'Reminder';

  @override
  String get newItemBirthday => 'Birthday';

  @override
  String get newItemDetailedReminder => 'Detailed reminder';

  @override
  String get newItemFabHint =>
      'Opens quick add. Long-press for a detailed reminder or a birthday';

  @override
  String get permNotifTitle => 'Get reminders on time';

  @override
  String get permNotifBody =>
      'I need notification access to let you know at the time you choose.';

  @override
  String get permNotifPoint1 =>
      'Reminders arrive as notifications right on time.';

  @override
  String get permNotifPoint2 => 'I\'ll tell you about birthdays in advance.';

  @override
  String get permNotifPoint3 =>
      'I\'ll also notify you when you arrive at a place.';

  @override
  String get permNotifConfirm => 'Allow notifications';

  @override
  String get permNotNow => 'Not now';

  @override
  String get permExactTradeOff =>
      'Without it, reminders may be a few minutes late.';

  @override
  String get permExactTitle => 'Reminders to the minute';

  @override
  String permExactBody(String tradeOff) {
    return 'To get notifications to the minute, you can turn on the “Alarms & reminders” permission. $tradeOff Your reminders still arrive.';
  }

  @override
  String get permLocationTitle => 'Get reminded when you arrive';

  @override
  String get permLocationBody =>
      'Location access is needed to pick a place on the map and tell you when you get there. Your location is only used on this device.';

  @override
  String get permContinue => 'Continue';

  @override
  String get permLocationAlwaysTitle => 'Keep working when the app is closed';

  @override
  String get permLocationAlwaysBodyIos =>
      'To remind you while the app is closed, set location access to “Always”. You can choose it in the prompt or in Settings.';

  @override
  String get permLocationAlwaysBodyAndroid =>
      'To keep it working while the app is closed, choose “Allow all the time” in Settings.';

  @override
  String permStep(String step) {
    return 'Step $step';
  }

  @override
  String get permIllustrationTitle => 'Location permission';

  @override
  String get permIllustrationAlways => 'Allow all the time';

  @override
  String get permIllustrationWhileInUse => 'Allow only while using the app';

  @override
  String get permIllustrationDeny => 'Don\'t allow';

  @override
  String get onboardingWidgetUnsupported =>
      'Long-press an empty spot on your home screen → Widgets → choose Hatırlatıcı.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String onboardingStep(int index, int count) {
    return 'Step $index of $count';
  }

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingCaptureTitle => 'Just type it.';

  @override
  String get onboardingCaptureBody =>
      'Type what\'s on your mind; pick its time and category. Understanding phrases like “yarın 9’da” or “#market” on its own is on the way (Turkish only for now).';

  @override
  String get onboardingDemoSentence =>
      'tomorrow at 9 stop by the pharmacy #health';

  @override
  String get onboardingDemoWhen => 'tomorrow at 9';

  @override
  String get onboardingDemoCategory => '#health';

  @override
  String get onboardingDemoCardTitle => 'Stop by the pharmacy';

  @override
  String get onboardingDemoCardMeta => 'Health · Tomorrow 09:00';

  @override
  String onboardingDemoSpoken(String sentence, String title) {
    return 'Example: typing “$sentence” creates a reminder: $title, Health, tomorrow at 09:00';
  }

  @override
  String get onboardingNotifTitle => 'We\'ll tell you at the right moment';

  @override
  String get onboardingNotifBenefit1 => 'A notification when it\'s time';

  @override
  String get onboardingNotifBenefit2 =>
      'Complete or snooze from the notification in one tap';

  @override
  String get onboardingNotifBenefit3 => 'Get reminded of birthdays in advance';

  @override
  String get onboardingNotifOn => 'Notifications are on.';

  @override
  String get onboardingNotifOff =>
      'Notifications are off. You can turn them on anytime in Settings › Permissions.';

  @override
  String get onboardingMockSpoken =>
      'Example notification: Grocery shopping. You\'re near Migros Kadıköy, 2 of 6 items done. Complete, snooze 10 min';

  @override
  String get onboardingMockApp => 'Hatırlatıcı · now';

  @override
  String get onboardingMockTitle => 'Grocery shopping';

  @override
  String get onboardingMockBody => 'You\'re near Migros Kadıköy · 2/6 items';

  @override
  String get onboardingMockSnooze => 'Snooze 10 min';

  @override
  String get onboardingEnterApp => 'Go to the app';

  @override
  String get onboardingReadyTitle => 'You\'re all set.';

  @override
  String get onboardingReadyBody => 'Shall we add your first reminder?';

  @override
  String get onboardingMarketList => 'Create a shopping list';

  @override
  String get onboardingAddBirthday => 'Add a birthday';

  @override
  String get onboardingAddWidget => 'Add a home screen widget';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingWelcomeTitle => 'Don\'t keep it in your head.';

  @override
  String get onboardingWelcomeBody =>
      'Write it down, say when or where; Hatırlatıcı keeps track of the rest.';

  @override
  String get onboardingNow => 'now';

  @override
  String get mapsServicesOff => 'Location services are off.';

  @override
  String get mapsPermissionOff => 'Location permission is off.';

  @override
  String get mapsLocationFailed => 'Couldn\'t get your location.';

  @override
  String get mapsPlacesKeyMissing =>
      'Nearby shops need a Google Places key (optional: --dart-define=GOOGLE_MAPS_KEY=...).';

  @override
  String get mapsNoMarkets => 'No shops found nearby.';

  @override
  String get mapsNearbyMarkets => 'Nearby shops';

  @override
  String get mapsTapToPick => 'Tap to choose';

  @override
  String get mapsBusiness => 'Business';

  @override
  String get mapsTitle => 'Choose location';

  @override
  String get mapsHint =>
      'Tap the map, adjust the radius and confirm with “Save this location”.';

  @override
  String get mapsRadius => 'Radius';

  @override
  String mapsRadiusMeters(int meters) {
    return '$meters m';
  }

  @override
  String mapsRadiusSpoken(int meters) {
    return 'Radius $meters meters';
  }

  @override
  String get mapsShowMarkets => 'Show nearby shops';

  @override
  String get mapsMap => 'Map';

  @override
  String get mapsMapHint => 'Tap to move the marker';

  @override
  String get mapsMyLocation => 'Go to my location';

  @override
  String get mapsSave => 'Save this location';

  @override
  String get mapsAttributionHint => 'Opens the copyright page';

  @override
  String get notifChannelReminders => 'Reminders';

  @override
  String get notifChannelRemindersDescription =>
      'Scheduled reminder notifications';

  @override
  String get notifChannelLocation => 'Location reminders';

  @override
  String get notifChannelLocationDescription =>
      'When you arrive at a place you chose';

  @override
  String get notifChannelBirthdays => 'Birthday reminders';

  @override
  String get notifChannelBirthdaysDescription =>
      'Birthday notifications that repeat every year';

  @override
  String get notifTitleFallback => 'Reminder';

  @override
  String get notifBodyFallback => 'Time for your reminder';

  @override
  String get notifGeoFallback => 'You arrived at a saved place';

  @override
  String notifSubtasksLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items left',
      one: '1 item left',
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
      other: '… and $count more items',
      one: '… and 1 more item',
    );
    return '$_temp0';
  }

  @override
  String notifBirthdayTitle(String name) {
    return '🎂 $name';
  }

  @override
  String notifBirthdayTitleSoon(String name) {
    return '🎂 Coming up: $name';
  }

  @override
  String get notifBirthdayToday => 'Birthday today.';

  @override
  String notifBirthdayInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Birthday in $count minutes.',
      one: 'Birthday in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String notifBirthdayInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Birthday in $count hours.',
      one: 'Birthday in 1 hour.',
    );
    return '$_temp0';
  }

  @override
  String get notifBirthdayTomorrow => 'Birthday tomorrow.';

  @override
  String notifBirthdayInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Birthday in $count days.',
      one: 'Birthday in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get notifActionComplete => 'Complete';

  @override
  String get notifActionSnooze10 => '10 min';

  @override
  String get notifActionSnooze1h => '1 hour';

  @override
  String get notifActionSnooze10Long => 'Snooze 10 min';

  @override
  String get notifActionSnooze1hLong => 'Snooze 1 hour';

  @override
  String get notifActionTomorrowMorning => 'Tomorrow morning';

  @override
  String get permCalendarTitle => 'Show your calendar events too';

  @override
  String get permCalendarBody =>
      'Let\'s show the events from your device calendar next to your reminders in the Today and Calendar tabs. Read only: nothing is ever written to your calendar and no event is changed.';

  @override
  String get permCalendarPoint1 => 'Events are read on this device only';

  @override
  String get permCalendarPoint2 => 'Nothing is written to your calendar';

  @override
  String get permCalendarPoint3 => 'You can turn it off any time';

  @override
  String get permCalendarConfirm => 'Allow';

  @override
  String get permissionCalendar => 'Calendar';

  @override
  String get permissionCalendarNotRequested =>
      'Calendar events need permission';

  @override
  String get permissionCalendarDenied =>
      'Not allowed — calendar events can\'t be shown';

  @override
  String get permissionCalendarGranted => 'Read-only access granted';

  @override
  String get settingsCalendar => 'Calendar events';

  @override
  String get settingsCalendarToggle => 'Calendar events';

  @override
  String get settingsCalendarToggleHint =>
      'Events from your device calendar appear in Today and Calendar. Read only.';

  @override
  String get settingsCalendarPickerTitle => 'Calendars to show';

  @override
  String get settingsCalendarPickerHint =>
      'Events from calendars you turn off are not shown.';

  @override
  String get settingsCalendarLoading => 'Reading calendars…';

  @override
  String get settingsCalendarNone => 'No calendar was found on this device.';

  @override
  String get settingsCalendarUnavailable =>
      'The calendar can\'t be read right now. Try again later.';

  @override
  String get settingsCalendarDenied =>
      'Calendar permission was not granted. Allow it in Settings and try again.';

  @override
  String get settingsCalendarAllHidden =>
      'You turned every calendar off, so no events are shown.';

  @override
  String get calendarEventsSection => 'Calendar events';

  @override
  String get calendarEventAllDay => 'All day';

  @override
  String get calendarEventSpokenAllDay => 'all day';

  @override
  String get calendarEventSpoken => 'calendar event';

  @override
  String get calendarEventSpokenReadOnly => 'read only';

  @override
  String get calendarEventOpenInCalendar => 'Open in calendar';

  @override
  String get calendarEventCreateReminder => 'Create reminder';

  @override
  String get calendarEventDetailsTitle => 'Event';

  @override
  String get calendarEventNoCalendarApp =>
      'The calendar app could not be opened.';

  @override
  String get calendarEventMoreActions => 'Event actions';

  @override
  String calendarEventCalendarLabel(String name) {
    return 'Calendar: $name';
  }

  @override
  String calendarEventLocationLabel(String place) {
    return 'Location: $place';
  }

  @override
  String get calendarEventWhenLabel => 'When';

  @override
  String calendarEventMultiDay(String start, String end) {
    return '$start – $end';
  }

  @override
  String get routinesTitle => 'My routines';

  @override
  String get routinesEmpty => 'No routines yet';

  @override
  String get routinesEmptyHint =>
      'Set up ready-made packs like a morning routine and turn them into reminders with one tap.';

  @override
  String get routineNew => 'New routine';

  @override
  String get routineEdit => 'Edit routine';

  @override
  String routineStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String routineRowSpoken(String name, String details) {
    return '$name, $details';
  }

  @override
  String routineMoveSpoken(String name) {
    return 'Move the $name routine';
  }

  @override
  String routineEditTooltip(String name) {
    return 'Edit the $name routine';
  }

  @override
  String get routineNameHint => 'Morning routine';

  @override
  String get routineNameEmpty => 'Type a name';

  @override
  String get routineNameTaken => 'A routine with this name exists';

  @override
  String get routineStepsTitle => 'Steps';

  @override
  String get routineStepsEmpty =>
      'No steps yet. What should this routine create?';

  @override
  String get routineStepAdd => 'Add step';

  @override
  String get routineStepNew => 'New step';

  @override
  String get routineStepEdit => 'Edit step';

  @override
  String get routineStepTitleHint => 'Workout';

  @override
  String get routineStepTime => 'Time';

  @override
  String get routineStepTimeSwitch => 'Give it a time';

  @override
  String get routineStepTimeHint =>
      'Without a time it becomes a reminder for sometime today.';

  @override
  String get routineStepTimeNone => 'No time';

  @override
  String routineStepRowSpoken(String title, String details) {
    return '$title, $details';
  }

  @override
  String routineStepMoveSpoken(String title) {
    return 'Move the step $title';
  }

  @override
  String get routineStepActions => 'Step actions';

  @override
  String routineDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get routineDeleteContent =>
      'The routine is deleted; the reminders it already created stay.';

  @override
  String get routineRepeatTitle => 'Apply automatically';

  @override
  String get routineRepeatHint =>
      'With a repeat, timed steps become recurring reminders, so the next days arrive on their own.';

  @override
  String get routineRepeatOff => 'Off';

  @override
  String get routineRepeatDaily => 'Every day';

  @override
  String get routineRepeatWeekly => 'Chosen days';

  @override
  String get routineRepeatNoTimeNote =>
      'Steps without a time don\'t repeat: a reminder without a time has no notification.';

  @override
  String routineRepeatSpoken(String summary) {
    return 'Repeat: $summary';
  }

  @override
  String get routineApplyTitle => 'Apply routine';

  @override
  String get routineApplyDay => 'Day';

  @override
  String routineApplyDaySpoken(String day) {
    return 'Day: $day';
  }

  @override
  String get routineApplyAction => 'Add';

  @override
  String get routineApplyOnlyNew => 'Add only the new ones';

  @override
  String get routineApplyAnyway => 'Add them all anyway';

  @override
  String get routineApplyUpdate => 'Update the reminders';

  @override
  String get routineApplyDuplicateToday =>
      'You already applied this routine today';

  @override
  String routineApplyDuplicateOnDay(String day) {
    return 'You already applied this routine for $day';
  }

  @override
  String routineApplyDuplicateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count steps already exist for that day. You can add only the new ones.',
      one: '1 step already exists for that day. You can add only the new ones.',
    );
    return '$_temp0';
  }

  @override
  String get routineApplySeriesTitle =>
      'This routine\'s reminders already exist';

  @override
  String get routineApplySeriesBody =>
      'A repeating routine is never created twice. You can update the existing ones to the day and repeat you chose.';

  @override
  String get routineApplyStepAlready => 'already there';

  @override
  String get routineApplyEmpty =>
      'This routine has no steps yet. Add one first.';

  @override
  String routineApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders added',
      one: '1 reminder added',
    );
    return '$_temp0';
  }

  @override
  String routineAppliedUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders updated',
      one: '1 reminder updated',
    );
    return '$_temp0';
  }

  @override
  String get routineApplyNothing => 'Nothing new to add';
}
