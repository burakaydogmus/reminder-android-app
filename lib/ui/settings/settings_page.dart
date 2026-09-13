import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/components/kor_surfaces.dart';
import 'package:reminder/ui/settings/permissions_group.dart';
import 'package:reminder/ui/theme/adaptive/platform_chrome.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';
import 'package:reminder/util/dialog.dart';

/// Ayarlar (§3.3.9): grouped cards for İzinler, Görünüm, Bildirimler, Ana
/// ekran widget'ı and data reset.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                      'Aktif hatırlatıcıları listeler. Soldaki kutuya '
                      'dokunarak öğeyi tamamlandı işaretlersin. Boyutu ana '
                      'ekranda kenarlardan sürükleyerek değiştirebilirsin.',
                      style: muted,
                    ),
                    const SizedBox(height: KorSpacing.s4),
                    FilledButton.tonalIcon(
                      onPressed: () => _pinHomeWidget(context),
                      icon: const Icon(Icons.add_to_home_screen_rounded),
                      label: const Text('Widget ekle'),
                    ),
                  ],
                ),
              ],
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

  Future<void> _pinHomeWidget(BuildContext context) async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!context.mounted) return;
    if (supported) {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: kReminderListWidgetQualifiedAndroidName,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ana ekranda boş bir alana uzun basın → Widget\'lar → Hatırlatıcıyı seçin.',
          ),
        ),
      );
    }
  }

  Future<void> _clearDataStore(
    BuildContext context,
    ReminderCubit cubit,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Tüm verileri sıfırla',
      content: 'Tüm hatırlatmalar ve ayarlar silinir. Bu işlem geri alınamaz.',
    );
    if (confirmed && context.mounted) {
      await cubit.clearAllData();
    }
  }
}

/// Title + subtitle + `Switch.adaptive`, one semantics node, whole row
/// toggles.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
