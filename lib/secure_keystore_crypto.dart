import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class SecureKeystoreCrypto {

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // 👈 استفاده از Keystore
    ),
  );

  // تولید IV تصادفی
  IV _generateIV() {
    final r = Random.secure();
    return IV(Uint8List.fromList(
      List.generate(12, (_) => r.nextInt(256)),
    ));
  }

  // 🔐 Encrypt
  Future<String> encryptText(String keyName, String text) async {
    final iv = _generateIV();

    // کلید داخل keystore مدیریت میشه
    await _storage.write(key: keyName, value: text);

    final stored = await _storage.read(key: keyName) ?? "";

    return "${iv.base64}:${base64Encode(utf8.encode(stored))}";
  }

  // 🔓 Decrypt
  Future<String> decryptText(String keyName) async {
    final value = await _storage.read(key: keyName);
    return value ?? "";
  }

  // ❌ حذف
  Future<void> delete(String keyName) async {
    await _storage.delete(key: keyName);
  }
}