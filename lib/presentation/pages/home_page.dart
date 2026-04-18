import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/status_badge.dart';
import '../widgets/vault_background.dart';
import 'recovery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlockVault() async {
    final controller = AccountScope.of(context);
    try {
      await controller.unlockActiveAccount(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on AccountException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to unlock vault.')));
    }
  }

  void _openRegisterPage() {
    Navigator.pushNamed(context, '/register');
  }

  Future<void> _openRecoveryFlow() async {
    final wasReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const RecoveryPage()),
    );

    if (!mounted || wasReset != true) {
      return;
    }

    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset complete. Sign in again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);

    return Scaffold(
      body: VaultBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                children: [
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Hero(
                          tag: 'vault-logo',
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accentCyan],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 32,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('VaultX', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Next-Gen Password Security',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unlock Vault',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SecurityBadge(
                              label: 'Encrypted',
                              icon: Icons.verified_user_outlined,
                              color: AppColors.accentGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Securely access your vault with your master credentials.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        if (controller.errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.danger.withValues(alpha: 0.12),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.34),
                              ),
                            ),
                            child: Text(
                              controller.errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        VaultTextField(
                          controller: _usernameController,
                          label: 'Email or Username',
                          hint: 'you@company.com',
                        ),
                        const SizedBox(height: 12),
                        VaultTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _isPasswordObscured,
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
                            tooltip: _isPasswordObscured
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                        const SizedBox(height: 18),
                        GlowButton(
                          label: controller.isBusy ? 'Signing In...' : 'Unlock Vault',
                          onPressed: controller.isBusy ? null : _unlockVault,
                          isLoading: controller.isBusy,
                          leading: const Icon(Icons.lock_open_rounded),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: controller.isBusy ? null : _openRecoveryFlow,
                          child: const Text('Forgot Password?'),
                        ),
                        const SizedBox(height: 4),
                        GlowButton(
                          label: 'Create Account',
                          onPressed: controller.isBusy ? null : _openRegisterPage,
                          style: AppButtonStyle.ghost,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
