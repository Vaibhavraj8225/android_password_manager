import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage_service.dart';
import '../models/account_model.dart';

class AccountLocalDataSource {
  AccountLocalDataSource(
    this._secureStorage,
    this._storageService,
  );

  final FlutterSecureStorage _secureStorage;
  final StorageService _storageService;

  static const String _accountsKey = 'accounts';
  static const String _activeAccountIdKey = 'active_account_id';
  static const String _migrationFlagKey = 'accounts_migrated_v1';

  Future<List<AccountModel>> getAccounts() async {
    await _migrateLegacyAccountIfNeeded();
    final raw = await _secureStorage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) {
      return <AccountModel>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => AccountModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> saveAccounts(List<AccountModel> accounts) {
    return _secureStorage.write(
      key: _accountsKey,
      value: jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  Future<String?> getActiveAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeAccountIdKey);
  }

  Future<void> setActiveAccountId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_activeAccountIdKey);
      return;
    }

    await prefs.setString(_activeAccountIdKey, id);
  }

  Future<void> _migrateLegacyAccountIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migrationFlagKey) ?? false;
    if (alreadyMigrated) {
      return;
    }

    final accountsRaw = await _secureStorage.read(key: _accountsKey);
    final legacy = await _storageService.loadLegacyMasterAccountJson();
    if ((accountsRaw == null || accountsRaw.isEmpty) && legacy != null) {
      final username = legacy['username'] as String? ?? '';
      if (username.isNotEmpty) {
        final account = AccountModel.fromJson({
          'id': username,
          ...legacy,
          'created_at': DateTime.now().toIso8601String(),
          'last_used_at': DateTime.now().toIso8601String(),
        });
        await saveAccounts([account]);
        await setActiveAccountId(account.id);
      }
      await _storageService.clearLegacyMasterAccount();
    }

    await prefs.setBool(_migrationFlagKey, true);
  }
}
