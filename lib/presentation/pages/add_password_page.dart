import 'package:flutter/material.dart';

import '../../data/vault_repository.dart';
import '../../domain/models/vault.dart';

class AddPasswordPage extends StatefulWidget {
  final Vault vault;
  final VaultRepository repository;
  final List<int> encryptionKey;
  final String username;

  const AddPasswordPage({
    required this.vault,
    required this.repository,
    required this.encryptionKey,
    required this.username,
    super.key,
  });

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final TextEditingController _appController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _appController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = _appController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (app.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedEntries = List<Map<String, dynamic>>.from(widget.vault.entries)
      ..add({
        'app': app,
        'username': username,
        'password': password,
      });

    final updatedVault = Vault(
      entries: updatedEntries,
      notes: List<Map<String, dynamic>>.from(widget.vault.notes),
    );

    try {
      await widget.repository.save(
        widget.username,
        widget.encryptionKey,
        updatedVault,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, updatedVault);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _appController,
              decoration: const InputDecoration(labelText: 'App'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
