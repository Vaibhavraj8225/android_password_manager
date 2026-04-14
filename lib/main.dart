import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/crypto_service.dart';
import 'core/device_id_generator.dart';
import 'core/device_trust_manager.dart';
import 'core/hashing_utility.dart';
import 'core/key_derivation.dart';
import 'core/recovery_key_generator.dart';
import 'core/secure_random_generator.dart';
import 'core/storage_service.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/vault_repository.dart';
import 'domain/usecases/account_usecases.dart';
import 'domain/usecases/recovery_usecases.dart';
import 'presentation/state/account_controller.dart';

void main() {
  const secureStorage = FlutterSecureStorage();
  final storageService = StorageService();
  final accountRepository = AccountRepositoryImpl(
    AccountLocalDataSource(secureStorage, storageService),
  );
  final keyDerivation = KeyDerivation();
  final secureRandomGenerator = SecureRandomGenerator();
  final hashingUtility = HashingUtility();
  final recoveryKeyGenerator = RecoveryKeyGenerator(
    secureRandomGenerator,
    hashingUtility,
  );
  final deviceTrustManager = DeviceTrustManager(
    secureStorage,
    DeviceIdGenerator(secureRandomGenerator),
  );
  final addAccount = AddAccount(
    accountRepository,
    keyDerivation,
    recoveryKeyGenerator,
    secureRandomGenerator,
  );

  runApp(
    VaultXApp(
      accountController: AccountController(
        getAccounts: GetAccounts(accountRepository),
        getActiveAccount: GetActiveAccount(accountRepository),
        addAccount: addAccount,
        switchAccount: SwitchAccount(accountRepository),
        logoutAccount: LogoutAccount(accountRepository),
        deleteAccount: DeleteAccount(accountRepository, keyDerivation),
        authenticateAccount: AuthenticateAccount(
          accountRepository,
          keyDerivation,
        ),
        changeAccountPassword: ChangeAccountPassword(
          accountRepository,
          keyDerivation,
          addAccount,
          recoveryKeyGenerator,
          secureRandomGenerator,
        ),
        initiateRecovery: InitiateRecovery(
          accountRepository,
          ValidateRecoveryKey(
            accountRepository,
            hashingUtility,
            recoveryKeyGenerator,
          ),
          deviceTrustManager,
        ),
        completeRecovery: CompleteRecovery(accountRepository),
        deviceTrustManager: deviceTrustManager,
        vaultRepository: VaultRepository(CryptoService(), storageService),
        storageService: storageService,
      ),
    ),
  );
}
