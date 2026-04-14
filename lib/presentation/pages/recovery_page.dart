import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../../domain/usecases/recovery_usecases.dart';
import '../state/account_scope.dart';
import 'recovery_delay_page.dart';
import 'reset_password_page.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _recoveryKeyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _recoveryKeyController.dispose();
    super.dispose();
  }

  Future<void> _submitRecovery() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AccountScope.of(context).startRecovery(
        username: _usernameController.text,
        recoveryKey: _recoveryKeyController.text,
      );

      if (!mounted) {
        return;
      }

      if (result.status == RecoveryStatus.immediateReset) {
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
        return;
      }

      final wasReset = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RecoveryDelayPage(
            username: result.username,
            availableAt: result.availableAt,
          ),
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
        const SnackBar(content: Text('Recovery could not be started.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Enter your username and recovery key. Trusted devices can reset immediately. Untrusted devices must wait 24 hours before the reset is unlocked.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recoveryKeyController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Recovery Key'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitRecovery,
            child: Text(_isSubmitting ? 'Checking...' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
