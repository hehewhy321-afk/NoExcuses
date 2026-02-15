import 'dart:convert';
import '../core/constants.dart';
import '../core/secure_storage.dart';

/// Roast history entry.
class RoastEntry {
  final String text;
  final DateTime timestamp;
  final String? provider;
  final String source; // 'manual' or 'notification'

  RoastEntry({
    required this.text,
    required this.timestamp,
    this.provider,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'provider': provider,
    'source': source,
  };

  factory RoastEntry.fromJson(Map<String, dynamic> json) => RoastEntry(
    text: json['text'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    provider: json['provider'],
    source: json['source'] ?? 'manual',
  );
}

/// Service for storing and retrieving roast history in local storage.
class RoastHistoryService {
  /// Get all roast entries (newest first).
  static Future<List<RoastEntry>> getHistory() async {
    final raw = await SecureStorage.read(AppConstants.keyRoastHistory);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      final entries = list.map((e) => RoastEntry.fromJson(e)).toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Add a new roast entry.
  static Future<void> addRoast({
    required String text,
    String? provider,
    String source = 'manual',
  }) async {
    final history = await getHistory();

    history.insert(
      0,
      RoastEntry(
        text: text,
        timestamp: DateTime.now(),
        provider: provider,
        source: source,
      ),
    );

    // Prune to max entries
    final pruned = history.take(AppConstants.maxHistoryEntries).toList();

    final json = jsonEncode(pruned.map((e) => e.toJson()).toList());
    await SecureStorage.write(AppConstants.keyRoastHistory, json);
  }

  /// Delete a roast entry by index.
  static Future<void> deleteRoast(int index) async {
    final history = await getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final json = jsonEncode(history.map((e) => e.toJson()).toList());
      await SecureStorage.write(AppConstants.keyRoastHistory, json);
    }
  }

  /// Clear all history.
  static Future<void> clearHistory() async {
    await SecureStorage.write(AppConstants.keyRoastHistory, '[]');
  }

  /// Get total roast count.
  static Future<int> totalRoasts() async {
    final history = await getHistory();
    return history.length;
  }
}
