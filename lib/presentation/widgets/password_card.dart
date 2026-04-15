import 'package:flutter/material.dart';

class PasswordCard extends StatelessWidget {
  const PasswordCard(
    this.entry, {
    required this.onDelete,
    this.isDeleting = false,
    super.key,
  });

  final Map<String, dynamic> entry;
  final VoidCallback? onDelete;
  final bool isDeleting;

  Future<void> _showDetails(BuildContext context) async {
    final appName = entry['app']?.toString() ?? '';
    final email = entry['email']?.toString() ?? '';
    final username = entry['username']?.toString() ?? '';
    final password = entry['password']?.toString() ?? '';
    var isPasswordVisible = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(appName.isEmpty ? 'Credential Details' : appName),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(email.isEmpty ? 'No email saved' : email),
                    const SizedBox(height: 12),
                    Text(
                      'Username',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      username.isEmpty ? 'No username saved' : username,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Password',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: isPasswordVisible
                              ? 'Hide password'
                              : 'Show password',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      password.isEmpty
                          ? 'No password saved'
                          : isPasswordVisible
                          ? password
                          : '*' * password.length,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          onDelete?.call();
                        },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appName = entry['app']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(appName.isEmpty ? 'Unnamed App' : appName),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showDetails(context),
      ),
    );
  }
}


