import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/biometric_second_factor_service.dart';
import '../../core/device_trust_manager.dart';
import '../../core/storage_service.dart';
import '../../data/vault_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/models/vault.dart';
import '../../domain/usecases/account_usecases.dart';
import '../../domain/usecases/recovery_usecases.dart';

class AccountController extends ChangeNotifier {
  AccountController({
    required this.getAccounts,
    required this.getActiveAccount,
    required this.addAccount,
    required this.switchAccount,
    required this.logoutAccount,
    required this.deleteAccount,
    required this.authenticateAccount,
    required this.changeAccountPassword,
    required this.initiateRecovery,
    required this.completeRecovery,
    required this.deviceTrustManager,
    required this.biometricSecondFactorService,
    required this.vaultRepository,
    required this.storageService,
  });

  final GetAccounts getAccounts;
  final GetActiveAccount getActiveAccount;
  final AddAccount addAccount;
  final SwitchAccount switchAccount;
  final LogoutAccount logoutAccount;
  final DeleteAccount deleteAccount;
  final AuthenticateAccount authenticateAccount;
  final ChangeAccountPassword changeAccountPassword;
  final InitiateRecovery initiateRecovery;
  final CompleteRecovery completeRecovery;
  final DeviceTrustManager deviceTrustManager;
  final BiometricSecondFactorService biometricSecondFactorService;
  final VaultRepository vaultRepository;
  final StorageService storageService;

  List<AccountEntity> _accounts = const <AccountEntity>[];
  AccountEntity? _activeAccount;
  Vault _currentVault = Vault.empty();
  List<int>? _encryptionKey;
  bool _isInitialized = false;
  bool _isBusy = false;
  bool _isBiometricSecondFactorAvailable = false;
  bool _isBiometricSecondFactorEnabled = false;
  String? _errorMessage;
  Future<void> _queue = Future<void>.value();

  List<AccountEntity> get accounts => List.unmodifiable(_accounts);
  AccountEntity? get activeAccount => _activeAccount;
  Vault get currentVault => _currentVault;
  List<int>? get encryptionKey =>
      _encryptionKey == null ? null : List<int>.unmodifiable(_encryptionKey!);
  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  bool get isBiometricSecondFactorAvailable =>
      _isBiometricSecondFactorAvailable;
  bool get isBiometricSecondFactorEnabled => _isBiometricSecondFactorEnabled;
  String? get errorMessage => _errorMessage;
  bool get hasAccounts => _accounts.isNotEmpty;
  bool get isAuthenticated => _activeAccount != null && _encryptionKey != null;

