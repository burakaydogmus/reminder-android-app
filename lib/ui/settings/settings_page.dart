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
                child: Text('Ayarlar', style: theme.textTheme.headlineLarge),
              ),
              const SizedBox(height: KorSpacing.s6),
              const PermissionsGroup(),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.palette_outlined,
                title: 'Görünüm',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemeModeIds.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: AppThemeModeIds.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Açık'),
                        ),
                        ButtonSegment(
                          value: AppThemeModeIds.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Koyu'),
                        ),
                      ],
                      selected: {state.settings.themeMode},
                      onSelectionChanged: (s) => cubit.setThemeMode(s.first),
                    ),
                  ),
                  const SizedBox(height: KorSpacing.s3),
                  Text(
                    'Açık veya koyu temayı seç ya da sistemi takip et.',
                    style: muted,
                  ),
                  if (HapticsScope.maybeOf(context) case final haptics?) ...[
                    const SizedBox(height: KorSpacing.s3),
                    _SwitchRow(
                      key: SettingsPageKeys.haptics,
                      title: 'Titreşim geri bildirimi',
                      subtitle: 'Tamamlama, silme ve kaydırma gibi '
                          'aksiyonlarda kısa titreşim.',
                      value: haptics.enabled,
                      onChanged: haptics.setEnabled,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                children: [
                  _SwitchRow(
                    title: 'Hatırlatma bildirimleri',
                    subtitle: 'Kapalıyken zamanlanmış hatırlatmalar '
                        'gönderilmez. Açıkken sistem bildirim ayarları '
                        'geçerlidir (ses, öncelik).',
                    value: state.settings.notificationsEnabled,
                    onChanged: cubit.setNotificationsEnabled,
                  ),
                  const SizedBox(height: KorSpacing.s2),
                  Text(
                    'Konum hatırlatmaları için de bildirimler açık olmalı.',
                    style: muted,
                  ),
                ],
              ),
              if (PlatformChrome.isAndroid(context)) ...[
                const SizedBox(height: KorSpacing.s5),
                GroupedCard(
                  icon: Icons.widgets_outlined,
                  title: 'Ana ekran widget\'ı',
                  children: [
                    Text(
                      'Dört widget var: Bugün, kaydırılabilir Liste, '
                      'Sıradaki ve Hızlı ekle. Daireye dokunarak işi '
                      'tamamlarsın, "+" yeni hatırlatıcı açar. Liste\'nin '
                      'boyutunu ana ekranda kenarlarından sürükleyerek '
                      'değiştirebilirsin.',
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
                      label: const Text('Widget ekle'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.settings_backup_restore_rounded,
                title: 'Yedekle ve geri yükle',
                children: [
                  Text(
                    'Hatırlatıcılarını, doğum günlerini ve ayarlarını bir '
                    'dosyaya yedekle; yeni bir cihazda veya yeniden '
                    'kurulumdan sonra geri yükle.',
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
                          label: const Text('Yedekle'),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: SettingsPageKeys.backupImport,
                        onPressed: () => _backup.import(context, cubit),
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('Geri yükle'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: KorSpacing.s5),
              GroupedCard(
                icon: Icons.info_outline_rounded,
                title: 'Diğer',
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
                    title: 'Gizlilik politikası',
                    external: true,
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  _LinkRow(
                    key: SettingsPageKeys.licenses,
                    icon: Icons.description_outlined,
                    title: 'Lisanslar',
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
                    label: 'Tüm verileri sıfırla',
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
                        'Tüm verileri sıfırla',
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

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await widget.linkOpener(AppLinks.privacyPolicy);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı açılamadı.')),
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
      applicationName: 'Hatırlatıcı',
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
