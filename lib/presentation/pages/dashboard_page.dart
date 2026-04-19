import 'package:flutter/material.dart';

import '../../domain/models/vault.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_stat_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/password_tile.dart';
import '../widgets/status_badge.dart';
import '../widgets/vault_background.dart';
import '../widgets/app_text_field.dart';
import 'add_password_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? _deletingIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddPasswordPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddPasswordPage()),
    );
  }

  Future<void> _openEditPasswordPage(int index, Map<String, dynamic> entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordPage(
          initialEntry: entry,
          entryIndex: index,
        ),
      ),
    );
  }

  Future<void> _deleteCredential(int index) async {
    final controller = AccountScope.of(context);
    final entry = controller.currentVault.entries[index];
    final appName = entry['app']?.toString().trim();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Credential'),
          content: Text(
            'Delete ${appName == null || appName.isEmpty ? 'this credential' : 'the credential for $appName'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingIndex = index;
    });

    final updatedEntries = List<Map<String, dynamic>>.from(
      controller.currentVault.entries,
    )..removeAt(index);

    try {
      await controller.saveVault(
        Vault(
          entries: updatedEntries,
          notes: List<Map<String, dynamic>>.from(controller.currentVault.notes),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credential deleted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete credential.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);

    if (!controller.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('VaultX')),
        body: EmptyStateWidget(
          title: 'Session Locked',
          subtitle: 'Sign in from the home page to access your vault.',
          icon: Icons.lock_outline_rounded,
          actionLabel: 'Back to Home',
          onAction: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
      );
    }

    final vault = controller.currentVault;
    final username = controller.activeAccount?.username ?? 'User';
    final query = _searchController.text.trim().toLowerCase();
    final filteredEntries = query.isEmpty
        ? vault.entries
        : vault.entries.where((entry) {
            final app = entry['app']?.toString().toLowerCase() ?? '';
            final user = entry['username']?.toString().toLowerCase() ?? '';
            final email = entry['email']?.toString().toLowerCase() ?? '';
            return app.contains(query) || user.contains(query) || email.contains(query);
          }).toList();

    final secureScore = vault.entries.isEmpty
        ? 100
        : ((vault.entries.where((entry) {
              final password = entry['password']?.toString() ?? '';
              return password.length >= 12;
            }).length /
                    vault.entries.length) *
                100)
            .round();

    return Scaffold(
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCyan.withValues(alpha: 0.45),
              blurRadius: 24,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: controller.isBusy ? null : _openAddPasswordPage,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: VaultBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $username',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your vault is encrypted and protected.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SecurityBadge(
                                label: 'Security Score High',
                                icon: Icons.shield_outlined,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/security-center');
                                },
                                icon: const Icon(Icons.tune_rounded),
                                tooltip: 'Security Center',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          VaultTextField(
                            controller: _searchController,
                            label: 'Search credentials',
                            hint: 'app, email, username',
                            suffixIcon: const Icon(Icons.search_rounded),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              AnimatedStatCard(
                                title: 'Total Passwords',
                                value: '${vault.entries.length}',
                                icon: Icons.lock_outline_rounded,
                                delayMs: 40,
                              ),
                              const AnimatedStatCard(
                                title: 'Trusted Devices',
                                value: '1',
                                icon: Icons.verified_user_outlined,
                                accent: AppColors.accentCyan,
                                delayMs: 80,
                              ),
                              const AnimatedStatCard(
                                title: 'Recovery Status',
                                value: 'Ready',
                                icon: Icons.key_outlined,
                                accent: AppColors.accentGreen,
                                delayMs: 120,
                              ),
                              AnimatedStatCard(
                                title: 'Vault Strength',
                                value: '$secureScore%',
                                icon: Icons.bolt_outlined,
                                accent: AppColors.primary,
                                delayMs: 160,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (controller.isBusy)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: 3,
                        itemBuilder: (_, i) {
                          return Container(
                            height: 84,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        },
                      ),
                    )
                  else if (filteredEntries.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        title: 'No credentials yet',
                        subtitle:
                            'Add your first app login to start building your secure vault.',
                        icon: Icons.lock_person_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList.builder(
                        itemCount: filteredEntries.length,
                        itemBuilder: (_, i) {
                          final entry = filteredEntries[i];
                          final originalIndex = vault.entries.indexOf(entry);
                          return PasswordTilePremium(
                            entry: entry,
                            onEdit: () => _openEditPasswordPage(originalIndex, entry),
                            onDelete: () => _deleteCredential(originalIndex),
                            isDeleting: _deletingIndex == originalIndex,
                          );
                        },
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
