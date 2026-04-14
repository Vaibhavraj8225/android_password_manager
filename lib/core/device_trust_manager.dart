import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'device_id_generator.dart';

class DeviceTrustManager {
  DeviceTrustManager(this._secureStorage, this._deviceIdGenerator);

  final FlutterSecureStorage _secureStorage;
  final DeviceIdGenerator _deviceIdGenerator;

  static const String _deviceIdKey = 'vaultx_device_id';

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _deviceIdGenerator.generate();
    await _secureStorage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<void> markTrusted(String accountId) async {
    final deviceId = await getOrCreateDeviceId();
    await _secureStorage.write(
      key: _trustedDeviceKey(accountId),
      value: deviceId,
    );
  }

  Future<bool> isTrusted(String accountId) async {
    final currentDeviceId = await getOrCreateDeviceId();
    final trustedDeviceId = await _secureStorage.read(
      key: _trustedDeviceKey(accountId),
    );
    if (trustedDeviceId == null || trustedDeviceId.isEmpty) {
      return false;
    }
    return trustedDeviceId == currentDeviceId;
  }

  Future<void> clearTrust(String accountId) {
    return _secureStorage.delete(key: _trustedDeviceKey(accountId));
  }

  String _trustedDeviceKey(String accountId) => 'trusted_device_$accountId';
}
