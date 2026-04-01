import 'package:flutter/material.dart';

import '../../core/master_account_service.dart';
import '../../data/vault_repository.dart';
import '../../domain/models/vault.dart';
import '../widgets/backup_codes_dialog.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({
    required this.accountService,
    required this.vaultRepository,
    super.key,
  });

  final MasterAccountService accountService;
  final VaultRepository vaultRepository;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await widget.accountService.createAccount(
        username: username,
        password: password,
      );

      await widget.vaultRepository.save(
        session.account.username,
        session.vaultKey,
        Vault.empty(),
      );

      if (!mounted) {
        return;
      }

      await showBackupCodesDialog(
        context,
        backupCodes: session.backupCodes,
        title: 'Backup Codes',
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, session);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Master Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              helperText: 'Use 8+ chars with uppercase, lowercase, and number.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _createAccount,
            child: Text(_isSubmitting ? 'Creating...' : 'Create Account'),
          ),
        ],
      ),
    );
  }
}
