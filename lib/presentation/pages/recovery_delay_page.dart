import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
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
  Duration _remaining = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final availableAt = widget.availableAt;
    if (availableAt == null) {
      setState(() {
        _remaining = Duration.zero;
      });
      return;
    }
    final now = DateTime.now();
    final diff = availableAt.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

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
        : 'Password reset becomes available on ${_formatDateTime(availableAt)}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Delay')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _RecoveryProgress(step: 2),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1400),
                          tween: Tween(begin: 0.9, end: 1.08),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.glowBorder),
                            ),
                            child: const Icon(
                              Icons.lock_clock_outlined,
                              size: 34,
                              color: AppColors.accentCyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Security Waiting Period',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New device detected. Security hold active. VaultX enforces a 24-hour delay to protect your account.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Time Remaining',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCountdown(_remaining),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        unlockLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: _isSubmitting
                            ? 'Checking...'
                            : 'Continue Recovery',
                        onPressed: _isSubmitting ? null : _continueRecovery,
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
