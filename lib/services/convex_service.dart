import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/secure_storage.dart';

/// HTTP client for Convex backend.
/// All calls are wrapped in try/catch — app works without Convex.
class ConvexService {
  /// Get the configured Convex URL.
  static Future<String> _getUrl() async {
    return await SecureStorage.read(AppConstants.keyConvexUrl) ??
        AppConstants.defaultConvexUrl;
  }

  /// Call a Convex mutation.
  static Future<Map<String, dynamic>?> mutation(
    String path,
    Map<String, dynamic> args,
  ) async {
    try {
      final url = await _getUrl();
      final response = await http
          .post(
            Uri.parse('$url/api/mutation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'path': path, 'args': args}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null; // Graceful failure
    }
  }

  /// Call a Convex query.
  static Future<Map<String, dynamic>?> query(
    String path,
    Map<String, dynamic> args,
  ) async {
    try {
      final url = await _getUrl();
      final response = await http
          .post(
            Uri.parse('$url/api/query'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'path': path, 'args': args}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save device profile to Convex.
  static Future<void> saveProfile({
    required String deviceId,
    required List<String> vibes,
    required String language,
    required List<String> reminderTimes,
  }) async {
    await mutation('deviceProfiles:saveProfile', {
      'deviceId': deviceId,
      'vibes': vibes,
      'language': language,
      'reminderTimes': reminderTimes,
    });
  }

  /// Get device profile from Convex.
  static Future<Map<String, dynamic>?> getProfile(String deviceId) async {
    return await query('deviceProfiles:getProfile', {'deviceId': deviceId});
  }

  /// Get stats (admin).
  static Future<Map<String, dynamic>?> getStats() async {
    return await query('deviceProfiles:getStats', {});
  }

  /// Set admin config.
  static Future<void> setConfig(String key, String value) async {
    await mutation('adminConfig:batchSetConfigs', {
      'configs': [
        {'key': key, 'value': value},
      ],
    });
  }

  /// Set multiple admin configs.
  static Future<bool> batchSetConfigs(List<Map<String, String>> configs) async {
    final result = await mutation('adminConfig:batchSetConfigs', {
      'configs': configs,
    });
    return result != null;
  }

  /// Get admin config.
  static Future<Map<String, dynamic>?> getConfig(String key) async {
    return await query('adminConfig:getConfig', {'key': key});
  }

  /// Get all admin configs.
  static Future<Map<String, dynamic>?> getAllConfigs() async {
    return await query('adminConfig:getAllConfigs', {});
  }

  /// List all admin configs.
  static Future<Map<String, dynamic>?> listConfigs() async {
    return await query('adminConfig:listConfigs', {});
  }
}
