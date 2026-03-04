/// Pareto front data models.
///
/// Parsed from GET /pareto-front/?limit=100
/// Plain Dart classes matching codebase conventions.

// ---------------------------------------------------------------------------
// ParetoMetrics — 8 KPI values for a single solution
// ---------------------------------------------------------------------------

class ParetoMetrics {
  final double tardinessDays;
  final double makespanDays;
  final double flowtimeDays;
  final double laborCost;
  final double fgHoldingCost;
  final double materialHoldingCost;
  final double restockCost;
  final double fgShippingCost;

  const ParetoMetrics({
    required this.tardinessDays,
    required this.makespanDays,
    required this.flowtimeDays,
    required this.laborCost,
    required this.fgHoldingCost,
    required this.materialHoldingCost,
    required this.restockCost,
    required this.fgShippingCost,
  });

  factory ParetoMetrics.fromJson(Map<String, dynamic> json) => ParetoMetrics(
        tardinessDays: (json['tardiness_days'] as num).toDouble(),
        makespanDays: (json['makespan_days'] as num).toDouble(),
        flowtimeDays: (json['flowtime_days'] as num).toDouble(),
        laborCost: (json['labor_cost'] as num).toDouble(),
        fgHoldingCost: (json['fg_holding_cost'] as num).toDouble(),
        materialHoldingCost: (json['material_holding_cost'] as num).toDouble(),
        restockCost: (json['restock_cost'] as num).toDouble(),
        fgShippingCost: (json['fg_shipping_cost'] as num).toDouble(),
      );

  /// Access any KPI by key string.
  double getByKey(String key) => switch (key) {
        'tardiness_days' => tardinessDays,
        'makespan_days' => makespanDays,
        'flowtime_days' => flowtimeDays,
        'labor_cost' => laborCost,
        'fg_holding_cost' => fgHoldingCost,
        'material_holding_cost' => materialHoldingCost,
        'restock_cost' => restockCost,
        'fg_shipping_cost' => fgShippingCost,
        _ => 0.0,
      };
}

// ---------------------------------------------------------------------------
// ParetoSolution — one schedule on the Pareto front
// ---------------------------------------------------------------------------

class ParetoSolution {
  final int scheduleId;
  final String createdAt;
  final String objective;
  final String solveStatus;
  final double solveTime;
  final ParetoMetrics paretoMetrics;

  const ParetoSolution({
    required this.scheduleId,
    required this.createdAt,
    required this.objective,
    required this.solveStatus,
    required this.solveTime,
    required this.paretoMetrics,
  });

  factory ParetoSolution.fromJson(Map<String, dynamic> json) => ParetoSolution(
        scheduleId: json['schedule_id'] as int,
        createdAt: json['created_at'] as String? ?? '',
        objective: json['objective'] as String? ?? 'unknown',
        solveStatus: json['solve_status'] as String? ?? 'unknown',
        solveTime: (json['solve_time'] as num?)?.toDouble() ?? 0.0,
        paretoMetrics: ParetoMetrics.fromJson(
            json['pareto_metrics'] as Map<String, dynamic>),
      );
}

// ---------------------------------------------------------------------------
// KPI axis definitions
// ---------------------------------------------------------------------------

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

const kpiLabels = {
  'tardiness_days': 'Tardiness (days)',
  'makespan_days': 'Makespan (days)',
  'flowtime_days': 'Flowtime (days)',
  'labor_cost': 'Labor Cost',
  'fg_holding_cost': 'FG Holding Cost',
  'material_holding_cost': 'Material Holding',
  'restock_cost': 'Restock Cost',
  'fg_shipping_cost': 'Shipping Cost',
};

const kpiShortLabels = {
  'tardiness_days': 'Tardiness',
  'makespan_days': 'Makespan',
  'flowtime_days': 'Flowtime',
  'labor_cost': 'Labor',
  'fg_holding_cost': 'FG Hold',
  'material_holding_cost': 'Mat Hold',
  'restock_cost': 'Restock',
  'fg_shipping_cost': 'Shipping',
};

const kpiUnits = {
  'tardiness_days': 'days',
  'makespan_days': 'days',
  'flowtime_days': 'days',
  'labor_cost': 'USD',
  'fg_holding_cost': 'USD',
  'material_holding_cost': 'USD',
  'restock_cost': 'USD',
  'fg_shipping_cost': 'USD',
};
