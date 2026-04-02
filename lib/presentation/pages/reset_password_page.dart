import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import '../widgets/backup_codes_dialog.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _backupCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _backupCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final backupCodes =
          await AccountScope.of(context).resetPasswordWithBackupCode(
        username: _usernameController.text,
        backupCode: _backupCodeController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      await showBackupCodesDialog(
        context,
        backupCodes: backupCodes,
        title: 'New Backup Codes',
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on AccountException catch (error) {
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
        const SnackBar(content: Text('Could not reset password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _backupCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Backup Code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _resetPassword,
            child: Text(_isSubmitting ? 'Resetting...' : 'Reset Password'),
          ),
        ],
      ),
    );
  }
}
