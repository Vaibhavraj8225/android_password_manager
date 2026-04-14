<<<<<<< HEAD
import 'dart:convert';
import '../core/crypto_service.dart';
import '../core/storage_service.dart';
import '../domain/models/vault.dart';

class VaultRepository {
  final CryptoService crypto;
  final StorageService storage;

  VaultRepository(this.crypto, this.storage);

  Future<void> save(String masterId, List<int> key, Vault vault) async {
    final jsonData = jsonEncode(vault.toJson());
    final encrypted = await crypto.encrypt(key, jsonData);
    await storage.saveVault(masterId, encrypted);
  }

=======
import 'dart:convert';
import '../core/crypto_service.dart';
import '../core/storage_service.dart';
import '../domain/models/vault.dart';

class VaultRepository {
  final CryptoService crypto;
  final StorageService storage;

  VaultRepository(this.crypto, this.storage);

  Future<void> save(String masterId, List<int> key, Vault vault) async {
    final jsonData = jsonEncode(vault.toJson());
    final encrypted = await crypto.encrypt(key, jsonData);
    await storage.saveVault(masterId, encrypted);
  }

>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
  Future<Vault> load(String masterId, List<int> key) async {
    final encrypted = await storage.loadVault(masterId);
    if (encrypted == null) {
      return Vault.empty();
    }
    final decrypted = await crypto.decrypt(key, encrypted);
    return Vault.fromJson(jsonDecode(decrypted));
  }
}
