import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum DialogType { success, error, warning }

void showHabiVaultDialog({
  required BuildContext context,
  required String title,
  required String message,
  required DialogType type,
}) {
  IconData icon;
  Color color;

  switch (type) {
    case DialogType.success:
      icon = Icons.check_circle_outline;
      color = Colors.green.shade400;
      break;
    case DialogType.error:
      icon = Icons.highlight_off;
      color = Colors.red.shade400;
      break;
    case DialogType.warning:
      icon = Icons.warning_amber_rounded;
      color = Colors.orange.shade400;
      break;
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color)
                .animate()
                .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(1.5, 1.5),
                )
                .then()
                .shake(hz: 3, duration: 300.ms),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}
