import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/master_account.dart';

class StorageService {
  Future<void> saveVault(String masterId, List<int> encrypted) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(encrypted);
    await prefs.setString(_vaultKey(masterId), encoded);
  }

  Future<List<int>?> loadVault(String masterId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_vaultKey(masterId));

    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    return base64Decode(encoded);
  }

  Future<void> saveMasterAccount(MasterAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masterAccountKey, jsonEncode(account.toJson()));
  }

  Future<MasterAccount?> loadMasterAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_masterAccountKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return MasterAccount.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  String _vaultKey(String masterId) => 'vault_$masterId';
  static const String _masterAccountKey = 'master_account';
}
