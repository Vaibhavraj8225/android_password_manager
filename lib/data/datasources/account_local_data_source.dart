import 'dart:convert';

import '../../core/app_secure_storage.dart';
import '../models/account_model.dart';

class AccountLocalDataSource {
  AccountLocalDataSource(this._secureStorage);

  final AppSecureStorage _secureStorage;

  static const String _accountsKey = 'accounts';
  static const String _activeAccountIdKey = 'active_account_id';

  Future<List<AccountModel>> getAccounts() async {
    final raw = await _secureStorage.read(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return <AccountModel>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              AccountModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveAccounts(List<AccountModel> accounts) {
    return _secureStorage.write(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  Future<String?> getActiveAccountId() async {
    return _secureStorage.read(_activeAccountIdKey);
  }

  Future<void> setActiveAccountId(String? id) async {
    if (id == null || id.isEmpty) {
      await _secureStorage.delete(_activeAccountIdKey);
      return;
    }

    await _secureStorage.write(_activeAccountIdKey, id);
  }

  Future<void> storeRecoveryRequest(
    String accountId,
    RecoveryRequestModel? request,
  ) async {
    final key = _recoveryRequestKey(accountId);
    if (request == null) {
      await _secureStorage.delete(key);
      return;
    }

    await _secureStorage.write(key, jsonEncode(request.toJson()));
  }

  Future<RecoveryRequestModel?> getRecoveryRequest(String accountId) async {
    final raw = await _secureStorage.read(_recoveryRequestKey(accountId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return RecoveryRequestModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  String _recoveryRequestKey(String accountId) => 'recovery_request_$accountId';
}



