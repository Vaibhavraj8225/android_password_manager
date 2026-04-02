import 'package:flutter/material.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import 'reset_password_page.dart';
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlockVault() async {
    final controller = AccountScope.of(context);
    try {
      await controller.unlockActiveAccount(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      _passwordController.clear();
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unlock vault.')),
      );
    }
  }

  Future<void> _openCreateAccount() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateAccountPage(),
      ),
    );
  }

  Future<void> _openResetPassword() async {
    final wasReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ResetPasswordPage(),
      ),
    );

    if (!mounted || wasReset != true) {
      return;
    }

    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset complete. Sign in again.')),
    );
  }

  Future<void> _switchAccount(AccountEntity account) async {
    final controller = AccountScope.of(context);
    try {
      await controller.switchToAccount(account.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _usernameController.text = account.username;
        _passwordController.clear();
      });
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _deleteAccount(AccountEntity account) async {
    final password = await _promptDeletePassword(account);
    if (password == null || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Remove ${account.username} from this device and delete its local vault data?',
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
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final controller = AccountScope.of(context);
    try {
      await controller.deleteSavedAccount(
        accountId: account.id,
        password: password,
      );
      if (!mounted) {
        return;
      }

      final activeUsername = controller.activeAccount?.username ?? '';
      setState(() {
        _usernameController.text = activeUsername;
        _passwordController.clear();
      });
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<String?> _promptDeletePassword(AccountEntity account) async {
    final passwordController = TextEditingController();
    var obscureText = true;

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Confirm master password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter the master password for ${account.username}.'),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscureText,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, passwordController.text),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );

    passwordController.dispose();
    return password;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);
    final active = controller.activeAccount;
    if (_usernameController.text.isEmpty && active != null) {
      _usernameController.text = active.username;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('VaultX')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (controller.errorMessage != null) ...[
            Card(
              color: Colors.red.withOpacity(0.18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(controller.errorMessage!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            controller.hasAccounts
                ? 'Saved accounts on this device'
                : 'Create your first master account to secure the vault and generate one-time backup codes.',
          ),
          const SizedBox(height: 16),
          if (controller.hasAccounts) ...[
            for (final account in controller.accounts)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_initialFor(account.username)),
                  ),
                  title: Text(account.username),
                  subtitle: Text(
                    account.id == active?.id ? 'Active account' : 'Tap to switch',
                  ),
                  onTap: controller.isBusy ? null : () => _switchAccount(account),
                  trailing: IconButton(
                    onPressed: controller.isBusy ? null : () => _deleteAccount(account),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete account',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Email or Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Master Password'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: controller.isBusy ? null : _unlockVault,
              child: Text(controller.isBusy ? 'Unlocking...' : 'Unlock Vault'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openResetPassword,
              child: const Text('Forgot password? Use a backup code'),
            ),
          ] else ...[
            FilledButton(
              onPressed: _openCreateAccount,
              child: const Text('Create Master Account'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: controller.isBusy ? null : _openCreateAccount,
            child: Text(controller.hasAccounts ? 'Add Another Account' : 'Add Account'),
          ),
        ],
      ),
    );
  }

  String _initialFor(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return '?';
    }
    return normalized.substring(0, 1).toUpperCase();
  }
}
