import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showRecoveryKeyDialog(
  BuildContext context, {
  required String recoveryKey,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Store this recovery key offline. VaultX only keeps a hashed copy, so it cannot be shown again later.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Anyone with this key can start account recovery.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SelectableText(
                recoveryKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: recoveryKey));

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery key copied')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Saved It'),
          ),
        ],
      );
    },
  );
}
