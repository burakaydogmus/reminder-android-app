import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import 'package:reminder/bloc/reminder_cubit.dart';
import 'package:reminder/domain/model/app_settings.dart';
import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/settings/rolling_switch_button.dart';
import 'package:reminder/util/dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final mutedStyle = TextStyle(
      fontSize: 12,
      color: mutedColor,
      height: 1.3,
    );

    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        final cubit = context.read<ReminderCubit>();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32 + 64 + 40, top: 32.0),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                Text(
                  'Ayarlar',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 22,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Görünüm',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Açık veya koyu temayı seçin; sistemi takip edebilir.',
                        style: mutedStyle,
                      ),
                      const SizedBox(height: 12),
                      _ThemeModeSelector(
                        value: state.settings.themeMode,
                        onChanged: (id) => cubit.setThemeMode(id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bildirimler'),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                      RollingSwitchButton(
                        value: state.settings.notificationsEnabled,
                        colorOff: errorColor,
                        onChange: (value) =>
                            cubit.setNotificationsEnabled(value),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6, top: 4),
                  child: Text(
                    'Kapalıyken zamanlanmış hatırlatmalar gönderilmez. '
                    'Açıkken sistem bildirim ayarları geçerlidir (ses, öncelik).',
                    style: mutedStyle,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6),
                  child: Text(
                    'Konum hatırlatmaları için bildirimler açık olmalı; konum izni '
                    '(Android’de mümkünse “Her zaman”) gerekir.',
                    style: mutedStyle.copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(height: 32),
                if (Platform.isAndroid) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ana ekran widget\'ı',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aktif hatırlatıcıları listeler. Soldaki kutuya dokunarak '
                          'öğeyi tamamlandı işaretlersiniz. Boyutu ana ekranda '
                          'kenarlardan sürükleyerek değiştirebilirsiniz.',
                          style: mutedStyle.copyWith(height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () => _pinHomeWidget(context),
                            child: const Text('Widget ekle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _clearDataStore(context, cubit),
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(
                        errorColor.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Tüm verileri sıfırla',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: errorColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _ThemeModeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ThemeModeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final containerColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    const options = <_ThemeOption>[
      _ThemeOption(
        id: AppThemeModeIds.system,
        label: 'Sistem',
        icon: Icons.brightness_auto_rounded,
      ),
      _ThemeOption(
        id: AppThemeModeIds.light,
        label: 'Açık',
        icon: Icons.light_mode_rounded,
      ),
      _ThemeOption(
        id: AppThemeModeIds.dark,
        label: 'Koyu',
        icon: Icons.dark_mode_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: _SegmentButton(
                option: opt,
                selected: value == opt.id,
                accent: accent,
                onTap: () => onChanged(opt.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeOption {
  final String id;
  final String label;
  final IconData icon;

  const _ThemeOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _SegmentButton extends StatelessWidget {
  final _ThemeOption option;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(option.icon, color: fg, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
