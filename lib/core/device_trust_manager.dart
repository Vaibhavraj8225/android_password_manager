import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'app_secure_storage.dart';
import 'device_id_generator.dart';

class DeviceTrustManager {
  DeviceTrustManager(this._secureStorage, this._deviceIdGenerator);

  final AppSecureStorage _secureStorage;
  final DeviceIdGenerator _deviceIdGenerator;

  static const String _deviceIdKey = 'vaultx_device_id';
  static const String _trustIntegrityKey = 'vaultx_trust_integrity_key';
  final Hmac _hmac = Hmac.sha256();

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _deviceIdGenerator.generate();
    await _secureStorage.write(_deviceIdKey, generated);
    return generated;
  }

  Future<void> markTrusted(String accountId) async {
    final deviceId = await getOrCreateDeviceId();
    final record = await _buildSignedTrustRecord(accountId, deviceId);
    await _secureStorage.write(_trustedDeviceKey(accountId), record);
  }

  Future<bool> isTrusted(String accountId) async {
    final currentDeviceId = await getOrCreateDeviceId();
    final trustedRecord = await _secureStorage.read(
      _trustedDeviceKey(accountId),
    );
    if (trustedRecord == null || trustedRecord.isEmpty) {
      return false;
    }

    final separator = trustedRecord.lastIndexOf('.');
    if (separator == -1) {
      // Legacy format migration: previously only the raw device id was stored.
      if (trustedRecord != currentDeviceId) {
        return false;
      }
      await markTrusted(accountId);
      return true;
    }

    final trustedDeviceId = trustedRecord.substring(0, separator);
    final providedMac = trustedRecord.substring(separator + 1);
    if (trustedDeviceId != currentDeviceId || providedMac.isEmpty) {
      return false;
    }

    final expectedMac = await _signTrustRecord(accountId, trustedDeviceId);
    return _constantTimeEquals(providedMac, expectedMac);
  }

  Future<void> clearTrust(String accountId) {
    return _secureStorage.delete(_trustedDeviceKey(accountId));
  }

  Future<String> _buildSignedTrustRecord(
    String accountId,
    String deviceId,
  ) async {
    final mac = await _signTrustRecord(accountId, deviceId);
    return '$deviceId.$mac';
  }

  Future<String> _signTrustRecord(String accountId, String deviceId) async {
    final secret = await _getOrCreateTrustIntegrityKey();
    final data = utf8.encode('$accountId|$deviceId');
    final digest = await _hmac.calculateMac(data, secretKey: SecretKey(secret));
    return base64Encode(digest.bytes);
  }

  Future<List<int>> _getOrCreateTrustIntegrityKey() async {
    final existing = await _secureStorage.read(_trustIntegrityKey);
    if (existing != null && existing.isNotEmpty) {
      try {
        return base64Decode(existing);
      } catch (_) {}
    }

    final keyBytes = utf8.encode(
      '${_deviceIdGenerator.generate()}${_deviceIdGenerator.generate()}',
    );
    final encoded = base64Encode(keyBytes);
    await _secureStorage.write(_trustIntegrityKey, encoded);
    return keyBytes;
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return result == 0;
  }

  String _trustedDeviceKey(String accountId) => 'trusted_device_$accountId';
}
