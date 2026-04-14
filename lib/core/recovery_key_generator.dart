import 'dart:convert';

import 'hashing_utility.dart';
import 'secure_random_generator.dart';

class RecoveryKeyGenerator {
  RecoveryKeyGenerator(this._randomGenerator, this._hashingUtility);

  final SecureRandomGenerator _randomGenerator;
  final HashingUtility _hashingUtility;

  Future<GeneratedRecoveryKey> generate() async {
    final plainText = _randomGenerator.recoveryKey();
    final salt = _randomGenerator.bytes(16);
    final hash = await _hashingUtility.sha256Base64(
      value: normalize(plainText),
      salt: salt,
    );

    return GeneratedRecoveryKey(
      plainText: plainText,
      salt: base64Encode(salt),
      hash: hash,
    );
  }

  String normalize(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');
  }
}

class GeneratedRecoveryKey {
  const GeneratedRecoveryKey({
    required this.plainText,
    required this.salt,
    required this.hash,
  });

  final String plainText;
  final String salt;
  final String hash;
}
