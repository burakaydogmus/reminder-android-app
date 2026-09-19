import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reminder/app.dart';
import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/domain/model/birthday.dart';
import 'package:reminder/domain/model/reminder.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/haptics_store.dart';
import 'package:reminder/ui/theme/kor_theme.dart';

import '../helpers/fake_permission_service.dart';
import '../helpers/mocks.dart';

/// Light and dark Kor themes for widget tests.
final korThemes = <(String, ThemeData Function())>[
  ('light', KorTheme.light),
  ('dark', KorTheme.dark),
];

/// A real [ReminderCubit] over mocked services, loaded with [reminders] and
/// [birthdays], plus a MaterialApp wrapper configured like `App`.
class UiHarness {
  UiHarness._(this.repository, this.cubit);

  final MockReminderRepository repository;
  final ReminderCubit cubit;

  static bool _fallbacksRegistered = false;

  static Future<UiHarness> create({
    List<Reminder> reminders = const [],
    List<Birthday> birthdays = const [],
    List<ReminderCategory> categories = const [],
    DateTime Function() now = DateTime.now,
  }) async {
    if (!_fallbacksRegistered) {
      registerModelFallbackValues();
      _fallbacksRegistered = true;
    }
    await initializeDateFormatting('tr_TR');
    await initializeDateFormatting('en_US');

    final repository = MockReminderRepository();
    final notifications = MockNotificationService();
    final geofence = MockGeofenceSync();
    final homeWidget = MockHomeWidgetSync();
    stubRepositoryWrites(repository);
    stubNotificationService(notifications);
    stubGeofenceSync(geofence);
    stubHomeWidgetSync(homeWidget);
    when(() => repository.loadReminders())
        .thenAnswer((_) async => [...reminders]);
    when(() => repository.loadBirthdays())
        .thenAnswer((_) async => [...birthdays]);
    when(() => repository.loadSettings())
        .thenAnswer((_) async => const AppSettings());
    when(() => repository.loadCategories())
        .thenAnswer((_) async => [...categories]);

    final cubit = ReminderCubit(
      repository,
      notifications,
      geofence: geofence,
      homeWidget: homeWidget,
      now: now,
    );
    await cubit.load();
    return UiHarness._(repository, cubit);
  }

  /// Permission state seen by the UI (all granted unless a test changes it).
  final FakePermissionService permissions = FakePermissionService();

  /// "Titreşim geri bildirimi" (on unless a test changes it).
  final HapticsStore haptics = HapticsStore.memory();

  /// "Dil" (F6.1): Turkish unless a test passes another [app] `language`.
  final AppLanguageStore languageStore = AppLanguageStore.memory();

  /// Wraps [home] like `App`. The app is Turkish by default so existing
  /// tests keep their Turkish expectations; pass
  /// `language: AppLanguage.english` for the English variants.
  Widget app({
    required Widget home,
    ThemeData Function() theme = KorTheme.light,
    TargetPlatform platform = TargetPlatform.android,
    AppLanguage language = AppLanguage.turkish,
    ValueChanged<AppLanguage>? onLanguageChanged,
  }) {
    return PermissionScope(
      service: permissions,
      child: BlocProvider.value(
        value: cubit,
        child: AppLanguageScope(
          store: languageStore,
          initial: language,
          onChanged: onLanguageChanged,
          child: Builder(
            builder: (context) => MaterialApp(
              theme: theme().copyWith(platform: platform),
              locale: AppLocales.resolve(
                AppLanguageScope.maybeOf(context)?.language ?? language,
                const [AppLocales.turkish],
              ),
              supportedLocales: AppLocales.supported,
              localizationsDelegates: App.localizationsDelegates,
              builder: (context, child) => HapticsScope(
                store: haptics,
                child: child ?? const SizedBox.shrink(),
              ),
              home: home,
            ),
          ),
        ),
      ),
    );
  }
}
