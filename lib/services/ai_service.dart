import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import 'convex_service.dart';

/// Abstract AI provider interface.
abstract class AiProvider {
  String get name;
  Future<String> generateRoast(List<String> vibes, String language);
}

/// Groq AI provider (OpenAI-compatible API).
class GroqProvider implements AiProvider {
  @override
  String get name => 'Groq';

  @override
  Future<String> generateRoast(List<String> vibes, String language) async {
    final apiKey = await AiService.getApiKey('groq');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key not configured');
    }

    final prompt = AppConstants.buildPrompt(vibes, language);

    final model = await AiService.getAiModel('groq');

    final response = await http
        .post(
          Uri.parse('${AppConstants.groqBaseUrl}/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 1.0,
            'max_completion_tokens': 150,
            'top_p': 0.95,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content == null || content.toString().trim().isEmpty) {
      throw Exception('Empty response from Groq');
    }

    // Clean up the response - remove thinking tags if present
    String cleaned = content.toString().trim();
    cleaned = cleaned.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    return cleaned;
  }
}

/// Cerebras AI provider.
class CerebrasProvider implements AiProvider {
  @override
  String get name => 'Cerebras';

  @override
  Future<String> generateRoast(List<String> vibes, String language) async {
    final apiKey = await AiService.getApiKey('cerebras');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Cerebras API key not configured');
    }

    final prompt = AppConstants.buildPrompt(vibes, language);

    final model = await AiService.getAiModel('cerebras');

    final response = await http
        .post(
          Uri.parse('${AppConstants.cerebrasBaseUrl}/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.9,
            'max_tokens': 150,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Cerebras API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content == null || content.toString().trim().isEmpty) {
      throw Exception('Empty response from Cerebras');
    }

    return content.toString().trim();
  }
}

/// AI Service — manages provider selection, fallback, and rate limiting.
class AiService {
  static final Map<String, AiProvider> _providers = {
    'groq': GroqProvider(),
    'cerebras': CerebrasProvider(),
  };

  /// Fetch API key — tries Convex first, falls back to local cache.
  static Future<String?> getApiKey(String provider) async {
    final cacheKey = provider == 'groq'
        ? AppConstants.keyGroqApiKey
        : AppConstants.keyCerebrasApiKey;

    // Check if cached keys are still valid (1 hour TTL)
    final cachedTime =
        await SecureStorage.read(AppConstants.keyCachedKeysTime) ?? '0';
    final cacheAge =
        DateTime.now().millisecondsSinceEpoch - int.parse(cachedTime);
    final isCacheValid =
        cacheAge < AppConstants.apiKeyCacheTtlMinutes * 60 * 1000;

    final cachedValue = await SecureStorage.read(cacheKey);

    // If cache looks like a JSON string (corruption from old bug) or is expired, refresh
    final looksCorrupt =
        cachedValue != null &&
        (cachedValue.startsWith('{') || cachedValue.contains('updatedAt'));

    if (!isCacheValid || looksCorrupt) {
      if (looksCorrupt) {
        debugPrint(
          'AiService: Detected corrupted cache for $provider, refreshing...',
        );
      }

      // Try fetching from Convex
      try {
        final configKey = provider == 'groq'
            ? 'groq_api_key'
            : 'cerebras_api_key';
        final result = await ConvexService.getConfig(configKey);
        if (result != null && result['value'] != null) {
          // Convex returns {"value": {"key": "...", "value": "..."}}
          final configDoc = result['value'] as Map<String, dynamic>;
          final key = configDoc['value']?.toString() ?? '';
          await SecureStorage.write(cacheKey, key);
          await SecureStorage.write(
            AppConstants.keyCachedKeysTime,
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
          return key;
        }
      } catch (e) {
        debugPrint('AiService: Convex fetch failed for $provider: $e');
      }
    }

    // Return local cache
    return cachedValue;
  }

  /// Fetch AI Model — tries Convex first, falls back to local cache or default.
  static Future<String> getAiModel(String provider) async {
    final cacheKey = provider == 'groq'
        ? AppConstants.keyGroqModel
        : AppConstants.keyCerebrasModel;
    final defaultModel = provider == 'groq'
        ? AppConstants.defaultGroqModel
        : AppConstants.defaultCerebrasModel;

    // Check if cached keys/models are still valid
    final cachedTime =
        await SecureStorage.read(AppConstants.keyCachedKeysTime) ?? '0';
    final cacheAge =
        DateTime.now().millisecondsSinceEpoch - int.parse(cachedTime);
    final isCacheValid =
        cacheAge < AppConstants.apiKeyCacheTtlMinutes * 60 * 1000;

    if (!isCacheValid) {
      try {
        final configKey = provider == 'groq' ? 'groq_model' : 'cerebras_model';
        final result = await ConvexService.getConfig(configKey);

        if (result != null && result['value'] != null) {
          final configDoc = result['value'] as Map<String, dynamic>;
          final modelName = configDoc['value']?.toString() ?? '';
          if (modelName.isNotEmpty) {
            await SecureStorage.write(cacheKey, modelName);
            return modelName;
          }
        }
      } catch (e) {
        debugPrint('AiService: Convex model fetch failed for $provider: $e');
      }
    }

    final cachedModel = await SecureStorage.read(cacheKey);
    return (cachedModel != null && cachedModel.isNotEmpty)
        ? cachedModel
        : defaultModel;
  }

  /// Generate a roast.
  /// [source] = 'manual' (unlimited) or 'reminder' (rate-limited).
  static Future<AiResult> generateRoast(
    List<String> vibes,
    String language, {
    String source = 'manual',
  }) async {
    // Get primary provider
    final primaryName =
        await SecureStorage.read(AppConstants.keyPrimaryAiProvider) ?? 'groq';
    final secondaryName = primaryName == 'groq' ? 'cerebras' : 'groq';

    final primary = _providers[primaryName]!;
    final secondary = _providers[secondaryName]!;

    // Try primary, then retry once, then fallback to secondary
    try {
      debugPrint('AiService: Trying primary provider ${primary.name}...');
      final result = await primary.generateRoast(vibes, language);
      return AiResult(success: true, message: result, provider: primary.name);
    } catch (e) {
      debugPrint('AiService: Primary provider ${primary.name} failed: $e');
      // Retry primary once
      try {
        debugPrint('AiService: Retrying primary provider ${primary.name}...');
        final result = await primary.generateRoast(vibes, language);
        return AiResult(success: true, message: result, provider: primary.name);
      } catch (_) {
        // Try secondary
        try {
          debugPrint(
            'AiService: Trying secondary provider ${secondary.name}...',
          );
          final result = await secondary.generateRoast(vibes, language);
          return AiResult(
            success: true,
            message: result,
            provider: secondary.name,
          );
        } catch (e2) {
          debugPrint(
            'AiService: Secondary provider ${secondary.name} failed: $e2',
          );
          return AiResult(
            success: false,
            message: e2.toString(),
            isOffline: true,
          );
        }
      }
    }
  }

  /// Check if any API key is available (from Convex or local).
  static Future<bool> hasApiKeys() async {
    final groq = await getApiKey('groq');
    final cerebras = await getApiKey('cerebras');
    return (groq != null && groq.isNotEmpty) ||
        (cerebras != null && cerebras.isNotEmpty);
  }
}

/// Result from AI generation.
class AiResult {
  final bool success;
  final String message;
  final String? provider;
  final bool isRateLimited;
  final bool isOffline;

  AiResult({
    required this.success,
    required this.message,
    this.provider,
    this.isRateLimited = false,
    this.isOffline = false,
  });
}
