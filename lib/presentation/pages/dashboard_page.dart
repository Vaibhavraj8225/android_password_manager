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
        title: Text('Vault: $username'),
        actions: [
          IconButton(
            onPressed: controller.isBusy ? null : _openChangePasswordPage,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Change master password',
          ),
          IconButton(
            onPressed: controller.isBusy ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
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
