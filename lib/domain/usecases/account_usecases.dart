import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../core/key_derivation.dart';
import '../entities/account_entity.dart';
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
  );

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;
  final Random _random = Random.secure();
  final Sha256 _sha256 = Sha256();

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
      throw const AccountException('That account is already saved on this device.');
    }

    final passwordSalt = _randomBytes(16);
    final passwordHash = await _keyDerivation.deriveKey(password, passwordSalt);
    final backupBundle = await _generateBackupCodes();
    final vaultKey = _randomBytes(32);
    final now = DateTime.now();

    final account = AccountEntity(
      id: _generateAccountId(),
      username: normalizedUsername,
      passwordSalt: base64Encode(passwordSalt),
      passwordHash: base64Encode(passwordHash),
      vaultKey: base64Encode(vaultKey),
      authToken: authToken?.trim().isEmpty ?? true ? null : authToken?.trim(),
      backupCodes: backupBundle.records,
      createdAt: now,
      lastUsedAt: now,
    );

    await _repository.saveAccount(account);
    await _repository.setActiveAccount(account.id);

    return AccountCreationResult(
      account: account,
      vaultKey: vaultKey,
      backupCodes: backupBundle.plainCodes,
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

  Future<_BackupCodeBundle> _generateBackupCodes() async {
    const backupCodeCount = 6;
    const backupCodeLength = 10;
    const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final plainCodes = <String>{};
    while (plainCodes.length < backupCodeCount) {
      final buffer = StringBuffer();
      for (var i = 0; i < backupCodeLength; i++) {
        buffer.write(charset[_random.nextInt(charset.length)]);
      }
      plainCodes.add(buffer.toString());
    }

    final records = <BackupCodeEntity>[];
    for (final code in plainCodes) {
      final salt = _randomBytes(16);
      final hash = await _hashValue(code, salt);
      records.add(
        BackupCodeEntity(
          salt: base64Encode(salt),
          hash: base64Encode(hash),
          isUsed: false,
        ),
      );
    }

    return _BackupCodeBundle(
      plainCodes: plainCodes.toList(),
      records: records,
    );
  }

  Future<List<int>> _hashValue(String value, List<int> salt) async {
    final digest = await _sha256.hash(salt + utf8.encode(value));
    return digest.bytes;
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  String _generateAccountId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32).toRadixString(16);
    return 'acct_$timestamp$suffix';
  }
}

class SwitchAccount {
  const SwitchAccount(this._repository);

  final AccountRepository _repository;

  Future<AccountEntity> call(String accountId) async {
    final account = await _repository.getAccountById(accountId);
    if (account == null) {
      throw const AccountException('The selected account is no longer available.');
    }

    final updated = account.copyWith(lastUsedAt: DateTime.now());
    await _repository.saveAccount(updated);
    await _repository.setActiveAccount(updated.id);
    return updated;
  }
}

class DeleteAccount {
  DeleteAccount(
    this._repository,
    this._keyDerivation,
  );

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;

  Future<DeleteAccountResult> call({
    required String accountId,
    required String password,
  }) async {
    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      throw const AccountException('Enter the master password to delete this account.');
    }

    final account = await _repository.getAccountById(accountId);
    if (account == null) {
      throw const AccountException('The selected account is no longer available.');
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
    final remaining = accounts.where((account) => account.id != accountId).toList();

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
    for (var i = 0; i < left.length; i++) {
      result |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return result == 0;
  }
}

class AuthenticateAccount {
  AuthenticateAccount(
    this._repository,
    this._keyDerivation,
  );

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
    for (var i = 0; i < left.length; i++) {
      result |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
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
  );

  final AccountRepository _repository;
  final KeyDerivation _keyDerivation;
  final AddAccount _addAccount;
  final Sha256 _sha256 = Sha256();
  final Random _random = Random.secure();

  Future<List<String>> call({
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

    final passwordError = _addAccount.validatePassword(newPassword);
    if (passwordError != null) {
      throw AccountException(passwordError);
    }

    final newPasswordSalt = _randomBytes(16);
    final newPasswordHash = await _keyDerivation.deriveKey(
      newPassword,
      newPasswordSalt,
    );
    final backupBundle = await _generateBackupCodes();

    await _repository.saveAccount(
      account.copyWith(
        passwordSalt: base64Encode(newPasswordSalt),
        passwordHash: base64Encode(newPasswordHash),
        backupCodes: backupBundle.records,
        lastUsedAt: DateTime.now(),
      ),
    );

    return backupBundle.plainCodes;
  }

  Future<List<String>> resetWithBackupCode({
    required String username,
    required String backupCode,
    required String newPassword,
  }) async {
    final account = await _repository.getAccountByUsername(username);
    if (account == null) {
      throw const AccountException('Account not found.');
    }

    final passwordError = _addAccount.validatePassword(newPassword);
    if (passwordError != null) {
      throw AccountException(passwordError);
    }

    final normalizedCode = backupCode.trim().toUpperCase();
    var matchedIndex = -1;
    for (var index = 0; index < account.backupCodes.length; index++) {
      final record = account.backupCodes[index];
      if (record.isUsed) {
        continue;
      }

      final hashed = await _hashValue(
        normalizedCode,
        base64Decode(record.salt),
      );
      if (_constantTimeEquals(base64Encode(hashed), record.hash)) {
        matchedIndex = index;
        break;
      }
    }

    if (matchedIndex == -1) {
      throw const AccountException('Backup code is invalid or already used.');
    }

    final newPasswordSalt = _randomBytes(16);
    final newPasswordHash = await _keyDerivation.deriveKey(
      newPassword,
      newPasswordSalt,
    );
    final backupBundle = await _generateBackupCodes();

    await _repository.saveAccount(
      account.copyWith(
        passwordSalt: base64Encode(newPasswordSalt),
        passwordHash: base64Encode(newPasswordHash),
        backupCodes: backupBundle.records,
        lastUsedAt: DateTime.now(),
      ),
    );

    return backupBundle.plainCodes;
  }

  Future<_BackupCodeBundle> _generateBackupCodes() async {
    const backupCodeCount = 6;
    const backupCodeLength = 10;
    const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final plainCodes = <String>{};
    while (plainCodes.length < backupCodeCount) {
      final buffer = StringBuffer();
      for (var i = 0; i < backupCodeLength; i++) {
        buffer.write(charset[_random.nextInt(charset.length)]);
      }
      plainCodes.add(buffer.toString());
    }

    final records = <BackupCodeEntity>[];
    for (final code in plainCodes) {
      final salt = _randomBytes(16);
      final hash = await _hashValue(code, salt);
      records.add(
        BackupCodeEntity(
          salt: base64Encode(salt),
          hash: base64Encode(hash),
          isUsed: false,
        ),
      );
    }

    return _BackupCodeBundle(
      plainCodes: plainCodes.toList(),
      records: records,
    );
  }

  Future<List<int>> _hashValue(String value, List<int> salt) async {
    final digest = await _sha256.hash(salt + utf8.encode(value));
    return digest.bytes;
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < left.length; i++) {
      result |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return result == 0;
  }
}

class AccountCreationResult {
  const AccountCreationResult({
    required this.account,
    required this.vaultKey,
    required this.backupCodes,
  });

  final AccountEntity account;
  final List<int> vaultKey;
  final List<String> backupCodes;
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

class _BackupCodeBundle {
  const _BackupCodeBundle({
    required this.plainCodes,
    required this.records,
  });

  final List<String> plainCodes;
  final List<BackupCodeEntity> records;
}
