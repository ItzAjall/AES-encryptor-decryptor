import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class SecureCrypto {
  Uint8List _deriveKey(String password) {
    var key = utf8.encode(password);
    var hash = sha256.convert(key).bytes;

    for (int i = 0; i < 10000; i++) {
      hash = sha256.convert(hash).bytes;
    }

    return Uint8List.fromList(hash);
  }

  IV _generateIV() {
    final r = Random.secure();
    return IV(Uint8List.fromList(
      List.generate(12, (_) => r.nextInt(256)),
    ));
  }

  String encryptText(String text, String password) {
    final key = _deriveKey(password);
    final iv = _generateIV();

    final encrypter = Encrypter(
      AES(Key(key), mode: AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(text, iv: iv);

    return "${iv.base64}:${encrypted.base64}";
  }

  String decryptText(String data, String password) {
    try {
      final parts = data.split(":");
      final key = _deriveKey(password);

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = Encrypter(
        AES(Key(key), mode: AESMode.gcm),
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return "Decryption failed";
    }
  }
}