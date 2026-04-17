import 'dart:async';

import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_data_source.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._localDataSource);

  final AccountLocalDataSource _localDataSource;
  static final Map<String, Future<void>> _recoveryQueues =
      <String, Future<void>>{};

  @override
  Future<List<AccountEntity>> getAccounts() => _localDataSource.getAccounts();

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    final accounts = await _localDataSource.getAccounts();
    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  @override
  Future<AccountEntity?> getAccountByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final accounts = await _localDataSource.getAccounts();
    for (final account in accounts) {
      if (account.username.trim().toLowerCase() == normalized) {
        return account;
      }
    }
    return null;
  }

  @override
  Future<AccountEntity?> getActiveAccount() async {
    final activeId = await _localDataSource.getActiveAccountId();
    if (activeId == null || activeId.isEmpty) {
      return null;
    }

    return getAccountById(activeId);
  }

  @override
  Future<void> saveAccounts(List<AccountEntity> accounts) {
    return _localDataSource.saveAccounts(
      accounts.map(AccountModel.fromEntity).toList(),
    );
  }

  @override
  Future<void> saveAccount(AccountEntity account) async {
    final accounts = await _localDataSource.getAccounts();
    final updated = <AccountModel>[];
    var replaced = false;

    for (final existing in accounts) {
      if (existing.id == account.id) {
        updated.add(AccountModel.fromEntity(account));
        replaced = true;
      } else {
        updated.add(existing);
      }
    }

    if (!replaced) {
      updated.add(AccountModel.fromEntity(account));
    }

    await _localDataSource.saveAccounts(updated);
  }

  @override
  Future<void> deleteAccount(String id) async {
    final accounts = await _localDataSource.getAccounts();
    await _localDataSource.saveAccounts(
      accounts.where((account) => account.id != id).toList(),
    );
    await _localDataSource.storeRecoveryRequest(id, null);
  }

  @override
  Future<void> setActiveAccount(String? id) {
    return _localDataSource.setActiveAccountId(id);
  }

  @override
  Future<void> storeRecoveryKeyHash({
    required String accountId,
    required String recoveryKeySalt,
    required String recoveryKeyHash,
  }) async {
    final account = await getAccountById(accountId);
    if (account == null) {
      return;
    }

    await saveAccount(
      account.copyWith(
        recoveryKeySalt: recoveryKeySalt,
        recoveryKeyHash: recoveryKeyHash,
      ),
    );
  }

  @override
  Future<String?> getRecoveryKeyHash(String accountId) async {
    final account = await getAccountById(accountId);
    return account?.recoveryKeyHash;
  }

  @override
  Future<String?> getRecoveryKeySalt(String accountId) async {
    final account = await getAccountById(accountId);
    return account?.recoveryKeySalt;
  }

  @override
  Future<void> storeRecoveryRequest(
    String accountId,
    RecoveryRequestEntity? request,
  ) {
    return _localDataSource.storeRecoveryRequest(
      accountId,
      request == null ? null : RecoveryRequestModel.fromEntity(request),
    );
  }

  @override
  Future<RecoveryRequestEntity?> getRecoveryRequest(String accountId) {
    return _localDataSource.getRecoveryRequest(accountId);
  }

  @override
  Future<bool> consumeRecoveryAuthorization({
    required String accountId,
    required DateTime now,
  }) {
    return _withRecoveryQueue<bool>(accountId, () async {
      final request = await _localDataSource.getRecoveryRequest(accountId);
      if (request == null) {
        return false;
      }
      if (request.authorizationUsed) {
        return false;
      }
      if (!request.isAuthorized(now)) {
        return false;
      }

      await _localDataSource.storeRecoveryRequest(
        accountId,
        RecoveryRequestModel.fromEntity(
          request.copyWith(
            authorizationUsed: true,
            attemptCount: 0,
            clearLockedUntil: true,
          ),
        ),
      );
      return true;
    });
  }

  Future<T> _withRecoveryQueue<T>(
    String accountId,
    Future<T> Function() operation,
  ) {
    final completer = Completer<T>();
    final previous = _recoveryQueues[accountId] ?? Future<void>.value();
    final next = previous.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _recoveryQueues[accountId] = next;
    return completer.future.whenComplete(() {
      if (identical(_recoveryQueues[accountId], next)) {
        _recoveryQueues.remove(accountId);
      }
    });
  }
}


