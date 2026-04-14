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
<<<<<<< HEAD
  Future<void> storeRecoveryKeyHash({
    required String accountId,
    required String recoveryKeySalt,
    required String recoveryKeyHash,
  });
  Future<String?> getRecoveryKeyHash(String accountId);
  Future<String?> getRecoveryKeySalt(String accountId);
  Future<void> storeRecoveryRequest(
    String accountId,
    RecoveryRequestEntity? request,
  );
  Future<RecoveryRequestEntity?> getRecoveryRequest(String accountId);
=======
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
}
