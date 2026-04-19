import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class PasswordTilePremium extends StatelessWidget {
  const PasswordTilePremium({
    required this.entry,
    required this.onDelete,
    this.onEdit,
    super.key,
    this.isDeleting = false,
  });

  final Map<String, dynamic> entry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isDeleting;

  Future<void> _copyPassword(BuildContext context) async {
    final password = entry['password']?.toString() ?? '';
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No password to copy.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: password));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password copied.')));
  }

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
                    _DetailBlock(
                      label: 'Email',
                      value: email.isEmpty ? 'No email saved' : email,
                    ),
                    const SizedBox(height: 12),
                    _DetailBlock(
                      label: 'Username',
                      value: username.isEmpty ? 'No username saved' : username,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Password',
                            style: Theme.of(context).textTheme.labelLarge,
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
                        ),
                      ],
                    ),
                    SelectableText(
                      password.isEmpty
                          ? 'No password saved'
                          : isPasswordVisible
                          ? password
                          : '*' * password.length,
                      style: Theme.of(context).textTheme.bodyLarge,
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
                  onPressed: onEdit == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          onEdit?.call();
                        },
                  child: const Text('Edit'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
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
    final username = entry['username']?.toString() ?? '';
    final password = entry['password']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(context),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName.isEmpty ? 'Unnamed App' : appName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username.isEmpty ? 'No username' : username,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      password.isEmpty ? '' : '*' * (password.length.clamp(6, 14)),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyPassword(context),
                icon: const Icon(Icons.content_copy_rounded),
                tooltip: 'Copy password',
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtext.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordTile extends PasswordTilePremium {
  const PasswordTile({
    required super.entry,
    required super.onDelete,
    super.onEdit,
    super.key,
    super.isDeleting,
  });
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

