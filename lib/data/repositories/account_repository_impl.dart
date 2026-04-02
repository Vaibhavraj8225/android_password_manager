import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_data_source.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._localDataSource);

  final AccountLocalDataSource _localDataSource;

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
  }

  @override
  Future<void> setActiveAccount(String? id) {
    return _localDataSource.setActiveAccountId(id);
  }
}
