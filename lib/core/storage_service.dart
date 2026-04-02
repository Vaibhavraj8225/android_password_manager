import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> deleteVault(String masterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vaultKey(masterId));
  }

  Future<void> saveLegacyMasterAccountJson(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_legacyMasterAccountKey, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadLegacyMasterAccountJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyMasterAccountKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> clearLegacyMasterAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyMasterAccountKey);
  }

  String _vaultKey(String masterId) => 'vault_$masterId';
  static const String _legacyMasterAccountKey = 'master_account';
}
