import 'package:flutter/material.dart';

import 'package:reminder/ui/widgets/primary_button.dart';
import 'package:reminder/ui/widgets/secondary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PrimaryButton(onPressed: onConfirm, title: "Onayla"),
          const SizedBox(height: 10),
          SecondaryButton(onPressed: onCancel, title: "İptal"),
        ],
      ),
    );
  }
}
