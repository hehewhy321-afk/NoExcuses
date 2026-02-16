import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Type-safe wrapper around FlutterSecureStorage.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> writeList(String key, List<String> value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  static Future<List<String>> readList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  static Future<void> writeInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<int> readInt(String key, {int defaultValue = 0}) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }

  static Future<void> writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<bool> readBool(String key, {bool defaultValue = false}) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return defaultValue;
    return raw == 'true';
  }
}
