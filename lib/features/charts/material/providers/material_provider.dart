import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cached_result.dart';
import '../../../../core/providers/settings_provider.dart';
import '../models/material_models.dart';

part 'material_provider.g.dart';

@riverpod
Future<CachedResult<MaterialData>> materialData(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);
  final cache = CacheManager();
  final cacheKey = CacheKeys.material(scheduleId);

  try {
    final json = await api.fetchMaterial(scheduleId: scheduleId);
    final data = MaterialData.fromJson(json);

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
          data: MaterialData.fromJson(json),
          isStale: true,
          cacheKey: cacheKey,
        );
      }
    } catch (_) {}
    rethrow;
  }
}
