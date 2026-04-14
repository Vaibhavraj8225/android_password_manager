import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showBackupCodesDialog(
  BuildContext context, {
  required List<String> backupCodes,
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
                'Save these backup codes. Each code can be used once to recover your account.',
              ),
              const SizedBox(height: 12),
              const Text(
                'They will not be shown again after you close this dialog.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...backupCodes.map(
                (code) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: backupCodes.join('\n')),
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup codes copied')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Saved Them'),
          ),
        ],
      );
    },
  );
}
