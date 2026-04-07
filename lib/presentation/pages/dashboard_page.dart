import 'package:flutter/material.dart';

import '../../domain/models/vault.dart';
import '../state/account_scope.dart';
import '../widgets/password_card.dart';
import 'add_password_page.dart';
import 'change_password_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? _deletingIndex;
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();
  bool _isDeleteAccountPasswordObscured = true;

  @override
  void dispose() {
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openAddPasswordPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPasswordPage(),
      ),
    );
  }

  Future<void> _openChangePasswordPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordPage(),
      ),
    );
  }

  Future<void> _logout() async {
    final controller = AccountScope.of(context);
    try {
      await controller.logout();
      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out right now.')),
      );
    }
  }

  Future<void> _openAccountMenu() async {
    final controller = AccountScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Change Master Password'),
                onTap: controller.isBusy
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _openChangePasswordPage();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: controller.isBusy
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _logout();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Delete Master Account'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: controller.isBusy
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _deleteMasterAccount();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCredential(int index) async {
    final controller = AccountScope.of(context);
    final entry = controller.currentVault.entries[index];
    final appName = entry['app']?.toString().trim();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Credential'),
          content: Text(
            'Delete ${appName == null || appName.isEmpty ? 'this credential' : 'the credential for $appName'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingIndex = index;
    });

    final updatedEntries =
        List<Map<String, dynamic>>.from(controller.currentVault.entries)
          ..removeAt(index);

    try {
      await controller.saveVault(
        Vault(
          entries: updatedEntries,
          notes: List<Map<String, dynamic>>.from(controller.currentVault.notes),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credential deleted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete credential.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIndex = null;
        });
      }
    }
  }

  Future<void> _deleteMasterAccount() async {
    final controller = AccountScope.of(context);
    final activeAccount = controller.activeAccount;
    if (activeAccount == null) {
      return;
    }

    _deleteAccountPasswordController.clear();
    _isDeleteAccountPasswordObscured = true;

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Master Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently deletes ${activeAccount.username} and destroys every credential stored inside this vault.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _deleteAccountPasswordController,
                      obscureText: _isDeleteAccountPasswordObscured,
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              _isDeleteAccountPasswordObscured =
                                  !_isDeleteAccountPasswordObscured;
                            });
                          },
                          icon: Icon(
                            _isDeleteAccountPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: _isDeleteAccountPasswordObscured
                              ? 'Show password'
                              : 'Hide password',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _deleteAccountPasswordController.text,
                  ),
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || password == null) {
      return;
    }

    try {
      final messenger = ScaffoldMessenger.of(context);
      await controller.deleteSavedAccount(
        accountId: activeAccount.id,
        password: password,
      );
      await controller.logout();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Master account deleted.')),
      );
    } on Exception {
      if (!mounted) {
        return;
      }

      final message = controller.errorMessage ?? 'Could not delete master account.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);

    if (!controller.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vault')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sign in from the home page to access your vault.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final vault = controller.currentVault;
    final username = controller.activeAccount?.username ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: controller.isBusy ? null : _openAccountMenu,
          icon: const Icon(Icons.menu),
          tooltip: 'Account options',
        ),
        title: Text('Vault: $username'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.isBusy ? null : _openAddPasswordPage,
        child: const Icon(Icons.add),
      ),
      body: vault.entries.isEmpty
          ? const Center(
              child: Text('No passwords saved yet'),
            )
          : ListView.builder(
              itemCount: vault.entries.length,
              itemBuilder: (_, i) {
                final entry = vault.entries[i];
                return PasswordCard(
                  entry,
                  onDelete: () => _deleteCredential(i),
                  isDeleting: _deletingIndex == i,
                );
              },
            ),
    );
  }
}
