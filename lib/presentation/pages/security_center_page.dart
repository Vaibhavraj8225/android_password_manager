import 'package:flutter/material.dart';

import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import 'change_password_page.dart';

class SecurityCenterPage extends StatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  State<SecurityCenterPage> createState() => _SecurityCenterPageState();
}

class _SecurityCenterPageState extends State<SecurityCenterPage> {
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();
  bool _isDeleteAccountPasswordObscured = true;

  @override
  void dispose() {
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openChangePasswordPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  Future<void> _setBiometricSecondFactor(bool enabled) async {
    final controller = AccountScope.of(context);
    try {
      await controller.setBiometricSecondFactorEnabled(enabled);
      if (!mounted) {
        return;
      }

      final message = enabled
          ? 'Biometric second-factor is enabled.'
          : 'Biometric second-factor is disabled.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on Exception {
      if (!mounted) {
        return;
      }

      final message =
          controller.errorMessage ?? 'Could not update biometric second-factor.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _logout() async {
    final controller = AccountScope.of(context);
    try {
      await controller.logout();
      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out right now.')),
      );
    }
  }

  Future<void> _deleteMasterAccount() async {
    final controller = AccountScope.of(context);
    final activeAccount = controller.activeAccount;
    if (activeAccount == null) {
      return;
    }

    _deleteAccountPasswordController.clear();
    _isDeleteAccountPasswordObscured = true;

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Vault'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently deletes ${activeAccount.username} and every credential inside your vault.',
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _deleteAccountPasswordController,
                      label: 'Master Password',
                      obscureText: _isDeleteAccountPasswordObscured,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _isDeleteAccountPasswordObscured =
                                !_isDeleteAccountPasswordObscured;
                          });
                        },
                        icon: Icon(
                          _isDeleteAccountPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(
                    context,
                    _deleteAccountPasswordController.text,
                  ),
                  child: const Text('Delete Vault'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || password == null) {
      return;
    }

    try {
      final messenger = ScaffoldMessenger.of(context);
      await controller.deleteSavedAccount(
        accountId: activeAccount.id,
        password: password,
      );
      await controller.logout();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      messenger.showSnackBar(const SnackBar(content: Text('Vault deleted.')));
    } on Exception {
      if (!mounted) {
        return;
      }

      final message = controller.errorMessage ?? 'Could not delete vault.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);
    final username = controller.activeAccount?.username ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Security Center')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.primary.withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.admin_panel_settings_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(username,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Tile(
                  icon: Icons.password_rounded,
                  title: 'Change Password',
                  subtitle: 'Rotate your master password and recovery key.',
                  onTap: _openChangePasswordPage,
                ),
                const SizedBox(height: 12),
                _Tile(
                  icon: Icons.key_outlined,
                  title: 'Recovery Key',
                  subtitle: 'Use recovery flow on login if needed.',
                  onTap: () => Navigator.pushNamed(context, '/recover'),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Biometric Login 2FA',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              controller.isBiometricSecondFactorAvailable
                                  ? 'Require biometrics after password sign in'
                                  : 'Biometrics unavailable on this device',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.isBiometricSecondFactorEnabled,
                        onChanged: controller.isBusy ||
                                (!controller.isBiometricSecondFactorAvailable &&
                                    !controller.isBiometricSecondFactorEnabled)
                            ? null
                            : _setBiometricSecondFactor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _Tile(
                  icon: Icons.devices_outlined,
                  title: 'Trusted Device',
                  subtitle: 'This device is currently marked as trusted.',
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Logout',
                  onPressed: controller.isBusy ? null : _logout,
                  style: AppButtonStyle.ghost,
                  leading: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Delete Vault',
                  onPressed: controller.isBusy ? null : _deleteMasterAccount,
                  style: AppButtonStyle.danger,
                  leading: const Icon(Icons.delete_forever_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
