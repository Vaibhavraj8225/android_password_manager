import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
<<<<<<< HEAD
import 'recovery_page.dart';
import '../state/account_scope.dart';
=======
import '../state/account_scope.dart';
import 'reset_password_page.dart';
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

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

<<<<<<< HEAD
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to unlock vault.')));
=======
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unlock vault.')),
      );
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
    }
  }

  void _openRegisterPage() {
    Navigator.pushNamed(context, '/register');
  }

<<<<<<< HEAD
  Future<void> _openRecoveryFlow() async {
    final wasReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const RecoveryPage()),
=======
  Future<void> _openResetPassword() async {
    final wasReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ResetPasswordPage(),
      ),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
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
      appBar: AppBar(title: const Text('VaultX')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
<<<<<<< HEAD
                'Sign in to access your encrypted vault. Successful sign-ins automatically trust this device for future recovery.',
=======
                'Sign in to access your vault from the centralized authentication home.',
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (controller.errorMessage != null) ...[
                Card(
<<<<<<< HEAD
                  color: Colors.red.withValues(alpha: 0.18),
=======
                  color: Colors.red.withOpacity(0.18),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(controller.errorMessage!),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'Password',
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: controller.isBusy ? null : _unlockVault,
                child: Text(controller.isBusy ? 'Signing In...' : 'Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
<<<<<<< HEAD
                onPressed: controller.isBusy ? null : _openRecoveryFlow,
                child: const Text('Forgot password? Recover with recovery key'),
=======
                onPressed: controller.isBusy ? null : _openResetPassword,
                child: const Text('Forgot password? Recover with backup code'),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.isBusy ? null : _openRegisterPage,
                child: const Text('Create New Account'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.switch_account_outlined),
                label: const Text('Switch Account (Coming Soon)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
