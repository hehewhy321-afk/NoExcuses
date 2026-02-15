import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Manages a unique device identifier.
/// Generates a UUIDv4 on first launch and persists it securely.
class DeviceId {
  static const _key = 'device_id';
  static final _storage = const FlutterSecureStorage();
  static String? _cached;

  /// Get or create the device identifier.
  static Future<String> get() async {
    if (_cached != null) return _cached!;

    String? stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) {
      _cached = stored;
      return stored;
    }

    final id = const Uuid().v4();
    await _storage.write(key: _key, value: id);
    _cached = id;
    return id;
  }

  /// Check if device has been initialized.
  static Future<bool> exists() async {
    final stored = await _storage.read(key: _key);
    return stored != null && stored.isNotEmpty;
  }
}
