import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cached_result.dart';
import '../../../core/providers/settings_provider.dart';
import '../models/kpi_data.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<CachedResult<DashboardData>> dashboardData(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final activeId = ref.watch(activeScheduleNotifierProvider);
  final cache = CacheManager();
  const cacheKey = CacheKeys.dashboard;

  try {
    final front = await api.fetchParetoFront(limit: 200);
    if (front.isEmpty) {
      return CachedResult(
        data: DashboardData(
          scheduleId: 0,
          objective: 'N/A',
          solveStatus: 'N/A',
          kpis: [],
          fetchedAt: DateTime.now(),
        ),
        cacheKey: cacheKey,
      );
    }

    final active = activeId != null
        ? front.firstWhere(
            (s) => s['schedule_id'] == activeId,
            orElse: () => front.first,
          )
        : front.first;

    final scheduleId = active['schedule_id'] as int;
    final objective = active['objective'] as String? ?? 'unknown';
    final solveStatus = active['solve_status'] as String? ?? 'unknown';
    final metrics = active['pareto_metrics'] as Map<String, dynamic>;
    final kpis = computeRagCards(front, metrics);

    final data = DashboardData(
      scheduleId: scheduleId,
      objective: objective,
      solveStatus: solveStatus,
      kpis: kpis,
      fetchedAt: DateTime.now(),
    );

    try {
      cache.put(cacheKey, jsonEncode(front));
    } catch (_) {}

    return CachedResult(data: data, cacheKey: cacheKey);
  } catch (e) {
    try {
      final cached = cache.getStale(cacheKey);
      if (cached != null) {
        final front =
            (jsonDecode(cached as String) as List).cast<Map<String, dynamic>>();
        if (front.isNotEmpty) {
          final active = activeId != null
              ? front.firstWhere(
                  (s) => s['schedule_id'] == activeId,
                  orElse: () => front.first,
                )
              : front.first;

          final scheduleId = active['schedule_id'] as int;
          final objective = active['objective'] as String? ?? 'unknown';
          final solveStatus = active['solve_status'] as String? ?? 'unknown';
          final metrics = active['pareto_metrics'] as Map<String, dynamic>;
          final kpis = computeRagCards(front, metrics);

          return CachedResult(
            data: DashboardData(
              scheduleId: scheduleId,
              objective: objective,
              solveStatus: solveStatus,
              kpis: kpis,
              fetchedAt: DateTime.now(),
            ),
            isStale: true,
            cacheKey: cacheKey,
          );
        }
      }
    } catch (_) {}
    rethrow;
  }
}
