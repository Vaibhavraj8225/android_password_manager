import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/vault.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

class AddPasswordPage extends StatefulWidget {
  const AddPasswordPage({super.key});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final TextEditingController _appController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _appController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword({int length = 16}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()-_=+[]{}';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _save() async {
    final app = _appController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (app.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill in all required fields.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final controller = AccountScope.of(context);
    final updatedEntries =
        List<Map<String, dynamic>>.from(controller.currentVault.entries)..add({
          'app': app,
          'email': email,
          'username': username,
          'password': password,
        });

    final updatedVault = Vault(
      entries: updatedEntries,
      notes: List<Map<String, dynamic>>.from(controller.currentVault.notes),
    );

    try {
      await controller.saveVault(updatedVault);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save password.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credential')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save New Password',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Store credentials securely and keep everything synced inside your encrypted vault.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _appController,
                        label: 'App / Website',
                        hint: 'GitHub, Notion, Stripe',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _usernameController,
                        label: 'Username',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Generate Password',
                        onPressed: () {
                          _passwordController.text = _generatePassword();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Strong password generated.'),
                            ),
                          );
                        },
                        style: AppButtonStyle.ghost,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: _isSaving ? 'Saving...' : 'Save',
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                        leading: const Icon(Icons.lock_outline_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Tip: Prefer unique passwords with 12+ characters for stronger protection.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
