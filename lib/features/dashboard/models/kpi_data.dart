import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/rag_colors.dart';

enum KpiRagStatus { green, amber, red }

class KpiRagData {
  final String label;
  final double value;
  final String unit;
  final double percentile;
  final Color color;

  const KpiRagData({
    required this.label,
    required this.value,
    required this.unit,
    required this.percentile,
    required this.color,
  });
}

class DashboardData {
  final int scheduleId;
  final String objective;
  final String solveStatus;
  final List<KpiRagData> kpis;
  final DateTime fetchedAt;

  const DashboardData({
    required this.scheduleId,
    required this.objective,
    required this.solveStatus,
    required this.kpis,
    required this.fetchedAt,
  });
}

List<KpiRagData> computeRagCards(
  List<Map<String, dynamic>> front,
  Map<String, dynamic> activeMetrics,
) {
  const kpiKeys = [
    'tardiness_days',
    'makespan_days',
    'flowtime_days',
    'labor_cost',
    'fg_holding_cost',
    'material_holding_cost',
    'restock_cost',
    'fg_shipping_cost',
  ];
  const kpiLabels = [
    'Tardiness',
    'Makespan',
    'Flowtime',
    'Labor Cost',
    'FG Holding',
    'Mat Holding',
    'Restock',
    'Shipping',
  ];
  const kpiUnits = [
    'days',
    'days',
    'days',
    'USD',
    'USD',
    'USD',
    'USD',
    'USD',
  ];

  return List.generate(kpiKeys.length, (i) {
    final key = kpiKeys[i];
    final values = front
        .map(
          (s) =>
              ((s['pareto_metrics'] as Map<String, dynamic>)[key] as num?)
                  ?.toDouble() ??
              0.0,
        )
        .toList();
    final minVal = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxVal = values.isEmpty ? 0.0 : values.reduce(math.max);
    final value = (activeMetrics[key] as num?)?.toDouble() ?? 0.0;
    final pct = RagColors.computePercentile(value, minVal, maxVal);

    return KpiRagData(
      label: kpiLabels[i],
      value: value,
      unit: kpiUnits[i],
      percentile: pct,
      color: RagColors.fromPercentile(pct),
    );
  });
}
