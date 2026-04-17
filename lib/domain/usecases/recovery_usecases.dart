import 'dart:convert';

import '../../core/device_trust_manager.dart';
import '../../core/hashing_utility.dart';
import '../../core/recovery_key_generator.dart';
import '../entities/account_entity.dart';
import '../repositories/account_repository.dart';
import 'account_usecases.dart';

class GenerateRecoveryKey {
  const GenerateRecoveryKey(this._recoveryKeyGenerator);

  final RecoveryKeyGenerator _recoveryKeyGenerator;

  Future<GeneratedRecoveryKey> call() => _recoveryKeyGenerator.generate();
}

class ValidateRecoveryKey {
  const ValidateRecoveryKey(
    this._repository,
    this._hashingUtility,
    this._recoveryKeyGenerator,
  );

  final AccountRepository _repository;
  final HashingUtility _hashingUtility;
  final RecoveryKeyGenerator _recoveryKeyGenerator;

  Future<AccountEntity> call({
    required String username,
    required String recoveryKey,
  }) async {
    final normalizedUsername = username.trim();
    final account = await _repository.getAccountByUsername(normalizedUsername);
    if (account == null) {
      await _performDummyHash(recoveryKey);
      throw await _registerFailure(accountId: null);
    }

    if (account.recoveryKeyHash.isEmpty || account.recoveryKeySalt.isEmpty) {
      await _performDummyHash(recoveryKey);
      throw await _registerFailure(accountId: account.id);
    }

    final existingRequest = await _repository.getRecoveryRequest(account.id);
    final state =
        existingRequest ?? const RecoveryRequestEntity(attemptCount: 0);
    final now = DateTime.now();
    if (state.isLocked(now)) {
      throw const AccountException('Recovery could not be completed.');
    }

    final hashed = await _hashingUtility.sha256Base64(
      value: _recoveryKeyGenerator.normalize(recoveryKey),
      salt: base64Decode(account.recoveryKeySalt),
    );

    if (!_hashingUtility.constantTimeEquals(hashed, account.recoveryKeyHash)) {
      throw await _registerFailure(accountId: account.id, request: state);
    }

    await _repository.storeRecoveryRequest(
      account.id,
      state.copyWith(
        attemptCount: 0,
        clearLockedUntil: true,
        authorizationUsed: false,
      ),
    );
    return account;
  }

  Future<void> _performDummyHash(String recoveryKey) async {
    final normalized = _recoveryKeyGenerator.normalize(recoveryKey);
    final bytes = utf8.encode(normalized.isEmpty ? 'DUMMYRECOVERYKEY' : normalized);
    final salt = List<int>.generate(16, (index) => bytes[index % bytes.length]);
    await _hashingUtility.sha256Base64(value: normalized, salt: salt);
  }

  Future<AccountException> _registerFailure({
    String? accountId,
    RecoveryRequestEntity? request,
  }) async {
    if (accountId == null) {
      return const AccountException('Recovery could not be completed.');
    }

    final now = DateTime.now();
    final current = request ?? const RecoveryRequestEntity(attemptCount: 0);
    final attempts = current.attemptCount + 1;
    final lockMinutes = attempts >= 5 ? 60 * 24 : 1 << (attempts - 1);
    await _repository.storeRecoveryRequest(
      accountId,
      current.copyWith(
        attemptCount: attempts,
        lockedUntil: now.add(Duration(minutes: lockMinutes)),
        clearAuthorizedAt: true,
        clearAuthorizationExpiresAt: true,
      ),
    );
    return const AccountException('Recovery could not be completed.');
  }
}

class InitiateRecovery {
  const InitiateRecovery(
    this._repository,
    this._validateRecoveryKey,
    this._deviceTrustManager,
  );

  final AccountRepository _repository;
  final ValidateRecoveryKey _validateRecoveryKey;
  final DeviceTrustManager _deviceTrustManager;

  static const Duration _recoveryDelay = Duration(hours: 24);
  static const Duration _authorizationWindow = Duration(minutes: 15);

