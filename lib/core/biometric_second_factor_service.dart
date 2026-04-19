import 'package:local_auth/local_auth.dart';

import 'app_secure_storage.dart';

class BiometricSecondFactorService {
  BiometricSecondFactorService(
    this._storage, {
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final AppSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      if (!supported) {
        return false;
      }

      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!canCheck) {
        return false;
      }

      final available = await _localAuthentication.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabledForAccount(String accountId) async {
    final raw = await _storage.read(_enabledKey(accountId));
    return raw == '1';
  }

  Future<void> setEnabledForAccount(String accountId, bool enabled) async {
    if (enabled) {
      await _storage.write(_enabledKey(accountId), '1');
      return;
    }
    await _storage.delete(_enabledKey(accountId));
  }

  Future<void> clearForAccount(String accountId) {
    return _storage.delete(_enabledKey(accountId));
  }

  Future<bool> verifyForLogin({required String reason}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _enabledKey(String accountId) => 'biometric_2fa_$accountId';
}

