import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reminder/app.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F6.1: "Dil" setting, locale rules and the background lookup used by
/// notifications, the widget payload and shortcuts.
void main() {
  group('AppLocales.resolve', () {
    test('Sistem: Turkish only when the first system language is Turkish', () {
      Locale resolve(List<Locale> system) =>
          AppLocales.resolve(AppLanguage.system, system);

      expect(resolve(const [Locale('tr', 'TR')]), AppLocales.turkish);
      expect(resolve(const [Locale('tr')]), AppLocales.turkish);
      expect(resolve(const [Locale('en', 'GB')]), AppLocales.english);
      expect(resolve(const [Locale('de', 'DE')]), AppLocales.english);
      expect(
        resolve(const [Locale('de'), Locale('tr')]),
        AppLocales.english,
        reason: 'only the preferred language counts',
      );
      expect(resolve(const []), AppLocales.english);
    });

    test('an explicit choice wins over the system language', () {
      const turkishDevice = [Locale('tr', 'TR')];
      const englishDevice = [Locale('en', 'US')];
      expect(
        AppLocales.resolve(AppLanguage.english, turkishDevice),
        AppLocales.english,
      );
      expect(
        AppLocales.resolve(AppLanguage.turkish, englishDevice),
        AppLocales.turkish,
      );
    });

    test('App: "Sistem" leaves MaterialApp.locale to the system', () {
      expect(App.localeFor(AppLanguage.system), isNull);
      expect(App.localeFor(AppLanguage.turkish), AppLocales.turkish);
      expect(App.localeFor(AppLanguage.english), AppLocales.english);
      expect(
        App.resolveSystemLocale(
          const [Locale('tr', 'TR')],
          AppLocales.supported,
        ),
        AppLocales.turkish,
      );
      expect(
        App.resolveSystemLocale(
          const [Locale('fr', 'FR')],
          AppLocales.supported,
        ),
        AppLocales.english,
      );
      expect(App.resolveSystemLocale(null, AppLocales.supported),
          AppLocales.english);
    });

    test('intl locales', () {
      expect(AppLocales.intlLocaleOf(AppLocales.turkish), 'tr_TR');
      expect(AppLocales.intlLocaleOf(AppLocales.english), 'en_US');
      expect(AppL10n.turkish.intlLocale, 'tr_TR');
      expect(AppL10n.english.intlLocale, 'en_US');
    });

    test('Turkish upper case keeps the dotted İ, English does not', () {
      expect(AppL10n.turkish.upper('bugün · pazartesi'), 'BUGÜN · PAZARTESİ');
      expect(AppL10n.english.upper('today · monday'), 'TODAY · MONDAY');
    });
  });

  group('AppLanguageStore (SharedPreferences, no schema change)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to Sistem and round-trips every choice', () async {
      final store = AppLanguageStore();
      expect(await store.load(), AppLanguage.system);
      for (final language in AppLanguage.values) {
        await store.save(language);
        expect(await AppLanguageStore().load(), language);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(AppLanguageStore.languageKey),
          language.storageKey,
        );
      }
    });

    test('unknown stored values fall back to Sistem', () async {
      SharedPreferences.setMockInitialValues({
        AppLanguageStore.languageKey: 'klingon',
      });
      expect(await AppLanguageStore().load(), AppLanguage.system);
    });

    test('storage keys are the persisted contract', () {
      expect(
        [for (final l in AppLanguage.values) l.storageKey],
        ['system', 'tr', 'en'],
      );
      expect(AppLanguageStore.languageKey, 'app_language_v1');
    });
  });

  group('BackgroundLocalizations (isolates without a BuildContext)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Sistem follows the given system language', () async {
      final tr = await BackgroundLocalizations.load(
        systemLocales: const [Locale('tr', 'TR')],
      );
      final en = await BackgroundLocalizations.load(
        systemLocales: const [Locale('es', 'ES')],
      );
      expect(tr.localeName, 'tr');
      expect(tr.notifBodyFallback, 'Hatırlatma zamanı');
      expect(en.localeName, 'en');
      expect(en.notifBodyFallback, 'Time for your reminder');
    });

    test('the stored choice wins, also when changed by another isolate',
        () async {
      await AppLanguageStore().save(AppLanguage.english);
      final l10n = await BackgroundLocalizations.load(
        systemLocales: const [Locale('tr', 'TR')],
      );
      expect(l10n.localeName, 'en');

      await AppLanguageStore().save(AppLanguage.turkish);
      expect(
        (await BackgroundLocalizations.load(
          systemLocales: const [Locale('en', 'US')],
        ))
            .localeName,
        'tr',
      );
    });

    test('an in-memory store (tests) is read as is', () async {
      final l10n = await BackgroundLocalizations.load(
        store: AppLanguageStore.memory(language: AppLanguage.english),
        systemLocales: const [Locale('tr')],
      );
      expect(l10n.todayTitle, 'Today');
    });
  });

  group('AppLanguageScope', () {
    testWidgets('setLanguage saves, rebuilds dependants and reports once',
        (tester) async {
      final store = AppLanguageStore.memory();
      final changes = <AppLanguage>[];
      late AppLanguageController controller;
      await tester.pumpWidget(
        AppLanguageScope(
          store: store,
          initial: AppLanguage.turkish,
          onChanged: changes.add,
          child: Builder(
            builder: (context) {
              controller = AppLanguageScope.maybeOf(context)!;
              return Text(
                controller.language.storageKey,
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );
      expect(find.text('tr'), findsOneWidget);

      await controller.setLanguage(AppLanguage.english);
      await tester.pump();
      expect(find.text('en'), findsOneWidget);
      expect(await store.load(), AppLanguage.english);
      expect(changes, [AppLanguage.english]);

      await controller.setLanguage(AppLanguage.english);
      await tester.pump();
      expect(changes, [AppLanguage.english], reason: 'no-op when unchanged');
    });
  });
}
