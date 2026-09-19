import 'package:material_ui/material_ui.dart';
import 'package:home_widget/home_widget.dart';

import 'package:reminder/services/reminder_home_widget_sync.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class WidgetPinSheetKeys {
  static Key option(ReminderHomeWidget widget) =>
      Key('widgetPin.${widget.name}');
}

/// Asks the launcher to pin a home screen widget (Android, F5.1).
abstract interface class HomeWidgetPinner {
  Future<bool> isSupported();
  Future<void> pin(ReminderHomeWidget widget);
}

/// [HomeWidgetPinner] over `home_widget`.
class PlatformHomeWidgetPinner implements HomeWidgetPinner {
  const PlatformHomeWidgetPinner();

  @override
  Future<bool> isSupported() async =>
      await HomeWidget.isRequestPinWidgetSupported() ?? false;

  @override
  Future<void> pin(ReminderHomeWidget widget) =>
      HomeWidget.requestPinWidget(qualifiedAndroidName: widget.qualifiedName);
}

/// Ayarlar › "Widget ekle": lets the user choose one of the four widgets
/// (Bugün first, the suggested default) and asks the launcher to pin it.
/// Where pinning is unsupported, explains how to add it by hand.
Future<void> pickAndPinHomeWidget(
  BuildContext context, {
  HomeWidgetPinner pinner = const PlatformHomeWidgetPinner(),
}) async {
  final supported = await pinner.isSupported();
  if (!context.mounted) return;
  if (!supported) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ana ekranda boş bir alana uzun basın → Widget\'lar → '
          'Hatırlatıcı\'yı seçin.',
        ),
      ),
    );
    return;
  }
  final choice = await showModalBottomSheet<ReminderHomeWidget>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _WidgetPinSheet(),
  );
  if (choice == null) return;
  await pinner.pin(choice);
}

class _WidgetPinSheet extends StatelessWidget {
  const _WidgetPinSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KorSpacing.screenEdge,
              0,
              KorSpacing.screenEdge,
              KorSpacing.s3,
            ),
            child: Semantics(
              header: true,
              child: Text(
                'Hangi widget?',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          for (final widget in ReminderHomeWidget.values)
            ListTile(
              key: WidgetPinSheetKeys.option(widget),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KorSpacing.screenEdge,
              ),
              leading: Icon(_iconOf(widget)),
              title: Text(widget.label),
              subtitle: Text(widget.description),
              onTap: () => Navigator.of(context).pop(widget),
            ),
          const SizedBox(height: KorSpacing.s3),
        ],
      ),
    );
  }

  static IconData _iconOf(ReminderHomeWidget widget) => switch (widget) {
        ReminderHomeWidget.today => Icons.today_rounded,
        ReminderHomeWidget.list => Icons.view_list_rounded,
        ReminderHomeWidget.next => Icons.schedule_rounded,
        ReminderHomeWidget.quickAdd => Icons.add_circle_outline_rounded,
      };
}
