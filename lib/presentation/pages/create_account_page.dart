import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
<<<<<<< HEAD
import '../state/account_scope.dart';
import '../widgets/recovery_key_dialog.dart';
=======
import '../widgets/backup_codes_dialog.dart';
import '../state/account_scope.dart';
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
<<<<<<< HEAD
  final TextEditingController _confirmPasswordController =
      TextEditingController();
=======
  final TextEditingController _confirmPasswordController = TextEditingController();
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
  final TextEditingController _tokenController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword != password) {
<<<<<<< HEAD
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
=======
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
<<<<<<< HEAD
      final recoveryKey = await AccountScope.of(context).createAccount(
=======
      final backupCodes = await AccountScope.of(context).createAccount(
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
        username: username,
        password: password,
        authToken: _tokenController.text,
      );

      if (!mounted) {
        return;
      }

<<<<<<< HEAD
      await showRecoveryKeyDialog(
        context,
        recoveryKey: recoveryKey,
        title: 'Recovery Key',
=======
      await showBackupCodesDialog(
        context,
        backupCodes: backupCodes,
        title: 'Backup Codes',
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

<<<<<<< HEAD
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
=======
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
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
            decoration: const InputDecoration(labelText: 'Email or Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Token or API Key (Optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'Use 8+ chars with uppercase, lowercase, and number.',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
                icon: Icon(
                  _isPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
<<<<<<< HEAD
                tooltip: _isPasswordObscured
                    ? 'Show password'
                    : 'Hide password',
=======
                tooltip: _isPasswordObscured ? 'Show password' : 'Hide password',
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                  });
                },
                icon: Icon(
                  _isConfirmPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _isConfirmPasswordObscured
                    ? 'Show password'
                    : 'Hide password',
              ),
            ),
          ),
<<<<<<< HEAD
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'VaultX will generate a one-time recovery key after account creation. Save it offline because the app stores only a salted hash.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _createAccount,
            child: Text(_isSubmitting ? 'Adding...' : 'Add Account'),
          ),
        ],
      ),
    );
  }
}