  Future<void> initialize() {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        _accounts = await getAccounts();
        _activeAccount =
            await getActiveAccount() ?? _selectActiveAccount(_accounts);
        if (_activeAccount != null) {
          await _loadBiometricSecondFactorState(_activeAccount!.id);
          _encryptionKey = base64Decode(_activeAccount!.vaultKey);
          _currentVault = await vaultRepository.load(
            _activeAccount!.id,
            _encryptionKey!,
          );
        } else {
          _currentVault = Vault.empty();
          _encryptionKey = null;
          _isBiometricSecondFactorAvailable = false;
          _isBiometricSecondFactorEnabled = false;
        }
      } catch (_) {
        _activeAccount = null;
        _encryptionKey = null;
        _currentVault = Vault.empty();
        _isBiometricSecondFactorAvailable = false;
        _isBiometricSecondFactorEnabled = false;
        _setError('Unable to load saved accounts.');
      } finally {
        _isInitialized = true;
        _setBusy(false);
      }
    });
  }

  Future<String> createAccount({
    required String username,
    required String password,
    String? authToken,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        final result = await addAccount(
          username: username,
          password: password,
          authToken: authToken,
        );
        await vaultRepository.save(
          result.account.id,
          result.vaultKey,
          Vault.empty(),
        );
        await deviceTrustManager.markTrusted(result.account.id);
        await _refreshFromAccount(
          result.account,
          vaultOverride: Vault.empty(),
          encryptionKey: result.vaultKey,
        );
        return result.recoveryKey;
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<void> unlockActiveAccount({
    required String username,
    required String password,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        final authenticated = await authenticateAccount(
          username: username,
          password: password,
        );

        final requiresSecondFactor = await biometricSecondFactorService
            .isEnabledForAccount(authenticated.account.id);
        if (requiresSecondFactor) {
          final passed = await biometricSecondFactorService.verifyForLogin(
            reason: 'Verify your identity to complete sign in.',
          );
          if (!passed) {
            throw const AccountException(
              'Biometric verification was not completed.',
            );
          }
        }

        final vault = await vaultRepository.load(
          authenticated.account.id,
          authenticated.vaultKey,
        );
        await deviceTrustManager.markTrusted(authenticated.account.id);
        await _refreshFromAccount(
          authenticated.account,
          vaultOverride: vault,
          encryptionKey: authenticated.vaultKey,
        );
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<void> switchToAccount(String accountId) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        final account = await switchAccount(accountId);
        final key = base64Decode(account.vaultKey);
        final vault = await vaultRepository.load(account.id, key);
        await _refreshFromAccount(
          account,
          vaultOverride: vault,
          encryptionKey: key,
        );
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<void> logout() {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        await logoutAccount();
        _activeAccount = null;
        _encryptionKey = null;
        _currentVault = Vault.empty();
        _isBiometricSecondFactorAvailable = false;
        _isBiometricSecondFactorEnabled = false;
        _accounts = await getAccounts();
        notifyListeners();
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<void> deleteSavedAccount({
    required String accountId,
    required String password,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        final result = await deleteAccount(
          accountId: accountId,
          password: password,
        );
        await deviceTrustManager.clearTrust(accountId);
        await biometricSecondFactorService.clearForAccount(accountId);
        await storageService.deleteVault(accountId);
        _accounts = await getAccounts();

        if (result.deletedActiveAccount) {
          if (result.nextActiveAccount == null) {
            _activeAccount = null;
            _encryptionKey = null;
            _currentVault = Vault.empty();
            _isBiometricSecondFactorAvailable = false;
            _isBiometricSecondFactorEnabled = false;
          } else {
            final key = base64Decode(result.nextActiveAccount!.vaultKey);
            final vault = await vaultRepository.load(
              result.nextActiveAccount!.id,
              key,
            );
            _activeAccount = result.nextActiveAccount;
            _encryptionKey = key;
            _currentVault = vault;
            await _loadBiometricSecondFactorState(_activeAccount!.id);
          }
        } else if (_activeAccount != null) {
          _activeAccount =
              _findAccountById(_activeAccount!.id) ?? _activeAccount;
          if (_activeAccount != null) {
            await _loadBiometricSecondFactorState(_activeAccount!.id);
          }
        }

        notifyListeners();
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _runSerialized(() async {
      final active = _activeAccount;
      if (active == null) {
        throw const AccountException('No active account found.');
      }

      _setBusy(true);
      _clearError();
      try {
        final recoveryKey = await changeAccountPassword(
          accountId: active.id,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        _accounts = await getAccounts();
        _activeAccount = _findAccountById(active.id) ?? active;
        notifyListeners();
        return recoveryKey;
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<RecoveryInitiationResult> startRecovery({
    required String username,
    required String recoveryKey,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        return await initiateRecovery(
          username: username,
          recoveryKey: recoveryKey,
        );
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<CompletedRecoveryResult> authorizeDelayedRecovery({
    required String username,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        return await completeRecovery(username: username);
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<String> resetPasswordAfterRecovery({
    required String username,
    required String newPassword,
  }) {
    return _runSerialized(() async {
      _setBusy(true);
      _clearError();
      try {
        final recoveryKey = await changeAccountPassword.resetWithRecovery(
          username: username,
          newPassword: newPassword,
        );
        _accounts = await getAccounts();
        final normalizedUsername = username.trim().toLowerCase();
        if (_activeAccount?.username.trim().toLowerCase() ==
            normalizedUsername) {
          _activeAccount =
              _findAccountById(_activeAccount!.id) ?? _activeAccount;
        }
        notifyListeners();
        return recoveryKey;
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<void> saveVault(Vault vault) {
    return _runSerialized(() async {
      final active = _activeAccount;
      final key = _encryptionKey;
      if (active == null || key == null) {
        throw const AccountException('No active account found.');
      }

      await vaultRepository.save(active.id, key, vault);
      _currentVault = vault;
      notifyListeners();
    });
  }

  Future<void> setBiometricSecondFactorEnabled(bool enabled) {
    return _runSerialized(() async {
      final active = _activeAccount;
      if (active == null) {
        throw const AccountException('No active account found.');
      }

      _setBusy(true);
      _clearError();
      try {
        if (enabled) {
          final available = await biometricSecondFactorService
              .isBiometricAvailable();
          _isBiometricSecondFactorAvailable = available;
          if (!available) {
            _isBiometricSecondFactorEnabled = false;
            throw const AccountException(
              'Biometric authentication is not available on this device.',
            );
          }

          final passed = await biometricSecondFactorService.verifyForLogin(
            reason: 'Verify biometrics to enable secure sign in.',
          );
          if (!passed) {
            throw const AccountException(
              'Biometric verification was canceled.',
            );
          }
        } else {
          _isBiometricSecondFactorAvailable = await biometricSecondFactorService
              .isBiometricAvailable();
        }

        await biometricSecondFactorService.setEnabledForAccount(
          active.id,
          enabled,
        );
        _isBiometricSecondFactorEnabled = enabled;
        notifyListeners();
      } finally {
        _setBusy(false);
      }
    });
  }

  Future<T> _runSerialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } on AccountException catch (error, stackTrace) {
        _setError(error.message);
        completer.completeError(error, stackTrace);
      } catch (error, stackTrace) {
        _setError('Something went wrong. Please try again.');
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _refreshFromAccount(
    AccountEntity account, {
    required List<int> encryptionKey,
    required Vault vaultOverride,
  }) async {
    _accounts = await getAccounts();
    _activeAccount = _findAccountById(account.id) ?? account;
    await _loadBiometricSecondFactorState(_activeAccount!.id);
    _encryptionKey = List<int>.from(encryptionKey);
    _currentVault = vaultOverride;
    notifyListeners();
  }

  Future<void> _loadBiometricSecondFactorState(String accountId) async {
    _isBiometricSecondFactorAvailable = await biometricSecondFactorService
        .isBiometricAvailable();
    _isBiometricSecondFactorEnabled = _isBiometricSecondFactorAvailable
        ? await biometricSecondFactorService.isEnabledForAccount(accountId)
        : false;
  }

  AccountEntity? _findAccountById(String id) {
    for (final account in _accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  AccountEntity? _selectActiveAccount(List<AccountEntity> accounts) {
    if (accounts.isEmpty) {
      return null;
    }

    accounts.sort((left, right) {
      final leftDate = left.lastUsedAt ?? left.createdAt ?? DateTime(1970);
      final rightDate = right.lastUsedAt ?? right.createdAt ?? DateTime(1970);
      return rightDate.compareTo(leftDate);
    });
    return accounts.first;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }
}

