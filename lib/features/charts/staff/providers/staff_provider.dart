import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cached_result.dart';
import '../../../../core/providers/settings_provider.dart';
import '../models/staff_models.dart';

part 'staff_provider.g.dart';

@riverpod
Future<CachedResult<StaffData>> staffData(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);
  final cache = CacheManager();
  final cacheKey = CacheKeys.staff(scheduleId);

  try {
    final json = await api.fetchStaff(scheduleId: scheduleId);
    final data = StaffData.fromJson(json);

    try {
      cache.put(cacheKey, jsonEncode(json));
    } catch (_) {}

    return CachedResult(data: data, cacheKey: cacheKey);
  } catch (e) {
    try {
      final cached = cache.getStale(cacheKey);
      if (cached != null) {
        final json = jsonDecode(cached as String) as Map<String, dynamic>;
        return CachedResult(
          data: StaffData.fromJson(json),
          isStale: true,
          cacheKey: cacheKey,
        );
      }
    } catch (_) {}
    rethrow;
  }
}
