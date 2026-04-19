import 'dart:math';

class SecureRandomGenerator {
  SecureRandomGenerator() : _random = Random.secure();

  final Random _random;

  static const String _recoveryCharset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  List<int> bytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  String recoveryKey({int groups = 6, int groupLength = 5}) {
    final segments = List<String>.generate(groups, (_) {
      final buffer = StringBuffer();
      for (var index = 0; index < groupLength; index++) {
        buffer.write(
          _recoveryCharset[_random.nextInt(_recoveryCharset.length)],
        );
      }
      return buffer.toString();
    });
    return segments.join('-');
  }
}

