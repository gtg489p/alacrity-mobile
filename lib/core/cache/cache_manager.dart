import 'package:hive_ce/hive.dart';

/// Hive-backed API cache with TTL support.
/// Stores API responses with timestamps for offline fallback.
class CacheManager {
  static const Duration defaultTtl = Duration(hours: 1);

  Box<dynamic> get _box => Hive.box('cache');

  /// Store API response data with current timestamp.
  void put(String key, dynamic data) {
    _box.put(key, {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieve cached data regardless of staleness (for offline mode).
  dynamic getStale(String key) {
    final entry = _box.get(key) as Map<dynamic, dynamic>?;
    return entry?['data'];
  }

  /// Check if cached data exists and is past TTL.
  bool isStale(String key, {Duration ttl = defaultTtl}) {
    final entry = _box.get(key) as Map<dynamic, dynamic>?;
    if (entry == null) return true;
    final cachedAt = DateTime.parse(entry['cached_at'] as String);
    return DateTime.now().difference(cachedAt) > ttl;
  }

  /// Get the age of cached data, or null if not cached.
  Duration? getAge(String key) {
    final entry = _box.get(key) as Map<dynamic, dynamic>?;
    if (entry == null) return null;
    final cachedAt = DateTime.parse(entry['cached_at'] as String);
    return DateTime.now().difference(cachedAt);
  }
}

/// Cache key generators for each data type.
class CacheKeys {
  static String gantt(int? scheduleId) => 'gantt:${scheduleId ?? "active"}';
  static String material(int? scheduleId) =>
      'material:${scheduleId ?? "active"}';
  static String staff(int? scheduleId) => 'staff:${scheduleId ?? "active"}';
  static String fg(int? scheduleId) => 'fg:${scheduleId ?? "active"}';
  static String trucks(int? scheduleId) => 'trucks:${scheduleId ?? "active"}';
  static const String paretoFront = 'pareto_front';
  static const String dashboard = 'dashboard';
  static const String disruptions = 'disruptions';
}
