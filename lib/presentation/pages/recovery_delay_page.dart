import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import 'reset_password_page.dart';

class RecoveryDelayPage extends StatefulWidget {
  const RecoveryDelayPage({super.key, this.username, this.availableAt});

  final String? username;
  final DateTime? availableAt;

  @override
  State<RecoveryDelayPage> createState() => _RecoveryDelayPageState();
}

class _RecoveryDelayPageState extends State<RecoveryDelayPage> {
  bool _isSubmitting = false;

  Future<void> _continueRecovery() async {
    final username = widget.username;
    if (username == null || username.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AccountScope.of(
        context,
      ).authorizeDelayedRecovery(username: username);

      if (!mounted) {
        return;
      }

      final wasReset = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(username: result.username),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, wasReset);
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
        const SnackBar(content: Text('Recovery delay is still active.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableAt = widget.availableAt;
    final unlockLabel = availableAt == null
        ? 'After the waiting period finishes, return here to continue with the password reset.'
        : 'This device is not trusted yet. Password reset becomes available after ${availableAt.toLocal()}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Delay')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(unlockLabel),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep access to this device. When the delay expires, continue here to complete recovery and set a new master password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _continueRecovery,
            child: Text(_isSubmitting ? 'Checking...' : 'Continue Recovery'),
          ),
        ],
      ),
    );
  }
}
