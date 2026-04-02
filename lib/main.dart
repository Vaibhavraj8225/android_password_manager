import 'package:flutter/material.dart';

import 'app.dart';
import 'core/crypto_service.dart';
import 'core/key_derivation.dart';
import 'core/storage_service.dart';
import 'data/datasources/account_local_data_source.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/vault_repository.dart';
import 'domain/usecases/account_usecases.dart';
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

  runApp(
    VaultXApp(
      accountController: AccountController(
        getAccounts: GetAccounts(accountRepository),
        getActiveAccount: GetActiveAccount(accountRepository),
        addAccount: addAccount,
        switchAccount: SwitchAccount(accountRepository),
        deleteAccount: DeleteAccount(accountRepository, keyDerivation),
        authenticateAccount: AuthenticateAccount(accountRepository, keyDerivation),
        changeAccountPassword: ChangeAccountPassword(
          accountRepository,
          keyDerivation,
          addAccount,
        ),
        vaultRepository: VaultRepository(
          CryptoService(),
          storageService,
        ),
        storageService: storageService,
      ),
    ),
  );
}
