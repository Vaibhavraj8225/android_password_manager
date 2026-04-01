import 'package:flutter/material.dart';

import '../../core/master_account_service.dart';
import '../../data/vault_repository.dart';
import '../../domain/models/vault.dart';
import '../widgets/password_card.dart';
import 'add_password_page.dart';
import 'change_password_page.dart';

class HomePage extends StatefulWidget {
  final Vault initialVault;
  final VaultRepository repository;
  final List<int> encryptionKey;
  final String username;
  final MasterAccountService accountService;

  const HomePage({
    required this.initialVault,
    required this.repository,
    required this.encryptionKey,
    required this.username,
    required this.accountService,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Vault _vault;

  @override
  void initState() {
    super.initState();
    _vault = widget.initialVault;
  }

  Future<void> _openAddPasswordPage() async {
    final updatedVault = await Navigator.push<Vault>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordPage(
          vault: _vault,
          repository: widget.repository,
          encryptionKey: widget.encryptionKey,
          username: widget.username,
        ),
      ),
    );

    if (updatedVault != null) {
      setState(() {
        _vault = updatedVault;
      });
    }
  }

  Future<void> _openChangePasswordPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          accountService: widget.accountService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vault: ${widget.username}'),
        actions: [
          IconButton(
            onPressed: _openChangePasswordPage,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Change master password',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPasswordPage,
        child: const Icon(Icons.add),
      ),
      body: _vault.entries.isEmpty
          ? const Center(
              child: Text('No passwords saved yet'),
            )
          : ListView.builder(
              itemCount: _vault.entries.length,
              itemBuilder: (_, i) {
                final entry = _vault.entries[i];
                return PasswordCard(entry);
              },
            ),
    );
  }
}
