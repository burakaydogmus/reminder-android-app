import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/config/app_licenses.dart';
import 'package:reminder/config/app_links.dart';
import 'package:reminder/data/backup/backup_io.dart';
import 'package:reminder/data/backup/backup_service.dart';
import 'package:reminder/data/reminder_repository.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/l10n/app_language.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/settings/backup_actions.dart';
import 'package:reminder/ui/settings/permissions_group.dart';
import 'package:reminder/ui/settings/reset_data_dialog.dart';
import 'package:reminder/ui/settings/widget_pin_sheet.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/haptics.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class SettingsPageKeys {
  static const backupExport = Key('settings.backupExport');
  static const backupImport = Key('settings.backupImport');
  static const privacyPolicy = Key('settings.privacyPolicy');
  static const licenses = Key('settings.licenses');
  static const haptics = Key('settings.haptics');
  static const pinWidget = Key('settings.pinWidget');
  static const language = Key('settings.language');
}

/// Ayarlar (§3.3.9): grouped cards for İzinler, Görünüm, Bildirimler, Ana
/// ekran widget'ı, Yedekleme, Diğer (privacy policy, licences) and data
/// reset.
class SettingsPage extends StatefulWidget {
  /// [backupIo] and [backupService] are injectable for tests; by default the
  /// platform share sheet/picker and a repository on the app's shared
  /// database are used. [linkOpener] opens external links (browser).
  const SettingsPage({
    super.key,
    this.backupIo,
    this.backupService,
    this.linkOpener = openExternalLink,
    this.widgetPinner = const PlatformHomeWidgetPinner(),
  });

  final BackupIo? backupIo;
  final BackupService? backupService;
  final LinkOpener linkOpener;

  /// Pins the chosen home screen widget (F5.1); tests pass a fake.
  final HomeWidgetPinner widgetPinner;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Created only when no [SettingsPage.backupService] is given; opens the
  /// isolate's shared database lazily and releases it in [dispose].
  ReminderRepository? _ownedRepository;
  late final BackupActions _backup = BackupActions(
    io: widget.backupIo ?? const PlatformBackupIo(),
    service: widget.backupService ??
        BackupService(_ownedRepository = ReminderRepository()),
  );

