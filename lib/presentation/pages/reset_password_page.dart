import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
<<<<<<< HEAD
import '../widgets/recovery_key_dialog.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.username});

  final String? username;
=======
import '../widgets/backup_codes_dialog.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
<<<<<<< HEAD
  late final TextEditingController _usernameController = TextEditingController(
    text: widget.username ?? '',
  );
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
=======
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _backupCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
  bool _isSubmitting = false;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
<<<<<<< HEAD
=======
    _backupCodeController.dispose();
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
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
      final recoveryKey = await AccountScope.of(context)
          .resetPasswordAfterRecovery(
            username: _usernameController.text,
            newPassword: _newPasswordController.text,
          );
=======
      final backupCodes =
          await AccountScope.of(context).resetPasswordWithBackupCode(
        username: _usernameController.text,
        backupCode: _backupCodeController.text,
        newPassword: _newPasswordController.text,
      );
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

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
        const SnackBar(content: Text('Could not reset password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final usernameLocked =
        widget.username != null && widget.username!.isNotEmpty;

=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _usernameController,
<<<<<<< HEAD
            enabled: !usernameLocked,
=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
<<<<<<< HEAD
=======
            controller: _backupCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Backup Code'),
          ),
          const SizedBox(height: 12),
          TextField(
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
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
                'Completing recovery rotates the recovery key immediately. Save the replacement key before leaving this screen.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
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
