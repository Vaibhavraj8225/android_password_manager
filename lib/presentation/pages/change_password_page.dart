import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
<<<<<<< HEAD
import '../widgets/recovery_key_dialog.dart';
=======
import '../widgets/backup_codes_dialog.dart';
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
<<<<<<< HEAD
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
=======
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
  bool _isSubmitting = false;
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
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
      final recoveryKey = await AccountScope.of(context).updatePassword(
=======
      final backupCodes = await AccountScope.of(context).updatePassword(
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) {
        return;
      }

<<<<<<< HEAD
      await showRecoveryKeyDialog(
        context,
        recoveryKey: recoveryKey,
        title: 'New Recovery Key',
=======
      await showBackupCodesDialog(
        context,
        backupCodes: backupCodes,
        title: 'New Backup Codes',
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
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
        const SnackBar(content: Text('Could not change password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Master Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _currentPasswordController,
            obscureText: _isCurrentPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Current Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordObscured = !_isCurrentPasswordObscured;
                  });
                },
                icon: Icon(
                  _isCurrentPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _isCurrentPasswordObscured
                    ? 'Show password'
                    : 'Hide password',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: _isNewPasswordObscured,
            decoration: InputDecoration(
              labelText: 'New Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isNewPasswordObscured = !_isNewPasswordObscured;
                  });
                },
                icon: Icon(
                  _isNewPasswordObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
<<<<<<< HEAD
                tooltip: _isNewPasswordObscured
                    ? 'Show password'
                    : 'Hide password',
=======
                tooltip: _isNewPasswordObscured ? 'Show password' : 'Hide password',
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
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
                'Changing the master password rotates the recovery key. Save the new key offline after the update completes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _changePassword,
            child: Text(_isSubmitting ? 'Updating...' : 'Change Password'),
          ),
        ],
      ),
    );
  }
}
