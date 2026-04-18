import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/recovery_key_dialog.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.username});

  final String? username;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController _usernameController = TextEditingController(
    text: widget.username ?? '',
  );
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final recoveryKey = await AccountScope.of(context)
          .resetPasswordAfterRecovery(
            username: _usernameController.text,
            newPassword: _newPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 450),
                  tween: Tween(begin: 0.6, end: 1),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    size: 68,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Password reset successful'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      await showRecoveryKeyDialog(
        context,
        recoveryKey: recoveryKey,
        title: 'New Recovery Key',
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
    final usernameLocked =
        widget.username != null && widget.username!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _RecoveryProgress(step: 3),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Master Password',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completing recovery rotates your key immediately. Save the replacement key before you exit.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _usernameController,
                        enabled: !usernameLocked,
                        label: 'Username',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        obscureText: _isNewPasswordObscured,
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        obscureText: _isConfirmPasswordObscured,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordObscured =
                                  !_isConfirmPasswordObscured;
                            });
                          },
                          icon: Icon(
                            _isConfirmPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: _isSubmitting ? 'Resetting...' : 'Reset Password',
                        onPressed: _isSubmitting ? null : _resetPassword,
                        isLoading: _isSubmitting,
                        leading: const Icon(Icons.lock_reset_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryProgress extends StatelessWidget {
  const _RecoveryProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(index: 1, active: step >= 1, label: 'Verify'),
        const Expanded(child: Divider()),
        _StepDot(index: 2, active: step >= 2, label: 'Delay'),
        const Expanded(child: Divider()),
        _StepDot(index: 3, active: step >= 3, label: 'Reset'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.active,
    required this.label,
  });

  final int index;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.white24;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
