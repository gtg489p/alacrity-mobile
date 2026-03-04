import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cached_result.dart';
import '../models/pareto_models.dart';

part 'pareto_provider.g.dart';

@riverpod
Future<CachedResult<List<ParetoSolution>>> paretoFront(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final cache = CacheManager();
  const cacheKey = CacheKeys.paretoFront;

  try {
    final rawList = await api.fetchParetoFront(limit: 100);
    final data = rawList.map((j) => ParetoSolution.fromJson(j)).toList();

    try {
      cache.put(cacheKey, jsonEncode(rawList));
    } catch (_) {}

    return CachedResult(data: data, cacheKey: cacheKey);
  } catch (e) {
    try {
      final cached = cache.getStale(cacheKey);
      if (cached != null) {
        final rawList = (jsonDecode(cached as String) as List)
            .cast<Map<String, dynamic>>();
        return CachedResult(
          data: rawList.map((j) => ParetoSolution.fromJson(j)).toList(),
          isStale: true,
          cacheKey: cacheKey,
        );
      }
    } catch (_) {}
    rethrow;
  }
}
