import 'dart:convert';
import 'dart:math';

import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final keyGeneratorProvider = Provider(
  (ref) => KeyGenerator(
    Random.secure(),
  ),
);
// coverage:ignore-end

class KeyGenerator {
  final Random _random;

  KeyGenerator(this._random);

  String generateKey(int byteCount) {
    final bytes = List.filled(byteCount, 0);
    for (var i = 0; i < byteCount; ++i) {
      bytes[i] = _random.nextInt(256);
    }

    return base64Url.encode(bytes);
  }
}
