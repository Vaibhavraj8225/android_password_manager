import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  final _algo = AesGcm.with256bits();

  Future<List<int>> encrypt(List<int> key, String data) async {
    final secretKey = SecretKey(key);
    final nonce = _randomBytes(12);

    final encrypted = await _algo.encrypt(
      utf8.encode(data),
      secretKey: secretKey,
      nonce: nonce,
    );

    return nonce + encrypted.cipherText + encrypted.mac.bytes;
  }

  Future<String> decrypt(List<int> key, List<int> encrypted) async {
    final nonce = encrypted.sublist(0, 12);
    final cipher = encrypted.sublist(12, encrypted.length - 16);
    final mac = encrypted.sublist(encrypted.length - 16);

    final box = SecretBox(cipher, nonce: nonce, mac: Mac(mac));
    final secretKey = SecretKey(key);

    final decrypted = await _algo.decrypt(box, secretKey: secretKey);

    return utf8.decode(decrypted);
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List.generate(length, (_) => rnd.nextInt(256));
  }
}



