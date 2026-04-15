import 'dart:convert';

import '../../core/key_derivation.dart';
import '../../core/recovery_key_generator.dart';
import '../../core/secure_random_generator.dart';
import '../../domain/entities/account_entity.dart';
import '../repositories/account_repository.dart';

class GetAccounts {
  const GetAccounts(this._repository);

  final AccountRepository _repository;

  Future<List<AccountEntity>> call() => _repository.getAccounts();
}

class GetActiveAccount {
  const GetActiveAccount(this._repository);

  final AccountRepository _repository;

  Future<AccountEntity?> call() => _repository.getActiveAccount();
}

class AddAccount {
  AddAccount(
    this._repository,
    this._keyDerivation,
    this._recoveryKeyGenerator,
    this._randomGenerator,
  );

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;
  final RecoveryKeyGenerator _recoveryKeyGenerator;
  final SecureRandomGenerator _randomGenerator;

  Future<AccountCreationResult> call({
    required String username,
    required String password,
    String? authToken,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw const AccountException('Email or username is required.');
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      throw AccountException(passwordError);
    }

    final existing = await _repository.getAccountByUsername(normalizedUsername);
    if (existing != null) {
      throw const AccountException(
        'That account is already saved on this device.',
      );
    }

    final passwordSalt = _randomGenerator.bytes(16);
    final passwordHash = await _keyDerivation.deriveKey(password, passwordSalt);
    final recoveryKey = await _recoveryKeyGenerator.generate();
    final vaultKey = _randomGenerator.bytes(32);
    final now = DateTime.now();

    final account = AccountEntity(
      id: _generateAccountId(),
      username: normalizedUsername,
      passwordSalt: base64Encode(passwordSalt),
      passwordHash: base64Encode(passwordHash),
      vaultKey: base64Encode(vaultKey),
      recoveryKeySalt: recoveryKey.salt,
      recoveryKeyHash: recoveryKey.hash,
      authToken: authToken?.trim().isEmpty ?? true ? null : authToken?.trim(),
      createdAt: now,
      lastUsedAt: now,
    );

    await _repository.saveAccount(account);
    await _repository.setActiveAccount(account.id);

    return AccountCreationResult(
      account: account,
      vaultKey: vaultKey,
      recoveryKey: recoveryKey.plainText,
    );
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must include a number.';
    }
    return null;
  }

  String _generateAccountId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = base64UrlEncode(
      _randomGenerator.bytes(9),
    ).replaceAll('=', '');
    return 'acct_$timestamp$suffix';
  }
}

class SwitchAccount {
  const SwitchAccount(this._repository);

  final AccountRepository _repository;

  Future<AccountEntity> call(String accountId) async {
    final account = await _repository.getAccountById(accountId);
    if (account == null) {
      throw const AccountException(
        'The selected account is no longer available.',
      );
    }

    final updated = account.copyWith(lastUsedAt: DateTime.now());
    await _repository.saveAccount(updated);
    await _repository.setActiveAccount(updated.id);
    return updated;
  }
}

class DeleteAccount {
  DeleteAccount(this._repository, this._keyDerivation);

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;

  Future<DeleteAccountResult> call({
    required String accountId,
    required String password,
  }) async {
    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      throw const AccountException(
        'Enter the master password to delete this account.',
      );
    }

    final account = await _repository.getAccountById(accountId);
    if (account == null) {
      throw const AccountException(
        'The selected account is no longer available.',
      );
    }

    final derivedHash = await _keyDerivation.deriveKey(
      password,
      base64Decode(account.passwordSalt),
    );

    if (!_constantTimeEquals(base64Encode(derivedHash), account.passwordHash)) {
      throw const AccountException('Incorrect master password.');
    }

    final active = await _repository.getActiveAccount();
    final accounts = await _repository.getAccounts();
    final remaining = accounts
        .where((account) => account.id != accountId)
        .toList();

    await _repository.deleteAccount(accountId);

    if (active?.id == accountId) {
      final nextActive = remaining.isEmpty ? null : remaining.first;
      await _repository.setActiveAccount(nextActive?.id);
      return DeleteAccountResult(
        deletedActiveAccount: true,
        nextActiveAccount: nextActive,
      );
    }

    return const DeleteAccountResult(
      deletedActiveAccount: false,
      nextActiveAccount: null,
    );
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return result == 0;
  }
}

