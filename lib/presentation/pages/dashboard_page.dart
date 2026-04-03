import 'package:flutter/material.dart';

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
                return PasswordCard(entry);
              },
            ),
    );
  }
}
