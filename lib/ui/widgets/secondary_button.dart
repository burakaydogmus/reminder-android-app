import 'package:material_ui/material_ui.dart';

class SecondaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(theme.primaryColor),
        overlayColor: WidgetStateProperty.all(
          theme.primaryColor.withValues(alpha: 0.06),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Text(title),
    );
  }
}