  @override
  void dispose() {
    _ownedRepository?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<ReminderCubit, ReminderState>(
        builder: (context, state) {
          final cubit = context.read<ReminderCubit>();
          final bottom = MediaQuery.paddingOf(context).bottom;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              KorSpacing.screenEdge,
              0,
              KorSpacing.screenEdge,
              bottom + KorSpacing.s7,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsTooltip,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: KorSpacing.s6),
              const PermissionsGroup(),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearance,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: AppThemeModeIds.system,
                          icon: const Icon(Icons.brightness_auto_rounded),
                          label: Text(l10n.settingsThemeSystem),
                        ),
                        ButtonSegment(
                          value: AppThemeModeIds.light,
                          icon: const Icon(Icons.light_mode_rounded),
                          label: Text(l10n.settingsThemeLight),
                        ),
                        ButtonSegment(
                          value: AppThemeModeIds.dark,
                          icon: const Icon(Icons.dark_mode_rounded),
                          label: Text(l10n.settingsThemeDark),
                        ),
                      ],
                      selected: {state.settings.themeMode},
                      onSelectionChanged: (s) => cubit.setThemeMode(s.first),
                    ),
                  ),
                  const SizedBox(height: KorSpacing.s3),
                  Text(
                    l10n.settingsThemeHint,
                    style: muted,
                  ),
                  if (AppLanguageScope.maybeOf(context) case final language?)
                    ..._languageRow(context, language, muted),
                  if (HapticsScope.maybeOf(context) case final haptics?) ...[
                    const SizedBox(height: KorSpacing.s3),
                    _SwitchRow(
                      key: SettingsPageKeys.haptics,
                      title: l10n.settingsHaptics,
                      subtitle: l10n.settingsHapticsHint,
                      value: haptics.enabled,
                      onChanged: haptics.setEnabled,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.notifications_outlined,
                title: l10n.settingsNotifications,
                children: [
                  _SwitchRow(
                    title: l10n.settingsReminderNotifications,
                    subtitle: l10n.settingsReminderNotificationsHint,
                    value: state.settings.notificationsEnabled,
                    onChanged: cubit.setNotificationsEnabled,
                  ),
                  const SizedBox(height: KorSpacing.s2),
                  Text(
                    l10n.settingsLocationNeedsNotifications,
                    style: muted,
                  ),
                ],
              ),
              if (PlatformChrome.isAndroid(context)) ...[
                const SizedBox(height: KorSpacing.s5),
                GroupedCard(
                  icon: Icons.widgets_outlined,
                  title: l10n.settingsHomeWidget,
                  children: [
                    Text(
                      l10n.settingsHomeWidgetHint,
                      style: muted,
                    ),
                    const SizedBox(height: KorSpacing.s4),
                    FilledButton.tonalIcon(
                      key: SettingsPageKeys.pinWidget,
                      onPressed: () => pickAndPinHomeWidget(
                        context,
                        pinner: widget.widgetPinner,
                      ),
                      icon: const Icon(Icons.add_to_home_screen_rounded),
                      label: Text(l10n.settingsAddWidget),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.settings_backup_restore_rounded,
                title: l10n.settingsBackup,
                children: [
                  Text(
                    l10n.settingsBackupHint,
                    style: muted,
                  ),
                  const SizedBox(height: KorSpacing.s4),
                  Wrap(
                    spacing: KorSpacing.s3,
                    runSpacing: KorSpacing.s3,
                    children: [
                      Builder(
                        builder: (buttonContext) => FilledButton.tonalIcon(
                          key: SettingsPageKeys.backupExport,
                          onPressed: () => _backup.export(buttonContext),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(l10n.settingsBackupExport),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: SettingsPageKeys.backupImport,
                        onPressed: () => _backup.import(context, cubit),
                        icon: const Icon(Icons.restore_rounded),
                        label: Text(l10n.backupRestore),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsOther,
                padding: const EdgeInsets.fromLTRB(
                  KorSpacing.s5,
                  KorSpacing.s3,
                  KorSpacing.s5,
                  KorSpacing.s2,
                ),
                children: [
                  _LinkRow(
                    key: SettingsPageKeys.privacyPolicy,
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.settingsPrivacy,
                    external: true,
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  _LinkRow(
                    key: SettingsPageKeys.licenses,
                    icon: Icons.description_outlined,
                    title: l10n.settingsLicenses,
                    onTap: () => _openLicenses(context),
                  ),
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
                children: [
                  Semantics(
                    button: true,
                    label: l10n.resetTitle,
                    excludeSemantics: true,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KorSpacing.s5,
                      ),
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: scheme.error,
                      ),
                      title: Text(
                        l10n.resetTitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                      onTap: () => _clearDataStore(context, cubit),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Dil" (F6.1): Sistem / Türkçe / English.
  List<Widget> _languageRow(
    BuildContext context,
    AppLanguageController language,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    return [
      const SizedBox(height: KorSpacing.s5),
      Text(l10n.settingsLanguageTitle,
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: KorSpacing.s3),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<AppLanguage>(
          key: SettingsPageKeys.language,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: AppLanguage.system,
              label: Text(l10n.settingsLanguageSystem),
            ),
            ButtonSegment(
              value: AppLanguage.turkish,
              label: Text(l10n.settingsLanguageTurkish),
            ),
            ButtonSegment(
              value: AppLanguage.english,
              label: Text(l10n.settingsLanguageEnglish),
            ),
          ],
          selected: {language.language},
          onSelectionChanged: (s) => language.setLanguage(s.first),
        ),
      ),
      const SizedBox(height: KorSpacing.s3),
      Text(l10n.settingsLanguageHint, style: muted),
    ];
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await widget.linkOpener(AppLinks.privacyPolicy);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsLinkFailed)),
    );
  }

  /// Flutter's licence page: packages from `pubspec.lock` plus the ones added
  /// by `registerAppLicenses` (Google Sans Flex).
  Future<void> _openLicenses(BuildContext context) async {
    String? version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: version,
      applicationLegalese: appLegalese,
    );
  }

  /// Confirmation with "Önce yedekle": after a backup (shared or sheet
  /// closed) the dialog comes back so the user can still reset.
  Future<void> _clearDataStore(
    BuildContext context,
    ReminderCubit cubit,
  ) async {
    while (true) {
      if (!context.mounted) return;
      final choice = await showResetDataDialog(context);
      if (choice == ResetDataChoice.cancel) return;
      if (choice == ResetDataChoice.reset) {
        await cubit.clearAllData();
        return;
      }
      if (!context.mounted) return;
      final backedUp = await _backup.export(context);
      if (!backedUp) return;
    }
  }
}

/// Title + subtitle + `Switch.adaptive`, one semantics node, whole row
/// toggles.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      ),
    );
  }
}

/// One tappable row in a [GroupedCard]: icon, title and a trailing hint
/// (open-in-new for links that leave the app, chevron otherwise).
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.external = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      link: external,
      button: !external,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(title),
        trailing: Icon(
          external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
