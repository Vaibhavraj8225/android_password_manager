import 'dart:convert';

import 'app_secure_storage.dart';

class StorageService {
  StorageService(this._secureStorage);

  final AppSecureStorage _secureStorage;

  Future<void> saveVault(String masterId, List<int> encrypted) async {
    final encoded = base64Encode(encrypted);
    await _secureStorage.write(_vaultKey(masterId), encoded);
  }

  Future<List<int>?> loadVault(String masterId) async {
    final encoded = await _secureStorage.read(_vaultKey(masterId));

    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    return base64Decode(encoded);
  }

  Future<void> deleteVault(String masterId) async {
    await _secureStorage.delete(_vaultKey(masterId));
  }

  String _vaultKey(String masterId) => 'vault_$masterId';
}

