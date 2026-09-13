import 'package:material_ui/material_ui.dart';

import 'package:reminder/ui/theme/tokens/kor_shapes.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

/// Keys for tests.
abstract final class PermissionSheetKeys {
  static const confirm = Key('permissionSheet.confirm');
  static const dismiss = Key('permissionSheet.dismiss');
}

/// Pre-permission explanation sheet. Resolves to `true` when the user chose
/// the primary action, `false` otherwise (also when dismissed).
Future<bool> showPermissionSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  List<String> points = const [],
  String? step,
  Widget? illustration,
  required String confirmLabel,
  required String dismissLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PermissionSheet(
      icon: icon,
      title: title,
      body: body,
      points: points,
      step: step,
      illustration: illustration,
      confirmLabel: confirmLabel,
      dismissLabel: dismissLabel,
    ),
  );
  return result ?? false;
}

class PermissionSheet extends StatelessWidget {
  const PermissionSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.points = const [],
    this.step,
    this.illustration,
    required this.confirmLabel,
    required this.dismissLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> points;

  /// e.g. "1/2" for the two-step location flow.
  final String? step;
  final Widget? illustration;
  final String confirmLabel;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        KorSpacing.s6,
        KorSpacing.s3,
        KorSpacing.s6,
        KorSpacing.s5 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: KorRadius.mdAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(KorSpacing.s4),
                  child: Icon(icon, color: scheme.onPrimaryContainer),
                ),
              ),
              const Spacer(),
              if (step != null)
                Text(
                  'Adım $step',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: KorSpacing.s5),
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: KorSpacing.s3),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(top: KorSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: KorSizes.iconSm,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: KorSpacing.s4),
                  Expanded(
                    child: Text(p, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (illustration != null) ...[
            const SizedBox(height: KorSpacing.s5),
            ExcludeSemantics(child: illustration!),
          ],
          const SizedBox(height: KorSpacing.s7),
          FilledButton(
            key: PermissionSheetKeys.confirm,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
          const SizedBox(height: KorSpacing.s3),
          TextButton(
            key: PermissionSheetKeys.dismiss,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(dismissLabel),
          ),
        ],
      ),
    );
  }
}

/// Simplified system location settings screen with "Her zaman izin ver"
/// selected (§3.3.10 step 2).
class LocationAlwaysIllustration extends StatelessWidget {
  const LocationAlwaysIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget option(String label, {bool selected = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: KorSpacing.s2),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: KorSizes.iconSm,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KorSpacing.s4),
            Expanded(
              child: Text(
                label,
                style: selected
                    ? theme.textTheme.labelLarge
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: KorRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(KorSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konum izni',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: KorSpacing.s3),
            option('Her zaman izin ver', selected: true),
            option('Yalnızca uygulamayı kullanırken'),
            option('İzin verme'),
          ],
        ),
      ),
    );
  }
}
