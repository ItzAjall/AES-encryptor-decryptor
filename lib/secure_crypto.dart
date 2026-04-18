import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class SecureCrypto {
  String encryptPassword(String password) {
  return encryptText(password, "master_key_123");
}

String decryptPassword(String data) {
  return decryptText(data, "master_key_123");
}

  Key deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).bytes;
    return Key(Uint8List.fromList(digest));
  }

  IV generateIV() {
    final random = Random.secure();
    final iv = List<int>.generate(16, (_) => random.nextInt(256));
    return IV(Uint8List.fromList(iv));
  }

  String encryptText(String text, String password) {
    final key = deriveKey(password);
    final iv = generateIV();

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(text, iv: iv);

    return base64Encode(iv.bytes + encrypted.bytes);
  }

  String decryptText(String data, String password) {
    final key = deriveKey(password);

    final decoded = base64Decode(data);

    final iv = IV(decoded.sublist(0, 16));
    final encrypted = Encrypted(decoded.sublist(16));

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}