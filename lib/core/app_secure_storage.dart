import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  AppSecureStorage({
    FlutterSecureStorage? primaryStorage,
    FlutterSecureStorage? legacyStorage,
  }) : _primaryStorage = primaryStorage ?? _buildPrimaryStorage(),
       _legacyStorage = legacyStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _primaryStorage;
  final FlutterSecureStorage _legacyStorage;

  Future<String?> read(String key) async {
    final primary = await _primaryStorage.read(key: key);
    if (primary != null) {
      return primary;
    }

    final legacy = await _legacyStorage.read(key: key);
    if (legacy == null) {
      return null;
    }

    // Promote legacy data into the hardened storage configuration.
    await _primaryStorage.write(key: key, value: legacy);
    await _legacyStorage.delete(key: key);
    return legacy;
  }

  Future<void> write(String key, String value) {
    return _primaryStorage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _primaryStorage.delete(key: key);
    await _legacyStorage.delete(key: key);
  }

  static FlutterSecureStorage _buildPrimaryStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }
}
