import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/settings_provider.dart';
import '../models/kpi_data.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardData> dashboardData(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final activeId = ref.watch(activeScheduleNotifierProvider);

  // Fetch the full Pareto front
  final front = await api.fetchParetoFront(limit: 200);
  if (front.isEmpty) {
    return DashboardData(
      scheduleId: 0,
      objective: 'N/A',
      solveStatus: 'N/A',
      kpis: [],
      fetchedAt: DateTime.now(),
    );
  }

  // Find the active schedule or use the first one
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

  return DashboardData(
    scheduleId: scheduleId,
    objective: objective,
    solveStatus: solveStatus,
    kpis: kpis,
    fetchedAt: DateTime.now(),
  );
}
