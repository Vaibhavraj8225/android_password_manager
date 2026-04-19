import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class HashingUtility {
  HashingUtility() : _sha256 = Sha256();

  final Sha256 _sha256;

  Future<String> sha256Base64({
    required String value,
    required List<int> salt,
  }) async {
    final digest = await _sha256.hash([...salt, ...utf8.encode(value)]);
    return base64Encode(digest.bytes);
  }

  bool constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return result == 0;
  }
}

