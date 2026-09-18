import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/settings/settings_page.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Opens Ayarlar (pushed route).
Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
  );
}

/// Top of a tab: optional overline (date), headlineLarge title, optional
/// [actions] (48 dp icon buttons, e.g. Ara) and the Ayarlar gear (48 dp).
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.overline,
    this.actions = const [],
  });

  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: KorSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(
                    overline!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineLarge),
                ),
              ],
            ),
          ),
        ),
        ...actions,
        IconButton(
          tooltip: 'Ayarlar',
          onPressed: () => openSettings(context),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