  Future<RecoveryInitiationResult> call({
    required String username,
    required String recoveryKey,
  }) async {
    final account = await _validateRecoveryKey(
      username: username,
      recoveryKey: recoveryKey,
    );
    final now = DateTime.now();
    final trustedDevice = await _deviceTrustManager.isTrusted(account.id);
    final existingRequest = await _repository.getRecoveryRequest(account.id);

    if (trustedDevice) {
      final authorizedRequest =
          (existingRequest ?? const RecoveryRequestEntity(attemptCount: 0))
              .copyWith(
                requestedAt: now,
                availableAt: now,
                delayConsumed: true,
                authorizationUsed: false,
                attemptCount: 0,
                clearLockedUntil: true,
                authorizedAt: now,
                authorizationExpiresAt: now.add(_authorizationWindow),
              );
      await _repository.storeRecoveryRequest(account.id, authorizedRequest);
      return RecoveryInitiationResult(
        username: account.username,
        status: RecoveryStatus.immediateReset,
        availableAt: now,
      );
    }

    final needsNewDelay =
        existingRequest == null ||
        existingRequest.delayConsumed ||
        existingRequest.authorizationUsed;

    final request = needsNewDelay
        ? const RecoveryRequestEntity(attemptCount: 0).copyWith(
            requestedAt: now,
            availableAt: now.add(_recoveryDelay),
            delayConsumed: false,
            authorizationUsed: false,
            attemptCount: 0,
            clearLockedUntil: true,
            clearAuthorizedAt: true,
            clearAuthorizationExpiresAt: true,
          )
        : existingRequest.copyWith(
            requestedAt: existingRequest.requestedAt ?? now,
            availableAt: existingRequest.availableAt ?? now.add(_recoveryDelay),
            delayConsumed: false,
            authorizationUsed: false,
            attemptCount: 0,
            clearLockedUntil: true,
            clearAuthorizedAt: true,
            clearAuthorizationExpiresAt: true,
          );
    await _repository.storeRecoveryRequest(account.id, request);

    return RecoveryInitiationResult(
      username: account.username,
      status: RecoveryStatus.awaitingDelay,
      availableAt: request.availableAt!,
    );
  }
}

class CompleteRecovery {
  const CompleteRecovery(this._repository);

  final AccountRepository _repository;

  static const Duration _authorizationWindow = Duration(minutes: 15);

  Future<CompletedRecoveryResult> call({required String username}) async {
    final account = await _repository.getAccountByUsername(username.trim());
    if (account == null) {
      throw const AccountException('Recovery could not be completed.');
    }

    final request = await _repository.getRecoveryRequest(account.id);
    final now = DateTime.now();
    if (request == null) {
      throw const AccountException('Recovery could not be completed.');
    }

    if (request.isLocked(now)) {
      throw const AccountException('Recovery could not be completed.');
    }

    if (request.authorizationUsed) {
      throw const AccountException('Recovery already completed. Restart recovery.');
    }

    if (!request.delayConsumed) {
      final availableAt = request.availableAt;
      if (availableAt == null || availableAt.isAfter(now)) {
        throw const AccountException('Recovery could not be completed.');
      }

      final authorizedRequest = request.copyWith(
        delayConsumed: true,
        authorizationUsed: false,
        authorizedAt: now,
        authorizationExpiresAt: now.add(_authorizationWindow),
        attemptCount: 0,
        clearLockedUntil: true,
      );
      await _repository.storeRecoveryRequest(account.id, authorizedRequest);

      return CompletedRecoveryResult(
        username: account.username,
        expiresAt: authorizedRequest.authorizationExpiresAt!,
      );
    }

    if (!request.isAuthorized(now)) {
      throw const AccountException(
        'Authorization expired. Restart recovery.',
      );
    }

    return CompletedRecoveryResult(
      username: account.username,
      expiresAt: request.authorizationExpiresAt!,
    );
  }
}

enum RecoveryStatus { immediateReset, awaitingDelay }

class RecoveryInitiationResult {
  const RecoveryInitiationResult({
    required this.username,
    required this.status,
    required this.availableAt,
  });

  final String username;
  final RecoveryStatus status;
  final DateTime availableAt;
}

class CompletedRecoveryResult {
  const CompletedRecoveryResult({
    required this.username,
    required this.expiresAt,
  });

  final String username;
  final DateTime expiresAt;
}
