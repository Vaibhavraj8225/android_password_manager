import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/crypto_service.dart';
import 'core/device_id_generator.dart';
import 'core/device_trust_manager.dart';
import 'core/hashing_utility.dart';
import 'core/key_derivation.dart';
import 'core/recovery_key_generator.dart';
import 'core/secure_random_generator.dart';
=======

import 'app.dart';
import 'core/crypto_service.dart';
import 'core/key_derivation.dart';
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
import 'core/storage_service.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/vault_repository.dart';
import 'domain/usecases/account_usecases.dart';
<<<<<<< HEAD
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
=======
import 'presentation/state/account_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  final storageService = StorageService();
  final accountRepository = AccountRepositoryImpl(
    AccountLocalDataSource(
      const FlutterSecureStorage(),
      storageService,
    ),
  );
  final keyDerivation = KeyDerivation();
  final addAccount = AddAccount(accountRepository, keyDerivation);
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

  runApp(
    VaultXApp(
      accountController: AccountController(
        getAccounts: GetAccounts(accountRepository),
        getActiveAccount: GetActiveAccount(accountRepository),
        addAccount: addAccount,
        switchAccount: SwitchAccount(accountRepository),
        logoutAccount: LogoutAccount(accountRepository),
        deleteAccount: DeleteAccount(accountRepository, keyDerivation),
<<<<<<< HEAD
        authenticateAccount: AuthenticateAccount(
          accountRepository,
          keyDerivation,
        ),
=======
        authenticateAccount: AuthenticateAccount(accountRepository, keyDerivation),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
        changeAccountPassword: ChangeAccountPassword(
          accountRepository,
          keyDerivation,
          addAccount,
<<<<<<< HEAD
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
=======
        ),
        vaultRepository: VaultRepository(
          CryptoService(),
          storageService,
        ),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
        storageService: storageService,
      ),
    ),
  );
}
