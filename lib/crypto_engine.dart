import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

Uint8List deriveKey(String password) {
  var bytes = utf8.encode(password);
  var hash = sha256.convert(bytes).bytes;

  for (int i = 0; i < 100000; i++) {
    hash = sha256.convert(hash).bytes;
  }

  return Uint8List.fromList(hash);
}

class CryptoEngine {
  Encrypter _enc(Uint8List key) =>
      Encrypter(AES(Key(key), mode: AESMode.gcm));

  IV _iv() {
    final r = Random.secure();
    return IV(Uint8List.fromList(
      List.generate(12, (_) => r.nextInt(256)),
    ));
  }

  String encrypt(String text, Uint8List key) {
    final iv = _iv();
    final e = _enc(key).encrypt(text, iv: iv);
    return iv.base64 + ":" + e.base64;
  }

  String decrypt(String data, Uint8List key) {
    final p = data.split(":");
    final iv = IV.fromBase64(p[0]);
    final enc = Encrypted.fromBase64(p[1]);
    return _enc(key).decrypt(enc, iv: iv);
  }
}