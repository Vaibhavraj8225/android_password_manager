import '../entities/account_entity.dart';

abstract class AccountRepository {
  Future<List<AccountEntity>> getAccounts();
  Future<AccountEntity?> getAccountById(String id);
  Future<AccountEntity?> getAccountByUsername(String username);
  Future<AccountEntity?> getActiveAccount();
  Future<void> saveAccounts(List<AccountEntity> accounts);
  Future<void> saveAccount(AccountEntity account);
  Future<void> deleteAccount(String id);
  Future<void> setActiveAccount(String? id);
}
