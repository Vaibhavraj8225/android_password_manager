import 'package:flutter/material.dart';

import '../../core/crypto_service.dart';
import '../../core/key_derivation.dart';
import '../../core/master_account_service.dart';
import '../../core/storage_service.dart';
import '../../data/vault_repository.dart';
import 'create_account_page.dart';
import 'home_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final StorageService _storageService;
  late final VaultRepository _vaultRepository;
  late final MasterAccountService _accountService;
  bool _isLoading = true;
  bool _isUnlocking = false;
  bool _hasAccount = false;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _vaultRepository = VaultRepository(
      CryptoService(),
      _storageService,
    );
    _accountService = MasterAccountService(
      _storageService,
      KeyDerivation(),
    );
    _loadAccountState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountState() async {
    final account = await _accountService.loadAccount();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasAccount = account != null;
      _isLoading = false;
      if (account != null) {
        _usernameController.text = account.username;
      } else {
        _usernameController.clear();
      }
    });
  }

  Future<void> _unlockVault() async {
    setState(() {
      _isUnlocking = true;
    });

    try {
      final session = await _accountService.authenticate(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      final vault = await _vaultRepository.load(
        session.account.username,
        session.vaultKey,
      );

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            initialVault: vault,
            repository: _vaultRepository,
            encryptionKey: session.vaultKey,
            username: session.account.username,
            accountService: _accountService,
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unlock vault.')),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUnlocking = false;
      });
    }
  }

  Future<void> _openCreateAccount() async {
    final session = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAccountPage(
          accountService: _accountService,
          vaultRepository: _vaultRepository,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadAccountState();

    if (session is! AccountSession) {
      return;
    }

    final vault = await _vaultRepository.load(
      session.account.username,
      session.vaultKey,
    );

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          initialVault: vault,
          repository: _vaultRepository,
          encryptionKey: session.vaultKey,
          username: session.account.username,
          accountService: _accountService,
        ),
      ),
    );
  }

  Future<void> _openResetPassword() async {
    final wasReset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(
          accountService: _accountService,
        ),
      ),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('VaultX')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_hasAccount) ...[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Master Password'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isUnlocking ? null : _unlockVault,
              child: Text(_isUnlocking ? 'Unlocking...' : 'Unlock Vault'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openResetPassword,
              child: const Text('Forgot password? Use a backup code'),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Create your master account to secure the vault and receive one-time backup codes for recovery.',
              ),
            ),
            FilledButton(
              onPressed: _openCreateAccount,
              child: const Text('Create Master Account'),
            ),
          ],
        ],
      ),
    );
  }
}
