import 'package:cryptography/cryptography.dart';

class KeyDerivation {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  Future<List<int>> deriveKey(String password, List<int> salt) async {
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(password.codeUnits),
      nonce: salt,
    );
    return key.extractBytes();
  }
}



