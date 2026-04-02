import 'package:flutter/material.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/usecases/account_usecases.dart';
import '../widgets/password_card.dart';
import 'add_password_page.dart';
import 'change_password_page.dart';
import 'create_account_page.dart';
import '../state/account_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  Future<void> _openAccountSwitcher() async {
    final controller = AccountScope.of(context);
    final selected = await showModalBottomSheet<_AccountSheetAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final innerController = AccountScope.of(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Accounts'),
                subtitle: Text('Switch, add, or remove saved accounts'),
              ),
              for (final account in innerController.accounts)
                ListTile(
                  title: Text(account.username),
                  subtitle: Text(
                    account.id == innerController.activeAccount?.id
                        ? 'Currently active'
                        : 'Switch to this account',
                  ),
                  leading: CircleAvatar(
                    child: Text(_initialFor(account.username)),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _AccountSheetAction.delete(account),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      _AccountSheetAction.switchTo(account),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Add account'),
                onTap: () {
                  Navigator.pop(context, const _AccountSheetAction.add());
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    switch (selected.type) {
      case _AccountSheetActionType.add:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CreateAccountPage()),
        );
        break;
      case _AccountSheetActionType.switchAccount:
        if (selected.account != null) {
          try {
            await controller.switchToAccount(selected.account!.id);
          } on AccountException catch (error) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.message)),
            );
          }
        }
        break;
      case _AccountSheetActionType.delete:
        if (selected.account != null) {
          await _deleteAccount(selected.account!);
        }
        break;
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

    try {
      await AccountScope.of(context).deleteSavedAccount(
        accountId: account.id,
        password: password,
      );
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

  String _initialFor(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return '?';
    }
    return normalized.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);
    final vault = controller.currentVault;
    final username = controller.activeAccount?.username ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Vault: $username'),
        actions: [
          IconButton(
            onPressed: controller.isBusy ? null : _openAccountSwitcher,
            icon: const Icon(Icons.switch_account_outlined),
            tooltip: 'Manage accounts',
          ),
          IconButton(
            onPressed: controller.isBusy ? null : _openChangePasswordPage,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Change master password',
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

class _AccountSheetAction {
  const _AccountSheetAction._(this.type, this.account);

  const _AccountSheetAction.add() : this._(_AccountSheetActionType.add, null);

  const _AccountSheetAction.switchTo(AccountEntity account)
      : this._(_AccountSheetActionType.switchAccount, account);

  const _AccountSheetAction.delete(AccountEntity account)
      : this._(_AccountSheetActionType.delete, account);

  final _AccountSheetActionType type;
  final AccountEntity? account;
}

enum _AccountSheetActionType {
  add,
  switchAccount,
  delete,
}
