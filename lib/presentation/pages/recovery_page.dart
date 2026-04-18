import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../../domain/usecases/recovery_usecases.dart';
import '../state/account_scope.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _RecoveryProgress(step: 1),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Recovery Factors',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your username and recovery key. Trusted devices continue instantly. Untrusted devices wait 24 hours.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _usernameController,
                        label: 'Username',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _recoveryKeyController,
                        label: 'Recovery Key',
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: _isSubmitting ? 'Checking...' : 'Continue',
                        onPressed: _isSubmitting ? null : _submitRecovery,
                        isLoading: _isSubmitting,
                        leading: const Icon(Icons.arrow_forward_rounded),
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