class AuthenticateAccount {
  AuthenticateAccount(this._repository, this._keyDerivation);

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;

  Future<AuthenticatedAccountResult> call({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final account = await _repository.getAccountByUsername(normalizedUsername);
    if (account == null) {
      throw const AccountException('Invalid username or password.');
    }

    final derivedHash = await _keyDerivation.deriveKey(
      password,
      base64Decode(account.passwordSalt),
    );

    if (!_constantTimeEquals(base64Encode(derivedHash), account.passwordHash)) {
      throw const AccountException('Invalid username or password.');
    }

    final updated = account.copyWith(lastUsedAt: DateTime.now());
    await _repository.saveAccount(updated);
    await _repository.setActiveAccount(updated.id);

    return AuthenticatedAccountResult(
      account: updated,
      vaultKey: base64Decode(updated.vaultKey),
    );
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return result == 0;
  }
}

class LogoutAccount {
  const LogoutAccount(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.setActiveAccount(null);
}

class ChangeAccountPassword {
  ChangeAccountPassword(
    this._repository,
    this._keyDerivation,
    this._addAccount,
    this._recoveryKeyGenerator,
    this._randomGenerator,
  );

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;
  final AddAccount _addAccount;
  final RecoveryKeyGenerator _recoveryKeyGenerator;
  final SecureRandomGenerator _randomGenerator;

  Future<String> call({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = await _repository.getAccountById(accountId);
    if (account == null) {
      throw const AccountException('No active account found.');
    }

    final currentHash = await _keyDerivation.deriveKey(
      currentPassword,
      base64Decode(account.passwordSalt),
    );

    if (!_constantTimeEquals(base64Encode(currentHash), account.passwordHash)) {
      throw const AccountException('Current password is incorrect.');
    }

    if (currentPassword == newPassword) {
      throw const AccountException('Choose a different new password.');
    }

    return _rotateCredentials(
      account: account,
      newPassword: newPassword,
      clearRecoveryState: true,
    );
  }

  Future<String> resetWithRecovery({
    required String username,
    required String newPassword,
  }) async {
    final account = await _repository.getAccountByUsername(username.trim());
    if (account == null) {
      throw const AccountException('Recovery could not be completed.');
    }

    final recoveryRequest = await _repository.getRecoveryRequest(account.id);
    final now = DateTime.now();
    if (recoveryRequest == null || !recoveryRequest.isAuthorized(now)) {
      throw const AccountException('Recovery could not be completed.');
    }

    return _rotateCredentials(
      account: account,
      newPassword: newPassword,
      clearRecoveryState: true,
    );
  }

  Future<String> _rotateCredentials({
    required AccountEntity account,
    required String newPassword,
    required bool clearRecoveryState,
  }) async {
    final passwordError = _addAccount.validatePassword(newPassword);
    if (passwordError != null) {
      throw AccountException(passwordError);
    }

    final newPasswordSalt = _randomGenerator.bytes(16);
    final newPasswordHash = await _keyDerivation.deriveKey(
      newPassword,
      newPasswordSalt,
    );
    final recoveryKey = await _recoveryKeyGenerator.generate();

    await _repository.saveAccount(
      account.copyWith(
        passwordSalt: base64Encode(newPasswordSalt),
        passwordHash: base64Encode(newPasswordHash),
        recoveryKeySalt: recoveryKey.salt,
        recoveryKeyHash: recoveryKey.hash,
        lastUsedAt: DateTime.now(),
      ),
    );

    if (clearRecoveryState) {
      await _repository.storeRecoveryRequest(account.id, null);
    }

    return recoveryKey.plainText;
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return result == 0;
  }
}

class AccountCreationResult {
  const AccountCreationResult({
    required this.account,
    required this.vaultKey,
    required this.recoveryKey,
  });

  final AccountEntity account;
  final List<int> vaultKey;
  final String recoveryKey;
}

class AuthenticatedAccountResult {
  const AuthenticatedAccountResult({
    required this.account,
    required this.vaultKey,
  });

  final AccountEntity account;
  final List<int> vaultKey;
}

class DeleteAccountResult {
  const DeleteAccountResult({
    required this.deletedActiveAccount,
    required this.nextActiveAccount,
  });

  final bool deletedActiveAccount;
  final AccountEntity? nextActiveAccount;
}

class AccountException implements Exception {
  const AccountException(this.message);

  final String message;
}


