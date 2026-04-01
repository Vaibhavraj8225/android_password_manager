import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../domain/models/master_account.dart';
import 'key_derivation.dart';
import 'storage_service.dart';

class MasterAccountService {
  MasterAccountService(this._storageService, this._keyDerivation);

  final StorageService _storageService;
  final KeyDerivation _keyDerivation;
  final Sha256 _sha256 = Sha256();
  final Random _random = Random.secure();

  static const int _backupCodeCount = 6;
  static const int _backupCodeLength = 10;
  static const String _charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<MasterAccount?> loadAccount() {
    return _storageService.loadMasterAccount();
  }

  Future<AccountSession> createAccount({
    required String username,
    required String password,
  }) async {
    final existingAccount = await _storageService.loadMasterAccount();
    if (existingAccount != null) {
      throw const AuthException('A master account already exists.');
    }

    final normalizedUsername = username.trim();
    final passwordError = validatePassword(password);
    if (normalizedUsername.isEmpty) {
      throw const AuthException('Username is required.');
    }
    if (passwordError != null) {
      throw AuthException(passwordError);
    }

    final passwordSalt = _randomBytes(16);
    final passwordHash = await _keyDerivation.deriveKey(password, passwordSalt);
    final backupBundle = await _generateBackupCodes();
    final vaultKey = _randomBytes(32);

    final account = MasterAccount(
      username: normalizedUsername,
      passwordSalt: base64Encode(passwordSalt),
      passwordHash: base64Encode(passwordHash),
      vaultKey: base64Encode(vaultKey),
      backupCodes: backupBundle.records,
    );

    await _storageService.saveMasterAccount(account);

    return AccountSession(
      account: account,
      vaultKey: vaultKey,
      backupCodes: backupBundle.plainCodes,
    );
  }

  Future<AuthenticatedAccount> authenticate({
    required String username,
    required String password,
  }) async {
    final account = await _storageService.loadMasterAccount();
    if (account == null) {
      throw const AuthException('Create your master account first.');
    }

    if (account.username != username.trim()) {
      throw const AuthException('Invalid username or password.');
    }

    final derivedHash = await _keyDerivation.deriveKey(
      password,
      base64Decode(account.passwordSalt),
    );
    final isMatch = _constantTimeEquals(
      base64Encode(derivedHash),
      account.passwordHash,
    );

    if (!isMatch) {
      throw const AuthException('Invalid username or password.');
    }

    return AuthenticatedAccount(
      account: account,
      vaultKey: base64Decode(account.vaultKey),
    );
  }

  Future<List<String>> resetPasswordWithBackupCode({
    required String username,
    required String backupCode,
    required String newPassword,
  }) async {
    final account = await _storageService.loadMasterAccount();
    if (account == null) {
      throw const AuthException('No master account found.');
    }

    if (account.username != username.trim()) {
      throw const AuthException('Account not found.');
    }

    final passwordError = validatePassword(newPassword);
    if (passwordError != null) {
      throw AuthException(passwordError);
    }

    final codeIndex = await _findMatchingBackupCodeIndex(
      account.backupCodes,
      backupCode.trim().toUpperCase(),
    );
    if (codeIndex == null) {
      throw const AuthException('Backup code is invalid or already used.');
    }

    final refreshedAccount = await _refreshAccountSecrets(
      account.copyWith(
        backupCodes: account.backupCodes
            .asMap()
            .entries
            .map(
              (entry) => entry.key == codeIndex
                  ? entry.value.copyWith(isUsed: true)
                  : entry.value,
            )
            .toList(),
      ),
      newPassword,
    );

    await _storageService.saveMasterAccount(refreshedAccount.account);
    return refreshedAccount.backupCodes;
  }

  Future<List<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = await _storageService.loadMasterAccount();
    if (account == null) {
      throw const AuthException('No master account found.');
    }

    final currentSession = await authenticate(
      username: account.username,
      password: currentPassword,
    );
    if (currentPassword == newPassword) {
      throw const AuthException('Choose a different new password.');
    }

    final refreshedAccount = await _refreshAccountSecrets(
      currentSession.account,
      newPassword,
    );

    await _storageService.saveMasterAccount(refreshedAccount.account);
    return refreshedAccount.backupCodes;
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
    final plainCodes = <String>{};
    while (plainCodes.length < _backupCodeCount) {
      plainCodes.add(_generateCode());
    }

    final records = <BackupCodeRecord>[];
    for (final code in plainCodes) {
      records.add(await _hashBackupCode(code));
    }

    return _BackupCodeBundle(
      plainCodes: plainCodes.toList(),
      records: records,
    );
  }

  Future<int?> _findMatchingBackupCodeIndex(
    List<BackupCodeRecord> records,
    String code,
  ) async {
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.isUsed) {
        continue;
      }

      final hashedCode = await _hashValue(
        code,
        base64Decode(record.salt),
      );
      if (_constantTimeEquals(base64Encode(hashedCode), record.hash)) {
        return i;
      }
    }

    return null;
  }

  Future<_RefreshedSecrets> _refreshAccountSecrets(
    MasterAccount account,
    String newPassword,
  ) async {
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) {
      throw AuthException(passwordError);
    }

    final newPasswordSalt = _randomBytes(16);
    final newPasswordHash = await _keyDerivation.deriveKey(
      newPassword,
      newPasswordSalt,
    );
    final backupBundle = await _generateBackupCodes();

    return _RefreshedSecrets(
      account: account.copyWith(
        passwordSalt: base64Encode(newPasswordSalt),
        passwordHash: base64Encode(newPasswordHash),
        backupCodes: backupBundle.records,
      ),
      backupCodes: backupBundle.plainCodes,
    );
  }

  Future<BackupCodeRecord> _hashBackupCode(String code) async {
    final salt = _randomBytes(16);
    final hash = await _hashValue(code, salt);
    return BackupCodeRecord(
      salt: base64Encode(salt),
      hash: base64Encode(hash),
      isUsed: false,
    );
  }

  Future<List<int>> _hashValue(String value, List<int> salt) async {
    final bytes = utf8.encode(value);
    final digest = await _sha256.hash(salt + bytes);
    return digest.bytes;
  }

  String _generateCode() {
    final buffer = StringBuffer();
    for (var i = 0; i < _backupCodeLength; i++) {
      buffer.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buffer.toString();
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

class AuthenticatedAccount {
  const AuthenticatedAccount({
    required this.account,
    required this.vaultKey,
  });

  final MasterAccount account;
  final List<int> vaultKey;
}

class AccountSession extends AuthenticatedAccount {
  const AccountSession({
    required super.account,
    required super.vaultKey,
    required this.backupCodes,
  });

  final List<String> backupCodes;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class _BackupCodeBundle {
  const _BackupCodeBundle({
    required this.plainCodes,
    required this.records,
  });

  final List<String> plainCodes;
  final List<BackupCodeRecord> records;
}

class _RefreshedSecrets {
  const _RefreshedSecrets({
    required this.account,
    required this.backupCodes,
  });

  final MasterAccount account;
  final List<String> backupCodes;
}
