import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SessionLockScreen extends StatefulWidget {
  const SessionLockScreen({required this.onUnlock, super.key});

  final Future<bool> Function(String password) onUnlock;

  @override
  State<SessionLockScreen> createState() => _SessionLockScreenState();
}

class _SessionLockScreenState extends State<SessionLockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isBusy = false;
  bool _isPasswordObscured = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isBusy) {
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your master password.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final unlocked = await widget.onUnlock(password);
    if (!mounted) {
      return;
    }

    if (unlocked) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isBusy = false;
      _errorMessage = 'Incorrect password. Try again.';
    });

    _passwordController.clear();
    _passwordFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 54,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VEYLOX',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Session locked while app was in background',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _isPasswordObscured,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        hintText: 'Enter password to unlock',
                        errorText: _errorMessage,
                        suffixIcon: IconButton(
                          onPressed: _isBusy
                              ? null
                              : () {
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
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isBusy ? null : _submit,
                        child: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Unlock'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

