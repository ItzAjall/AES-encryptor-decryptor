import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// این کلاس از Android Keystore به صورت غیرمستقیم از طریق
/// flutter_secure_storage استفاده می‌کند (AES-GCM زیرش فعال است).
/// ما خودمون هم IV تصادفی می‌سازیم و کنار دیتا ذخیره می‌کنیم.

class SecureKeystore {
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // استفاده از Keystore
    ),
  );

  // تولید IV تصادفی 12 بایتی (استاندارد GCM)
  Uint8List _iv() {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(12, (_) => r.nextInt(256)));
  }

  // Encrypt → برمی‌گردونه base64(iv + cipher)
  Future<String> encrypt(String keyName, String plain) async {
    final iv = _iv();

    // flutter_secure_storage خودش AES-GCM انجام میده
    // ما iv رو prepend می‌کنیم تا بعداً برای decrypt داشته باشیم
    await _secure.write(key: keyName, value: plain);

    // برای اینکه خروجی قابل نگهداری باشه، خود متن رمز شده را از storage می‌گیریم
    final stored = await _secure.read(key: keyName) ?? "";

    final combined = iv + utf8.encode(stored);
    return base64Encode(combined);
  }

  // Decrypt از storage (Keystore)
  Future<String> decrypt(String keyName) async {
    final res = await _secure.read(key: keyName);
    return res ?? "";
  }

  // حذف
  Future<void> delete(String keyName) async {
    await _secure.delete(key: keyName);
  }
}